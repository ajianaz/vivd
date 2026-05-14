# Contributing to Vivd

Thank you for your interest in contributing! This guide will help you get started.

## 🚀 Quick Start

### Prerequisites

- **Flutter 3.29+** ([install](https://docs.flutter.dev/get-started/install))
- **Dart 3.6+** (included with Flutter)
- **Melos** (monorepo management)
- **Android Studio / Xcode** (for platform-specific code)
- A physical device or emulator with a camera

### Setup

```bash
# Clone the repository
git clone https://github.com/ajianaz/vivd.git
cd vivd

# Install Melos
dart pub global activate melos

# Bootstrap all packages (runs pub get in each)
melos bootstrap

# Run all tests
melos run test

# Run analyzer on all packages
melos run analyze
```

## 📁 Project Structure

```
vivd/
├── packages/
│   ├── vivd/                  ← Core SDK (Apache 2.0)
│   │   ├── lib/src/
│   │   │   ├── camera/        Camera abstraction + implementation
│   │   │   ├── detection/     Face detector interface + ML Kit
│   │   │   ├── liveness/      Liveness engine (action orchestration)
│   │   │   ├── identity/      Face registration & identification
│   │   │   ├── security/      Session manager (HMAC-SHA256)
│   │   │   ├── ml/            Anti-spoof engine
│   │   │   ├── models/        Data models (VivdAction, LivenessResult, etc.)
│   │   │   ├── ui/            VivdLivenessDetector widget
│   │   │   └── vivd.dart      Core facade
│   │   └── test/              Unit tests (31 tests)
│   └── vivd_pro/              ← Pro SDK (BSL 1.1, planned)
├── examples/
│   ├── basic/                 ← Minimal integration example
│   └── advanced/              ← Full-featured demo (4 screens)
├── web/                       ← Landing page (SvelteKit)
├── .github/workflows/         ← CI/CD
├── melos.yaml                 ← Monorepo config
└── README.md
```

## 🔀 Branch Convention

| Branch | Purpose |
|--------|---------|
| `develop` | Default branch. All PRs merge here. |
| `main` | Release branch. Only for tagged releases. |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `docs/*` | Documentation changes |
| `chore/*` | CI, tooling, dependencies |

**Always create feature branches from `develop`. PRs target `develop`.**

## 📝 Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(vivd): add face registration API
fix(camera): handle permission denied gracefully
docs(readme): update quick start guide
test(liveness): add action timeout tests
refactor(detection): extract face crop utility
chore(ci): add format check workflow
```

## ✅ Pull Request Checklist

Before submitting a PR, ensure:

- [ ] `dart format .` passes (auto-format with `dart fix --apply`)
- [ ] `dart analyze --fatal-infos` passes (zero warnings)
- [ ] `flutter test` passes (all tests green)
- [ ] New public APIs have documentation comments (`///`)
- [ ] Tests cover new functionality
- [ ] No hardcoded secrets or credentials
- [ ] PR description explains **what** changed and **why**

### CI Pipeline

Every PR runs these checks automatically:

| Step | Command | Requirement |
|------|---------|-------------|
| Format | `dart format --set-exit-if-changed` | No unformatted files |
| Analyze | `dart analyze --fatal-infos` | Zero issues |
| Test | `flutter test --coverage` | All pass |
| Publish dry-run | `dart pub publish --dry-run` | No warnings (develop only) |

## 🧪 Testing

```bash
# Run all tests
cd packages/vivd && flutter test

# Run with coverage
cd packages/vivd && flutter test --coverage

# Run specific test file
cd packages/vivd && flutter test test/vivd_test.dart

# Run specific test group
cd packages/vivd && flutter test --plain-name "VivdAction"
```

## 🐛 Reporting Issues

Use [GitHub Issues](https://github.com/ajianaz/vivd/issues) with:

- **Flutter version** (`flutter --version`)
- **Device/simulator** details
- **Minimal reproducible code**
- **Expected** vs **actual** behavior
- **Logs** (if applicable)

## 💡 Architecture Notes

- **Offline-first**: All processing happens on-device. No server required.
- **Pluggable detection**: Implement `FaceDetectorInterface` to swap ML Kit, MediaPipe, etc.
- **Security**: Use `VivdConfig.hmacKey` for session signing. All actions are shuffled per session.
- **Widget-first**: `VivdLivenessDetector` provides a full UI. Use `Vivd` class directly for headless integration.

## 📄 Code of Conduct

Be respectful, constructive, and inclusive. We're building this for the Indonesian HR tech community. 🇮🇩

---

**Questions?** Open a [Discussion](https://github.com/ajianaz/vivd/discussions) or ping us on [Discord](https://discord.gg/).
