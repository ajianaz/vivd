# Extending Vivd

This guide covers how to extend Vivd with custom detectors, anti-spoof engines, new actions, and platform-specific backends.

---

## Custom Face Detector

### Interface Contract

`FaceDetectorInterface` defines three methods that any detector must implement:

```dart
abstract class FaceDetectorInterface {
  String get name;
  Future<void> initialize();
  Future<List<FaceDetection>> detect(Uint8List bytes, {
    required int width,
    required int height,
    int rotation = 0,
    VivdImageFormat format = VivdImageFormat.nv21,
  });
  Future<void> dispose();
}
```

### Required Output Fields

`LivenessEngine._detectAction()` and `_calculateActionScore()` read these fields from `FaceDetection`:

| Field | Used By | Required For |
|---|---|---|
| `leftEyeOpen`, `rightEyeOpen` | `blink` action, `_BlinkTracker` | Blink detection |
| `smiling` | `smile` action | Smile detection |
| `headEulerAngleY` | `headTurnLeft`, `headTurnRight` | Head turn detection |
| `headEulerAngleX` | `lookUp`, `lookDown` | Head tilt detection |
| `boundingBox` | `FaceDetection` geometry | Face size validation |

### Example: MediaPipe Face Detector

This example shows how to integrate MediaPipe Face Detection using the `mediapipe` package:

```dart
import 'dart:typed_data';
import 'package:mediapipe/mediapipe.dart' as mp;
import 'package:vivd/vivd.dart';

class MediaPipeFaceDetector implements FaceDetectorInterface {
  mp.FaceDetection? _detector;
  bool _initialized = false;

  @override
  String get name => 'MediaPipe Face Detection';

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    _detector = mp.FaceDetection(
      mode: mp.FaceDetectionMode.shortRange,
      minDetectionConfidence: 0.5,
      minTrackingConfidence: 0.5,
    );
    await _detector!.initialize();
    _initialized = true;
  }

  @override
  Future<List<FaceDetection>> detect(
    Uint8List bytes, {
    required int width,
    required int height,
    int rotation = 0,
    VivdImageFormat format = VivdImageFormat.nv21,
  }) async {
    if (!_initialized) {
      throw StateError('MediaPipeFaceDetector not initialized.');
    }

    // Convert NV21 bytes to MediaPipe image format
    final image = mp.Image(
      bytes: bytes,
      width: width,
      height: height,
      format: _toMediaPipeFormat(format),
    );

    final results = await _detector!.detect(image);

    return results.detections.map((d) {
      final bbox = d.boundingBox;
      // Extract classification probabilities from keypoints/landmarks
      final leftEyeOpen = _estimateEyeOpen(d, side: 'left');
      final rightEyeOpen = _estimateEyeOpen(d, side: 'right');
      final smiling = _estimateSmile(d);
      final headY = _estimateEulerY(d);

      return FaceDetection(
        boundingBox: Rect.fromLTWH(
          bbox.x, bbox.y, bbox.width, bbox.height,
        ),
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        smiling: smiling,
        headEulerAngleY: headY,
      );
    }).toList();
  }

  @override
  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _initialized = false;
  }
}
```

### Registering Your Detector

Pass it through `VivdConfig`:

```dart
final vivd = Vivd(config: VivdConfig(
  faceDetector: MediaPipeFaceDetector(),
));
await vivd.initialize(); // Calls initialize() on your detector
```

The `Vivd` facade does not instantiate a default detector if one is provided -- it uses yours directly.

---

## Custom Anti-Spoof Engine

### Current Limitation

`AntiSpoofEngine` is a concrete class, not behind an interface. Replacing it requires either forking the package or waiting for the planned `AntiSpoofInterface` in Phase 3.

### Expected Contract

Based on the current implementation, any replacement should accept:

```dart
Future<double> analyze(CameraFrame frame);
Future<double> analyzeFaceRegion(Uint8List faceBytes, {
  required int width,
  required int height,
});
```

Return a score from 0.0 (definitely spoofed) to 1.0 (definitely real).

### Example: ML-Based PAD with ONNX Runtime

