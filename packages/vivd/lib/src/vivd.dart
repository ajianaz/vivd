import 'dart:async';

import 'package:flutter/widgets.dart';

import 'src/camera/camera_service.dart';
import 'src/camera/camera_validator.dart';
import 'src/camera/frame_processor.dart';
import 'src/detection/face_detector_interface.dart';
import 'src/detection/ml_kit_face_detector.dart';
import 'src/identity/face_identity.dart';
import 'src/liveness/liveness_engine.dart';
import 'src/ml/anti_spoof_engine.dart';
import 'src/models/face_id_result.dart';
import 'src/models/liveness_action.dart';
import 'src/models/liveness_result.dart';
import 'src/security/session_manager.dart';

/// Configuration for Vivd SDK.
class VivdConfig {
  const VivdConfig({
    this.actions = const [VivdAction.blink, VivdAction.smile],
    this.minConfirmationFrames = 3,
    this.maxSessionDurationMs = 30000,
    this.actionTimeoutMs = 10000,
    this.actionPassThreshold = 0.7,
    this.enableAntiSpoof = false,
    this.hmacKey = '',
    this.sessionDurationSeconds = 300,
    this.faceDetector,
  });

  /// Actions to challenge the user with.
  final List<VivdAction> actions;

  /// Minimum frames to confirm an action.
  final int minConfirmationFrames;

  /// Maximum session duration in milliseconds.
  final int maxSessionDurationMs;

  /// Action timeout in milliseconds.
  final int actionTimeoutMs;

  /// Minimum confidence to pass an action.
  final double actionPassThreshold;

  /// Enable anti-spoof detection.
  final bool enableAntiSpoof;

  /// HMAC key for session signing. Empty = no signing.
  final String hmacKey;

  /// Session duration in seconds.
  final int sessionDurationSeconds;

  /// Custom face detector. Uses ML Kit by default.
  final FaceDetectorInterface? faceDetector;
}

/// Callback for liveness progress updates.
typedef VivdProgressCallback = void Function(
  VivdAction currentAction,
  int actionIndex,
  int totalActions,
);

/// Core Vivd API.
///
/// Provides face liveness detection and face identification.
/// All processing happens on-device — no server required.
///
/// ```dart
/// final vivd = Vivd(config: VivdConfig(
///   actions: [VivdAction.blink, VivdAction.smile],
/// ));
/// await vivd.initialize();
///
/// // Liveness check
/// final result = await vivd.startLiveness(
///   frameStream: camera.frameStream,
///   onProgress: (action, index, total) {
///     print('Action $index/$total: ${action.label}');
///   },
/// );
///
/// // Face identity
/// final reg = await vivd.registerFace(faceBytes, label: 'john');
/// final match = await vivd.identifyFace(faceBytes);
///
/// await vivd.dispose();
/// ```
class Vivd {
  VivdConfig _config;

  LivenessEngine? _livenessEngine;
  FaceDetectorInterface? _faceDetector;
  FaceIdentity? _faceIdentity;
  AntiSpoofEngine? _antiSpoofEngine;
  SessionManager? _sessionManager;
  CameraValidator? _cameraValidator;
  FrameProcessor? _frameProcessor;

  bool _initialized = false;

  Vivd({VivdConfig? config}) : _config = config ?? const VivdConfig();

  /// Current configuration.
  VivdConfig get config => _config;

  /// Whether the SDK is initialized.
  bool get isInitialized => _initialized;

  /// Face identity store (available after [initialize]).
  FaceIdentity? get faceIdentity =>
      _initialized ? _faceIdentity : null;

