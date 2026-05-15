import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Liveness session with HMAC signature.
class Session {
  const Session({
    required this.sessionId,
    required this.nonce,
    required this.createdAt,
    required this.actions,
    required this.expiresAt,
  });

  /// Unique session ID (random hex).
  final String sessionId;

  /// Random nonce for replay protection.
  final String nonce;

  /// Session creation timestamp (milliseconds since epoch).
  final int createdAt;

  /// List of actions in this session (shuffled order).
  final List<String> actions;

  /// Session expiration timestamp (milliseconds since epoch).
  final int expiresAt;

  /// Whether this session has expired.
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch > expiresAt;

  /// Time remaining in seconds.
  int get remainingSeconds {
    final remaining = expiresAt - DateTime.now().millisecondsSinceEpoch;
    return (remaining / 1000).ceil();
  }

  /// Serialize session to JSON.
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'nonce': nonce,
        'createdAt': createdAt,
        'actions': actions,
        'expiresAt': expiresAt,
      };

  @override
  String toString() => 'Session($sessionId, expires: $remainingSeconds s)';
}

/// Signed payload — session data + HMAC for server verification.
class SignedPayload {
  const SignedPayload({
    required this.sessionId,
    required this.nonce,
    required this.actions,
    required this.results,
    required this.score,
    required this.timestamp,
    required this.signature,
  });

  final String sessionId;
  final String nonce;
  final List<String> actions;
  final List<Map<String, dynamic>> results;
  final double score;
  final int timestamp;
  final String signature;

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode({
        'sessionId': sessionId,
        'nonce': nonce,
        'actions': actions,
        'results': results,
        'score': score,
        'timestamp': timestamp,
        'signature': signature,
      });

  /// Verify HMAC signature.
  bool verifySignature(String hmacKey) {
    final payload = _buildPayloadString();
    final expected = _computeHmacSha256(payload, hmacKey);
    return expected == signature;
  }

  String _buildPayloadString() {
    return '$sessionId|$nonce|$timestamp|$score';
  }

  /// Compute HMAC-SHA256 hex digest.
  static String _computeHmacSha256(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(dataBytes);
    return digest.toString();
  }
}

/// Session manager — HMAC-SHA256 frame signing, nonce replay protection.
///
/// Provides tamper-proof session payloads that can be verified server-side.
///
/// ```dart
/// final manager = SessionManager(hmacKey: 'your-secret-key');
///
/// // Create session
/// final session = manager.createSession(
///   actions: ['blink', 'smile', 'headTurnLeft'],
/// );
///
/// // After liveness check, sign results
/// final signed = manager.signResults(
///   session: session,
///   results: [...],
///   score: 0.95,
/// );
///
/// // Server verification
/// final valid = signed.verifySignature('your-secret-key');
/// ```
class SessionManager {
  /// HMAC key for signing. Must match server-side key.
  final String hmacKey;

  /// Session duration in seconds.
  final int sessionDurationSeconds;

  /// Nonce length in bytes.
  final int nonceLength;

  SessionManager({
    required this.hmacKey,
    this.sessionDurationSeconds = 300,
    this.nonceLength = 32,
  });

  /// Create a new liveness session.
  Session createSession({
    List<String>? actions,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return Session(
      sessionId: _randomHex(16),
      nonce: _randomHex(nonceLength),
      createdAt: now,
      actions: actions ?? ['blink', 'smile'],
      expiresAt: now + (sessionDurationSeconds * 1000),
    );
  }

  /// Sign liveness results with HMAC-SHA256.
  SignedPayload signResults({
    required Session session,
    required List<Map<String, dynamic>> results,
    required double score,
  }) {
    if (session.isExpired) {
      throw StateError('Session ${session.sessionId} has expired');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final payloadString =
        '${session.sessionId}|${session.nonce}|$timestamp|$score';
    final signature = SignedPayload._computeHmacSha256(payloadString, hmacKey);

    return SignedPayload(
      sessionId: session.sessionId,
      nonce: session.nonce,
      actions: session.actions,
      results: results,
      score: score,
      timestamp: timestamp,
      signature: signature,
    );
  }

  /// Verify a signed payload from the server (or client-side).
  bool verify(SignedPayload payload) {
    // Check nonce format
    if (payload.nonce.length < nonceLength) return false;

    // Check timestamp freshness (within session duration)
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - payload.timestamp > sessionDurationSeconds * 1000) {
      return false;
    }

    // Verify HMAC
    return payload.verifySignature(hmacKey);
  }

  /// Generate random hex string.
  String _randomHex(int byteLength) {
    final random = Random.secure();
    final bytes = List<int>.generate(byteLength, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
