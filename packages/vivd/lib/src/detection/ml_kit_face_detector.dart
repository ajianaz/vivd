/// ML Kit face detector — default implementation using Google ML Kit.
library;

import 'face_detector_interface.dart';

class MlKitFaceDetector implements FaceDetectorInterface {
  @override
  String get name => 'Google ML Kit';

  @override
  Future<List<FaceDetection>> detect(CameraFrame frame) {
    throw UnimplementedError('ML Kit detection not yet implemented');
  }

  @override
  void dispose() {}
}