```dart
import 'dart:typed_data';
import 'package:flutter_app_runner/onnx_runner.dart';
import 'package:vivd/vivd.dart';

class OnnxAntiSpoofEngine {
  OnnxRunner? _runner;
  bool _initialized = false;

  /// Score threshold: below this = spoof
  static const double spoofThreshold = 0.5;

  Future<void> initialize() async {
    if (_initialized) return;

    _runner = OnnxRunner();
    await _runner!.loadModel('assets/models/anti_spoof.onnx');
    _initialized = true;
  }

  /// Analyze a face crop for spoof indicators.
  /// Returns 0.0 (spoof) to 1.0 (real).
  Future<double> analyzeFaceRegion(
    Uint8List faceBytes, {
    required int width,
    required int height,
  }) async {
    if (!_initialized) {
      throw StateError('OnnxAntiSpoofEngine not initialized.');
    }

    // Preprocess: resize to model input size, normalize
    final input = _preprocess(faceBytes, width, height,
        targetSize: 224);

    // Run inference
    final outputs = await _runner!.run({'input': input});
    final score = (outputs['output'] as List<double>).first;

    return score.clamp(0.0, 1.0);
  }

  List<double> _preprocess(Uint8List bytes, int w, int h,
      {required int targetSize}) {
    // Resize, normalize to [0, 1], arrange as CHW tensor
    // Implementation depends on your image processing library
    return List<double>.filled(targetSize * targetSize * 3, 0.0);
  }

  Future<void> dispose() async {
    await _runner?.release();
    _runner = null;
    _initialized = false;
  }
}
```

### Integrating with Liveness Flow

Until `AntiSpoofInterface` is introduced, run the engine alongside the liveness session:

```dart
final vivd = Vivd(config: VivdConfig(enableAntiSpoof: true));
await vivd.initialize();

// After liveness result, run additional anti-spoof check
final result = await vivd.startLiveness(frameStream: stream);

// Double-check with custom engine
final antiSpoof = OnnxAntiSpoofEngine();
await antiSpoof.initialize();

// Extract face crop from the best frame
final isReal = result.antiSpoofScore != null &&
    result.antiSpoofScore! > spoofThreshold;

await antiSpoof.dispose();
```

---

## Server Verification Flow

### How HMAC Signing Works

When `VivdConfig.hmacKey` is non-empty, `Vivd.startLiveness()` automatically creates and signs sessions:

```
1. SessionManager.createSession()
   - Generates random sessionId (16 hex bytes)
   - Generates random nonce (32 hex bytes)
   - Records creation timestamp
   - Sets expiration (createdAt + sessionDurationSeconds)

2. LivenessEngine.runSession()
   - Runs shuffled actions, collects ActionDetail results

3. SessionManager.signResults()
   - Builds payload string: "{sessionId}|{nonce}|{timestamp}|{score}"
   - Computes HMAC-SHA256(payloadString, hmacKey)
   - Returns SignedPayload with all fields + signature
```

### Signed Payload Format

```json
{
  "sessionId": "a1b2c3d4e5f6a7b8",
  "nonce": "f8e7d6c5b4a39281000000000000000000000000000000000000000000000000",
  "actions": ["blink", "smile", "headTurnLeft"],
  "results": [
    { "action": "blink", "passed": true, "score": 0.92, "durationMs": 845 },
    { "action": "smile", "passed": true, "score": 0.87, "durationMs": 1520 }
  ],
  "score": 0.895,
  "timestamp": 1717065600000,
  "signature": "a1b2c3d4e5f6..."
}
```

### Building a Verification Server

Here is a minimal Node.js verification endpoint:

