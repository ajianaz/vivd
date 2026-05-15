<p align="center">
  <img src="https://img.shields.io/badge/vivd-v0.0.1-blue?style=flat-square" alt="version" />
  <img src="https://img.shields.io/badge/flutter-3.29+-02569B?logo=flutter&logoColor=white&style=flat-square" alt="Flutter" />
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey?style=flat-square" alt="Platform" />
  <img src="https://img.shields.io/badge/license-Apache%202.0-green?style=flat-square" alt="License" />
  <a href="https://github.com/ajianaz/vivd/actions"><img src="https://img.shields.io/github/actions/workflow/status/ajianaz/vivd/ci.yml?branch=develop&style=flat-square" alt="CI" /></a>
</p>

<h1 align="center">Vivd</h1>

<p align="center">
  <strong>Vivid + ID</strong> — The open source Flutter face liveness SDK that actually works.<br/>
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

// That's it.
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

## 📐 Architecture

```
vivd/
├── packages/
│   ├── vivd/                    ← Core SDK (Apache 2.0)
│   │   ├── lib/src/
│   │   │   ├── camera/          CameraService, FrameProcessor, CameraValidator
│   │   │   ├── detection/       FaceDetectorInterface + ML Kit impl
│   │   │   ├── liveness/        LivenessEngine (action orchestration)
│   │   │   ├── identity/        FaceIdentity (registration + matching)
│   │   │   ├── security/        SessionManager (HMAC-SHA256)
│   │   │   ├── ml/              AntiSpoofEngine (texture analysis)
│   │   │   ├── models/          VivdAction, LivenessResult, FaceIdResult
│   │   │   ├── ui/              VivdLivenessDetector widget
│   │   │   └── vivd.dart        Core Vivd facade
│   │   └── test/
│   └── vivd_pro/                ← Pro SDK (BSL 1.1, planned)
├── examples/
│   └── basic/                   ← Minimal integration example
├── web/                         ← Landing page (SvelteKit)
├── .github/workflows/ci.yml
├── melos.yaml
├── CHANGELOG.md
└── CONTRIBUTING.md
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

## 🧪 Example App

```bash
cd examples/basic
flutter pub get
flutter run  # Requires physical device (camera)
```

## 📋 Roadmap

- [x] Core SDK — models, camera, face detection, liveness engine
- [x] VivdLivenessDetector drop-in widget
- [x] Basic example app
- [x] Advanced example app (full config + face identity demo)
- [x] CI/CD — format, analyze, test, publish dry-run
- [ ] Integration tests (needs device/emulator)
- [ ] Landing page (vivd.ajianaz.dev)
- [ ] Publish to pub.dev
- [ ] Pro SDK — server-backed liveness, ML PAD, compliance

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## 📄 License

- **vivd** (Core SDK): [Apache 2.0](LICENSE)
- **vivd_pro** (Pro SDK): [BSL 1.1](packages/vivd_pro/LICENSE)

---

<p align="center">
  <sub>Built for HR attendance systems. Made with ❤️ in Indonesia.</sub><br/>
  <a href="https://vivd.ajianaz.dev">vivd.ajianaz.dev</a>
</p>
