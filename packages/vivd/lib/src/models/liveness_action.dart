/// Face liveness action types.
///
/// Each action challenges the user to perform a specific gesture
/// to prove they are a live person (not a photo/video replay).
enum VivdAction {
  /// Close both eyes briefly.
  blink('Blink', 'Close both eyes', '👁️'),

  /// Show teeth / smile clearly.
  smile('Smile', 'Show your teeth', '😊'),

  /// Turn head to the left (ear visible).
  headTurnLeft('Turn Left', 'Turn head to the left', '👈'),

  /// Turn head to the right (ear visible).
  headTurnRight('Turn Right', 'Turn head to the right', '👉'),

  /// Look up (chin up).
  lookUp('Look Up', 'Raise your chin', '⬆️'),

  /// Look down (chin down).
  lookDown('Look Down', 'Lower your chin', '⬇️');

  const VivdAction(
    this.label,
    this.instruction,
    this.emoji,
  );

  /// Short human-readable label for UI prompts.
  final String label;

  /// Detailed instruction shown to the user.
  final String instruction;

  /// Emoji representation.
  final String emoji;

  /// Estimated completion time in milliseconds.
  int get estimatedDurationMs {
    switch (this) {
      case VivdAction.blink:
        return 1000;
      case VivdAction.smile:
        return 2000;
      case VivdAction.headTurnLeft:
      case VivdAction.headTurnRight:
        return 2500;
      case VivdAction.lookUp:
      case VivdAction.lookDown:
        return 1500;
    }
  }
}
