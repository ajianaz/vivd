/// Anti-spoof engine — ONNX-based presentation attack detection.
///
/// This is the core anti-spoofing module. In Phase 1, it's a basic
/// texture-analysis stub. In Phase 3, it uses a trained ONNX model.
library;

class AntiSpoofEngine {
  /// Analyze a frame for spoofing indicators.
  /// Returns a score (0.0 = definitely spoofed, 1.0 = definitely real).
  Future<double> analyze(CameraFrame frame) {
    throw UnimplementedError();
  }

  /// Load ONNX model for inference.
  Future<void> loadModel(String modelPath) {
    throw UnimplementedError();
  }
}
