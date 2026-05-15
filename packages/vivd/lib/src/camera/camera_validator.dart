import 'camera_service.dart';

/// Validation result for frame quality.
class ValidationResult {
  const ValidationResult({
    required this.score,
    required this.passed,
    this.brightness,
    this.isBlurry,
    this.isTooDark,
    this.isTooBright,
    this.faceTooSmall,
    this.reason,
  });

  /// Quality score (0.0 - 1.0). Frames below 0.4 should be rejected.
  final double score;

  /// Whether the frame passes the minimum quality threshold.
  final bool passed;

  /// Brightness level (0.0 - 255.0).
  final double? brightness;

  /// Whether the frame appears blurry (Laplacian variance too low).
  final bool? isBlurry;

  /// Whether the frame is too dark.
  final bool? isTooDark;

  /// Whether the frame is too bright (overexposed).
  final bool? isTooBright;

  /// Whether the detected face is too small.
  final bool? faceTooSmall;

  /// Human-readable rejection reason (null if passed).
  final String? reason;

  @override
  String toString() =>
      passed ? 'ValidationResult(✓ ${score.toStringAsFixed(2)})'
             : 'ValidationResult(✗ $reason, ${score.toStringAsFixed(2)})';
}

/// Camera validator — brightness, blur detection, quality gates.
///
/// Rejects low-quality frames before processing to improve
/// liveness detection accuracy.
///
/// ```dart
/// final validator = CameraValidator();
/// final result = validator.validate(frame);
/// if (!result.passed) {
///   print('Frame rejected: ${result.reason}');
/// }
/// ```
class CameraValidator {
  /// Minimum brightness (0-255). Below this = too dark.
  final double minBrightness;

  /// Maximum brightness (0-255). Above this = too bright.
  final double maxBrightness;

  /// Minimum face size relative to frame width (0.0 - 1.0).
  final double minFaceSizeRatio;

  /// Minimum quality score to pass (0.0 - 1.0).
  final double passThreshold;

  CameraValidator({
    this.minBrightness = 40.0,
    this.maxBrightness = 240.0,
    this.minFaceSizeRatio = 0.2,
    this.passThreshold = 0.4,
  });

  /// Validate frame quality for liveness detection.
  /// Returns quality score (0.0 - 1.0) and rejection reason if failed.
  ValidationResult validate(
    CameraFrame frame, {
    double? faceWidthPixels,
  }) {
    final issues = <String>[];
    var score = 1.0;

    // 1. Brightness check (luminance of Y channel in NV21)
    final brightness = _calculateBrightness(frame);
    if (brightness < minBrightness) {
      issues.add('Too dark (${brightness.toStringAsFixed(0)})');
      score -= 0.3;
    } else if (brightness > maxBrightness) {
      issues.add('Too bright (${brightness.toStringAsFixed(0)})');
      score -= 0.3;
    }

    // 2. Blur detection (simplified Laplacian variance on downscaled image)
    final blurScore = _estimateSharpness(frame);
    if (blurScore < 50.0) {
      issues.add('Blurry (sharpness: ${blurScore.toStringAsFixed(0)})');
      score -= 0.3;
    }

    // 3. Face size check
    if (faceWidthPixels != null) {
      final ratio = faceWidthPixels / frame.width;
      if (ratio < minFaceSizeRatio) {
        issues.add('Face too small (${(ratio * 100).toStringAsFixed(0)}%)');
        score -= 0.2;
      }
    }

    score = score.clamp(0.0, 1.0);
    final passed = score >= passThreshold;

    return ValidationResult(
      score: score,
      passed: passed,
      brightness: brightness,
      isBlurry: blurScore < 50.0,
      isTooDark: brightness < minBrightness,
      isTooBright: brightness > maxBrightness,
      faceTooSmall: faceWidthPixels != null &&
          (faceWidthPixels / frame.width) < minFaceSizeRatio,
      reason: issues.isEmpty ? null : issues.join(', '),
    );
  }

  /// Calculate average brightness from NV21 Y channel.
  double _calculateBrightness(CameraFrame frame) {
    if (frame.bytes.isEmpty) return 0.0;

    final bytes = frame.bytes;
    final yPlaneLength = frame.width * frame.height;
    var sum = 0;

    // Sample every 16th pixel for performance
    const step = 16;
    final samples = (yPlaneLength / step).floor();
    for (var i = 0; i < yPlaneLength; i += step) {
      sum += bytes[i] & 0xFF;
    }

    return samples > 0 ? sum / samples : 0.0;
  }

  /// Estimate image sharpness using simplified Laplacian variance.
  /// Works on the Y (luminance) channel of NV21.
  double _estimateSharpness(CameraFrame frame) {
    if (frame.width < 3 || frame.height < 3) return 0.0;

    final bytes = frame.bytes;
    final w = frame.width;
    final h = frame.height;
    var sumLaplacian = 0.0;
    var count = 0;

    // Downsample: process every 4th pixel
    const step = 4;
    for (var y = 1; y < h - 1; y += step) {
      for (var x = 1; x < w - 1; x += step) {
        final center = bytes[y * w + x] & 0xFF;
        final top = bytes[(y - 1) * w + x] & 0xFF;
        final bottom = bytes[(y + 1) * w + x] & 0xFF;
        final left = bytes[y * w + (x - 1)] & 0xFF;
        final right = bytes[y * w + (x + 1)] & 0xFF;

        final laplacian = (top + bottom + left + right - 4 * center).toDouble();
        sumLaplacian += laplacian * laplacian;
        count++;
      }
    }

    return count > 0 ? sumLaplacian / count : 0.0;
  }
}
