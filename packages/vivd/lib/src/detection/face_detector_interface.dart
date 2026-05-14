import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// FaceDetectorInterface — abstraction for pluggable face detection.
///
/// Default implementation uses Google ML Kit Face Detection.
/// Fallback options: MediaPipe, InsightFace ONNX, Apple Vision.
///
/// Usage:
/// ```dart
/// final detector = MlKitFaceDetector();
/// await detector.initialize();
/// final faces = await detector.detect(imageBytes, width: 640, height: 480);
/// await detector.dispose();
/// ```
abstract class FaceDetectorInterface {
  /// Human-readable name of this detector.
  String get name;

  /// Initialize the detector. Must be called before [detect].
  Future<void> initialize();

  /// Detect faces in a camera frame.
  ///
  /// [bytes] — raw image bytes (NV21, YUV420, or BGRA depending on platform).
  /// [width] — image width in pixels.
  /// [height] — image height in pixels.
  /// [rotation] — clockwise rotation of image (0, 90, 180, 270).
  /// [format] — input format hint.
  ///
  /// Returns list of detected faces (empty if none found).
  Future<List<FaceDetection>> detect(
    Uint8List bytes, {
    required int width,
    required int height,
    int rotation = 0,
    InputImageFormat format = InputImageFormat.nv21,
  });

  /// Release resources. Call when done using the detector.
  Future<void> dispose();
}

/// Input image format.
enum InputImageFormat {
  /// Android default — NV21 (YUV420 semi-planar).
  nv21,

  /// iOS default — BGRA8888.
  bgra8888,

  /// YUV420 planar.
  yuv420,

  /// RGB888.
  rgb888,
}

/// Detected face bounding box and landmarks.
class FaceDetection {
  const FaceDetection({
    required this.boundingBox,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smiling,
    this.headEulerAngleX,
    this.headEulerAngleY,
    this.headEulerAngleZ,
    this.leftEyePosition,
    this.rightEyePosition,
    this.noseBasePosition,
    this.bottomMouthPosition,
    this.landmarks = const [],
  });

  /// Axis-aligned bounding box of the face.
  final Rect boundingBox;

  /// Left eye open probability (0.0 = closed, 1.0 = open).
  /// `null` if not detected.
  final double? leftEyeOpen;

  /// Right eye open probability (0.0 = closed, 1.0 = open).
  /// `null` if not detected.
  final double? rightEyeOpen;

  /// Smiling probability (0.0 = not smiling, 1.0 = smiling).
  /// `null` if not detected.
  final double? smiling;

  /// Head rotation around the X-axis (tilt up/down).
  /// Negative = looking up, positive = looking down.
  final double? headEulerAngleX;

  /// Head rotation around the Y-axis (turn left/right).
  /// Negative = looking left, positive = looking right.
  final double? headEulerAngleY;

  /// Head rotation around the Z-axis (tilt left/right).
  /// Negative = tilt left, positive = tilt right.
  final double? headEulerAngleZ;

  /// Position of the left eye center.
  final Point<double>? leftEyePosition;

  /// Position of the right eye center.
  final Point<double>? rightEyePosition;

  /// Position of the nose base.
  final Point<double>? noseBasePosition;

  /// Position of the bottom of the mouth.
  final Point<double>? bottomMouthPosition;

  /// All face landmarks as key-value pairs.
  final Map<String, Point<double>> landmarks;

  /// Average eye open probability (both eyes).
  double? get avgEyeOpen {
    if (leftEyeOpen == null && rightEyeOpen == null) return null;
    final l = leftEyeOpen ?? 0.0;
    final r = rightEyeOpen ?? 0.0;
    return (l + r) / 2;
  }

  /// Whether both eyes are likely closed (below threshold).
  bool areEyesClosed({double threshold = 0.3}) {
    final avg = avgEyeOpen;
    return avg != null && avg < threshold;
  }

  /// Whether both eyes are likely open (above threshold).
  bool areEyesOpen({double threshold = 0.7}) {
    final avg = avgEyeOpen;
    return avg != null && avg >= threshold;
  }

  /// Whether the person is likely smiling (above threshold).
  bool isSmiling({double threshold = 0.7}) {
    return smiling != null && smiling! >= threshold;
  }

  /// Whether head is turned left beyond threshold.
  bool isHeadTurnedLeft({double threshold = -20.0}) {
    return headEulerAngleY != null && headEulerAngleY! < threshold;
  }

  /// Whether head is turned right beyond threshold.
  bool isHeadTurnedRight({double threshold = 20.0}) {
    return headEulerAngleY != null && headEulerAngleY! > threshold;
  }

  /// Whether head is looking up beyond threshold.
  bool isLookingUp({double threshold = -15.0}) {
    return headEulerAngleX != null && headEulerAngleX! < threshold;
  }

  /// Whether head is looking down beyond threshold.
  bool isLookingDown({double threshold = 15.0}) {
    return headEulerAngleX != null && headEulerAngleX! > threshold;
  }

  /// Face width from bounding box.
  double get faceWidth => boundingBox.width;

  /// Face height from bounding box.
  double get faceHeight => boundingBox.height;

  /// Face area in pixels squared.
  double get faceArea => boundingBox.width * boundingBox.height;

  @override
  String toString() =>
      'FaceDetection(box: $boundingBox, eyes: $avgEyeOpen, '
      'smile: $smiling, headY: $headEulerAngleY)';
}
