import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vivd/vivd.dart';

void main() {
  group('CameraFrame', () {
    test('factory creates valid frame with defaults', () {
      final frame = CameraFrame(
        bytes: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
      );
      expect(frame.width, 640);
      expect(frame.height, 480);
      expect(frame.rotation, 0);
      expect(frame.format, VivdImageFormat.nv21);
      expect(frame.timestamp, isNull);
      expect(frame.sizeInBytes, 3);
    });

    test('factory creates frame with custom format', () {
      final frame = CameraFrame(
        bytes: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
        format: VivdImageFormat.bgra8888,
        rotation: 90,
        timestamp: 1000,
      );
      expect(frame.format, VivdImageFormat.bgra8888);
      expect(frame.rotation, 90);
      expect(frame.timestamp, 1000);
    });
  });

  group('CameraError', () {
    test('has all expected values', () {
      expect(CameraError.values, [
        CameraError.noCamera,
        CameraError.permissionDenied,
        CameraError.cameraInUse,
        CameraError.unknown,
      ]);
    });

    test('CameraException formats message', () {
      const exc = CameraException(CameraError.noCamera, 'No device');
      expect(exc.toString(), 'CameraException: CameraError.noCamera — No device');
    });

    test('CameraException without message', () {
      const exc = CameraException(CameraError.unknown);
      expect(exc.toString(), 'CameraException: CameraError.unknown');
      expect(exc.message, isNull);
    });
  });

  group('VivdImageFormat', () {
    test('has 4 format types', () {
      expect(VivdImageFormat.values.length, 4);
      expect(VivdImageFormat.values, [
        VivdImageFormat.nv21,
        VivdImageFormat.bgra8888,
        VivdImageFormat.yuv420,
        VivdImageFormat.rgb888,
      ]);
    });
  });

  group('ProcessedFrame', () {
    test('factory creates valid processed frame', () {
      final processed = ProcessedFrame(
        bytes: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
        format: VivdImageFormat.rgb888,
      );
      expect(processed.width, 640);
      expect(processed.height, 480);
      expect(processed.format, VivdImageFormat.rgb888);
      expect(processed.rotation, 0);
    });
  });

  group('VivdAction', () {
    test('has 6 action types', () {
      expect(VivdAction.values.length, 6);
    });

    test('each action has a label', () {
      for (final action in VivdAction.values) {
        expect(action.label, isNotEmpty);
      }
    });

    test('each action has estimated duration', () {
      for (final action in VivdAction.values) {
        expect(action.estimatedDurationMs, greaterThan(0));
      }
    });
  });

  group('VivdConfig', () {
    test('default config has blink and smile', () {
      const config = VivdConfig();
      expect(config.actions, [VivdAction.blink, VivdAction.smile]);
      expect(config.minConfirmationFrames, 3);
      expect(config.maxSessionDurationMs, 30000);
      expect(config.actionTimeoutMs, 10000);
      expect(config.actionPassThreshold, 0.7);
      expect(config.enableAntiSpoof, false);
      expect(config.hmacKey, '');
    });

    test('custom config overrides defaults', () {
      const config = VivdConfig(
        actions: [VivdAction.headTurnLeft],
        minConfirmationFrames: 5,
        enableAntiSpoof: true,
        hmacKey: 'test-key',
      );
      expect(config.actions, [VivdAction.headTurnLeft]);
      expect(config.minConfirmationFrames, 5);
      expect(config.enableAntiSpoof, true);
      expect(config.hmacKey, 'test-key');
    });
  });

  group('LivenessResult', () {
    test('creates with required fields', () {
      final result = LivenessResult(isLive: true, score: 0.95);
      expect(result.isLive, true);
      expect(result.score, 0.95);
      expect(result.actions, isEmpty);
      expect(result.completedAt, isPositive);
      expect(result.sessionId, isNull);
      expect(result.antiSpoofScore, isNull);
    });

    test('toJson includes all fields', () {
      final result = LivenessResult(isLive: true, score: 0.8);
      final json = result.toJson();
      expect(json['isLive'], true);
      expect(json['score'], 0.8);
      expect(json['sessionId'], isNull);
      expect(json['actions'], []);
    });

    test('passedActions and failedActions count correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final result = LivenessResult(
        isLive: true,
        score: 0.9,
        actions: [
          ActionDetail(
            action: VivdAction.blink,
            passed: true,
            score: 0.9,
            startedAt: now - 2000,
            completedAt: now - 1000,
            frameCount: 5,
          ),
          ActionDetail(
            action: VivdAction.smile,
            passed: false,
            score: 0.3,
            startedAt: now - 1000,
            completedAt: now,
            frameCount: 10,
            failureReason: 'Timeout',
          ),
        ],
      );
      expect(result.passedActions, 1);
      expect(result.failedActions, 1);
      expect(result.totalActions, 2);
      expect(result.allActionsPassed, false);
    });

    test('durationMs calculates correctly', () {
      final result = LivenessResult(
        isLive: true,
        score: 0.9,
        actions: [
          ActionDetail(
            action: VivdAction.blink,
            passed: true,
            score: 0.9,
            startedAt: 1000,
            completedAt: 3500,
          ),
        ],
      );
      expect(result.durationMs, 2500);
    });
  });

  group('ActionDetail', () {
    test('toJson includes action name', () {
      const detail = ActionDetail(
        action: VivdAction.blink,
        passed: true,
        score: 0.85,
        startedAt: 1000,
        completedAt: 2000,
        frameCount: 3,
      );
      expect(detail.toJson()['action'], 'blink');
      expect(detail.durationMs, 1000);
      expect(detail.failureReason, isNull);
    });

    test('toString formats correctly', () {
      const detail = ActionDetail(
        action: VivdAction.smile,
        passed: true,
        score: 0.92,
        startedAt: 0,
        completedAt: 1500,
      );
      expect(detail.toString(), contains('Smile'));
      expect(detail.toString(), contains('✓'));
    });
  });

  group('FaceIdResult', () {
    test('creates with required fields', () {
      final result = FaceIdResult(faceId: 'FID-0001', score: 0.92);
      expect(result.faceId, 'FID-0001');
      expect(result.score, 0.92);
      expect(result.isMatch, false);
      expect(result.timestamp, isPositive);
    });

    test('meetsThreshold returns correct bool', () {
      final result = FaceIdResult(faceId: 'FID-0001', score: 0.7);
      expect(result.meetsThreshold(0.6), true);
      expect(result.meetsThreshold(0.8), false);
    });

    test('toJson serialization', () {
      final result = FaceIdResult(faceId: 'FID-0001', score: 0.8, label: 'john');
      final json = result.toJson();
      expect(json['faceId'], 'FID-0001');
      expect(json['label'], 'john');
      expect(json['isMatch'], false);
    });
  });

  group('FaceDetection', () {
    test('default values are null', () {
      final detection = FaceDetection(boundingBox: Rect.zero);
      expect(detection.leftEyeOpen, isNull);
      expect(detection.rightEyeOpen, isNull);
      expect(detection.smiling, isNull);
    });

    test('eye helper methods handle null values', () {
      final detection = FaceDetection(boundingBox: Rect.zero);
      expect(detection.areEyesClosed(), false);
      expect(detection.areEyesOpen(), false);
      expect(detection.isSmiling(), false);
      expect(detection.isHeadTurnedLeft(), false);
      expect(detection.isHeadTurnedRight(), false);
    });

    test('avgEyeOpen handles mixed null values', () {
      final detection = FaceDetection(
        boundingBox: Rect.zero,
        leftEyeOpen: 0.8,
        rightEyeOpen: null,
      );
      expect(detection.avgEyeOpen, 0.4);
    });

    test('eye helpers detect closed eyes', () {
      final detection = FaceDetection(
        boundingBox: Rect.zero,
        leftEyeOpen: 0.1,
        rightEyeOpen: 0.15,
      );
      expect(detection.areEyesClosed(threshold: 0.3), true);
      expect(detection.areEyesOpen(threshold: 0.7), false);
      expect(detection.isSmiling(threshold: 0.7), false);
    });

    test('head turn helpers', () {
      final detection = FaceDetection(
        boundingBox: Rect.zero,
        headEulerAngleY: -25.0,
        headEulerAngleX: 10.0,
      );
      expect(detection.isHeadTurnedLeft(threshold: -20.0), true);
      expect(detection.isHeadTurnedRight(threshold: 20.0), false);
      expect(detection.isLookingUp(threshold: -15.0), false);
      expect(detection.isLookingDown(threshold: 15.0), false);
    });

    test('face dimensions from bounding box', () {
      final detection = FaceDetection(
        boundingBox: const Rect.fromLTWH(10, 20, 100, 120),
      );
      expect(detection.faceWidth, 100);
      expect(detection.faceHeight, 120);
      expect(detection.faceArea, 12000);
    });
  });

  group('Session', () {
    test('isExpired returns false for future expiry', () {
      const session = Session(
        sessionId: 'test-session',
        nonce: 'abcdef1234567890abcdef1234567890',
        createdAt: 0,
        actions: ['blink'],
        expiresAt: 9999999999999,
      );
      expect(session.isExpired, false);
    });

    test('isExpired returns true for past expiry', () {
      const session = Session(
        sessionId: 'test-session',
        nonce: 'abcdef1234567890abcdef1234567890',
        createdAt: 0,
        actions: ['blink'],
        expiresAt: 1000,
      );
      expect(session.isExpired, true);
    });
  });

  group('SignedPayload', () {
    test('verifySignature runs without error', () {
      const payload = SignedPayload(
        sessionId: 'test',
        nonce: 'abcdef1234567890abcdef1234567890',
        actions: ['blink'],
        results: [],
        score: 0.95,
        timestamp: 1000000,
        signature:
            'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2',
      );
      expect(payload.verifySignature('test-key'), isA<bool>());
    });
  });

  group('ValidationResult', () {
    test('default is not passed', () {
      const result = ValidationResult(score: 0.0, passed: false);
      expect(result.passed, false);
      expect(result.brightness, isNull);
    });
  });
}
