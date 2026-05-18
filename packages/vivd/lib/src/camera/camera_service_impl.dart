import 'dart:async';

import 'package:camera/camera.dart' as cam;
import 'package:flutter/foundation.dart';

import 'camera_service.dart';

/// Concrete [CameraService] implementation using the `camera` Flutter plugin.
///
/// Handles front camera initialization, YUV/BGRA frame streaming,
/// and platform-specific byte format conversion.
///
/// ```dart
/// final camera = CameraServiceImpl();
/// await camera.initialize();
/// camera.frameStream.listen((frame) { /* process */ });
/// await camera.dispose();
/// ```
class CameraServiceImpl extends CameraService {
  cam.CameraController? _controller;
  StreamController<CameraFrame>? _frameController;
  bool _isRunning = false;
  int _width = 0;
  int _height = 0;
  int _sensorOrientation = 0;
  bool _disposed = false;

  /// The underlying camera controller for preview rendering.
  /// Exposed so that [VivdLivenessDetector] can build a camera preview.
  @visibleForTesting
  cam.CameraController? get controller => _controller;

  @override
  Future<void> initialize() async {
    if (_disposed) {
      throw CameraException(CameraError.unknown, 'CameraService disposed');
    }

    final cameras = await cam.availableCameras();
    if (cameras.isEmpty) {
      throw CameraException(CameraError.noCamera, 'No cameras available');
    }

    final front = cameras.firstWhere(
      (c) => c.lensDirection == cam.CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = cam.CameraController(
      front,
      cam.ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
    } on cam.CameraException catch (e) {
      if (e.code == 'CameraAccessDenied') {
        throw CameraException(CameraError.permissionDenied, e.description ?? '');
      }
      throw CameraException(
        CameraError.unknown,
        'Failed to initialize camera: ${e.description ?? e.code}',
      );
    }

    final size = _controller!.value.previewSize;
    if (size != null) {
      // Camera sensor outputs in landscape; swap for portrait preview.
      _width = size.height.toInt();
      _height = size.width.toInt();
    }

    _sensorOrientation = front.sensorOrientation;

    debugPrint('[Vivd] Camera: ${front.name} '
        'sensorOrientation=$_sensorOrientation '
        'previewSize=${size?.width}x${size?.height} '
        'lensDirection=${front.lensDirection}');

    _frameController = StreamController<CameraFrame>.broadcast();
  }

  @override
  Future<void> start() async {
    _ensureController();
    if (_isRunning) return;

    await _controller!.startImageStream(_onFrame);
    _isRunning = true;
  }

  @override
  Future<void> pause() async {
    if (_controller != null && _isRunning) {
      await _controller!.stopImageStream();
      _isRunning = false;
    }
  }

  @override
  Future<void> resume() async {
    if (_controller != null && !_isRunning && !_disposed) {
      await _controller!.startImageStream(_onFrame);
      _isRunning = true;
    }
  }

  @override
  Future<void> stop() async {
    await pause();
  }

  @override
  Stream<CameraFrame> get frameStream {
    _ensureController();
    return _frameController!.stream;
  }

  @override
  int get resolutionWidth => _width;

  @override
  int get resolutionHeight => _height;

  @override
  bool get isRunning => _isRunning;

  @override
  Future<void> dispose() async {
    _disposed = true;
    _isRunning = false;
    // Close stream controller first to unblock any listeners.
    await _frameController?.close();
    // Stop image stream with timeout to prevent hanging.
    try {
      await _controller?.stopImageStream().timeout(const Duration(seconds: 2));
    } catch (_) {}
    try {
      await _controller?.dispose();
    } catch (_) {}
    _controller = null;
    _frameController = null;
  }

  /// Build a [CameraPreview] widget for this camera.
  ///
  /// Call only after [initialize].
  cam.CameraPreview buildPreview() {
    _ensureController();
    return cam.CameraPreview(_controller!);
  }

  /// Convert platform CameraImage to our unified [CameraFrame].
  void _onFrame(cam.CameraImage image) {
    if (_disposed || _frameController == null || _frameController!.isClosed) {
      return;
    }

    final bytes = _convertCameraImage(image);
    if (bytes == null) return;

    // Determine source format to know if conversion happened.
    final srcFormat = _detectFormat(image);
    // After _convertCameraImage, all Android formats become NV21.
    // BGRA8888 (iOS) stays BGRA8888.
    final outputFormat = srcFormat == VivdImageFormat.bgra8888
        ? VivdImageFormat.bgra8888
        : VivdImageFormat.nv21;

    // Log first frame info
    if (_frameController!.hasListener && !_frameController!.isClosed) {
      final yPlane = image.planes.isNotEmpty ? image.planes[0] : null;
      if (yPlane != null && image.width > 0) {
        debugPrint('[Vivd] Frame: ${image.width}x${image.height} '
            'format=0x${image.format.raw.toRadixString(16)} '
            'yStride=${yPlane.bytesPerRow} '
            'planes=${image.planes.length} '
            'rotation=$_sensorOrientation '
            'bytesLen=${bytes.length}');
      }
    }

    final frame = CameraFrame(
      bytes: bytes,
      width: image.width,
      height: image.height,
      format: outputFormat,
      rotation: _sensorOrientation,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    _frameController!.add(frame);
  }

  /// Detect the image format from [cam.CameraImage].
  VivdImageFormat _detectFormat(cam.CameraImage image) {
    return switch (image.format.raw) {
      // Android NV21
      0x11 => VivdImageFormat.nv21,
      // Android YUV420
      0x23 => VivdImageFormat.yuv420,
      // iOS BGRA8888
      0x20 => VivdImageFormat.bgra8888,
      _ => VivdImageFormat.nv21,
    };
  }

  /// Convert [cam.CameraImage] planes into a single [Uint8List].
  ///
  /// Properly handles row stride and pixel stride for YUV420 on Android.
  /// For NV21 (Android): concatenate Y + VU planes (stride-aware).
  /// For BGRA8888 (iOS): use the single plane directly.
  Uint8List? _convertCameraImage(cam.CameraImage image) {
    try {
      final format = _detectFormat(image);

      if (format == VivdImageFormat.bgra8888) {
        // iOS: single plane, copy directly
        if (image.planes.isEmpty) return null;
        return Uint8List.fromList(image.planes.first.bytes);
      }

      final planes = image.planes;
      if (planes.isEmpty) return null;

      final width = image.width;
      final height = image.height;
      final yPlane = planes[0];
      final yRowStride = yPlane.bytesPerRow;

      final totalSize = width * height * 3 ~/ 2;
      final bytes = Uint8List(totalSize);

      // Copy Y plane — strip row padding
      if (yRowStride == width) {
        bytes.setRange(0, width * height, yPlane.bytes);
      } else {
        for (var row = 0; row < height; row++) {
          final srcStart = row * yRowStride;
          bytes.setRange(
            row * width,
            row * width + width,
            yPlane.bytes.sublist(srcStart, srcStart + width),
          );
        }
      }

      if (planes.length >= 3 && format == VivdImageFormat.yuv420) {
        // YUV420: interleave V and U into NV21 format (stride-aware)
        final uPlane = planes[1];
        final vPlane = planes[2];
        final uvRowStride = uPlane.bytesPerRow;
        final uvPixelStride = uPlane.bytesPerPixel ?? 1;
        final uvHeight = height ~/ 2;
        final uvWidth = width ~/ 2;

        var uvIndex = width * height;
        for (var row = 0; row < uvHeight; row++) {
          for (var col = 0; col < uvWidth; col++) {
            final srcIdx = row * uvRowStride + col * uvPixelStride;
            if (srcIdx < vPlane.bytes.length && srcIdx < uPlane.bytes.length) {
              bytes[uvIndex++] = vPlane.bytes[srcIdx]; // V first (NV21 = VU)
              bytes[uvIndex++] = uPlane.bytes[srcIdx]; // U second
            }
          }
        }
      } else if (planes.length >= 2) {
        // NV21: Y + VU plane (already interleaved, strip padding)
        final vuPlane = planes[1];
        final vuRowStride = vuPlane.bytesPerRow;
        final uvHeight = height ~/ 2;
        final uvWidth = width;

        if (vuRowStride == uvWidth) {
          bytes.setRange(width * height, totalSize, vuPlane.bytes);
        } else {
          var dstIdx = width * height;
          for (var row = 0; row < uvHeight; row++) {
            final srcStart = row * vuRowStride;
            bytes.setRange(
              dstIdx,
              dstIdx + uvWidth,
              vuPlane.bytes.sublist(srcStart, srcStart + uvWidth),
            );
            dstIdx += uvWidth;
          }
        }
      }

      return bytes;
    } catch (_) {
      return null;
    }
  }

  void _ensureController() {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException(
        CameraError.unknown,
        'Camera not initialized. Call initialize() first.',
      );
    }
  }
}
