import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

/// Represents a raw camera frame.
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    this.format = InputImageFormat.nv21,
    this.rotation = 0,
    this.timestamp,
  });

  /// Raw image bytes.
  final Uint8List bytes;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Input format.
  final InputImageFormat format;

  /// Clockwise rotation in degrees (0, 90, 180, 270).
  final int rotation;

  /// Capture timestamp (milliseconds since epoch).
  final int? timestamp;

  /// Frame size in bytes.
  int get sizeInBytes => bytes.length;
}

/// Processed frame ready for face detection.
class ProcessedFrame {
  const ProcessedFrame({
    required this.bytes,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.format = InputImageFormat.nv21,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final int rotation;
  final InputImageFormat format;
}

/// Camera service — handles front camera init, frame streaming, and lifecycle.
///
/// This is an abstract class. The real implementation uses the `camera` plugin
/// internally and is provided via [CameraServiceImpl].
///
/// ```dart
/// final camera = CameraServiceImpl();
/// await camera.initialize();
/// camera.frameStream.listen((frame) {
///   // Process frame
/// });
/// ```
abstract class CameraService {
  /// Initialize front camera.
  Future<void> initialize();

  /// Stream of camera frames (YUV/BGRA).
  Stream<CameraFrame> get frameStream;

  /// Current resolution width.
  int get resolutionWidth;

  /// Current resolution height.
  int get resolutionHeight;

  /// Whether the camera is currently active.
  bool get isRunning;

  /// Pause frame streaming without releasing the camera.
  Future<void> pause();

  /// Resume frame streaming.
  Future<void> resume();

  /// Stop streaming and release camera resources.
  Future<void> stop();

  /// Dispose all resources.
  Future<void> dispose();
}

/// Camera error types.
enum CameraError {
  /// No camera available on the device.
  noCamera,

  /// User denied camera permission.
  permissionDenied,

  /// Camera is already in use by another app.
  cameraInUse,

  /// Unknown camera error.
  unknown,
}

/// Exception thrown when camera operations fail.
class CameraException implements Exception {
  const CameraException(this.error, [this.message]);

  final CameraError error;
  final String? message;

  @override
  String toString() =>
      'CameraException: $error${message != null ? ' — $message' : ''}';
}
