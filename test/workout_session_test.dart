import 'package:dunkmax/core/models/workout_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoggedSet', () {
    test('round-trips through toMap/fromMap', () {
      const set = LoggedSet(setNumber: 1, reps: 10, weightLbs: 45.5);
      final restored = LoggedSet.fromMap(set.toMap());
      expect(restored, isNotNull);
      expect(restored!.setNumber, 1);
      expect(restored.reps, 10);
      expect(restored.weightLbs, 45.5);
    });

    test('bodyweight set (null weight) round-trips', () {
      const set = LoggedSet(setNumber: 2, reps: 8);
      final restored = LoggedSet.fromMap(set.toMap());
      expect(restored, isNotNull);
      expect(restored!.weightLbs, isNull);
    });

    test('missing required fields return null instead of throwing', () {
      expect(LoggedSet.fromMap({'reps': 10}), isNull);
      expect(LoggedSet.fromMap({'setNumber': 1}), isNull);
      expect(LoggedSet.fromMap({'setNumber': '1', 'reps': 10}), isNull);
    });
  });

  group('LoggedExercise', () {
    const exercise = LoggedExercise(
      exerciseId: 'pogo_hops',
      exerciseName: 'Pogo Hops',
      sets: [
        LoggedSet(setNumber: 1, reps: 10, weightLbs: 20),
        LoggedSet(setNumber: 2, reps: 8),
      ],
    );

    test('totalReps sums correctly', () {
      expect(exercise.totalReps, 18);
    });

    test('round-trips through toMap/fromMap', () {
      final restored = LoggedExercise.fromMap(exercise.toMap());
      expect(restored, isNotNull);
      expect(restored!.exerciseId, 'pogo_hops');
      expect(restored.exerciseName, 'Pogo Hops');
      expect(restored.sets.length, 2);
      expect(restored.totalReps, 18);
    });

    test('malformed map returns null', () {
      expect(LoggedExercise.fromMap({'exerciseName': 'x'}), isNull);
      expect(LoggedExercise.fromMap({'exerciseId': 1, 'exerciseName': 'x'}), isNull);
    });

    test('malformed entries within sets list are dropped, not fatal', () {
      final restored = LoggedExercise.fromMap({
        'exerciseId': 'pogo_hops',
        'exerciseName': 'Pogo Hops',
        'sets': [
          {'setNumber': 1, 'reps': 10},
          {'setNumber': 'bad', 'reps': 10},
          'not a map',
        ],
      });
      expect(restored, isNotNull);
      expect(restored!.sets.length, 1);
    });
  });

  group('WorkoutSession', () {
    final session = WorkoutSession(
      programId: 'foundation',
      sessionNumber: 3,
      completedAt: DateTime.utc(2026, 8, 1, 12, 30),
      exercises: const [
        LoggedExercise(
          exerciseId: 'squat_jumps',
          exerciseName: 'Squat Jumps',
          sets: [LoggedSet(setNumber: 1, reps: 12, weightLbs: 25)],
        ),
      ],
    );

    test('round-trips through toMap/fromMap without loss', () {
      final restored = WorkoutSession.fromMap(session.toMap());
      expect(restored, isNotNull);
      expect(restored!.programId, 'foundation');
      expect(restored.sessionNumber, 3);
      expect(restored.completedAt, session.completedAt);
      expect(restored.exercises.length, 1);
      expect(restored.exercises.first.totalReps, 12);
    });

    test('round-trips through toJson/fromJson without loss', () {
      final restored = WorkoutSession.fromJson(session.toJson());
      expect(restored, isNotNull);
      expect(restored!.programId, session.programId);
      expect(restored.sessionNumber, session.sessionNumber);
      expect(restored.completedAt, session.completedAt);
      expect(restored.exercises.length, session.exercises.length);
    });

    test('garbage JSON returns null instead of throwing', () {
      expect(WorkoutSession.fromJson('not json'), isNull);
      expect(WorkoutSession.fromJson('[]'), isNull);
      expect(WorkoutSession.fromJson('{"programId":"x"}'), isNull);
    });

    test('missing/wrong-type required fields return null', () {
      expect(
        WorkoutSession.fromMap({
          'sessionNumber': 1,
          'completedAt': DateTime.now().toIso8601String(),
          'exercises': [],
        }),
        isNull,
      );
      expect(
        WorkoutSession.fromMap({
          'programId': 'foundation',
          'sessionNumber': 'one',
          'completedAt': DateTime.now().toIso8601String(),
          'exercises': [],
        }),
        isNull,
      );
      expect(
        WorkoutSession.fromMap({
          'programId': 'foundation',
          'sessionNumber': 1,
          'completedAt': 'not-a-date',
          'exercises': [],
        }),
        isNull,
      );
    });
  });
}
