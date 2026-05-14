/// Camera validator — brightness, blur detection, quality gates.
library;

class CameraValidator {
  /// Validate frame quality for liveness detection.
  /// Returns quality score (0.0 - 1.0) and rejection reason if failed.
  ValidationResult validate(CameraFrame frame) {
    throw UnimplementedError();
  }
}

class ValidationResult {
  final bool isValid;
  final double qualityScore;
  final String? rejectionReason;

  const ValidationResult({
    required this.isValid,
    required this.qualityScore,
    this.rejectionReason,
  });
}
