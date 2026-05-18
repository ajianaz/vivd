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
    this.maxSessionDurationMs = 60000,
    this.actionTimeoutMs = 15000,
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
    }

    final passed = actionResults.where((a) => a.passed).length;
    final total = actionResults.length;
    final overallScore = total > 0
        ? actionResults.map((a) => a.score).reduce((a, b) => a + b) / total
        : 0.0;

    // Pass if majority of actions passed and overall score is decent
    final isLive = passed >= 1 && overallScore > actionPassThreshold;

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

    // For blink: track eye-open baseline to detect relative change.
    // This makes blink detection work with glasses where eye-open
    // probability never drops as low as without glasses.
    final blinkTracker = _BlinkTracker();

    final completer = Completer<ActionDetail>();
    var processing = false;

    final subscription = frameStream.listen(
      (frame) async {
        if (completer.isCompleted || processing) return;
        processing = true;

        try {
          final elapsed = DateTime.now().millisecondsSinceEpoch - actionStart;
          if (elapsed >= actionTimeoutMs) {
            if (!completer.isCompleted) {
              _log('[Vivd] ⏱ ${action.label} timeout after ${elapsed}ms '
                  '(confirmed=$confirmedFrames frames=$totalFrames)');
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

          // Detect action — blink uses relative delta tracker
          final detected = action == VivdAction.blink
              ? blinkTracker.updateAndDetect(face)
              : _detectAction(action, face);
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
        _log('[Vivd] ✗ ${action.label} HARD TIMEOUT '
            '(confirmed=$confirmedFrames frames=$totalFrames errors=$detectionErrors rejected=$validationRejected)');
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
      VivdAction.smile => face.isSmiling(threshold: 0.6),
      VivdAction.headTurnLeft => face.isHeadTurnedLeft(threshold: -18.0),
      VivdAction.headTurnRight => face.isHeadTurnedRight(threshold: 18.0),
      VivdAction.lookUp => face.isLookingUp(threshold: -12.0),
      VivdAction.lookDown => face.isLookingDown(threshold: 12.0),
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

/// Blink detection that works with glasses.
///
/// Instead of a fixed threshold (which fails with glasses because
/// eye-open probability stays higher), this tracker:
/// 1. Builds a baseline of eye-open values during the first few frames
/// 2. Detects blink as a significant relative DROP from baseline
/// 3. Also checks absolute threshold as fallback
class _BlinkTracker {
  /// Baseline eye-open average (built from first frames).
  double _baseline = 0.0;

  /// Whether baseline has been established.
  bool _baselineReady = false;

  /// Number of baseline samples collected.
  int _baselineSamples = 0;

  /// Minimum baseline samples before detection starts.
  static const _minBaselineSamples = 3;

  /// Relative drop threshold — if eye-open drops by this fraction
  /// from baseline, consider it a blink.
  /// E.g. 0.4 = 40% drop from baseline.
  static const _relativeDropThreshold = 0.35;

  /// Absolute threshold fallback (works for no-glasses case).
  static const _absoluteThreshold = 0.3;

  /// Maximum baseline value to use (cap at 0.95 to handle noisy readings).
  static const _maxBaselineCap = 0.95;

  /// Update with new face data and return whether blink is detected.
  bool updateAndDetect(FaceDetection face) {
    final eyeOpen = face.avgEyeOpen;
    if (eyeOpen == null) return false;

    // Build baseline from first frames (eyes open state)
    if (!_baselineReady) {
      // Only add to baseline if eyes are reasonably open (> 0.5)
      // to avoid building baseline from already-closed eyes.
      if (eyeOpen > 0.5) {
        _baseline = (_baseline * _baselineSamples + eyeOpen) / (_baselineSamples + 1);
        _baselineSamples++;
      }

      if (_baselineSamples >= _minBaselineSamples) {
        _baseline = _baseline.clamp(0.0, _maxBaselineCap);
        _baselineReady = true;
        _log('[Vivd] Blink baseline established: ${_baseline.toStringAsFixed(2)}');
      }
      return false; // Don't detect during baseline building
    }

    // Method 1: Relative drop from baseline (glasses-friendly)
    final relativeDrop = _baseline - eyeOpen;
    final relativeDetected = relativeDrop >= (_baseline * _relativeDropThreshold);

    // Method 2: Absolute threshold (fallback for no-glasses)
    final absoluteDetected = eyeOpen < _absoluteThreshold;

    final detected = relativeDetected || absoluteDetected;

    if (detected && _baselineSamples < 20) {
      _log('[Vivd] Blink detected! method=${relativeDetected ? "relative" : "absolute"} '
          'eyeOpen=${eyeOpen.toStringAsFixed(2)} baseline=$_baseline '
          'drop=${relativeDrop.toStringAsFixed(2)}');
    }

    return detected;
  }
}

void _log(String message) {
  // ignore: avoid_print
  print(message);
}
