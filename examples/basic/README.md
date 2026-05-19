# Vivd — Basic Example

Minimal integration example for the Vivd face liveness SDK.

<p align="center">
  <img src="../../assets/demo_wm.gif" alt="Vivd basic example demo" width="180" />
</p>

> ⚠️ **Demo is watermarked and overlaid with a privacy box for data protection.** Actual face is not shown.

## Setup

1. Ensure Flutter 3.29.0+ is installed
2. Navigate to this directory:
   ```bash
   cd examples/basic
   ```
3. Get dependencies:
   ```bash
   flutter pub get
   ```
4. Run on a physical device (camera required):
   ```bash
   flutter run
   ```

## What This Demonstrates

- Drop-in `VivdLivenessDetector` widget
- Default config (blink + smile)
- Automatic camera initialization
- Real-time action progress
- Result display with score

## Code

```dart
// That's it — 3 lines of actual integration code:
VivdLivenessDetector(
  onResult: (result) {
    print('Live: ${result.isLive}');
  },
)
```
