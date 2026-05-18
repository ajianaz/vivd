import 'package:flutter/material.dart';

import '../models/liveness_action.dart';

/// Extension to provide Material Icons for VivdAction without
/// importing Flutter in the model layer.
extension VivdActionIcon on VivdAction {
  /// Material Icon for the action.
  IconData get icon => switch (this) {
    VivdAction.blink => Icons.remove_red_eye,
    VivdAction.smile => Icons.sentiment_satisfied_alt,
    VivdAction.headTurnLeft => Icons.rotate_left,
    VivdAction.headTurnRight => Icons.rotate_right,
    VivdAction.lookUp => Icons.arrow_upward,
    VivdAction.lookDown => Icons.arrow_downward,
  };
}
