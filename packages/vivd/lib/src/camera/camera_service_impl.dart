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
      cam.ResolutionPreset.high,
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
      _width = size.width.toInt();
      _height = size.height.toInt();
    }

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
    await stop();
    await _frameController?.close();
    await _controller?.dispose();
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

    final frame = CameraFrame(
      bytes: bytes,
      width: image.width,
      height: image.height,
      format: _detectFormat(image),
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
  /// For NV21 (Android): concatenate Y + VU planes.
  /// For BGRA8888 (iOS): use the single plane directly.
  Uint8List? _convertCameraImage(cam.CameraImage image) {
    try {
      final format = _detectFormat(image);

      if (format == VivdImageFormat.bgra8888) {
        // iOS: single plane, copy directly
        if (image.planes.isEmpty) return null;
        return Uint8List.fromList(image.planes.first.bytes);
      }

      // Android: NV21 = Y plane + interleaved VU plane
      // Or YUV420 = Y + U + V separate planes
      final planes = image.planes;
      if (planes.isEmpty) return null;

      final yPlane = planes[0];
      final totalSize = image.width * image.height * 3 ~/ 2;
      final bytes = Uint8List(totalSize);

      // Copy Y plane
      bytes.setRange(0, yPlane.bytes.length, yPlane.bytes);

      if (planes.length >= 3 && format == VivdImageFormat.yuv420) {
        // YUV420: interleave U and V into NV21 format
        final uPlane = planes[1];
        final vPlane = planes[2];
        var uvIndex = yPlane.bytes.length;

        for (var i = 0; i < uPlane.bytes.length; i++) {
          bytes[uvIndex++] = vPlane.bytes[i];
          bytes[uvIndex++] = uPlane.bytes[i];
        }
      } else if (planes.length >= 2) {
        // NV21: Y + VU plane (already interleaved)
        final vuPlane = planes[1];
        bytes.setRange(yPlane.bytes.length, totalSize, vuPlane.bytes);
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
