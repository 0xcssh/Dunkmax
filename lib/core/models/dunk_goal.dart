/// The dunk ambitions a user can select during onboarding (multi-select).
///
/// Pure data — no Flutter imports — so it stays trivially unit-testable.
/// Icon/colour choices live in the UI layer, keyed off these cases.
enum DunkGoal {
  firstDunk,
  dunkInGames,
  windmillsAnd360s,
  alleyOopFinishing,
  maxVertical;

  String get title {
    switch (this) {
      case DunkGoal.firstDunk:
        return 'First Dunk Ever';
      case DunkGoal.dunkInGames:
        return 'Dunk in Games';
      case DunkGoal.windmillsAnd360s:
        return 'Windmills & 360s';
      case DunkGoal.alleyOopFinishing:
        return 'Alley-Oop Finishing';
      case DunkGoal.maxVertical:
        return 'Max Vertical';
    }
  }

  String get subtitle {
    switch (this) {
      case DunkGoal.firstDunk:
        return 'Unlock your first slam';
      case DunkGoal.dunkInGames:
        return 'Finish when it counts';
      case DunkGoal.windmillsAnd360s:
        return 'Style and flair';
      case DunkGoal.alleyOopFinishing:
        return 'Catch and finish';
      case DunkGoal.maxVertical:
        return 'Add inches to your leap';
    }
  }

  /// Stable key for persistence (never localise this).
  String get storageKey => name;

  static DunkGoal? fromStorageKey(String key) {
    for (final goal in DunkGoal.values) {
      if (goal.storageKey == key) return goal;
    }
    return null;
  }
}
