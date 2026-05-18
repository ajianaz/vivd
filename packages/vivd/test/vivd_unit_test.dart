import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vivd/src/camera/camera_service.dart';
import 'package:vivd/src/camera/camera_validator.dart';
import 'package:vivd/src/camera/frame_processor.dart';
import 'package:vivd/src/detection/face_detector_interface.dart';
import 'package:vivd/src/models/liveness_action.dart';

void main() {
  group('CameraValidator', () {
    late CameraValidator validator;

    setUp(() {
      validator = CameraValidator();
    });

    CameraFrame makeFrame(int width, int height, {int yValue = 128}) {
      final ySize = width * height;
      final vuSize = width * (height ~/ 2);
      final bytes = Uint8List(ySize + vuSize);
      // Fill Y plane with given brightness
      for (var i = 0; i < ySize; i++) {
        bytes[i] = yValue;
      }
      return CameraFrame(
        bytes: bytes,
        width: width,
        height: height,
        format: VivdImageFormat.nv21,
      );
    }

    test('accepts normal brightness frame', () {
      final frame = makeFrame(320, 240, yValue: 128);
      final result = validator.validate(frame);
      expect(result.passed, true);
      expect(result.brightness, greaterThan(0));
    });

    test('rejects too dark frame', () {
      final frame = makeFrame(320, 240, yValue: 10);
      final result = validator.validate(frame);
      expect(result.passed, false);
      expect(result.isTooDark, true);
    });

    test('rejects too bright frame', () {
      final frame = makeFrame(320, 240, yValue: 250);
      final result = validator.validate(frame);
      expect(result.passed, false);
      expect(result.isTooBright, true);
    });

    test('custom thresholds work', () {
      final strictValidator = CameraValidator(
        minBrightness: 80,
        maxBrightness: 200,
        passThreshold: 0.8,
      );
      // yValue=70 → below minBrightness=80
      final frame = makeFrame(320, 240, yValue: 70);
      final result = strictValidator.validate(frame);
      expect(result.isTooDark, true);
    });

    test('empty bytes frame returns score 0', () {
      final frame = CameraFrame(
        bytes: Uint8List(0),
        width: 0,
        height: 0,
      );
      final result = validator.validate(frame);
      expect(result.brightness, 0.0);
    });
  });

  group('FrameProcessor', () {
    late FrameProcessor processor;

    setUp(() {
      processor = FrameProcessor();
    });

    test('NV21 passthrough — returns same bytes', () async {
      final bytes = Uint8List.fromList(List.filled(100, 42));
      final frame = CameraFrame(
        bytes: bytes,
        width: 10,
        height: 10,
        format: VivdImageFormat.nv21,
      );
      final result = await processor.process(frame);
      expect(result.format, VivdImageFormat.nv21);
      expect(result.bytes, bytes);
      expect(result.width, 10);
      expect(result.height, 10);
    });

    test('YUV420 passthrough — returns as-is', () async {
      final bytes = Uint8List.fromList(List.filled(100, 42));
      final frame = CameraFrame(
        bytes: bytes,
        width: 10,
        height: 10,
        format: VivdImageFormat.yuv420,
      );
      final result = await processor.process(frame);
      expect(result.format, VivdImageFormat.yuv420);
    });

    test('BGRA8888 converts to NV21', () async {
      // 4x2 image, BGRA = 4 bytes per pixel = 32 bytes
      final bytes = Uint8List(4 * 2 * 4);
      for (var i = 0; i < 4 * 2; i++) {
        bytes[i * 4] = 100;     // B
        bytes[i * 4 + 1] = 150; // G
        bytes[i * 4 + 2] = 200; // R
        bytes[i * 4 + 3] = 255; // A
      }
      final frame = CameraFrame(
        bytes: bytes,
        width: 4,
        height: 2,
        format: VivdImageFormat.bgra8888,
      );
      final result = await processor.process(frame);
      expect(result.format, VivdImageFormat.nv21);
      expect(result.width, 4);
      expect(result.height, 2);
      expect(result.bytes.length, greaterThan(0));
    });
  });

  group('VivdAction', () {
    test('each action has label, instruction, emoji', () {
      for (final action in VivdAction.values) {
        expect(action.label, isNotEmpty);
        expect(action.instruction, isNotEmpty);
        expect(action.emoji, isNotEmpty);
      }
    });

    test('blink has correct properties', () {
      expect(VivdAction.blink.label, 'Blink');
      expect(VivdAction.blink.instruction, 'Close both eyes');
      expect(VivdAction.blink.emoji, '👁️');
    });

    test('smile has correct properties', () {
      expect(VivdAction.smile.label, 'Smile');
      expect(VivdAction.smile.instruction, 'Show your teeth');
    });

    test('head turns have correct properties', () {
      expect(VivdAction.headTurnLeft.label, 'Turn Left');
      expect(VivdAction.headTurnRight.label, 'Turn Right');
      expect(VivdAction.lookUp.label, 'Look Up');
      expect(VivdAction.lookDown.label, 'Look Down');
    });

    test('estimated duration is positive for all actions', () {
      for (final action in VivdAction.values) {
        expect(action.estimatedDurationMs, greaterThan(0));
      }
    });

    test('blink is fastest, head turns slowest', () {
      expect(VivdAction.blink.estimatedDurationMs,
          lessThan(VivdAction.headTurnLeft.estimatedDurationMs));
    });
  });

  group('FaceDetection helpers', () {
    FaceDetection makeFace({
      double? leftEyeOpen,
      double? rightEyeOpen,
      double? smiling,
      double? headEulerAngleX,
      double? headEulerAngleY,
    }) {
      return FaceDetection(
        boundingBox: const Rect.fromLTWH(10, 20, 100, 120),
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        smiling: smiling,
        headEulerAngleX: headEulerAngleX,
        headEulerAngleY: headEulerAngleY,
      );
    }

    test('areEyesClosed — eyes at 0.2, threshold 0.3 → closed', () {
      final face = makeFace(leftEyeOpen: 0.2, rightEyeOpen: 0.2);
      expect(face.areEyesClosed(threshold: 0.3), true);
      expect(face.areEyesOpen(threshold: 0.7), false);
    });

    test('areEyesOpen — eyes at 0.9, threshold 0.7 → open', () {
      final face = makeFace(leftEyeOpen: 0.9, rightEyeOpen: 0.9);
      expect(face.areEyesClosed(threshold: 0.3), false);
      expect(face.areEyesOpen(threshold: 0.7), true);
    });

    test('avgEyeOpen with one null eye uses 0 for null', () {
      final face = makeFace(leftEyeOpen: 0.8, rightEyeOpen: null);
      expect(face.avgEyeOpen, closeTo(0.4, 0.01));
    });

    test('avgEyeOpen with both null returns null', () {
      final face = makeFace();
      expect(face.avgEyeOpen, isNull);
    });

    test('isSmiling — above threshold', () {
      final face = makeFace(smiling: 0.85);
      expect(face.isSmiling(threshold: 0.7), true);
      expect(face.isSmiling(threshold: 0.9), false);
    });

    test('isSmiling — null smiling returns false', () {
      final face = makeFace();
      expect(face.isSmiling(), false);
    });

    test('head turn detection', () {
      final face = makeFace(headEulerAngleY: -30.0);
      expect(face.isHeadTurnedLeft(threshold: -20.0), true);
      expect(face.isHeadTurnedRight(threshold: 20.0), false);
    });

    test('head turn right detection', () {
      final face = makeFace(headEulerAngleY: 25.0);
      expect(face.isHeadTurnedLeft(threshold: -20.0), false);
      expect(face.isHeadTurnedRight(threshold: 20.0), true);
    });

    test('look up / down detection', () {
      final upFace = makeFace(headEulerAngleX: -20.0);
      expect(upFace.isLookingUp(threshold: -15.0), true);
      expect(upFace.isLookingDown(threshold: 15.0), false);

      final downFace = makeFace(headEulerAngleX: 20.0);
      expect(downFace.isLookingUp(threshold: -15.0), false);
      expect(downFace.isLookingDown(threshold: 15.0), true);
    });

    test('face dimensions from bounding box', () {
      final face = makeFace();
      expect(face.faceWidth, 100);
      expect(face.faceHeight, 120);
      expect(face.faceArea, 12000);
    });
  });

  group('CameraFrame', () {
    test('sizeInBytes returns correct length', () {
      final frame = CameraFrame(
        bytes: Uint8List(1024),
        width: 32,
        height: 32,
      );
      expect(frame.sizeInBytes, 1024);
    });

    test('default format is nv21', () {
      final frame = CameraFrame(
        bytes: Uint8List(10),
        width: 1,
        height: 1,
      );
      expect(frame.format, VivdImageFormat.nv21);
    });

    test('default rotation is 0', () {
      final frame = CameraFrame(
        bytes: Uint8List(10),
        width: 1,
        height: 1,
      );
      expect(frame.rotation, 0);
    });
  });

  group('ProcessedFrame', () {
    test('stores all fields correctly', () {
      final frame = ProcessedFrame(
        bytes: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
        rotation: 90,
        format: VivdImageFormat.bgra8888,
      );
      expect(frame.width, 640);
      expect(frame.height, 480);
      expect(frame.rotation, 90);
      expect(frame.format, VivdImageFormat.bgra8888);
    });
  });
}
