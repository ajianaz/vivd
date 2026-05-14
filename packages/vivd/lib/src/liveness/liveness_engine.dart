import 'dart:async';
import 'dart:math';

import '../camera/camera_service.dart';
import '../camera/camera_validator.dart';
import '../camera/frame_processor.dart';
import '../detection/face_detector_interface.dart';
import '../models/liveness_action.dart';
import '../models/liveness_result.dart';

/// Liveness engine — orchestrates blink, smile, head turn detection.
///
/// Runs a sequence of random liveness actions and scores each one.
/// All processing happens on-device — no network required.
///
/// ```dart
/// final engine = LivenessEngine(
///   faceDetector: MlKitFaceDetector(),
///   cameraValidator: CameraValidator(),
/// );
/// await engine.initialize();
///
/// final result = await engine.runSession(
///   actions: [VivdAction.blink, VivdAction.smile],
///   frameStream: camera.frameStream,
/// );
///
/// print(result.isLive); // true/false
/// ```
class LivenessEngine {
  /// Face detector for landmark extraction.
  final FaceDetectorInterface faceDetector;

  /// Camera validator for frame quality.
  final CameraValidator cameraValidator;

  /// Frame processor for format conversion.
  final FrameProcessor frameProcessor;

  /// Minimum frames to confirm an action.
  final int minConfirmationFrames;

  /// Maximum session duration in milliseconds.
  final int maxSessionDurationMs;

  /// Action timeout in milliseconds per action.
  final int actionTimeoutMs;

  /// Minimum confidence to pass an action (0.0 - 1.0).
  final double actionPassThreshold;

  LivenessEngine({
    required this.faceDetector,
    CameraValidator? cameraValidator,
    FrameProcessor? frameProcessor,
    this.minConfirmationFrames = 3,
    this.maxSessionDurationMs = 30000,
    this.actionTimeoutMs = 10000,
    this.actionPassThreshold = 0.7,
  })  : cameraValidator = cameraValidator ?? CameraValidator(),
        frameProcessor = frameProcessor ?? FrameProcessor();

  bool _initialized = false;

  /// Initialize the engine and underlying detector.
  Future<void> initialize() async {
    if (_initialized) return;
    await faceDetector.initialize();
    _initialized = true;
  }

