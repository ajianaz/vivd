/// Frame processor — YUV/BGRA conversion, isolate-based processing.
library;

class FrameProcessor {
  /// Convert camera frame to processable format.
  Future<ProcessedFrame> process(CameraFrame frame) {
    throw UnimplementedError();
  }
}

class ProcessedFrame {
  final int width;
  final int height;
  final List<double>? normalizedPixels;

  const ProcessedFrame({required this.width, required this.height, this.normalizedPixels});
}
