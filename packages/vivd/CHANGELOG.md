# CHANGELOG

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2025-05-14

### Added
- Core SDK structure — models, camera, detection, liveness, identity, security, ML
- **6 liveness actions**: blink, smile, head turn left/right, look up/down (Fisher-Yates shuffled)
- **CameraService** — abstract camera service with frame streaming
- **CameraServiceImpl** — concrete implementation using `camera` plugin (front camera default)
- **FaceDetectorInterface** — pluggable face detector (ML Kit default)
- **MlKitFaceDetector** — ML Kit face detection implementation
- **LivenessEngine** — action orchestration with configurable thresholds and timeouts
- **VivdLivenessDetector** — drop-in widget with camera preview, action prompts, error/result views
- **FaceIdentity** — face registration & identification (up to 20 faces)
- **SessionManager** — HMAC-SHA256 session signing with nonce replay protection
- **AntiSpoofEngine** — texture analysis stub (ML PAD planned for Pro)
- **CameraValidator** — frame quality validation
- **FrameProcessor** — camera frame format conversion
- **Vivd** facade class — single API for liveness + identity
- **VivdConfig** — full configuration (actions, thresholds, timeouts, anti-spoof, HMAC)
- 31 unit tests covering models, config, session, camera, detection
- Basic example app (`examples/basic/`)
- Advanced example app (`examples/advanced/`) — 4 screens, full config builder, face identity demo
- Melos monorepo setup
- GitHub Actions CI (analyze, test, format check)
