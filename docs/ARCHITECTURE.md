# Vivd Architecture

## System Overview

Vivd is an on-device face liveness detection SDK for Flutter. All processing runs locally -- no network calls, no server dependency. The system is organized into five horizontal layers, each with a single responsibility:

```
+--------------------------------------------------------------+
|                       UI Layer                                |
|   VivdLivenessDetector (drop-in Flutter widget)                |
+--------------------------------------------------------------+
|                      Vivd Facade                              |
|   Vivd class -- initialize(), startLiveness(), dispose()      |
+--------------------------------------------------------------+
|   Camera Layer    |  Detection Layer  |  Liveness Layer       |
|   CameraService   |  FaceDetector    |  LivenessEngine       |
|   FrameProcessor  |  Interface       |  Action Detection     |
|   CameraValidator |  ML Kit impl     |  _BlinkTracker        |
+--------------------------------------------------------------+
|   Identity Layer  |  ML Layer        |  Security Layer       |
|   FaceIdentity    |  AntiSpoofEngine |  SessionManager       |
|   FaceIdResult    |  Texture analysis|  HMAC-SHA256 signing  |
+--------------------------------------------------------------+
```

### Layer Responsibilities

| Layer | Component | Responsibility |
|---|---|---|
| Camera | `CameraServiceImpl` | Front camera initialization, frame streaming, NV21/BGRA conversion |
| Camera | `FrameProcessor` | Format normalization (BGRA to NV21), center cropping |
| Camera | `CameraValidator` | Frame quality gates: brightness, blur, face size |
| Detection | `FaceDetectorInterface` | Abstract face detection contract |
| Detection | `MlKitFaceDetector` | Google ML Kit implementation (default) |
| Liveness | `LivenessEngine` | Session orchestration, action sequencing, scoring |
| Liveness | `_BlinkTracker` | Glasses-friendly blink detection via relative eye-open drop |
| Identity | `FaceIdentity` | Face registration and 1:N matching |
| ML | `AntiSpoofEngine` | Presentation attack detection (texture analysis stub) |
| Security | `SessionManager` | HMAC-SHA256 session signing, nonce replay protection |
| UI | `VivdLivenessDetector` | Self-contained Flutter widget with camera preview |

---

## Data Flow

The path from a raw camera frame to a `LivenessResult` follows a strict pipeline:

```
Camera sensor
    |
    v
CameraServiceImpl._onFrame()
    |  Converts platform CameraImage (NV21/YUV420/BGRA)
    |  Strips row stride padding, interleaves VU for YUV420
    v
CameraFrame { bytes, width, height, format, rotation, timestamp }
    |
    v
LivenessEngine._runAction() -- frame stream listener
    |
    +-- CameraValidator.validate(frame)
    |       Checks brightness (40-240), blur (Laplacian > 50), face size (>20% frame width)
    |       Rejects low-quality frames before expensive detection
    |       Returns ValidationResult { passed, score, reason }
    |
    +-- FrameProcessor.process(frame)
    |       NV21 passthrough, BGRA-to-NV21 conversion
    |       Returns ProcessedFrame { bytes, width, height, rotation, format }
    |
    +-- FaceDetectorInterface.detect(bytes, width, height, rotation, format)
    |       Default: MlKitFaceDetector wraps google_mlkit_face_detection
    |       Returns List<FaceDetection> with bounding box, landmarks, euler angles
    |
    v
FaceDetection { boundingBox, leftEyeOpen, rightEyeOpen, smiling,
                headEulerAngleX/Y/Z, eye/mouth/nose positions }
    |
    v
Action detection (per action):
    blink   -> _BlinkTracker.updateAndDetect() OR face.areEyesClosed()
    smile   -> face.isSmiling(threshold: 0.6)
    left    -> face.isHeadTurnedLeft/Right() (mirrored if sensor 270)
    right   -> face.isHeadTurnedRight/Left() (mirrored if sensor 270)
    up      -> face.isLookingUp/Down() (mirrored if sensor 270)
    down    -> face.isLookingDown/Up() (mirrored if sensor 270)
    |
    v
ActionDetail { action, passed, score, startedAt, completedAt, frameCount }
    |
    v
LivenessResult { isLive, score, sessionId, actions[], antiSpoofScore }
    |
    v
(Optional) SessionManager.signResults() -> SignedPayload with HMAC-SHA256
```

### Concurrency Model

The frame listener uses a `processing` boolean guard to prevent overlapping frame processing. Only one frame is analyzed at a time -- subsequent frames are dropped until the current frame completes. This ensures deterministic behavior and prevents race conditions in the confirmation counter.

---

