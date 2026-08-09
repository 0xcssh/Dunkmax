/// Which hand — or hands — the athlete dunks with.
///
/// This exists because it changes the target, not because it makes the quiz
/// look thorough. The reference app asks the same question and says it feeds
/// an "approach angle analysis"; nothing here analyses approach angle, and
/// adding a twelfth decorative question right after auditing the flow for
/// exactly that would be indefensible.
///
/// What it genuinely changes is how far above the rim the athlete has to get.
/// A one-hand dunk needs the ball and one hand over the ring. A two-hand dunk
/// needs both forearms above it, which is several inches more — so the same
/// athlete has a different vertical target depending on how they intend to
/// finish. See `VertAssessment.dunkClearanceFor`.
///
/// Pure data, no Flutter imports.
enum DunkHand {
  left,
  right,
  both;

  String get title {
    switch (this) {
      case DunkHand.left:
        return 'Left Hand';
      case DunkHand.right:
        return 'Right Hand';
      case DunkHand.both:
        return 'Both Hands';
    }
  }

  String get subtitle {
    switch (this) {
      case DunkHand.left:
      case DunkHand.right:
        return 'One-hand finish';
      case DunkHand.both:
        return 'Needs more room over the rim';
    }
  }

  /// True when the finish puts both forearms over the ring.
  bool get isTwoHanded => this == DunkHand.both;

  /// Stable key for persistence (never localise this).
  String get storageKey => name;

  static DunkHand? fromStorageKey(String key) {
    for (final hand in DunkHand.values) {
      if (hand.storageKey == key) return hand;
    }
    return null;
  }
}
