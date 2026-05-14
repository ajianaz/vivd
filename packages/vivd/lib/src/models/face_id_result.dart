/// Result of face identification.
class FaceIdResult {
  /// Face ID in format `FID-XXXX`.
  final String faceId;

  /// Confidence score (0.0 - 1.0).
  final double score;

  /// Label provided during registration.
  final String? label;

  /// Embedding vector (for internal use).
  final List<double>? embedding;

  const FaceIdResult({
    required this.faceId,
    required this.score,
    this.label,
    this.embedding,
  });

  @override
  String toString() =>
      'FaceIdResult(faceId: $faceId, score: ${score.toStringAsFixed(3)}, label: $label)';
}