## Component Breakdown

### Vivd Facade (`vivd.dart`, 307 lines)

The `Vivd` class is the single entry point. It wires all subsystems together during `initialize()` and exposes a simple API:

```dart
final vivd = Vivd(config: VivdConfig(
  actions: [VivdAction.blink, VivdAction.smile],
  hmacKey: 'your-secret-key',       // optional
  faceDetector: myCustomDetector,     // optional, defaults to ML Kit
));
await vivd.initialize();
final result = await vivd.startLiveness(frameStream: stream);
await vivd.dispose();
```

**VivdConfig** holds all tunables:

| Field | Default | Purpose |
|---|---|---|
| `actions` | `[blink, smile]` | Challenge sequence |
| `minConfirmationFrames` | `3` | Frames needed to confirm an action |
| `maxSessionDurationMs` | `60000` | Hard session timeout |
| `actionTimeoutMs` | `15000` | Per-action timeout |
| `actionPassThreshold` | `0.6` | Minimum score to pass |
| `enableAntiSpoof` | `false` | Enable texture analysis |
| `hmacKey` | `''` | HMAC signing key (empty = no signing) |
| `sessionDurationSeconds` | `300` | HMAC session validity window |
| `faceDetector` | `null` | Custom detector (null = ML Kit) |
| `sensorOrientation` | `270` | Front camera sensor orientation |

### Camera Layer

**CameraService** (`camera_service.dart`, 140 lines) -- Abstract interface for camera operations. Defines the contract: `initialize()`, `start()`, `pause()`, `resume()`, `stop()`, `dispose()`, and the `frameStream` getter.

**CameraServiceImpl** (`camera_service_impl.dart`, 306 lines) -- Concrete implementation wrapping the `camera` Flutter plugin. Handles:

- Front camera selection with fallback to first available camera
- ResolutionPreset.medium (balanced quality/performance)
- YUV420 image format group on Android, BGRA on iOS
- Stride-aware NV21/YUV420 conversion (strips row padding, interleaves V/U planes)
- Exposes `controller` for `VivdLivenessDetector` to build camera preview widgets
- Broadcast `StreamController<CameraFrame>` for frame distribution

**CameraFrame** model carries raw bytes, dimensions, format (NV21/BGRA/YUV420/RGB888), rotation, and timestamp.

**FrameProcessor** (`frame_processor.dart`, 166 lines) -- Normalizes frames for the detection layer. NV21 passes through directly. BGRA8888 converts to NV21 using BT.601 coefficients (Y = 0.299R + 0.587G + 0.114B). Also provides `cropCenter()` for reducing processing size.

**CameraValidator** (`camera_validator.dart`, 176 lines) -- Quality gate that rejects frames before expensive face detection:

- Brightness: samples Y channel every 16th pixel, rejects below 40 or above 240
- Blur: simplified Laplacian variance on downsampled Y channel, rejects below 50
- Face size: rejects if face bounding box is less than 20% of frame width
- Each issue penalizes the quality score by 0.2-0.3; frames below 0.4 are rejected

### Detection Layer

**FaceDetectorInterface** (`face_detector_interface.dart`, 164 lines) -- Abstract contract for pluggable face detectors:

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

**FaceDetection** model provides:
- Bounding box (`Rect`)
- Eye open probability (0.0 closed to 1.0 open) for left and right eye
- Smiling probability
- Head euler angles X (tilt), Y (turn), Z (roll) in degrees
- Landmark positions: eyes, nose base, bottom mouth
- Helper methods: `areEyesClosed()`, `isSmiling()`, `isHeadTurnedLeft/Right()`, `isLookingUp/Down()`

**MlKitFaceDetector** (`ml_kit_face_detector.dart`, 144 lines) -- Default implementation using `google_mlkit_face_detection`. Configurable options: classification mode, landmarks, contours, minimum face size, performance mode. Converts ML Kit `Face` objects to `FaceDetection` models, mapping `Point` landmarks to `Offset` values.

### Liveness Layer

**LivenessEngine** (`liveness_engine.dart`, 407 lines) -- Core orchestrator that runs a sequence of randomized liveness challenges.

**VivdAction** enum (`liveness_action.dart`, 54 lines) -- Six challenge types:

| Action | Label | Instruction | Est. Duration |
|---|---|---|---|
| `blink` | Blink | Close both eyes | 1000ms |
| `smile` | Smile | Show your teeth | 2000ms |
| `headTurnLeft` | Turn Left | Turn head to the left | 2500ms |
| `headTurnRight` | Turn Right | Turn head to the right | 2500ms |
| `lookUp` | Look Up | Raise your chin | 1500ms |
| `lookDown` | Look Down | Lower your chin | 1500ms |

