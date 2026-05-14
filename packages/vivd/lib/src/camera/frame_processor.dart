import 'dart:typed_data';

import 'camera_service.dart';

/// Frame processor — converts camera frames to processable format.
///
/// Handles NV21 → RGB conversion and can run processing in isolates
/// to avoid jank on the main UI thread.
///
/// ```dart
/// final processor = FrameProcessor();
/// final processed = await processor.process(frame);
/// ```
class FrameProcessor {
  /// Whether to use an isolate for heavy processing.
  /// Default is `false` (main thread) — set to `true` for large frames.
  final bool useIsolate;

  FrameProcessor({this.useIsolate = false});

  /// Convert camera frame to processable format.
  ///
  /// For NV21: passes through unchanged.
  /// For BGRA: converts to NV21 for ML Kit compatibility.
  Future<ProcessedFrame> process(CameraFrame frame) async {
    if (frame.format == VivdImageFormat.nv21) {
      // Passthrough — ML Kit accepts NV21 directly
      return ProcessedFrame(
        bytes: frame.bytes,
        width: frame.width,
        height: frame.height,
        rotation: frame.rotation,
        format: VivdImageFormat.nv21,
      );
    }

    if (frame.format == VivdImageFormat.bgra8888) {
      return _bgraToNv21(frame);
    }

    // For other formats, return as-is
    return ProcessedFrame(
      bytes: frame.bytes,
      width: frame.width,
      height: frame.height,
      rotation: frame.rotation,
      format: frame.format,
    );
  }

  /// Convert BGRA8888 to NV21 (YUV420 semi-planar).
  ///
  /// NV21 layout: Y plane (width × height) followed by VU plane (width × height/2).
  ProcessedFrame _bgraToNv21(CameraFrame frame) {
    final width = frame.width;
    final height = frame.height;
    final src = frame.bytes;
    final ySize = width * height;
    final vuSize = width * (height ~/ 2);
    final dst = Uint8List(ySize + vuSize);

    for (var i = 0; i < ySize; i++) {
      final srcIdx = i * 4; // BGRA = 4 bytes per pixel
      final b = src[srcIdx] & 0xFF;
      final g = src[srcIdx + 1] & 0xFF;
      final r = src[srcIdx + 2] & 0xFF;
      // Y = 0.299R + 0.587G + 0.114B
      dst[i] = ((77 * r + 150 * g + 29 * b) >> 8).clamp(0, 255);
    }

    // Downsample to half resolution for chroma
    var vuIdx = 0;
    for (var y = 0; y < height; y += 2) {
      for (var x = 0; x < width; x += 2) {
        // Average 4 pixels for U and V
        final idx00 = y * width + x;
        final idx10 = y * width + (x + 1);
        final idx01 = (y + 1) * width + x;
        final idx11 = (y + 1) * width + (x + 1);

        int sumR = 0, sumG = 0, sumB = 0;
        for (final idx in [idx00, idx10, idx01, idx11]) {
          final srcIdx = idx * 4;
          sumB += src[srcIdx] & 0xFF;
          sumG += src[srcIdx + 1] & 0xFF;
          sumR += src[srcIdx + 2] & 0xFF;
        }

        final avgR = (sumR ~/ 4).clamp(0, 255);
        final avgG = (sumG ~/ 4).clamp(0, 255);
        final avgB = (sumB ~/ 4).clamp(0, 255);

        // U = -0.169R - 0.331G + 0.5B + 128
        dst[ySize + vuIdx] =
            ((-43 * avgR - 85 * avgG + 128 * avgB) >> 8 + 128).clamp(0, 255);
        // V = 0.5R - 0.419G - 0.081B + 128
        dst[ySize + vuIdx + 1] =
            ((128 * avgR - 107 * avgG - 21 * avgB) >> 8 + 128).clamp(0, 255);
        vuIdx += 2;
      }
    }

    return ProcessedFrame(
      bytes: dst,
      width: width,
      height: height,
      rotation: frame.rotation,
      format: VivdImageFormat.nv21,
    );
  }

  /// Crop center region of frame (useful for reducing processing size).
  ProcessedFrame cropCenter(CameraFrame frame, {double cropFactor = 0.5}) {
    final targetWidth = (frame.width * cropFactor).round();
    final targetHeight = (frame.height * cropFactor).round();
    final offsetX = ((frame.width - targetWidth) / 2).round();
    final offsetY = ((frame.height - targetHeight) / 2).round();

    if (frame.format == VivdImageFormat.nv21) {
      final yStride = frame.width;
      final cropped = Uint8List(targetWidth * targetHeight * 3 ~/ 2);

      // Crop Y plane
      for (var y = 0; y < targetHeight; y++) {
        final srcOffset = (y + offsetY) * yStride + offsetX;
        final dstOffset = y * targetWidth;
        cropped.setRange(
          dstOffset,
          dstOffset + targetWidth,
          frame.bytes.sublist(srcOffset, srcOffset + targetWidth),
        );
      }

      // Crop VU plane
      final vuOffset = frame.width * frame.height;
      final croppedVuOffset = targetWidth * targetHeight;
      final vuHeight = targetHeight ~/ 2;
      for (var y = 0; y < vuHeight; y++) {
        final srcOffset = vuOffset + ((y + offsetY ~/ 2) * frame.width) + (offsetX & ~1);
        final dstOffset = croppedVuOffset + y * targetWidth;
        cropped.setRange(
          dstOffset,
          dstOffset + targetWidth,
          frame.bytes.sublist(srcOffset, srcOffset + targetWidth),
        );
      }

      return ProcessedFrame(
        bytes: cropped,
        width: targetWidth,
        height: targetHeight,
        rotation: frame.rotation,
        format: VivdImageFormat.nv21,
      );
    }

    // Fallback for non-NV21
    return ProcessedFrame(
      bytes: frame.bytes,
      width: targetWidth,
      height: targetHeight,
      rotation: frame.rotation,
      format: frame.format,
    );
  }
}
