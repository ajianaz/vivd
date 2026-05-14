/// Face liveness action types.
enum VivdAction {
  /// Close both eyes for 0.5+ seconds.
  blink('Blink'),

  /// Show teeth / smile clearly.
  smile('Smile'),

  /// Turn head to the left (ear visible).
  headTurnLeft('Head Turn Left'),

  /// Turn head to the right (ear visible).
  headTurnRight('Head Turn Right');

  const VivdAction(this.label);
  final String label;

  /// All available actions.
  static List<VivdAction> get all => VivdAction.values;

  /// Default set for free tier (4 actions).
  static List<VivdAction> get defaults => VivdAction.values;
}