  /// Initialize the SDK.
  ///
  /// Must be called before any other method.
  /// Sets up face detector, liveness engine, and optional anti-spoof.
  Future<void> initialize() async {
    if (_initialized) return;

    // Face detector
    _faceDetector = _config.faceDetector ?? MlKitFaceDetector();
    await _faceDetector!.initialize();

    // Camera validator
    _cameraValidator = CameraValidator();

    // Frame processor
    _frameProcessor = FrameProcessor();

    // Liveness engine
    _livenessEngine = LivenessEngine(
      faceDetector: _faceDetector!,
      cameraValidator: _cameraValidator!,
      frameProcessor: _frameProcessor!,
      minConfirmationFrames: _config.minConfirmationFrames,
      maxSessionDurationMs: _config.maxSessionDurationMs,
      actionTimeoutMs: _config.actionTimeoutMs,
      actionPassThreshold: _config.actionPassThreshold,
    );

    // Face identity
    _faceIdentity = FaceIdentity();

    // Anti-spoof (optional)
    if (_config.enableAntiSpoof) {
      _antiSpoofEngine = AntiSpoofEngine();
      await _antiSpoofEngine!.initialize();
    }

    // Session manager (if HMAC key provided)
    if (_config.hmacKey.isNotEmpty) {
      _sessionManager = SessionManager(
        hmacKey: _config.hmacKey,
        sessionDurationSeconds: _config.sessionDurationSeconds,
      );
    }

    _initialized = true;
  }

  /// Start a liveness detection session.
  ///
  /// [frameStream] — stream of camera frames.
  /// [actions] — override default actions. Use `null` for config defaults.
  /// [onProgress] — callback for UI progress updates.
  Future<LivenessResult> startLiveness({
    required Stream<CameraFrame> frameStream,
    List<VivdAction>? actions,
    VivdProgressCallback? onProgress,
  }) async {
    _ensureInitialized();

    Session? session;
    if (_sessionManager != null) {
      session = _sessionManager!.createSession(
        actions: (actions ?? _config.actions).map((a) => a.name).toList(),
      );
    }

    final result = await _livenessEngine!.runSession(
      actions: actions ?? _config.actions,
      frameStream: frameStream,
      onActionChanged: (action, index, total) {
        onProgress?.call(action, index, total);
      },
    );

    // Sign results if session manager is available
    if (_sessionManager != null && session != null) {
      final signed = _sessionManager!.signResults(
        session: session,
        results: result.actions.map((a) => a.toJson()).toList(),
        score: result.score,
      );
      // Return new result with session ID and signature
      return LivenessResult(
        isLive: result.isLive,
        score: result.score,
        sessionId: signed.sessionId,
        actions: result.actions,
        antiSpoofScore: result.antiSpoofScore,
        completedAt: result.completedAt,
      );
    }

    return result;
  }

  /// Register a new face for identification.
  ///
  /// [faceBytes] — raw face image bytes.
  /// [label] — unique identifier (e.g., employee ID).
  Future<FaceIdResult> registerFace(
    dynamic faceBytes, {
    required String label,
    int? width,
    int? height,
  }) async {
    _ensureInitialized();
    return _faceIdentity!.register(
      faceBytes as List<int>,
      label: label,
      width: width,
      height: height,
    );
  }

  /// Identify a face against registered faces.
  ///
  /// Returns the best match if confidence exceeds [threshold].
  /// Returns `null` if no match found.
  Future<FaceIdResult?> identifyFace(
    dynamic faceBytes, {
    double threshold = 0.6,
    int? width,
    int? height,
  }) async {
    _ensureInitialized();
    return _faceIdentity!.identify(
      faceBytes as List<int>,
      threshold: threshold,
      width: width,
      height: height,
    );
  }

  /// Remove a registered face by ID.
  bool removeFace(String faceId) {
    _ensureInitialized();
    return _faceIdentity!.remove(faceId);
  }

  /// List all registered faces.
  List<Map<String, dynamic>> listFaces() {
    _ensureInitialized();
    return _faceIdentity!.listFaces();
  }

  /// Verify a signed liveness payload.
  ///
  /// Returns `true` if the HMAC signature is valid and not expired.
  bool verifySession(String signedPayloadJson) {
    _ensureInitialized();
    if (_sessionManager == null) {
      throw StateError('No HMAC key configured. Set VivdConfig.hmacKey to enable verification.');
    }
    // TODO: Parse JSON and call _sessionManager.verify()
    return false;
  }

  /// Dispose all resources.
  Future<void> dispose() async {
    await _faceDetector?.dispose();
    await _antiSpoofEngine?.dispose();
    _livenessEngine = null;
    _faceDetector = null;
    _faceIdentity = null;
    _antiSpoofEngine = null;
    _sessionManager = null;
    _cameraValidator = null;
    _frameProcessor = null;
    _initialized = false;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('Vivd not initialized. Call initialize() first.');
    }
  }
}