Each action carries a `label`, `instruction`, and `emoji` for UI rendering, plus an `estimatedDurationMs` getter.

**LivenessResult** (`liveness_result.dart`, 121 lines) -- Session outcome:

- `isLive` (bool) -- overall pass/fail
- `score` (0.0-1.0) -- average score across all actions
- `sessionId` (String?) -- HMAC session identifier
- `actions` (List<ActionDetail>) -- per-action breakdown with timing
- `antiSpoofScore` (double?) -- anti-spoof confidence (null if disabled)
- `completedAt` (int) -- milliseconds since epoch

### Identity Layer

**FaceIdentity** (`face_identity.dart`, 215 lines) -- In-memory face registration and matching. Currently a stub using deterministic hash-based pseudo-embeddings (128 dimensions via seeded random). Planned Phase 2 upgrade to MobileFaceNet embeddings. Supports up to 20 faces with cosine similarity matching.

**FaceIdResult** (`face_id_result.dart`, 42 lines) -- Result with face ID (format `FID-XXXX`), confidence score, label, and match boolean.

### Security Layer

**SessionManager** (`session_manager.dart`, 205 lines) -- HMAC-SHA256 session signing for tamper-proof server verification. See [SECURITY.md](SECURITY.md) for full details.

### UI Layer

**VivdLivenessDetector** (`vivd_liveness_detector.dart`) -- Drop-in StatefulWidget that manages the full lifecycle: camera init, liveness session, result display. Provides builder callbacks for custom overlays, loading states, and error handling. Includes built-in UI: camera preview with vignette, animated face oval guide, step indicator, action prompt overlay, timeout progress bar, and result/retry screens.

**VivdLivenessDetectorActionExt** (`vivd_liveness_detector_action_ext.dart`, 17 lines) -- Extension mapping `VivdAction` to Material Icons.

---

## Pluggable Detection

The detection layer uses a strategy pattern. `FaceDetectorInterface` is the abstract contract; `VivdConfig.faceDetector` accepts any implementation.

### Current Default: ML Kit

```
CameraServiceImpl
    |
    v
FrameProcessor (NV21 passthrough / BGRA-to-NV21)
    |
    v
MlKitFaceDetector.detect()
    |  InputImage.fromBytes(bytes, metadata)
    |  FaceDetector.processImage(inputImage)
    v
FaceDetection model
```

ML Kit is chosen as the default because it runs on-device, has no network dependency, and provides classification (eye open, smiling) and head pose (euler angles) natively.

### Adding Alternative Detectors

To add a new detector (MediaPipe, InsightFace, Apple Vision), implement `FaceDetectorInterface`:

```dart
class MediaPipeFaceDetector implements FaceDetectorInterface {
  @override
  String get name => 'MediaPipe Face Detection';

  @override
  Future<void> initialize() async { /* load model */ }

  @override
  Future<List<FaceDetection>> detect(Uint8List bytes, {
    required int width,
    required int height,
    int rotation = 0,
    VivdImageFormat format = VivdImageFormat.nv21,
  }) async {
    // Run MediaPipe inference
    // Convert results to FaceDetection models
    return [FaceDetection(boundingBox: ..., ...)];
  }

  @override
  Future<void> dispose() async { /* release resources */ }
}
```

Then inject it via config:

```dart
final vivd = Vivd(config: VivdConfig(
  faceDetector: MediaPipeFaceDetector(),
));
```

The only contract requirement is that the returned `FaceDetection` objects populate the fields that `LivenessEngine._detectAction()` reads:
- `avgEyeOpen` -- for `blink` action
- `smiling` -- for `smile` action
- `headEulerAngleY` -- for `headTurnLeft` / `headTurnRight`
- `headEulerAngleX` -- for `lookUp` / `lookDown`

### Platform-Specific Detection Strategy

A factory approach can select the best detector per platform:

```dart
FaceDetectorInterface createPlatformDetector() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS => AppleVisionFaceDetector(),
    TargetPlatform.android => InsightFaceOnnxDetector(),
    _ => MlKitFaceDetector(),
  };
}
```

---

## Liveness Session Lifecycle

### From `runSession()` to Result

