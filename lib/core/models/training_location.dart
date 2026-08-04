/// Where the athlete trains — drives which program variant we recommend.
enum TrainingLocation {
  home,
  gym,
  both;

  String get title {
    switch (this) {
      case TrainingLocation.home:
        return 'Home Only';
      case TrainingLocation.gym:
        return 'Gym Only';
      case TrainingLocation.both:
        return 'Both';
    }
  }

  String get subtitle {
    switch (this) {
      case TrainingLocation.home:
        return 'Bodyweight & minimal equipment';
      case TrainingLocation.gym:
        return 'Full access to weights & machines';
      case TrainingLocation.both:
        return 'Train anywhere, anytime';
    }
  }

  String get storageKey => name;

  static TrainingLocation? fromStorageKey(String key) {
    for (final v in TrainingLocation.values) {
      if (v.storageKey == key) return v;
    }
    return null;
  }
}
