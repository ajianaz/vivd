/// Result of face identification.
class FaceIdResult {
  /// Face ID in format `FID-XXXX`.
  final String faceId;

  /// Confidence score (0.0 - 1.0).
  final double score;

  /// Label provided during registration.
  final String? label;

  /// Whether the face was found in the database (identification mode).
  /// `false` if this is a registration result.
  final bool isMatch;

  /// Timestamp of the identification (milliseconds since epoch).
  final int timestamp;

  FaceIdResult({
    required this.faceId,
    required this.score,
    this.label,
    this.isMatch = false,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// Whether this result meets a minimum confidence threshold.
  bool meetsThreshold(double threshold) => score >= threshold;

  Map<String, dynamic> toJson() => {
        'faceId': faceId,
        'score': score,
        'label': label,
        'isMatch': isMatch,
        'timestamp': timestamp,
      };

  @override
  String toString() =>
      'FaceIdResult($faceId, score: ${score.toStringAsFixed(2)}, '
      'label: $label, match: $isMatch)';
}