```javascript
const crypto = require('crypto');

function verifyLivenessPayload(payloadJson, hmacKey, maxAgeSeconds) {
  const payload = JSON.parse(payloadJson);

  // 1. Check timestamp freshness
  const now = Date.now();
  const age = (now - payload.timestamp) / 1000;
  if (age > maxAgeSeconds) {
    return { valid: false, reason: 'Payload expired' };
  }

  // 2. Reconstruct the payload string that was signed
  const payloadString = `${payload.sessionId}|${payload.nonce}|${payload.timestamp}|${payload.score}`;

  // 3. Compute expected HMAC-SHA256
  const expected = crypto
    .createHmac('sha256', hmacKey)
    .update(payloadString)
    .digest('hex');

  // 4. Compare signatures (constant-time)
  if (!crypto.timingSafeEqual(
    Buffer.from(expected, 'hex'),
    Buffer.from(payload.signature, 'hex')
  )) {
    return { valid: false, reason: 'Invalid signature' };
  }

  // 5. Check nonce format (minimum length)
  if (payload.nonce.length < 64) {
    return { valid: false, reason: 'Invalid nonce' };
  }

  // 6. Optional: check nonce against recent nonces for replay protection
  //    Store nonce in Redis/DB with TTL = sessionDurationSeconds
  //    if (await nonceStore.exists(payload.nonce)) {
  //      return { valid: false, reason: 'Nonce replay' };
  //    }
  //    await nonceStore.set(payload.nonce, '1', 'EX', maxAgeSeconds);

  // 7. Validate overall score
  if (payload.score < 0.6) {
    return { valid: false, reason: 'Score below threshold' };
  }

  // 8. Check action results
  const passedActions = payload.results.filter(r => r.passed).length;
  if (passedActions < 1) {
    return { valid: false, reason: 'No actions passed' };
  }

  return {
    valid: true,
    sessionId: payload.sessionId,
    score: payload.score,
    actions: payload.results,
  };
}

// Express.js example
app.post('/verify-liveness', (req, res) => {
  const result = verifyLivenessPayload(
    req.body.payload,
    process.env.VIVD_HMAC_KEY,
    300 // 5 minutes
  );
  res.json(result);
});
```

### Replay Protection

Each session includes a random nonce (32 hex bytes via `Random.secure()`). To prevent replay attacks:

1. On the server, store nonces in a set with TTL matching `sessionDurationSeconds`
2. On each verification request, check if the nonce was already used
3. If yes, reject as replay attack
4. If no, add to the set and proceed with verification

This prevents an attacker from capturing a valid signed payload and resubmitting it.

---

## Adding New Actions

### Step 1: Add to VivdAction Enum

Edit `packages/vivd/lib/src/models/liveness_action.dart`:

```dart
enum VivdAction {
  // ... existing actions ...

  /// Open mouth wide.
  mouthOpen('Open Mouth', 'Open your mouth wide', '👄'),

  const VivdAction(this.label, this.instruction, this.emoji);
  // ... existing fields ...
}
```

### Step 2: Add Detection Logic

Edit `packages/vivd/lib/src/liveness/liveness_engine.dart`. Add cases to `_detectAction()` and `_calculateActionScore()`:

```dart
bool _detectAction(VivdAction action, FaceDetection face) {
  final m = _mirrorEulerAngles;
  return switch (action) {
    // ... existing cases ...

    VivdAction.mouthOpen =>
      face.landmarks['bottomMouth'] != null &&
      face.landmarks['noseBase'] != null &&
      (face.landmarks['bottomMouth']!.dy -
       face.landmarks['noseBase']!.dy) > 25.0,
  };
}

double _calculateActionScore(VivdAction action, FaceDetection face) {
  return switch (action) {
    // ... existing cases ...

    VivdAction.mouthOpen =>
      face.landmarks['bottomMouth'] != null &&
      face.landmarks['noseBase'] != null
          ? ((face.landmarks['bottomMouth']!.dy -
              face.landmarks['noseBase']!.dy) / 40.0)
              .clamp(0.0, 1.0)
          : 0.0,
  };
}
```

### Step 3: Add UI Icon (Optional)

Edit `packages/vivd/lib/src/ui/vivd_liveness_detector_action_ext.dart`:

```dart
extension VivdActionIcon on VivdAction {
  IconData get icon => switch (this) {
    // ... existing cases ...
    VivdAction.mouthOpen => Icons.mood,
  };
}
```

### Step 4: Update Estimated Duration

Add a case to `estimatedDurationMs` in the enum:

