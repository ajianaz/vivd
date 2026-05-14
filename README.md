# Vivd

> **Vivd** (Vivid + ID) — The open source Flutter face liveness SDK that actually works.

100% on-device, offline, no API key needed. Privacy-first face verification for Flutter apps.

## Features

- 🎯 **4 Liveness Actions** — Blink, smile, head turn left, head turn right
- 🆔 **Face ID** — MobileFaceNet-based face recognition (20 faces max)
- 🔒 **Session Security** — HMAC-SHA256 frame signing, nonce replay protection
- 📱 **Cross-Platform** — iOS (TrueDepth) and Android (front camera)
- 📦 **Zero Dependencies** — Works offline, no server required
- 🛡️ **ML Kit Ready** — FaceDetectorInterface abstraction for pluggable face detection

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  vivd: ^0.1.0
```

```dart
import 'package:vivd/vivd.dart';

// Basic usage
final result = await Vivd.startLiveness(
  actions: [VivdAction.blink, VivdAction.smile],
);

if (result.isLive) {
  print('Face verified! Score: ${result.score}');
}
```

## Pro Features (vivd_pro)

Server-backed liveness with ML PAD, compliance features, and face management:

```yaml
dependencies:
  vivd_pro: ^0.1.0  # depends on vivd
```

```dart
import 'package:vivd_pro/vivd_pro.dart';

final result = await VivdPro.startLiveness(
  apiKey: 'your-api-key',
  actions: VivdAction.all,
  enablePAD: true,
  faceId: 'user-123',
);

// Server-verified result with JWT
print('Session ID: ${result.sessionId}');
print('JWT: ${result.jwt}');
```

## Repository Structure

This is a **Melos-managed Flutter monorepo**:

```
vivd/
├── packages/
│   ├── vivd/              ← Core SDK (Apache 2.0)
│   │   └── pubspec.yaml   → pub.dev: vivd
│   └── vivd_pro/          ← Pro SDK (BSL 1.1)
│       └── pubspec.yaml   → pub.dev: vivd_pro
├── melos.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
└── CONTRIBUTING.md
```

## License

- **vivd** (Core SDK): [Apache 2.0](LICENSE)
- **vivd_pro** (Pro SDK): [BSL 1.1](packages/vivd_pro/LICENSE)

---

**Landing & Docs:** [vivd.ajianaz.dev](https://vivd.ajianaz.dev)
