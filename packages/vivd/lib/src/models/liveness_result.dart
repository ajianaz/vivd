/// Result of a liveness detection session.
class LivenessResult {
  /// Whether the liveness check passed.
  final bool isLive;

  /// Confidence score (0.0 - 1.0).
  final double score;

  /// Session ID for verification (HMAC-signed).
  final String? sessionId;

  /// Per-action results.
  final Map<String, bool> actionResults;

  /// Timestamp of the session (ISO 8601).
  final DateTime timestamp;

  const LivenessResult({
    required this.isLive,
    required this.score,
    this.sessionId,
    this.actionResults = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'LivenessResult(isLive: $isLive, score: ${score.toStringAsFixed(3)}, '
      'sessionId: ${sessionId ?? "N/A"}, actions: $actionResults)';
}
