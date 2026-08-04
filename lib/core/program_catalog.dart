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
      focus: 'Power',
      warmUp: '5 min jump rope + leg swings',
      exercises: [
        Exercise(id: 'depth_jumps', name: 'Depth Jumps', sets: 5, repsLabel: '6-8 reps'),
        Exercise(id: 'box_jumps', name: 'Box Jumps', sets: 4, repsLabel: '8-10 reps'),
        Exercise(id: 'single_leg_hops', name: 'Single Leg Hops', sets: 3, repsLabel: '10 reps'),
      ],
    ),
    ProgramDay(
      day: 2,
      focus: 'Strength',
      warmUp: '5 min dynamic lunges + glute bridges',
      exercises: [
        Exercise(id: 'bulgarian_split_squat_jumps', name: 'Bulgarian Split Squat Jumps', sets: 4, repsLabel: '8 reps/leg'),
        Exercise(id: 'depth_jumps', name: 'Depth Jumps', sets: 4, repsLabel: '6 reps'),
        Exercise(id: 'calf_raises', name: 'Calf Raises', sets: 3, repsLabel: '15 reps'),
      ],
    ),
    ProgramDay(
      day: 3,
      focus: 'Speed',
      warmUp: '5 min high-knee skips + A-skips',
      exercises: [
        Exercise(id: 'bounds', name: 'Bounding', sets: 4, repsLabel: '20m'),
        Exercise(id: 'lateral_bounds', name: 'Lateral Bounds', sets: 3, repsLabel: '10 reps'),
        Exercise(id: 'pogo_hops', name: 'Pogo Hops', sets: 4, repsLabel: '15 reps'),
      ],
    ),
  ];

  static const _foundationDays = [
    ProgramDay(
      day: 1,
      focus: 'Power',
      warmUp: '5 min jump rope + ankle bounces',
      exercises: [
        Exercise(id: 'pogo_hops', name: 'Pogo Hops', sets: 4, repsLabel: '12 reps'),
        Exercise(id: 'squat_jumps', name: 'Squat Jumps', sets: 4, repsLabel: '8 reps'),
        Exercise(id: 'calf_raises', name: 'Calf Raises', sets: 3, repsLabel: '15 reps'),
      ],
    ),
    ProgramDay(
      day: 2,
      focus: 'Strength',
      warmUp: '5 min bodyweight squats + walking lunges',
      exercises: [
        Exercise(id: 'box_step_ups', name: 'Box Step-Ups', sets: 4, repsLabel: '10 reps'),
        Exercise(id: 'broad_jumps', name: 'Broad Jumps', sets: 4, repsLabel: '6 reps'),
        Exercise(id: 'wall_sits', name: 'Wall Sits', sets: 3, repsLabel: '30 sec'),
      ],
    ),
    ProgramDay(
      day: 3,
      focus: 'Control',
      warmUp: '5 min light jog + hip openers',
      exercises: [
        Exercise(id: 'single_leg_hops', name: 'Single Leg Hops', sets: 3, repsLabel: '10 reps'),
        Exercise(id: 'lateral_bounds', name: 'Lateral Bounds', sets: 3, repsLabel: '10 reps'),
        Exercise(id: 'calf_raises', name: 'Calf Raises', sets: 3, repsLabel: '15 reps'),
      ],
    ),
  ];

  static const _eliteDays = [
    ProgramDay(
      day: 1,
      focus: 'Power',
      warmUp: '8 min dynamic warm-up + 2 easy depth jumps',
      exercises: [
        Exercise(id: 'depth_jumps', name: 'Depth Jumps', sets: 6, repsLabel: '5 reps'),
        Exercise(id: 'weighted_box_jumps', name: 'Weighted Box Jumps', sets: 5, repsLabel: '5 reps'),
        Exercise(id: 'bounds', name: 'Bounding', sets: 4, repsLabel: '20m'),
        Exercise(id: 'single_leg_hops', name: 'Single Leg Hops', sets: 3, repsLabel: '8 reps'),
      ],
    ),
    ProgramDay(
      day: 2,
      focus: 'Strength',
      warmUp: '8 min mobility flow + banded lateral walks',
      exercises: [
        Exercise(id: 'weighted_squat_jumps', name: 'Weighted Squat Jumps', sets: 5, repsLabel: '5 reps'),
        Exercise(id: 'broad_jumps', name: 'Broad Jumps', sets: 5, repsLabel: '5 reps'),
        Exercise(id: 'nordic_hamstring_curls', name: 'Nordic Hamstring Curls', sets: 3, repsLabel: '8 reps'),
      ],
    ),
    ProgramDay(
      day: 3,
      focus: 'Speed',
      warmUp: '8 min sprint drills + ankle bounces',
      exercises: [
        Exercise(id: 'alternating_bounds', name: 'Alternating Bounds', sets: 4, repsLabel: '20m'),
        Exercise(id: 'depth_jumps', name: 'Depth Jumps', sets: 5, repsLabel: '5 reps'),
        Exercise(id: 'lateral_bounds', name: 'Lateral Bounds', sets: 4, repsLabel: '10 reps'),
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
