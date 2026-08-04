/// Basketball position, used to tailor exercise selection copy.
enum CourtPosition {
  pointGuard,
  shootingGuard,
  smallForward,
  powerForward,
  center;

  /// 1-based number shown in the onboarding list (Point Guard = 1 … Center = 5).
  int get number => index + 1;

  String get label {
    switch (this) {
      case CourtPosition.pointGuard:
        return 'Point Guard';
      case CourtPosition.shootingGuard:
        return 'Shooting Guard';
      case CourtPosition.smallForward:
        return 'Small Forward';
      case CourtPosition.powerForward:
        return 'Power Forward';
      case CourtPosition.center:
        return 'Center';
    }
  }

  String get storageKey => name;

  static CourtPosition? fromStorageKey(String key) {
    for (final position in CourtPosition.values) {
      if (position.storageKey == key) return position;
    }
    return null;
  }
}
