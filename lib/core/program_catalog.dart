import 'models/exercise.dart';
import 'models/experience_level.dart';
import 'models/onboarding_profile.dart';
import 'models/training_program.dart';

/// Maps an onboarding profile onto a concrete training program.
///
/// Deterministic and Flutter-free so the recommendation logic is fully
/// unit-tested — the expensive-to-validate parts (UI, persistence) stay thin.
abstract class ProgramCatalog {
  static const _reactivePowerDays = [
    ProgramDay(
      day: 1,
      exercises: [
        Exercise(id: 'depth_jumps', name: 'Depth Jumps', sets: 5, repsLabel: '6-8 reps'),
        Exercise(id: 'box_jumps', name: 'Box Jumps', sets: 4, repsLabel: '8-10 reps'),
        Exercise(id: 'single_leg_hops', name: 'Single Leg Hops', sets: 3, repsLabel: '10 reps'),
      ],
    ),
  ];

  static const _foundationDays = [
    ProgramDay(
      day: 1,
      exercises: [
        Exercise(id: 'pogo_hops', name: 'Pogo Hops', sets: 4, repsLabel: '12 reps'),
        Exercise(id: 'squat_jumps', name: 'Squat Jumps', sets: 4, repsLabel: '8 reps'),
        Exercise(id: 'calf_raises', name: 'Calf Raises', sets: 3, repsLabel: '15 reps'),
      ],
    ),
  ];

  static const _eliteDays = [
    ProgramDay(
      day: 1,
      exercises: [
        Exercise(id: 'depth_jumps', name: 'Depth Jumps', sets: 6, repsLabel: '5 reps'),
        Exercise(id: 'weighted_box_jumps', name: 'Weighted Box Jumps', sets: 5, repsLabel: '5 reps'),
        Exercise(id: 'bounds', name: 'Bounding', sets: 4, repsLabel: '20m'),
        Exercise(id: 'single_leg_hops', name: 'Single Leg Hops', sets: 3, repsLabel: '8 reps'),
      ],
    ),
  ];

  /// Recommend a program. Experience picks the template; the user's chosen
  /// training frequency sets sessions/week (which in turn drives total volume,
  /// i.e. the progress denominator).
  static TrainingProgram recommend(OnboardingProfile profile) {
    final sessionsPerWeek = profile.daysPerWeek.clamp(2, 7);
    switch (profile.experience) {
      case ExperienceLevel.beginner:
        return TrainingProgram(
          id: 'foundation',
          name: 'Foundation Builder',
          weeks: 8,
          sessionsPerWeek: sessionsPerWeek,
          sampleDays: _foundationDays,
        );
      case ExperienceLevel.intermediate:
        return TrainingProgram(
          id: 'reactive_power',
          name: 'Reactive Power Program',
          weeks: 8,
          sessionsPerWeek: sessionsPerWeek,
          sampleDays: _reactivePowerDays,
        );
      case ExperienceLevel.advanced:
        return TrainingProgram(
          id: 'elite_vertical',
          name: 'Elite Vertical System',
          weeks: 10,
          sessionsPerWeek: sessionsPerWeek,
          sampleDays: _eliteDays,
        );
    }
  }
}
