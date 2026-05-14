/// Liveness engine — orchestrates blink, smile, head turn detection.
library;

import '../models/liveness_action.dart';
import '../models/liveness_result.dart';

class LivenessEngine {
  /// Run a liveness session with the given actions.
  Future<LivenessResult> runSession({
    required List<VivdAction> actions,
    Duration timeout = const Duration(seconds: 60),
  }) {
    throw UnimplementedError();
  }
}
