/// Session manager — HMAC-SHA256 frame signing, nonce replay protection.
library;

class SessionManager {
  /// Create a new liveness session.
  Session createSession({
    List<String>? actions,
    int nonceLength = 32,
  }) {
    throw UnimplementedError();
  }

  /// Sign a frame with HMAC-SHA256.
  String signFrame(Session session, CameraFrame frame) {
    throw UnimplementedError();
  }

  /// Verify a frame signature against the session.
  bool verifyFrame(Session session, String signature, CameraFrame frame) {
    throw UnimplementedError();
  }
}

class Session {
  final String id;
  final String nonce;
  final List<String> actions;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Session({
    required this.id,
    required this.nonce,
    required this.actions,
    required this.createdAt,
    required this.expiresAt,
  });
}
