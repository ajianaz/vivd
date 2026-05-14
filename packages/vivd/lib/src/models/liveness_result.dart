import 'liveness_action.dart';

/// Result of a liveness detection session.
class LivenessResult {
  /// Whether the liveness check passed.
  final bool isLive;

  /// Confidence score (0.0 - 1.0).
  /// 0.0 = definitely spoofed, 1.0 = definitely real.
  final double score;

  /// Session ID for verification (HMAC-signed).
  final String? sessionId;

  /// Per-action breakdown.
  final List<ActionDetail> actions;

  /// Anti-spoof score from [AntiSpoofEngine] (0.0 - 1.0).
  /// `null` if anti-spoof was not run.
  final double? antiSpoofScore;

  /// Timestamp when the session completed (milliseconds since epoch).
  final int completedAt;

  LivenessResult({
    required this.isLive,
    required this.score,
    this.sessionId,
    List<ActionDetail>? actions,
    this.antiSpoofScore,
    int? completedAt,
  })  : actions = actions ?? const [],
        completedAt = completedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Duration of the entire session in milliseconds.
  int? get durationMs {
    if (actions.isEmpty) return null;
    return actions.last.completedAt - actions.first.startedAt;
  }

  /// Number of actions that were passed.
  int get passedActions =>
      actions.where((a) => a.passed).length;

  /// Number of actions that failed.
  int get failedActions =>
      actions.where((a) => !a.passed).length;

  /// Total number of actions in the session.
  int get totalActions => actions.length;

  /// Whether all required actions were completed successfully.
  bool get allActionsPassed =>
      actions.isNotEmpty && actions.every((a) => a.passed);

  /// Serialize to JSON for session verification payload.
  Map<String, dynamic> toJson() => {
        'isLive': isLive,
        'score': score,
        'sessionId': sessionId,
        'antiSpoofScore': antiSpoofScore,
        'completedAt': completedAt,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  @override
  String toString() =>
      'LivenessResult(isLive: $isLive, score: ${score.toStringAsFixed(2)}, '
      'actions: $passedActions/$totalActions passed)';
}

/// Detail of a single action attempt.
class ActionDetail {
  /// The action type.
  final VivdAction action;

  /// Whether the user completed the action successfully.
  final bool passed;

  /// Confidence score for this specific action (0.0 - 1.0).
  final double score;

  /// Time when this action started (milliseconds since epoch).
  final int startedAt;

  /// Time when this action completed (milliseconds since epoch).
  final int completedAt;

  /// Number of detection frames analyzed.
  final int frameCount;

  /// Optional failure reason if [passed] is false.
  final String? failureReason;

  const ActionDetail({
    required this.action,
    required this.passed,
    required this.score,
    required this.startedAt,
    required this.completedAt,
    this.frameCount = 0,
    this.failureReason,
  });

  /// Duration of this action in milliseconds.
  int get durationMs => completedAt - startedAt;

  Map<String, dynamic> toJson() => {
        'action': action.name,
        'passed': passed,
        'score': score,
        'durationMs': durationMs,
        'frameCount': frameCount,
        'failureReason': failureReason,
      };

  @override
  String toString() =>
      'ActionDetail(${action.label}: ${passed ? '✓' : '✗'} '
      '${score.toStringAsFixed(2)}, ${durationMs}ms)';
}
