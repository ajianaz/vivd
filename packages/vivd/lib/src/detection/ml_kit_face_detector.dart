import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../camera/camera_service.dart';
import 'face_detector_interface.dart';

/// ML Kit face detector — default implementation using Google ML Kit.
///
/// On-device, no network required. Supports Android and iOS.
class MlKitFaceDetector implements FaceDetectorInterface {
  FaceDetector? _detector;
  bool _initialized = false;

  /// Classification mode — enable smile and eye open probability.
  final bool enableClassification;

  /// Landmark mode — enable face landmarks (eyes, nose, mouth).
  final bool enableLandmarks;

  /// Contour mode — enable face contour points.
  final bool enableContours;

  /// Minimum face size relative to image (0.0 - 1.0).
  final double minFaceSize;

  /// Performance mode — prioritize speed over accuracy.
  final bool performanceMode;

  MlKitFaceDetector({
    this.enableClassification = true,
    this.enableLandmarks = true,
    this.enableContours = false,
    this.minFaceSize = 0.15,
    this.performanceMode = false,
  });

  @override
  String get name => 'Google ML Kit';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final options = FaceDetectorOptions(
      enableClassification: enableClassification,
      enableLandmarks: enableLandmarks,
      enableContours: enableContours,
      enableTracking: false,
      minFaceSize: minFaceSize,
      performanceMode:
          performanceMode ? FaceDetectorMode.fast : FaceDetectorMode.accurate,
    );

    _detector = FaceDetector(options: options);
    _initialized = true;
  }

  @override
  Future<List<FaceDetection>> detect(
    Uint8List bytes, {
    required int width,
    required int height,
    int rotation = 0,
    VivdImageFormat format = VivdImageFormat.nv21,
  }) async {
    if (!_initialized) {
      throw StateError(
          'MlKitFaceDetector not initialized. Call initialize() first.');
    }

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: _toInputImageRotation(rotation),
        format: _toInputImageFormat(format),
        bytesPerRow: width,
      ),
    );

    final faces = await _detector!.processImage(inputImage);
    return faces.map(_convertFace).toList();
  }

  InputImageRotation _toInputImageRotation(int degrees) {
    return switch (degrees) {
      90 => InputImageRotation.rotation90deg,
      180 => InputImageRotation.rotation180deg,
      270 => InputImageRotation.rotation270deg,
      _ => InputImageRotation.rotation0deg,
    };
  }

  InputImageFormat _toInputImageFormat(VivdImageFormat format) {
    return switch (format) {
      VivdImageFormat.nv21 => InputImageFormat.nv21,
      VivdImageFormat.bgra8888 => InputImageFormat.bgra8888,
      VivdImageFormat.yuv420 => InputImageFormat.yuv420,
      VivdImageFormat.rgb888 => InputImageFormat.nv21, // ML Kit handles conversion
    };
  }

  FaceDetection _convertFace(Face face) {
    Offset? _toOffset(dynamic point) {
      if (point == null) return null;
      if (point is Offset) return point;
      if (point is Point) return Offset(point.x.toDouble(), point.y.toDouble());
      return null;
    }

    return FaceDetection(
      boundingBox: face.boundingBox,
      leftEyeOpen: face.leftEyeOpenProbability,
      rightEyeOpen: face.rightEyeOpenProbability,
      smiling: face.smilingProbability,
      headEulerAngleX: face.headEulerAngleX,
      headEulerAngleY: face.headEulerAngleY,
      headEulerAngleZ: face.headEulerAngleZ,
      leftEyePosition:
          _toOffset(face.landmarks[FaceLandmarkType.leftEye]?.position),
      rightEyePosition:
          _toOffset(face.landmarks[FaceLandmarkType.rightEye]?.position),
      noseBasePosition:
          _toOffset(face.landmarks[FaceLandmarkType.noseBase]?.position),
      bottomMouthPosition:
          _toOffset(face.landmarks[FaceLandmarkType.bottomMouth]?.position),
    );
  }

  @override
  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _initialized = false;
  }
}
