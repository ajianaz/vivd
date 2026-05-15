import 'dart:math';
import 'dart:typed_data';

import '../models/face_id_result.dart';

/// Face identity — face registration and identification.
///
/// In Phase 0-1, this is a stub using face bounding box features.
/// In Phase 2, it will use MobileFaceNet embeddings for real face recognition.
///
/// ```dart
/// final identity = FaceIdentity();
///
/// // Register
/// final reg = await identity.register(faceBytes, label: 'employee_001');
/// print(reg.faceId); // FID-XXXX
///
/// // Identify
/// final result = await identity.identify(faceBytes);
/// print(result.label); // employee_001
/// ```
class FaceIdentity {
  /// Maximum number of faces that can be stored.
  static const int maxFaces = 20;

  /// Registered face entries.
  final List<_FaceEntry> _faces = [];

  /// Counter for generating face IDs.
  int _idCounter = 0;

  /// Create a new face identity store.
  FaceIdentity();

  /// Current number of registered faces.
  int get faceCount => _faces.length;

  /// Whether the store has reached maximum capacity.
  bool get isFull => _faces.length >= maxFaces;

  /// Register a new face with a label.
  ///
  /// Returns a Face ID in format FID-XXXX.
  /// Throws [StateError] if the store is full.
  Future<FaceIdResult> register(
    Uint8List faceBytes, {
    required String label,
    int? width,
    int? height,
  }) async {
    if (isFull) {
      throw StateError(
        'FaceIdentity is full ($maxFaces/$maxFaces). '
        'Remove a face before registering a new one.',
      );
    }

    // Check for duplicate label
    if (_faces.any((f) => f.label == label)) {
      throw ArgumentError('Label "$label" is already registered. '
          'Remove it first or use a different label.');
    }

    final faceId = _generateFaceId();

    // In Phase 0: generate a stub embedding from face dimensions
    // In Phase 2: this will use MobileFaceNet to generate a real 128D embedding
    final embedding = await _generateEmbedding(faceBytes, width, height);

    _faces.add(_FaceEntry(
      faceId: faceId,
      label: label,
      embedding: embedding,
      registeredAt: DateTime.now().millisecondsSinceEpoch,
    ));

    return FaceIdResult(
      faceId: faceId,
      score: 1.0,
      label: label,
      isMatch: false, // Registration, not identification
    );
  }

  /// Identify a face against registered faces.
  ///
  /// Returns the best match if confidence exceeds [threshold].
  /// Returns `null` if no match found.
  Future<FaceIdResult?> identify(
    Uint8List faceBytes, {
    double threshold = 0.6,
    int? width,
    int? height,
  }) async {
    if (_faces.isEmpty) return null;

    final embedding = await _generateEmbedding(faceBytes, width, height);

    _FaceEntry? bestMatch;
    var bestScore = 0.0;

    for (final entry in _faces) {
      final score = _cosineSimilarity(embedding, entry.embedding);
      if (score > bestScore) {
        bestScore = score;
        bestMatch = entry;
      }
    }

    if (bestMatch == null || bestScore < threshold) return null;

    return FaceIdResult(
      faceId: bestMatch.faceId,
      score: bestScore,
      label: bestMatch.label,
      isMatch: true,
    );
  }

  /// Remove a face by face ID.
  ///
  /// Returns `true` if the face was found and removed.
  bool remove(String faceId) {
    final initialLength = _faces.length;
    _faces.removeWhere((f) => f.faceId == faceId);
    return _faces.length < initialLength;
  }

  /// Remove a face by label.
  ///
  /// Returns `true` if the face was found and removed.
  bool removeByLabel(String label) {
    final initialLength = _faces.length;
    _faces.removeWhere((f) => f.label == label);
    return _faces.length < initialLength;
  }

  /// Clear all registered faces.
  void clear() => _faces.clear();

  /// List all registered face IDs and labels.
  List<Map<String, dynamic>> listFaces() {
    return _faces
        .map((f) => {
              'faceId': f.faceId,
              'label': f.label,
              'registeredAt': f.registeredAt,
            })
        .toList();
  }

  /// Check if a face ID exists.
  bool contains(String faceId) => _faces.any((f) => f.faceId == faceId);

  /// Generate face ID in format FID-XXXX.
  String _generateFaceId() {
    _idCounter++;
    final hex = _idCounter.toRadixString(16).toUpperCase().padLeft(4, '0');
    return 'FID-$hex';
  }

  /// Generate embedding from face bytes.
  ///
  /// Phase 0: Stub — uses image hash as pseudo-embedding.
  /// Phase 2: MobileFaceNet 128D embedding.
  Future<List<double>> _generateEmbedding(
    Uint8List bytes,
    int? width,
    int? height,
  ) async {
    // Stub: generate a deterministic hash-based embedding.
    // In production, this calls MobileFaceNet via TFLite.
    final random = Random(bytes.fold<int>(0, (sum, b) => sum + b));
    return List<double>.generate(
      128,
      (_) => (random.nextDouble() * 2 - 1),
    );
  }

  /// Cosine similarity between two embeddings.
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0.0;

    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = sqrt(normA);
    normB = sqrt(normB);

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (normA * normB);
  }
}

/// Internal face entry.
class _FaceEntry {
  const _FaceEntry({
    required this.faceId,
    required this.label,
    required this.embedding,
    required this.registeredAt,
  });

  final String faceId;
  final String label;
  final List<double> embedding;
  final int registeredAt;
}
