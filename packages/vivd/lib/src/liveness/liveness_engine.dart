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
class LivenessEngine {
  final FaceDetectorInterface faceDetector;
  final CameraValidator cameraValidator;
  final FrameProcessor frameProcessor;
  final int minConfirmationFrames;
  final int maxSessionDurationMs;
  final int actionTimeoutMs;
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

  Future<void> initialize() async {
    if (_initialized) return;
    await faceDetector.initialize();
    _initialized = true;
  }

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
      return LivenessResult(isLive: false, score: 0.0, actions: []);
    }

    final sessionStart = DateTime.now().millisecondsSinceEpoch;
    final actionResults = <ActionDetail>[];
    final shuffledActions = _shuffleActions(actions);

    for (var i = 0; i < shuffledActions.length; i++) {
      final action = shuffledActions[i];
      onActionChanged?.call(action, i, shuffledActions.length);

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

      // Don't stop early on first action fail — continue to next action.
    }

    final passed = actionResults.where((a) => a.passed).length;
    final total = actionResults.length;
    final overallScore = total > 0
        ? actionResults.map((a) => a.score).reduce((a, b) => a + b) / total
        : 0.0;

    // Pass if at least 1 action passed (for 2-action default)
    final isLive = passed >= 1 && overallScore > 0.3;

    return LivenessResult(
      isLive: isLive,
      score: overallScore,
      actions: actionResults,
      completedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<ActionDetail> _runAction({
    required VivdAction action,
    required Stream<CameraFrame> frameStream,
    void Function(VivdAction action, FaceDetection face)? onProgress,
  }) async {
    final actionStart = DateTime.now().millisecondsSinceEpoch;
    var confirmedFrames = 0;
    var totalFrames = 0;
    var bestScore = 0.0;
    var validationRejected = 0;
    var detectionErrors = 0;

    final completer = Completer<ActionDetail>();

    // Use a single-subscription stream with sync=False so async processing works.
    // We serialize processing to avoid race conditions.
    var processing = false;

    final subscription = frameStream.listen(
      (frame) async {
        if (completer.isCompleted || processing) return;
        processing = true;

        try {
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
                    ? 'Timeout — confirmed $confirmedFrames/$minConfirmationFrames'
                    : null,
              ));
            }
            return;
          }

          // Validate frame quality
          final validation = cameraValidator.validate(frame);
          if (!validation.passed) {
            validationRejected++;
            if (validationRejected <= 3) {
              _log('[Vivd] Frame rejected: ${validation.reason}');
            }
            return;
          }

          // Process frame
          final processed = await frameProcessor.process(frame);

          List<FaceDetection> faces;
          try {
            faces = await faceDetector.detect(
              processed.bytes,
              width: processed.width,
              height: processed.height,
              rotation: processed.rotation,
              format: processed.format,
            );
          } catch (e) {
            detectionErrors++;
            if (detectionErrors <= 3) {
              _log('[Vivd] Detection error: $e');
            }
            return;
          }

          if (faces.isEmpty) return;
          totalFrames++;

          final face = faces.first;
          onProgress?.call(action, face);

          final detected = _detectAction(action, face);
          final score = _calculateActionScore(action, face);

          if (totalFrames <= 5 || detected) {
            _log('[Vivd] ${action.label}: detected=$detected score=${score.toStringAsFixed(2)} '
                'eyes=${face.avgEyeOpen?.toStringAsFixed(2)} smile=${face.smiling?.toStringAsFixed(2)} '
                'headY=${face.headEulerAngleY?.toStringAsFixed(1)}');
          }

          if (detected) {
            confirmedFrames++;
            if (score > bestScore) bestScore = score;

            if (confirmedFrames >= minConfirmationFrames) {
              if (!completer.isCompleted) {
                _log('[Vivd] ✓ ${action.label} PASSED (frames=$confirmedFrames score=${bestScore.toStringAsFixed(2)})');
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
        } catch (e) {
          _log('[Vivd] Unexpected error in frame processing: $e');
        } finally {
          processing = false;
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

    // Hard timeout safety net
    Future.delayed(Duration(milliseconds: actionTimeoutMs + 2000), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        _log('[Vivd] ✗ ${action.label} TIMEOUT (confirmed=$confirmedFrames frames=$totalFrames errors=$detectionErrors rejected=$validationRejected)');
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
    });

    final result = await completer.future;
    await subscription.cancel();
    return result;
  }

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

  List<VivdAction> _shuffleActions(List<VivdAction> actions) {
    final random = Random.secure();
    final shuffled = List<VivdAction>.from(actions);
    for (var i = shuffled.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    return shuffled;
  }
}

/// debugPrint is available from Flutter foundation.
void _log(String message) {
  // ignore: avoid_print
  print(message);
}
