# Vivd — Advanced Example

Comprehensive example demonstrating all Vivd SDK features.

<p align="center">
  <img src="../../assets/demo_wm.gif" alt="Vivd advanced example demo" width="180" />
</p>

> ⚠️ **Demo is watermarked and overlaid with a privacy box for data protection.** Actual face is not shown.

## Setup

1. Ensure Flutter 3.29.0+ is installed
2. Navigate to this directory:
   ```bash
   cd examples/advanced
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run on a physical device (camera required):
   ```bash
   flutter run
   ```

## Screens

### 1. Home
Feature cards linking to each demo.

### 2. Liveness Detection
- Custom `VivdConfig` with action selection
- Adjustable confirmation frames and pass threshold
- Real-time action progress via `onProgress` callback
- Detailed result breakdown with per-action scores
- Session JSON export for server verification

### 3. Face Identity
- Register faces with labels
- Identify faces against registered store
- Face management (list, remove)

### 4. Settings
- `VivdConfig` parameter builder
- Live preview of generated config code
- Anti-spoof toggle

## Architecture

```
lib/
├── main.dart
└── screens/
    ├── home_screen.dart        ← Feature cards
    ├── liveness_screen.dart    ← Custom config + result
    ├── identity_screen.dart    ← Face registration + identification
    └── settings_screen.dart    ← Config builder
```
