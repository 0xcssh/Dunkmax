import 'dart:convert';

import 'court_position.dart';
import 'dunk_goal.dart';
import 'experience_level.dart';

/// Everything the onboarding quiz collects. Serialisable to a JSON string so
/// it can be dropped straight into shared_preferences.
class OnboardingProfile {
  final Set<DunkGoal> goals;
  final ExperienceLevel experience;
  final CourtPosition position;
  final int daysPerWeek;

  const OnboardingProfile({
    required this.goals,
    required this.experience,
    required this.position,
    required this.daysPerWeek,
  });

  OnboardingProfile copyWith({
    Set<DunkGoal>? goals,
    ExperienceLevel? experience,
    CourtPosition? position,
    int? daysPerWeek,
  }) {
    return OnboardingProfile(
      goals: goals ?? this.goals,
      experience: experience ?? this.experience,
      position: position ?? this.position,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    );
  }

  Map<String, dynamic> toMap() => {
        'goals': goals.map((g) => g.storageKey).toList(),
        'experience': experience.storageKey,
        'position': position.storageKey,
        'daysPerWeek': daysPerWeek,
      };

  String toJson() => jsonEncode(toMap());

  static OnboardingProfile? fromMap(Map<String, dynamic> map) {
    final experience =
        ExperienceLevel.fromStorageKey(map['experience'] as String? ?? '');
    final position =
        CourtPosition.fromStorageKey(map['position'] as String? ?? '');
    final daysPerWeek = map['daysPerWeek'];
    if (experience == null || position == null || daysPerWeek is! int) {
      return null;
    }
    final goals = <DunkGoal>{};
    for (final raw in (map['goals'] as List? ?? const [])) {
      final goal = DunkGoal.fromStorageKey(raw as String);
      if (goal != null) goals.add(goal);
    }
    return OnboardingProfile(
      goals: goals,
      experience: experience,
      position: position,
      daysPerWeek: daysPerWeek,
    );
  }

  static OnboardingProfile? fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}
