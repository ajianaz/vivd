/// FaceDetectorInterface — abstraction for pluggable face detection.
///
/// Default implementation uses Google ML Kit Face Detection.
/// Fallback options: MediaPipe, InsightFace ONNX, Apple Vision.
library;

/// Detected face bounding box and landmarks.
class FaceDetection {
  final Rect boundingBox;
  final double? leftEyeOpen;
  final double? rightEyeOpen;
  final double? smileProbability;
  final double? headEulerAngleY;
  final double? headEulerAngleX;

  const FaceDetection({
    required this.boundingBox,
    this.leftEyeOpen,
    this.rightEyeOpen,
    this.smileProbability,
    this.headEulerAngleY,
    this.headEulerAngleX,
  });
}

/// Interface for face detection backends.
///
/// Implementations:
/// - [MlKitFaceDetector] — Google ML Kit (default, on-device)
/// - MediaPipe (future fallback)
/// - InsightFace ONNX (future fallback)
/// - Apple Vision (future fallback, iOS only)
abstract class FaceDetectorInterface {
  /// Detect faces in a camera frame.
  Future<List<FaceDetection>> detect(CameraFrame frame);

  /// Dispose resources.
  void dispose();

  /// Human-readable name of this detector.
  String get name;
}
