# CHANGELOG

All notable changes to the Vivd SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - TBD

### Added
- Initial project skeleton (Melos monorepo)
- `vivd` package — Core SDK structure
  - Camera service abstraction
  - FaceDetectorInterface (ML Kit default)
  - Liveness engine stub
  - Face identity (MobileFaceNet) stub
  - Session security (HMAC-SHA256)
  - 4 liveness actions: blink, smile, head turn left/right
  - Face ID registration and identification
- `vivd_pro` package — Pro SDK structure
  - Server communication stub
  - ML PAD integration point
  - Encrypted face keystore
  - API key authentication

### Not Yet Implemented
- Actual camera capture and frame processing
- ML Kit face detection integration
- Liveness detection algorithms
- ONNX model inference
- Server API client
- Pro-specific actions (mouth open, head shake)