```
runSession(actions, frameStream)
    |
    +-- Record sessionStart timestamp
    +-- Shuffle actions (Fisher-Yates via Random.secure)
    |
    v
FOR EACH shuffled action:
    |
    +-- Check session timeout (maxSessionDurationMs)
    |       If expired: record failure, break
    |
    +-- Call _runAction(action, frameStream)
    |       |
    |       +-- Create _BlinkTracker (if action == blink)
    |       +-- Start listening to frameStream
    |       +-- Set hard timeout (actionTimeoutMs + 2000ms)
    |       |
    |       v  (for each frame)
    |       +-- Check per-action timeout
    |       +-- CameraValidator.validate(frame) -> reject if poor quality
    |       +-- FrameProcessor.process(frame)
    |       +-- FaceDetector.detect(processed.bytes)
    |       +-- If no face found: skip frame
    |       +-- Detect action:
    |       |       blink -> _BlinkTracker.updateAndDetect(face)
    |       |       others -> _detectAction(action, face)
    |       +-- If detected:
    |       |       confirmedFrames++
    |       |       Update bestScore
    |       |       If confirmedFrames >= minConfirmationFrames:
    |       |           Complete action as PASSED
    |       +-- On timeout:
    |               Complete action (PASSED if enough confirmed frames,
    |               FAILED otherwise)
    |
    v
Aggregate results:
    +-- overallScore = average of all action scores
    +-- isLive = (at least 1 passed) AND (overallScore > actionPassThreshold)
    |
    v
Return LivenessResult
```

### Timing Details

| Parameter | Default | Purpose |
|---|---|---|
| `maxSessionDurationMs` | 60,000ms | Total session window. If exceeded, remaining actions fail immediately. |
| `actionTimeoutMs` | 15,000ms | Per-action timeout. Frame stream subscription is cancelled. |
| Hard timeout | +2,000ms | Safety net: `Future.delayed` cancels subscription if action timeout doesn't fire. |
| `minConfirmationFrames` | 3 | Minimum consecutive detections before action passes. Prevents false positives. |
| Session shuffle | Fisher-Yates | `Random.secure()` ensures cryptographic randomness of action order. |

### Pass/Fail Logic

```
passed = count(actions where action.passed)
total = actions.length
overallScore = sum(action.scores) / total

isLive = (passed >= 1) AND (overallScore > actionPassThreshold)
```

This is intentionally lenient -- at least one action must pass and the average score must exceed the threshold. This handles cases where a single action times out (e.g., user misunderstands instruction) but still proves liveness through other actions.

### Euler Angle Mirroring

When `sensorOrientation == 270` (common for front camera in portrait mode), the frame is rotated 270 degrees before ML Kit analysis. This inverts the sign of both X and Y euler angles relative to ML Kit documentation conventions. `LivenessEngine._mirrorEulerAngles` detects this and swaps the detection logic:

```
sensorOrientation == 270:
  headTurnLeft  -> actually checks face.isHeadTurnedRight() 
  headTurnRight -> actually checks face.isHeadTurnedLeft()
  lookUp        -> actually checks face.isLookingDown()
  lookDown      -> actually checks face.isLookingUp()
```

Score calculations are similarly mirrored.

---

## BlinkTracker

### Problem

ML Kit's eye open probability (`leftEyeOpenProbability` / `rightEyeOpenProbability`) returns lower values for users wearing glasses. A fixed threshold (e.g., `avgEyeOpen < 0.3`) works for bare eyes but misses blinks through glasses because the baseline eye-open value is already depressed.

### Solution: Relative Drop Detection

`_BlinkTracker` uses two complementary methods:

**Method 1 -- Relative drop from baseline (glasses-friendly):**
1. During the first frames, build a running average of eye-open probability as a baseline
2. Only sample baseline when `eyeOpen > 0.5` to avoid building from already-closed eyes
3. Require minimum 3 samples (`_minBaselineSamples`) before detection activates
4. Cap baseline at 0.95 to handle noisy readings
5. Detect blink when the drop from baseline exceeds 35% of the baseline value

```
baseline = rolling average of eye-open during first frames
relativeDrop = baseline - currentEyeOpen
blink = relativeDrop >= (baseline * 0.35)
```

**Method 2 -- Absolute threshold (fallback):**
```
blink = eyeOpen < 0.3
```

The two methods are OR'd together: `detected = relativeDetected || absoluteDetected`. This means:
- Without glasses: absolute threshold catches it immediately
- With glasses: relative drop catches it even when absolute values stay above 0.3

### Key Parameters

| Parameter | Value | Purpose |
|---|---|---|
| `_minBaselineSamples` | 3 | Frames needed before detection starts |
| `_relativeDropThreshold` | 0.35 | 35% drop from baseline triggers blink |
| `_absoluteThreshold` | 0.3 | Fallback for no-glasses case |
| `_maxBaselineCap` | 0.95 | Caps baseline to handle noisy high readings |

---

## Anti-Spoof

### Current Status: Texture Analysis Stub (Phase 0-1)

