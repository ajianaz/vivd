/// Vivd — Open source Flutter face liveness SDK.
///
/// 100% on-device, offline, no API key needed.
/// Target niche: HR Attendance (Indonesia).
///
/// Quick start:
/// ```dart
/// import 'package:vivd/vivd.dart';
///
/// final vivd = Vivd();
/// await vivd.initialize();
///
/// final result = await vivd.startLiveness(
///   frameStream: camera.frameStream,
/// );
///
/// print('Live: ${result.isLive}, Score: ${result.score}');
/// await vivd.dispose();
/// ```
library vivd;

// Models
export 'src/models/liveness_action.dart';
export 'src/models/liveness_result.dart';
export 'src/models/face_id_result.dart';

// Camera
export 'src/camera/camera_service.dart';
export 'src/camera/camera_validator.dart';
export 'src/camera/frame_processor.dart';

// Detection
export 'src/detection/face_detector_interface.dart';
export 'src/detection/ml_kit_face_detector.dart';

// Liveness
export 'src/liveness/liveness_engine.dart';

// Identity
export 'src/identity/face_identity.dart';

// Security
export 'src/security/session_manager.dart';

// ML
export 'src/ml/anti_spoof_engine.dart';

// Core
export 'src/vivd.dart';

// Re-export image format from camera_service
export 'src/camera/camera_service.dart' show VivdImageFormat, CameraFrame, ProcessedFrame, CameraError, CameraException;