```dart
int get estimatedDurationMs {
  switch (this) {
    // ... existing cases ...
    case VivdAction.mouthOpen:
      return 2000;
  }
}
```

### Step 5: Use the New Action

```dart
final vivd = Vivd(config: VivdConfig(
  actions: [
    VivdAction.blink,
    VivdAction.mouthOpen,
    VivdAction.headTurnLeft,
  ],
));
```

### Requirements for Detection

Your action's detection logic can use any data available on `FaceDetection`:

- **Landmark positions** -- Use the `landmarks` map (keyed by string). ML Kit provides predefined landmarks (`leftEye`, `rightEye`, `noseBase`, `bottomMouth`) which are mapped to named keys in `MlKitFaceDetector._convertFace()`.
- **Classification probabilities** -- `leftEyeOpen`, `rightEyeOpen`, `smiling` (0.0 to 1.0).
- **Euler angles** -- `headEulerAngleX`, `headEulerAngleY`, `headEulerAngleZ` in degrees.
- **Bounding box** -- `boundingBox` is a `Rect` with width and height.

---

## Platform-Specific Detection

### Apple Vision on iOS

Apple Vision Framework provides high-quality face detection optimized for A-series chips. To use it on iOS only:

```dart
import 'dart:io';
import 'package:vivd/vivd.dart';

FaceDetectorInterface createPlatformDetector() {
  if (Platform.isIOS) {
    return AppleVisionFaceDetector();
  }
  return MlKitFaceDetector();
}
```

An `AppleVisionFaceDetector` implementation would:
1. Use a platform channel to call Vision's `VNDetectFaceLandmarksRequest`
2. Extract landmark positions, euler angles, and classification from `VNFaceObservation`
3. Convert to `FaceDetection` model
4. Return results to Dart via the platform channel

Key considerations:
- Vision Framework provides 68 face landmarks natively
- Head pose estimation via `VNFaceObservation.roll`, `yaw`, `pitch`
- Mouth state via landmark distance analysis (no built-in "mouth open" probability)
- Eye state via landmark distance analysis (no built-in probability, but landmarks are precise)

### InsightFace ONNX on Android

InsightFace provides state-of-the-art face detection and landmark models in ONNX format, optimized for mobile:

```dart
class InsightFaceOnnxDetector implements FaceDetectorInterface {
  @override
  String get name => 'InsightFace ONNX';

  @override
  Future<void> initialize() async {
    // Load retinaface.onnx via onnxruntime
    // Load landmark model (106 or 5 landmarks)
  }

  @override
  Future<List<FaceDetection>> detect(
    Uint8List bytes, {
    required int width,
    required int height,
    int rotation = 0,
    VivdImageFormat format = VivdImageFormat.nv21,
  }) async {
    // Preprocess: NV21 -> RGB -> resize to 640x640 -> normalize
    // Run RetinaFace detection
    // Run landmark model on detected faces
    // Estimate head pose from landmarks using PnP
    // Estimate eye/mouth state from landmark distances
    // Convert to FaceDetection
    return [];
  }

  @override
  Future<void> dispose() async {}
}
```

Key considerations:
- InsightFace models are larger than ML Kit (~10MB vs ~2MB)
- RetinaFace provides more accurate bounding boxes
- 106-point landmarks enable precise head pose estimation via solvePnP
- Eye/mouth state requires custom threshold logic based on landmark distances
- ONNX Runtime Flutter package handles model execution

### Hybrid Strategy

For best results, use platform-native detection where available:

```dart
FaceDetectorInterface createOptimalDetector() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppleVisionFaceDetector(),
    TargetPlatform.android => InsightFaceOnnxDetector(),
    TargetPlatform.macOS => AppleVisionFaceDetector(),
    // Fallback to ML Kit for web, linux, windows
    _ => MlKitFaceDetector(),
  };
}
```

This can be packaged as a factory function or a conditional import:

```dart
// lib/src/detection/platform_detector.dart
export 'ml_kit_face_detector.dart'
    if (dart.library.io) 'native_face_detector.dart';
```
