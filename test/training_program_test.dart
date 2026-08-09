import 'package:dunkmax/core/models/exercise.dart';
import 'package:dunkmax/core/models/training_program.dart';
import 'package:flutter_test/flutter_test.dart';

const _dayA = ProgramDay(
  day: 1,
  focus: 'Power',
  warmUp: '5 min jump rope',
  exercises: [
    Exercise(id: 'a_ex', name: 'A Exercise', sets: 4, repsLabel: '10 reps', equipment: Equipment.none),
  ],
);

const _dayB = ProgramDay(
  day: 2,
  focus: 'Strength',
  warmUp: '5 min lunges',
  exercises: [
    Exercise(id: 'b_ex', name: 'B Exercise', sets: 4, repsLabel: '8 reps', equipment: Equipment.none),
  ],
);

const _dayC = ProgramDay(
  day: 3,
  focus: 'Speed',
  warmUp: '5 min sprint drills',
  exercises: [
    Exercise(id: 'c_ex', name: 'C Exercise', sets: 3, repsLabel: '20m', equipment: Equipment.none),
  ],
);

const _rotatingProgram = TrainingProgram(
  id: 'rotation_test',
  name: 'Rotation Test Program',
  weeks: 4,
  sessionsPerWeek: 3,
  sampleDays: [_dayA, _dayB, _dayC],
);

const _singleDayProgram = TrainingProgram(
  id: 'single_day_test',
  name: 'Single Day Test Program',
  weeks: 4,
  sessionsPerWeek: 3,
  sampleDays: [_dayA],
);

void main() {
  group('TrainingProgram.dayFor', () {
    test('sessions 1, 2, 3 return three distinct days', () {
      final day1 = _rotatingProgram.dayFor(1);
      final day2 = _rotatingProgram.dayFor(2);
      final day3 = _rotatingProgram.dayFor(3);

      expect(day1.focus, 'Power');
      expect(day2.focus, 'Strength');
      expect(day3.focus, 'Speed');

      expect(day1.exercises.first.id, 'a_ex');
      expect(day2.exercises.first.id, 'b_ex');
      expect(day3.exercises.first.id, 'c_ex');
    });

    test('session 4 wraps back around to day 1\'s content', () {
      final day1 = _rotatingProgram.dayFor(1);
      final day4 = _rotatingProgram.dayFor(4);

      expect(day4.focus, day1.focus);
      expect(day4.warmUp, day1.warmUp);
      expect(day4.exercises.first.id, day1.exercises.first.id);
    });

    test('further sessions keep rotating (session 7 == day 1, session 8 == day 2)', () {
      expect(_rotatingProgram.dayFor(7).focus, 'Power');
      expect(_rotatingProgram.dayFor(8).focus, 'Strength');
      expect(_rotatingProgram.dayFor(9).focus, 'Speed');
    });

    test('a program with a single authored day always returns that day', () {
      final first = _singleDayProgram.dayFor(1);
      final fifth = _singleDayProgram.dayFor(5);
      final hundredth = _singleDayProgram.dayFor(100);

      expect(first.focus, 'Power');
      expect(fifth.focus, 'Power');
      expect(hundredth.focus, 'Power');
      expect(fifth.exercises.first.id, first.exercises.first.id);
      expect(hundredth.exercises.first.id, first.exercises.first.id);
    });

    test('throws StateError when sampleDays is empty', () {
      const emptyProgram = TrainingProgram(
        id: 'empty_test',
        name: 'Empty Test Program',
        weeks: 1,
        sessionsPerWeek: 1,
        sampleDays: [],
      );

      expect(() => emptyProgram.dayFor(1), throwsStateError);
    });
  });
}
