import 'package:dunkmax/core/exercise_library.dart';
import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/exercise.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:dunkmax/core/models/training_location.dart';
import 'package:dunkmax/core/models/training_program.dart';
import 'package:dunkmax/core/program_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

OnboardingProfile _profile({
  required ExperienceLevel experience,
  required TrainingLocation location,
}) {
  return OnboardingProfile(
    goals: {DunkGoal.firstDunk},
    experience: experience,
    position: CourtPosition.pointGuard,
    daysPerWeek: 3,
    trainingLocation: location,
  );
}

Iterable<Exercise> _allExercises(TrainingProgram program) sync* {
  for (final day in program.sampleDays) {
    yield* day.exercises;
  }
}

void main() {
  group('ExerciseLibrary content', () {
    test('every exercise the catalog can prescribe has a guide', () {
      for (final experience in ExperienceLevel.values) {
        for (final location in TrainingLocation.values) {
          final program = ProgramCatalog.recommend(
            _profile(experience: experience, location: location),
          );
          for (final exercise in _allExercises(program)) {
            expect(
              ExerciseLibrary.guideFor(exercise.id),
              isNotNull,
              reason: 'no library guide for "${exercise.id}" '
                  '(${experience.name} / ${location.name})',
            );
          }
        }
      }
    });

    test('a guide id always matches its map key', () {
      ExerciseLibrary.guides.forEach((key, guide) {
        expect(guide.id, key);
      });
    });

    test('every guide carries real coaching content', () {
      for (final guide in ExerciseLibrary.guides.values) {
        expect(guide.name, isNotEmpty, reason: guide.id);
        expect(guide.summary, isNotEmpty, reason: guide.id);
        expect(guide.steps.length, greaterThanOrEqualTo(3), reason: guide.id);
        expect(guide.commonMistakes.length, greaterThanOrEqualTo(2),
            reason: guide.id);
        expect(guide.commonMistakes.length, lessThanOrEqualTo(3),
            reason: guide.id);
        expect(guide.trains, isNotEmpty, reason: guide.id);
      }
    });

    test('demo frames come in start/finish pairs under assets/exercises', () {
      // The rule this replaces was "no media at all". Real reference photos
      // now ship, so the rule becomes: whatever is there must be a genuine
      // pair for that drill, filed under that drill's own id — never another
      // exercise's photo standing in.
      for (final guide in ExerciseLibrary.guides.values) {
        expect(guide.demoVideoUrl, isNull,
            reason: 'no clips exist yet: ${guide.id}');
        if (guide.demoFrames.isEmpty) continue;
        expect(guide.demoFrames.length, 2, reason: guide.id);
        for (final frame in guide.demoFrames) {
          expect(frame, startsWith('assets/exercises/${guide.id}/'),
              reason: guide.id);
        }
        expect(guide.hasDemoMedia, isTrue, reason: guide.id);
      }
    });

    test('a drill with no honest photo simply has none', () {
      // Wall sits have no matching entry in the source dataset, and
      // illustrating them with a squat would be showing a different exercise.
      expect(ExerciseLibrary.guides['wall_sits']!.demoFrames, isEmpty);
      expect(ExerciseLibrary.guides['wall_sits']!.hasDemoMedia, isFalse);
    });
  });

  group('home substitutes', () {
    test('every equipment-requiring exercise names a substitute', () {
      for (final guide in ExerciseLibrary.guides.values) {
        if (!guide.equipment.isRequired) continue;
        expect(guide.homeSubstituteId, isNotNull,
            reason: '${guide.id} needs ${guide.equipment.name} but has no '
                'home substitute');
        expect(ExerciseLibrary.guideFor(guide.homeSubstituteId!), isNotNull,
            reason: '${guide.id} points at an unknown substitute '
                '"${guide.homeSubstituteId}"');
      }
    });

    test('a substitute itself needs no equipment', () {
      for (final guide in ExerciseLibrary.guides.values) {
        final substitute = ExerciseLibrary.homeSubstituteFor(guide.id);
        if (substitute == null) continue;
        expect(substitute.equipment, Equipment.none,
            reason: '${guide.id} substitutes ${substitute.id}, which itself '
                'needs ${substitute.equipment.name}');
      }
    });

    test('a no-equipment drill is its own home version', () {
      for (final guide in ExerciseLibrary.guides.values) {
        if (guide.equipment.isRequired) continue;
        expect(guide.homeSubstituteId, isNull, reason: guide.id);
      }
    });

    test('homeVariantOf keeps the prescribed volume and records the swap', () {
      const boxJump = Exercise(
        id: 'box_jumps',
        name: 'Box Jumps',
        sets: 4,
        repsLabel: '8-10 reps',
        equipment: Equipment.box,
      );
      final home = ExerciseLibrary.homeVariantOf(boxJump);
      expect(home.id, isNot('box_jumps'));
      expect(home.equipment, Equipment.none);
      expect(home.sets, 4);
      expect(home.repsLabel, '8-10 reps');
      expect(home.substitutedForId, 'box_jumps');
      expect(home.isSubstitution, isTrue);
    });

    test('homeVariantOf leaves a bodyweight drill untouched', () {
      const pogos = Exercise(
        id: 'pogo_hops',
        name: 'Pogo Hops',
        sets: 4,
        repsLabel: '15 reps',
        equipment: Equipment.none,
      );
      final home = ExerciseLibrary.homeVariantOf(pogos);
      expect(identical(home, pogos), isTrue);
      expect(home.isSubstitution, isFalse);
    });
  });

  group('ProgramCatalog respects the training location', () {
    test('a home program prescribes nothing that needs equipment', () {
      for (final experience in ExperienceLevel.values) {
        final program = ProgramCatalog.recommend(
          _profile(experience: experience, location: TrainingLocation.home),
        );
        for (final exercise in _allExercises(program)) {
          expect(exercise.equipment, Equipment.none,
              reason: '${program.id} still prescribes ${exercise.id}, which '
                  'needs ${exercise.equipment.name}');
        }
      }
    });

    test('a gym program is the authored catalogue, untouched', () {
      for (final experience in ExperienceLevel.values) {
        final gym = ProgramCatalog.recommend(
          _profile(experience: experience, location: TrainingLocation.gym),
        );
        final both = ProgramCatalog.recommend(
          _profile(experience: experience, location: TrainingLocation.both),
        );
        final gymIds = _allExercises(gym).map((e) => e.id).toList();
        expect(gymIds, _allExercises(both).map((e) => e.id).toList());
        expect(
          _allExercises(gym).any((e) => e.equipment.isRequired),
          isTrue,
          reason: '${gym.id} should still use the full catalogue at the gym',
        );
        expect(_allExercises(gym).every((e) => !e.isSubstitution), isTrue);
      }
    });

    test('the home swap changes only the drills that need equipment', () {
      final gym = ProgramCatalog.recommend(
        _profile(
          experience: ExperienceLevel.intermediate,
          location: TrainingLocation.gym,
        ),
      );
      final home = ProgramCatalog.recommend(
        _profile(
          experience: ExperienceLevel.intermediate,
          location: TrainingLocation.home,
        ),
      );
      final gymExercises = _allExercises(gym).toList();
      final homeExercises = _allExercises(home).toList();
      expect(homeExercises.length, gymExercises.length);
      for (var i = 0; i < gymExercises.length; i++) {
        if (gymExercises[i].equipment.isRequired) {
          expect(homeExercises[i].substitutedForId, gymExercises[i].id);
        } else {
          expect(homeExercises[i].id, gymExercises[i].id);
          expect(homeExercises[i].isSubstitution, isFalse);
        }
        expect(homeExercises[i].sets, gymExercises[i].sets);
      }
    });

    test('the program shape survives the swap', () {
      final home = ProgramCatalog.recommend(
        _profile(
          experience: ExperienceLevel.advanced,
          location: TrainingLocation.home,
        ),
      );
      expect(home.id, 'elite_vertical');
      expect(home.sampleDays.length, 3);
      for (final day in home.sampleDays) {
        expect(day.exercises, isNotEmpty);
      }
    });
  });
}
