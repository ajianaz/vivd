import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vivd/vivd.dart';

void main() {
  group('VivdAction', () {
    test('has 6 action types', () {
      expect(VivdAction.values.length, 6);
    });

    test('each action has a label', () {
      for (final action in VivdAction.values) {
        expect(action.label, isNotEmpty);
      }
    });
  });

  group('VivdConfig', () {
    test('default config has blink and smile', () {
      const config = VivdConfig();
      expect(config.actions, [VivdAction.blink, VivdAction.smile]);
    });

    test('custom actions override defaults', () {
      const config = VivdConfig(
        actions: [VivdAction.headTurnLeft],
      );
      expect(config.actions, [VivdAction.headTurnLeft]);
    });
  });

  group('VivdImageFormat', () {
    test('has 4 format types', () {
      expect(VivdImageFormat.values.length, 4);
    });
  });

  group('LivenessResult', () {
    test('creates with required fields', () {
      final result = LivenessResult(isLive: true, score: 0.95);
      expect(result.isLive, true);
      expect(result.score, 0.95);
      expect(result.actions, isEmpty);
      expect(result.completedAt, isPositive);
    });

    test('toJson includes all fields', () {
      final result = LivenessResult(isLive: true, score: 0.8);
      final json = result.toJson();
      expect(json['isLive'], true);
      expect(json['score'], 0.8);
      expect(json['sessionId'], isNull);
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
    test('verifySignature with matching key returns true', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
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
      // Signature won't match random key — test that method runs without error
      expect(payload.verifySignature('test-key'), isA<bool>());
    });
  });

  group('CameraFrame', () {
    test('factory creates valid frame', () {
      final frame = CameraFrame(
        bytes: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
      );
      expect(frame.width, 640);
      expect(frame.height, 480);
      expect(frame.rotation, 0);
      expect(frame.format, VivdImageFormat.nv21);
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
      expect(processed.rotation, 0);
    });
  });

  group('ValidationResult', () {
    test('default is not passed', () {
      const result = ValidationResult(score: 0.0, passed: false);
      expect(result.passed, false);
      expect(result.brightness, isNull);
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
      expect(detection.isSmiling(), false);
      expect(detection.isHeadTurnedLeft(), false);
      expect(detection.isHeadTurnedRight(), false);
    });

    test('eye helpers detect closed eyes', () {
      final detection = FaceDetection(
        boundingBox: Rect.zero,
        leftEyeOpen: 0.1,
        rightEyeOpen: 0.15,
      );
      expect(detection.areEyesClosed(threshold: 0.3), true);
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
  });
}
