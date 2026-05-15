# CHANGELOG

All notable changes to the Vivd project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1] - 2025-05-14

### Added
- **Core SDK** (`packages/vivd/`) — face liveness detection engine
  - 6 liveness actions (blink, smile, head turn, look up/down), Fisher-Yates shuffled
  - `CameraService` abstraction + `CameraServiceImpl` (camera plugin)
  - `FaceDetectorInterface` (pluggable) + ML Kit implementation
  - `VivdLivenessDetector` drop-in widget — camera preview, action prompts, result view
  - `Vivd` facade class — single API for liveness + face identity
  - `FaceIdentity` — face registration & identification (20 faces max)
  - `SessionManager` — HMAC-SHA256 session signing, nonce replay protection
  - `AntiSpoofEngine` — texture analysis stub
  - Full `VivdConfig` — actions, thresholds, timeouts, anti-spoof, HMAC
- **31 unit tests** — models, config, session, camera, detection
- **Basic example** (`examples/basic/`) — minimal 3-line integration
- **Advanced example** (`examples/advanced/`) — 4 screens, full config builder, face identity demo
- **Landing page** (`web/`) — SvelteKit + Cloudflare Pages (deploy pending)
- **Monorepo setup** — Melos + `vivd_pro` scaffold
- **CI/CD** — GitHub Actions (format, analyze, test, publish dry-run)
- **Documentation** — README, CHANGELOG, CONTRIBUTING, LICENSE (Apache 2.0)
