/// Commitment self-assessment — a motivation/onboarding-sell step.
enum CommitmentLevel {
  extremely,
  very,
  needHelp;

  String get title {
    switch (this) {
      case CommitmentLevel.extremely:
        return 'Extremely Committed';
      case CommitmentLevel.very:
        return 'Very Committed';
      case CommitmentLevel.needHelp:
        return 'I Need Help Staying Consistent';
    }
  }

  String get subtitle {
    switch (this) {
      case CommitmentLevel.extremely:
        return "I'm ready to do what it takes";
      case CommitmentLevel.very:
        return 'I want a clear plan and accountability';
      case CommitmentLevel.needHelp:
        return 'Keep me locked in week after week';
    }
  }

  String get storageKey => name;

  static CommitmentLevel? fromStorageKey(String key) {
    for (final v in CommitmentLevel.values) {
      if (v.storageKey == key) return v;
    }
    return null;
  }
}
