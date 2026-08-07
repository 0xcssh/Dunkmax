import 'dart:convert';

import 'commitment_level.dart';
import 'court_position.dart';
import 'dunk_goal.dart';
import 'experience_level.dart';
import 'hops_level.dart';
import 'training_location.dart';

/// Everything the onboarding quiz collects. Serialisable to a JSON string so
/// it can be dropped straight into shared_preferences.
///
/// The four "core" answers are required; the vitals + newer questions carry
/// sensible defaults so older persisted payloads (and tests) keep decoding.
class OnboardingProfile {
  final Set<DunkGoal> goals;
  final ExperienceLevel experience;
  final CourtPosition position;
  final int daysPerWeek;

  final TrainingLocation trainingLocation;
  final HopsLevel hopsLevel;
  final int heightInches;
  final int weightLbs;
  final int ageYears;
  final CommitmentLevel commitment;

  /// Fingertip height with one arm overhead, flat-footed, in inches — the
  /// athlete's own measurement. Null when they haven't measured it, in which
  /// case VertAssessment falls back to estimating it from their height. That
  /// estimate is a population average and can be several inches out, which is
  /// enough to move "inches to dunk" from believable to nonsense, so anything
  /// showing a dunk gap should say which one it used.
  final int? standingReachInches;

  const OnboardingProfile({
    required this.goals,
    required this.experience,
    required this.position,
    required this.daysPerWeek,
    this.trainingLocation = TrainingLocation.both,
    this.hopsLevel = HopsLevel.touchRim,
    this.heightInches = 70,
    this.weightLbs = 175,
    this.ageYears = 25,
    this.commitment = CommitmentLevel.very,
    this.standingReachInches,
  });

  OnboardingProfile copyWith({
    Set<DunkGoal>? goals,
    ExperienceLevel? experience,
    CourtPosition? position,
    int? daysPerWeek,
    TrainingLocation? trainingLocation,
    HopsLevel? hopsLevel,
    int? heightInches,
    int? weightLbs,
    int? ageYears,
    int? standingReachInches,
    CommitmentLevel? commitment,
  }) {
    return OnboardingProfile(
      goals: goals ?? this.goals,
      experience: experience ?? this.experience,
      position: position ?? this.position,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      trainingLocation: trainingLocation ?? this.trainingLocation,
      hopsLevel: hopsLevel ?? this.hopsLevel,
      heightInches: heightInches ?? this.heightInches,
      weightLbs: weightLbs ?? this.weightLbs,
      ageYears: ageYears ?? this.ageYears,
      commitment: commitment ?? this.commitment,
      standingReachInches: standingReachInches ?? this.standingReachInches,
    );
  }

  Map<String, dynamic> toMap() => {
        'goals': goals.map((g) => g.storageKey).toList(),
        'experience': experience.storageKey,
        'position': position.storageKey,
        'daysPerWeek': daysPerWeek,
        'trainingLocation': trainingLocation.storageKey,
        'hopsLevel': hopsLevel.storageKey,
        'heightInches': heightInches,
        'weightLbs': weightLbs,
        'ageYears': ageYears,
        'commitment': commitment.storageKey,
        if (standingReachInches != null)
          'standingReachInches': standingReachInches,
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
      trainingLocation: TrainingLocation.fromStorageKey(
              map['trainingLocation'] as String? ?? '') ??
          TrainingLocation.both,
      hopsLevel: HopsLevel.fromStorageKey(map['hopsLevel'] as String? ?? '') ??
          HopsLevel.touchRim,
      heightInches: map['heightInches'] is int ? map['heightInches'] as int : 70,
      weightLbs: map['weightLbs'] is int ? map['weightLbs'] as int : 175,
      ageYears: map['ageYears'] is int ? map['ageYears'] as int : 25,
      commitment:
          CommitmentLevel.fromStorageKey(map['commitment'] as String? ?? '') ??
              CommitmentLevel.very,
      standingReachInches: map['standingReachInches'] is int
          ? map['standingReachInches'] as int
          : null,
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
