/// Face liveness action types.
///
/// Each action challenges the user to perform a specific gesture
/// to prove they are a live person (not a photo/video replay).
enum VivdAction {
  /// Close both eyes for 0.5+ seconds.
  blink('Blink'),

  /// Show teeth / smile clearly.
  smile('Smile'),

  /// Turn head to the left (ear visible).
  headTurnLeft('Head Turn Left'),

  /// Turn head to the right (ear visible).
  headTurnRight('Head Turn Right'),

  /// Look up (chin up).
  lookUp('Look Up'),

  /// Look down (chin down).
  lookDown('Look Down');

  const VivdAction(this.label);

  /// Human-readable label for UI prompts.
  final String label;

  /// Estimated completion time in milliseconds.
  int get estimatedDurationMs {
    switch (this) {
      case VivdAction.blink:
        return 800;
      case VivdAction.smile:
        return 1200;
      case VivdAction.headTurnLeft:
      case VivdAction.headTurnRight:
        return 1500;
      case VivdAction.lookUp:
      case VivdAction.lookDown:
        return 1000;
    }
  }
}
