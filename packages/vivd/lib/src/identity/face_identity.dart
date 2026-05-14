/// Face identity — MobileFaceNet-based face recognition and management.
library;

import '../models/face_id_result.dart';

class FaceIdentity {
  static const int maxFaces = 20;

  /// Register a new face with a label.
  /// Returns a Face ID in format FID-XXXX.
  Future<FaceIdResult> register({
    required String label,
    required CameraFrame frame,
  }) {
    throw UnimplementedError();
  }

  /// Identify a face against registered faces.
  /// Returns the best match or null if below threshold.
  Future<FaceIdResult?> identify(CameraFrame frame) {
    throw UnimplementedError();
  }

  /// Delete a registered face by Face ID.
  Future<bool> delete(String faceId) {
    throw UnimplementedError();
  }

  /// List all registered face IDs.
  List<FaceIdResult> listFaces() {
    throw UnimplementedError();
  }
}