`AntiSpoofEngine` (`anti_spoof_engine.dart`, 120 lines) implements basic presentation attack detection using texture variance analysis. It is a placeholder for a full ML-based PAD system.

**How it works:**
1. Compute a simplified Laplacian (horizontal + vertical gradient magnitude) on downsampled Y channel pixels (step=4)
2. Calculate variance of gradient values
3. Normalize to 0.0-1.0 score: `(variance / 1000.0).clamp(0.0, 1.0)`
4. Scores below 0.5 indicate potential spoof

**What it catches:** Low-texture screen replay attacks (uniform brightness, lack of skin micro-texture).

**What it does NOT catch:**
- Deepfake video replays with realistic texture
- High-resolution printed photos
- 3D mask attacks
- Any attack with texture variance similar to real skin

### Roadmap: ML-Based PAD (Phase 3)

The planned upgrade replaces the texture heuristic with an ONNX/TFLite model:

```dart
// Phase 3 (planned)
final _interpreter = await tflite.Interpreter.loadAsset('models/anti_spoof.tflite');
// Input: face crop tensor
// Output: [real_score, spoof_score]
```

This would provide proper presentation attack detection using a model trained on real vs. spoof datasets (print attacks, replay attacks, 3D masks).

### Integration

Anti-spoof is gated behind `VivdConfig.enableAntiSpoof`:

```dart
final vivd = Vivd(config: VivdConfig(
  enableAntiSpoof: true,
));
```

When enabled, the score appears in `LivenessResult.antiSpoofScore`. The engine does not automatically reject spoofs -- the application decides the threshold.

---

## Extension Points

Vivd is designed for extensibility at multiple levels:

### 1. Custom Face Detector

Implement `FaceDetectorInterface` and pass via `VivdConfig.faceDetector`. See [EXTENDING.md](EXTENDING.md) for a full MediaPipe example.

### 2. Custom Anti-Spoof Engine

The current `AntiSpoofEngine` is not behind an interface. To replace it, fork the package or wait for Phase 3 which will introduce an `AntiSpoofInterface`. The current implementation can be used as a reference for the expected input/output contract:
- Input: `CameraFrame` or `Uint8List` face crop
- Output: `double` score (0.0 = spoof, 1.0 = real)

### 3. Custom Actions

Add new `VivdAction` enum values and extend `_detectAction()` and `_calculateActionScore()` in `LivenessEngine`. See [EXTENDING.md](EXTENDING.md) for details.

### 4. Custom Camera Service

Implement `CameraService` to use a different camera plugin or a fixed image source. The abstract class defines the full lifecycle contract.

### 5. Server-Side Verification

Enable HMAC signing via `VivdConfig.hmacKey` and verify payloads server-side. See [EXTENDING.md](EXTENDING.md) for a verification server implementation.

### 6. UI Customization

`VivdLivenessDetector` provides builder callbacks:
- `overlayBuilder` -- fully custom action overlay
- `cameraPreviewBuilder` -- custom camera preview rendering
- `errorBuilder` -- custom error display
- `loadingWidget` -- custom loading state

Or build your own UI using `Vivd` directly with any camera source.

---

## Source File Map

| File | Lines | Responsibility |
|---|---|---|
| `vivd.dart` | 307 | Core facade, VivdConfig, wiring |
| `camera/camera_service.dart` | 140 | Abstract CameraService, CameraFrame, CameraError |
| `camera/camera_service_impl.dart` | 306 | Camera plugin wrapper, YUV/BGRA conversion |
| `camera/camera_validator.dart` | 176 | Frame quality validation |
| `camera/frame_processor.dart` | 166 | Format conversion, cropping |
| `detection/face_detector_interface.dart` | 164 | Abstract FaceDetectorInterface, FaceDetection model |
| `detection/ml_kit_face_detector.dart` | 144 | ML Kit implementation |
| `liveness/liveness_engine.dart` | 407 | Session orchestration, _BlinkTracker |
| `identity/face_identity.dart` | 215 | Face registration and matching (stub) |
| `ml/anti_spoof_engine.dart` | 120 | Texture analysis PAD (stub) |
| `models/liveness_action.dart` | 54 | VivdAction enum |
| `models/liveness_result.dart` | 121 | LivenessResult, ActionDetail |
| `models/face_id_result.dart` | 42 | FaceIdResult |
| `security/session_manager.dart` | 205 | HMAC-SHA256 signing |
| `ui/vivd_liveness_detector.dart` | 799 | Drop-in Flutter widget |
| `ui/vivd_liveness_detector_action_ext.dart` | 17 | Material icon mapping |
