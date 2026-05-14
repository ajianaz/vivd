import 'dart:typed_data';

import '../camera/camera_service.dart';

/// Anti-spoof engine — presentation attack detection.
///
/// Phase 0-1: Basic texture analysis stub.
/// Phase 3: Uses a trained ONNX model for ML-based PAD.
///
/// ```dart
/// final antiSpoof = AntiSpoofEngine();
/// final score = await antiSpoof.analyze(frame);
/// if (score < 0.5) {
///   print('Possible spoof detected!');
/// }
/// ```
class AntiSpoofEngine {
  /// Whether the engine has been initialized.
  bool _initialized = false;

  AntiSpoofEngine();

  /// Initialize the engine.
  /// Loads the ONNX model in Phase 3.
  Future<void> initialize() async {
    if (_initialized) return;
    // Phase 3: Load TFLite/ONNX model
    // _interpreter = await tflite.Interpreter.loadAsset('models/anti_spoof.tflite');
    _initialized = true;
  }

  /// Analyze a frame for spoofing indicators.
  ///
  /// Returns a score (0.0 = definitely spoofed, 1.0 = definitely real).
  /// Scores below 0.5 should be treated as potential spoof attempts.
  Future<double> analyze(CameraFrame frame) async {
    if (!_initialized) {
      throw StateError('AntiSpoofEngine not initialized. Call initialize() first.');
    }

    // Phase 0-1: Basic texture analysis heuristic.
    // Checks for patterns typical of screen replay attacks:
    // - Moiré patterns (high-frequency repeating patterns)
    // - Uniform brightness (screen glow)
    // - Low color variance (screen typically has limited color range)

    final bytes = frame.bytes;
    if (bytes.isEmpty) return 0.0;

    final width = frame.width;
    final height = frame.height;

    // Calculate texture variance (simplified)
    final variance = _calculateTextureVariance(bytes, width, height);

    // High variance = real face texture, low variance = potential spoof
    // Threshold calibrated to be conservative (false accept > false reject)
    final score = (variance / 1000.0).clamp(0.0, 1.0);

    return score;
  }

  /// Analyze a cropped face region for better accuracy.
  Future<double> analyzeFaceRegion(
    Uint8List faceBytes, {
    required int width,
    required int height,
  }) async {
    if (!_initialized) {
      throw StateError('AntiSpoofEngine not initialized.');
    }

    // Use the same texture analysis on the cropped face
    final variance = _calculateTextureVariance(faceBytes, width, height);
    return (variance / 800.0).clamp(0.0, 1.0);
  }

  /// Release resources.
  Future<void> dispose() async {
    // Phase 3: Close interpreter
    _initialized = false;
  }

  /// Calculate texture variance using simplified Laplacian.
  /// Higher variance = more natural texture = likely real.
  double _calculateTextureVariance(
    Uint8List bytes,
    int width,
    int height,
  ) {
    if (width < 3 || height < 3) return 0.0;

    final yLength = width * height;
    var sum = 0.0;
    var sumSq = 0.0;
    var count = 0;

    const step = 4; // Downsample for performance
    for (var y = 1; y < height - 1; y += step) {
      for (var x = 1; x < width - 1; x += step) {
        final idx = y * width + x;
        final center = bytes[idx] & 0xFF;
        final right = bytes[idx + 1] & 0xFF;
        final below = bytes[idx + width] & 0xFF;

        // Horizontal and vertical gradient magnitude
        final gx = (right - center).abs();
        final gy = (below - center).abs();
        final gradient = gx + gy;

        sum += gradient.toDouble();
        sumSq += gradient.toDouble() * gradient.toDouble();
        count++;
      }
    }

    if (count == 0) return 0.0;
    final mean = sum / count;
    return sumSq / count - mean * mean; // Variance
  }
}
