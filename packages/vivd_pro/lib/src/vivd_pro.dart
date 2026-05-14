/// Vivd Pro — Server-backed face liveness SDK.
///
/// Extends the free Vivd SDK with:
/// - Server-side session verification (JWT RS256)
/// - ML PAD (Presentation Attack Detection)
/// - Encrypted face keystore
/// - API key authentication
/// - Additional Pro liveness actions (smile, mouth open, head shake)
library;

import 'package:vivd/vivd.dart';

class VivdPro {
  static const String version = '0.1.0';

  /// Start a Pro liveness session with server verification.
  ///
  /// [apiKey] — Your Vivd Pro API key.
  /// [actions] — List of liveness actions (Pro supports 7+).
  /// [enablePAD] — Enable ML presentation attack detection.
  /// [faceId] — Optional face ID for identification.
  static Future<VivdProResult> startLiveness({
    required String apiKey,
    List<VivdAction>? actions,
    bool enablePAD = true,
    String? faceId,
  }) {
    throw UnimplementedError('VivdPro.startLiveness — not yet implemented');
  }
}

/// Pro result includes server-verified JWT.
class VivdProResult extends LivenessResult {
  /// Server-issued JWT token for verification.
  final String? jwt;

  /// Server session ID.
  final String? sessionId;

  /// PAD (Presentation Attack Detection) score.
  final double? padScore;

  const VivdProResult({
    required super.isLive,
    required super.score,
    this.jwt,
    this.sessionId,
    this.padScore,
    super.actionResults,
    super.timestamp,
  });
}
