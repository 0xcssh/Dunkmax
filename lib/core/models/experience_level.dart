/// Self-reported jump-training experience, gathered during onboarding.
/// Drives which program the catalog recommends.
enum ExperienceLevel {
  beginner,
  intermediate,
  advanced;

  String get title {
    switch (this) {
      case ExperienceLevel.beginner:
        return 'Beginner';
      case ExperienceLevel.intermediate:
        return 'Intermediate';
      case ExperienceLevel.advanced:
        return 'Advanced';
    }
  }

  String get subtitle {
    switch (this) {
      case ExperienceLevel.beginner:
        return "I've got hops but no plan";
      case ExperienceLevel.intermediate:
        return "I've trained, ready to level up";
      case ExperienceLevel.advanced:
        return "I'm chasing inches";
    }
  }

  String get storageKey => name;

  static ExperienceLevel? fromStorageKey(String key) {
    for (final level in ExperienceLevel.values) {
      if (level.storageKey == key) return level;
    }
    return null;
  }
}
