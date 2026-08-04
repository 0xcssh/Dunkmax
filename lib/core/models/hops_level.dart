/// Self-reported current jumping ability ("Where are your hops today?").
/// Ordered best → building-up, matching the onboarding ladder.
enum HopsLevel {
  dunkConsistently,
  dunkOnGoodDay,
  grabRim,
  touchRim,
  belowRim;

  String get title {
    switch (this) {
      case HopsLevel.dunkConsistently:
        return 'Dunk consistently';
      case HopsLevel.dunkOnGoodDay:
        return 'Dunk on a good day';
      case HopsLevel.grabRim:
        return 'Grab the rim';
      case HopsLevel.touchRim:
        return 'Touch the rim';
      case HopsLevel.belowRim:
        return 'Below the rim';
    }
  }

  String get subtitle {
    switch (this) {
      case HopsLevel.dunkConsistently:
        return 'Chasing bigger finishes';
      case HopsLevel.dunkOnGoodDay:
        return "It's in you — not consistent yet";
      case HopsLevel.grabRim:
        return 'Palming iron on a good day';
      case HopsLevel.touchRim:
        return 'Fingertips on iron';
      case HopsLevel.belowRim:
        return 'Building from the ground up';
    }
  }

  String get storageKey => name;

  static HopsLevel? fromStorageKey(String key) {
    for (final v in HopsLevel.values) {
      if (v.storageKey == key) return v;
    }
    return null;
  }
}