  /// Run a liveness session with the given actions.
  ///
  /// [actions] — list of actions to challenge the user with.
  /// [frameStream] — stream of camera frames to analyze.
  /// [onActionChanged] — callback when a new action starts.
  /// [onProgress] — callback with per-frame detection updates.
  Future<LivenessResult> runSession({
    required List<VivdAction> actions,
    required Stream<CameraFrame> frameStream,
    void Function(VivdAction action, int index, int total)? onActionChanged,
    void Function(VivdAction action, FaceDetection face)? onProgress,
  }) async {
    if (!_initialized) {
      throw StateError('LivenessEngine not initialized. Call initialize() first.');
    }

    if (actions.isEmpty) {
      return LivenessResult(
        isLive: false,
        score: 0.0,
        actions: [],
      );
    }

    final sessionStart = DateTime.now().millisecondsSinceEpoch;
    final actionResults = <ActionDetail>[];
    final shuffledActions = _shuffleActions(actions);

    for (var i = 0; i < shuffledActions.length; i++) {
      final action = shuffledActions[i];
      onActionChanged?.call(action, i, shuffledActions.length);

      // Check session timeout
      final elapsed = DateTime.now().millisecondsSinceEpoch - sessionStart;
      if (elapsed >= maxSessionDurationMs) {
        actionResults.add(ActionDetail(
          action: action,
          passed: false,
          score: 0.0,
          startedAt: DateTime.now().millisecondsSinceEpoch,
          completedAt: DateTime.now().millisecondsSinceEpoch,
          failureReason: 'Session timeout',
        ));
        break;
      }

      final detail = await _runAction(
        action: action,
        frameStream: frameStream,
        onProgress: onProgress,
      );
      actionResults.add(detail);

      // If critical action fails, stop early
      if (!detail.passed && i == 0) {
        break;
      }
    }

    await faceDetector.dispose();

    final passed = actionResults.where((a) => a.passed).length;
    final total = actionResults.length;
    final overallScore = total > 0
        ? actionResults.map((a) => a.score).reduce((a, b) => a + b) / total
        : 0.0;

    return LivenessResult(
      isLive: passed >= (total * 0.6).ceil() && passed >= 2,
      score: overallScore,
      actions: actionResults,
      completedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Run a single action and wait for completion or timeout.
  Future<ActionDetail> _runAction({
    required VivdAction action,
    required Stream<CameraFrame> frameStream,
    void Function(VivdAction action, FaceDetection face)? onProgress,
  }) async {
    final actionStart = DateTime.now().millisecondsSinceEpoch;
    var confirmedFrames = 0;
    var totalFrames = 0;
    var bestScore = 0.0;

    final completer = Completer<ActionDetail>();

    final subscription = frameStream.listen(
      (frame) async {
        if (completer.isCompleted) return;

        // Check action timeout
        final elapsed = DateTime.now().millisecondsSinceEpoch - actionStart;
        if (elapsed >= actionTimeoutMs) {
          if (!completer.isCompleted) {
            completer.complete(ActionDetail(
              action: action,
              passed: confirmedFrames >= minConfirmationFrames,
              score: bestScore,
              startedAt: actionStart,
              completedAt: DateTime.now().millisecondsSinceEpoch,
              frameCount: totalFrames,
              failureReason: confirmedFrames < minConfirmationFrames
                  ? 'Timeout — not enough confirmed frames ($confirmedFrames/$minConfirmationFrames)'
                  : null,
            ));
          }
          return;
        }

        // Validate frame quality
        final validation = cameraValidator.validate(frame);
        if (!validation.passed) return;

        // Process frame
        final processed = await frameProcessor.process(frame);
        final faces = await faceDetector.detect(
          processed.bytes,
          width: processed.width,
          height: processed.height,
          rotation: processed.rotation,
          format: processed.format,
        );

        if (faces.isEmpty) return;
        totalFrames++;

        final face = faces.first;
        onProgress?.call(action, face);

        // Check if action is detected
        final detected = _detectAction(action, face);
        final score = _calculateActionScore(action, face);

        if (detected) {
          confirmedFrames++;
          if (score > bestScore) bestScore = score;

          if (confirmedFrames >= minConfirmationFrames) {
            if (!completer.isCompleted) {
              completer.complete(ActionDetail(
                action: action,
                passed: true,
                score: bestScore,
                startedAt: actionStart,
                completedAt: DateTime.now().millisecondsSinceEpoch,
                frameCount: totalFrames,
              ));
            }
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete(ActionDetail(
            action: action,
            passed: false,
            score: 0.0,
            startedAt: actionStart,
            completedAt: DateTime.now().millisecondsSinceEpoch,
            frameCount: totalFrames,
            failureReason: 'Frame stream error: $error',
          ));
        }
      },
    );

    // Set a hard timeout as safety net
    Future.delayed(
      Duration(milliseconds: actionTimeoutMs + 2000),
      () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.complete(ActionDetail(
            action: action,
            passed: confirmedFrames >= minConfirmationFrames,
            score: bestScore,
            startedAt: actionStart,
            completedAt: DateTime.now().millisecondsSinceEpoch,
            frameCount: totalFrames,
            failureReason: confirmedFrames < minConfirmationFrames
                ? 'Timeout'
                : null,
          ));
        }
      },
    );

    final result = await completer.future;
    await subscription.cancel();
    return result;
  }

  /// Check if the detected face satisfies the requested action.
  bool _detectAction(VivdAction action, FaceDetection face) {
    return switch (action) {
      VivdAction.blink => face.areEyesClosed(threshold: 0.3),
      VivdAction.smile => face.isSmiling(threshold: 0.7),
      VivdAction.headTurnLeft => face.isHeadTurnedLeft(threshold: -20.0),
      VivdAction.headTurnRight => face.isHeadTurnedRight(threshold: 20.0),
      VivdAction.lookUp => face.isLookingUp(threshold: -15.0),
      VivdAction.lookDown => face.isLookingDown(threshold: 15.0),
    };
  }

  /// Calculate confidence score for an action based on face metrics.
  double _calculateActionScore(VivdAction action, FaceDetection face) {
    return switch (action) {
      VivdAction.blink => (1.0 - (face.avgEyeOpen ?? 1.0)).clamp(0.0, 1.0),
      VivdAction.smile => (face.smiling ?? 0.0).clamp(0.0, 1.0),
      VivdAction.headTurnLeft =>
        (-(face.headEulerAngleY ?? 0.0) / 45.0).clamp(0.0, 1.0),
      VivdAction.headTurnRight =>
        ((face.headEulerAngleY ?? 0.0) / 45.0).clamp(0.0, 1.0),
      VivdAction.lookUp =>
        (-(face.headEulerAngleX ?? 0.0) / 30.0).clamp(0.0, 1.0),
      VivdAction.lookDown =>
        ((face.headEulerAngleX ?? 0.0) / 30.0).clamp(0.0, 1.0),
    };
  }

  /// Shuffle actions with secure random (prevents replay prediction).
  List<VivdAction> _shuffleActions(List<VivdAction> actions) {
    final random = Random.secure();
    final shuffled = List<VivdAction>.from(actions);
    // Fisher-Yates shuffle
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    return shuffled;
  }
}
