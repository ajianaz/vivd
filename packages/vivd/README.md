<p align="center">
  <img src="https://img.shields.io/badge/vivd-v0.0.1-blue?style=flat-square" alt="version" />
  <img src="https://img.shields.io/badge/flutter-3.29+-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-Apache%202.0-green?style=flat-square" alt="License" />
</p>

<h1 align="center">Vivd</h1>

<p align="center">
  <strong>Vivid + ID</strong> — Open source Flutter face liveness SDK.<br/>
  100% on-device, offline, no API key needed. Privacy-first face verification.
</p>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎯 **6 Liveness Actions** | Blink, smile, head turn left/right, look up/down |
| 📷 **Drop-in Widget** | `VivdLivenessDetector` — 3 lines to integrate |
| 🆔 **Face ID** | Face registration & identification (20 faces max) |
| 🔒 **Session Security** | HMAC-SHA256 signing, nonce replay protection |
| 📱 **Cross-Platform** | iOS (TrueDepth) and Android (front camera) |
| 📦 **Offline-First** | No server required, all processing on-device |
| 🛡️ **Anti-Spoof Stub** | Basic texture analysis (ML PAD planned for Pro) |
| 🔌 **Pluggable Detection** | `FaceDetectorInterface` — swap ML Kit, MediaPipe, etc. |

## 🚀 Quick Start

### 1. Add dependency

```yaml
# pubspec.yaml
dependencies:
  vivd: ^0.0.1
```

### 2. Drop-in widget

```dart
import 'package:vivd/vivd.dart';

VivdLivenessDetector(
  onResult: (result) {
    if (result.isLive) {
      print('Face verified! Score: ${(result.score * 100).toStringAsFixed(1)}%');
    }
  },
)
```

### 3. Advanced usage

```dart
import 'package:vivd/vivd.dart';

final vivd = Vivd(config: VivdConfig(
  actions: [VivdAction.blink, VivdAction.smile, VivdAction.headTurnLeft],
  enableAntiSpoof: true,
  hmacKey: 'your-server-key',
));

await vivd.initialize();

// Liveness check
final result = await vivd.startLiveness(
  frameStream: camera.frameStream,
  onProgress: (action, index, total) {
    print('Step ${index + 1}/$total: ${action.label}');
  },
);

print('Live: ${result.isLive}');
print('Score: ${result.score}');
print('Actions: ${result.passedActions}/${result.totalActions}');

// Face identity
final reg = await vivd.registerFace(faceBytes, label: 'employee_001');
final match = await vivd.identifyFace(faceBytes);
print('Match: ${match?.label} (${match?.score})');

await vivd.dispose();
```

## 🎮 Liveness Actions

| Action | Trigger | Est. Duration |
|--------|---------|---------------|
| 👁️ Blink | Both eyes close (< 0.3 openness) | 800ms |
| 😊 Smile | Smile probability > 0.7 | 1200ms |
| ⬅️ Head Turn Left | Euler Y < -20° | 1500ms |
| ➡️ Head Turn Right | Euler Y > 20° | 1500ms |
| ⬆️ Look Up | Euler X < -15° | 1000ms |
| ⬇️ Look Down | Euler X > 15° | 1000ms |

Actions are **shuffled randomly** each session (Fisher-Yates with `Random.secure`) to prevent replay attacks.

## 🔧 Configuration

```dart
VivdConfig(
  actions: [VivdAction.blink, VivdAction.smile],  // Default
  minConfirmationFrames: 3,       // Frames to confirm an action
  maxSessionDurationMs: 30000,    // Max total session time
  actionTimeoutMs: 10000,         // Timeout per action
  actionPassThreshold: 0.7,       // Min confidence to pass
  enableAntiSpoof: false,         // Enable texture analysis
  hmacKey: '',                    // Empty = no session signing
  sessionDurationSeconds: 300,    // HMAC session validity
  faceDetector: null,             // null = ML Kit default
)
```

## 📐 Architecture

```
lib/
├── src/
│   ├── camera/          CameraService, FrameProcessor, CameraValidator
│   ├── detection/       FaceDetectorInterface + ML Kit impl
│   ├── liveness/        LivenessEngine (action orchestration)
│   ├── identity/        FaceIdentity (registration + matching)
│   ├── security/        SessionManager (HMAC-SHA256)
│   ├── ml/              AntiSpoofEngine (texture analysis)
│   ├── models/          VivdAction, LivenessResult, FaceIdResult
│   ├── ui/              VivdLivenessDetector widget
│   └── vivd.dart        Core Vivd facade
└── vivd.dart            Package entry point
```

## 🧪 Run Example

```bash
cd example
flutter pub get
flutter run  # Requires physical device (camera)
```

## 📄 License

[Apache 2.0](LICENSE)

---

<p align="center">
  <sub>Built for HR attendance systems. Made with ❤️ in Indonesia.</sub>
</p>
