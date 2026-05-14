/// Core Vivd API.
///
/// Provides face liveness detection and face identification.
/// All processing happens on-device — no server required.
library;

import 'package:flutter/widgets.dart';
import 'src/camera/camera_service.dart';
import 'src/detection/face_detector_interface.dart';
import 'src/liveness/liveness_engine.dart';
import 'src/identity/face_identity.dart';
import 'src/security/session_manager.dart';
import 'src/models/liveness_action.dart';
import 'src/models/liveness_result.dart';
import 'src/models/face_id_result.dart';

/// Main entry point for Vivd face liveness SDK.
///
/// Example:
/// ```dart
/// final result = await Vivd.startLiveness(
///   actions: [VivdAction.blink, VivdAction.smile],
/// );
/// ```
class Vivd {
  static const String version = '0.1.0';

  /// Start a liveness detection session.
  ///
  /// [actions] — List of liveness actions to perform.
  /// [timeout] — Maximum duration in seconds (default: 60).
  /// Returns a [LivenessResult] with verification status and score.
  static Future<LivenessResult> startLiveness({
    List<VivdAction>? actions,
    int timeout = 60,
  }) {
    throw UnimplementedError('Vivd.startLiveness — not yet implemented');
  }

  /// Register a face identity for later recognition.
  ///
  /// [label] — Unique identifier for this face.
  /// Returns a Face ID in format `FID-XXXX`.
  static Future<FaceIdResult> registerFace({
    required String label,
  }) {
    throw UnimplementedError('Vivd.registerFace — not yet implemented');
  }

  /// Identify a face against registered identities.
  ///
  /// Returns the best matching [FaceIdResult] or null if no match.
  static Future<FaceIdResult?> identifyFace() {
    throw UnimplementedError('Vivd.identifyFace — not yet implemented');
  }

  /// Check if the device supports face liveness detection.
  static Future<bool> isSupported() async {
    return true; // TODO: implement device capability check
  }
}
