/// Camera service — handles front camera init, frame streaming, and lifecycle.
library;

abstract class CameraService {
  /// Initialize front camera.
  Future<void> initialize();

  /// Stream of camera frames (YUV/BGRA).
  Stream<CameraFrame> get frameStream;

  /// Start camera preview.
  Future<void> start();

  /// Stop camera and release resources.
  Future<void> stop();

  /// Dispose all resources.
  void dispose();
}

class CameraFrame {
  final int width;
  final int height;
  final Uint8List bytes;
  final DateTime timestamp;

  const CameraFrame({
    required this.width,
    required this.height,
    required this.bytes,
    required this.timestamp,
  });
}
