import 'package:dunkmax/core/models/exercise.dart';
import 'package:dunkmax/core/models/training_program.dart';
import 'package:dunkmax/core/training_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

const _dayA = ProgramDay(
  day: 1,
  focus: 'Power',
  warmUp: '5 min jump rope',
  exercises: [
    Exercise(id: 'a1', name: 'A One', sets: 4, repsLabel: '10 reps', equipment: Equipment.none),
    Exercise(id: 'a2', name: 'A Two', sets: 3, repsLabel: '8 reps', equipment: Equipment.none),
  ],
);

const _dayB = ProgramDay(
  day: 2,
  focus: 'Strength',
  warmUp: '5 min lunges',
  exercises: [
    Exercise(id: 'b1', name: 'B One', sets: 4, repsLabel: '8 reps', equipment: Equipment.none),
  ],
);

const _dayC = ProgramDay(
  day: 3,
  focus: 'Speed',
  warmUp: '5 min sprint drills',
  exercises: [
    Exercise(id: 'c1', name: 'C One', sets: 3, repsLabel: '20m', equipment: Equipment.none),
  ],
);

TrainingProgram _program({int weeks = 8, int sessionsPerWeek = 3}) =>
    TrainingProgram(
      id: 'schedule_test',
      name: 'Schedule Test Program',
      weeks: weeks,
      sessionsPerWeek: sessionsPerWeek,
      sampleDays: const [_dayA, _dayB, _dayC],
    );

/// Gaps between consecutive training weekdays, wrapping into the next week.
List<int> _gaps(List<int> weekdays) {
  final gaps = <int>[];
  for (var i = 1; i < weekdays.length; i++) {
    gaps.add(weekdays[i] - weekdays[i - 1]);
  }
  if (weekdays.isNotEmpty) {
    gaps.add(TrainingSchedule.daysInWeek - weekdays.last + weekdays.first);
  }
  return gaps;
}

void main() {
  group('rest-day spreading', () {
    test('2 sessions/week land on Monday and Thursday', () {
      expect(TrainingSchedule.trainingWeekdaysFor(2), [1, 4]);
    });

    test('3 sessions/week land on Monday, Wednesday, Friday', () {
      expect(TrainingSchedule.trainingWeekdaysFor(3), [1, 3, 5]);
    });

    test('4 and 5 sessions/week stay spread, never all back-to-back', () {
      expect(TrainingSchedule.trainingWeekdaysFor(4), [1, 2, 4, 6]);
      expect(TrainingSchedule.trainingWeekdaysFor(5), [1, 2, 3, 5, 6]);
    });

    test('7 sessions/week fills the week, 0 fills nothing', () {
      expect(TrainingSchedule.trainingWeekdaysFor(7), [1, 2, 3, 4, 5, 6, 7]);
      expect(TrainingSchedule.trainingWeekdaysFor(0), isEmpty);
    });

    test('more than 7 sessions/week is clamped to a real week', () {
      expect(TrainingSchedule.trainingWeekdaysFor(9).length, 7);
    });

    test('gaps between training days are always as even as 7 days allow', () {
      for (var n = 2; n <= 7; n++) {
        final weekdays = TrainingSchedule.trainingWeekdaysFor(n);
        expect(weekdays.length, n, reason: '$n sessions/week');
        expect(weekdays.toSet().length, n, reason: 'no duplicate weekday ($n)');
        expect(weekdays, orderedEquals(List<int>.from(weekdays)..sort()));

        final floor = TrainingSchedule.daysInWeek ~/ n;
        for (final gap in _gaps(weekdays)) {
          expect(
            gap,
            anyOf(floor, floor + 1),
            reason: '$n sessions/week produced an uneven gap of $gap',
          );
        }
      }
    });

    test('a week has 7 days: training days plus rest days', () {
      final schedule = TrainingSchedule(_program(sessionsPerWeek: 3));
      final week = schedule.weekAt(1);

      expect(week.days.length, 7);
      expect(week.trainingDays.length, 3);
      expect(week.restDays.length, 4);
      expect(week.trainingDays.map((d) => d.weekday), [1, 3, 5]);
      expect(week.restDays.map((d) => d.weekday), [2, 4, 6, 7]);
      for (final rest in week.restDays) {
        expect(rest.day, isNull);
        expect(rest.sessionNumber, isNull);
      }
    });

    test('week days carry their global session numbers and completion state',
        () {
      final schedule = TrainingSchedule(_program(sessionsPerWeek: 3));
      final week2 = schedule.weekAt(2, completedSessions: 4);

      expect(week2.trainingDays.map((d) => d.sessionNumber), [4, 5, 6]);
      expect(week2.trainingDays.map((d) => d.isCompleted), [true, false, false]);
      expect(week2.trainingDays.map((d) => d.dayInWeek), [1, 2, 3]);
      expect(week2.trainingDays.first.weekdayLabel, 'MON');
    });
  });

  group('session ↔ week/day mapping', () {
    final schedule = TrainingSchedule(_program(sessionsPerWeek: 3));

    test('session 1 is week 1 day 1', () {
      expect(schedule.weekOfSession(1), 1);
      expect(schedule.dayInWeekOfSession(1), 1);
    });

    test('session 3 is the last day of week 1, session 4 opens week 2', () {
      expect(schedule.weekOfSession(3), 1);
      expect(schedule.dayInWeekOfSession(3), 3);
      expect(schedule.weekOfSession(4), 2);
      expect(schedule.dayInWeekOfSession(4), 1);
    });

    test('sessionNumberAt round-trips', () {
      for (var week = 1; week <= 8; week++) {
        for (var day = 1; day <= 3; day++) {
          final n = schedule.sessionNumberAt(week: week, dayInWeek: day);
          expect(schedule.weekOfSession(n), week);
          expect(schedule.dayInWeekOfSession(n), day);
        }
      }
    });
  });

  group('progressive overload', () {
    final schedule = TrainingSchedule(_program(weeks: 8));

    test('week 1 trains exactly the authored base volume', () {
      final day = schedule.prescriptionFor(week: 1, dayInWeek: 1);
      expect(day.exercises.map((e) => e.sets), [4, 3]);
    });

    test('sets climb one per week inside a build block', () {
      expect(schedule.setsFor(baseSets: 4, week: 1), 4);
      expect(schedule.setsFor(baseSets: 4, week: 2), 5);
      expect(schedule.setsFor(baseSets: 4, week: 3), 6);
    });

    test('progression is monotonic across the build weeks of every block', () {
      for (var block = 0; block < 3; block++) {
        var previous = 0;
        for (var i = 0; i < 3; i++) {
          final week = block * TrainingSchedule.deloadEveryWeeks + i + 1;
          final sets = schedule.setsFor(baseSets: 4, week: week);
          expect(sets, greaterThanOrEqualTo(previous),
              reason: 'week $week regressed');
          previous = sets;
        }
      }
    });

    test('a later block opens heavier than the block before it', () {
      expect(
        schedule.setsFor(baseSets: 4, week: 5),
        greaterThan(schedule.setsFor(baseSets: 4, week: 1)),
      );
    });

    test('progression is capped, never runaway', () {
      for (var week = 1; week <= 60; week++) {
        final sets = schedule.setsFor(baseSets: 4, week: week);
        expect(sets, lessThanOrEqualTo(4 + TrainingSchedule.maxAddedSets));
        expect(sets, lessThanOrEqualTo(TrainingSchedule.maxSetsPerExercise));
        expect(sets, greaterThanOrEqualTo(1));
      }
      // A heavy authored day is held under the absolute ceiling.
      expect(
        TrainingSchedule(_program(weeks: 40)).setsFor(baseSets: 7, week: 12),
        TrainingSchedule.maxSetsPerExercise,
      );
    });

    test('a one-set exercise is never progressed below one set', () {
      expect(schedule.setsFor(baseSets: 1, week: 4), 1);
    });

    test('reps, focus and warm-up are carried through untouched', () {
      const base = _dayA;
      final progressed = schedule.prescriptionFor(week: 3, dayInWeek: 1);

      expect(progressed.focus, base.focus);
      expect(progressed.warmUp, base.warmUp);
      expect(progressed.exercises.map((e) => e.id), base.exercises.map((e) => e.id));
      expect(
        progressed.exercises.map((e) => e.repsLabel),
        base.exercises.map((e) => e.repsLabel),
      );
    });

    test('the authored catalog day is not mutated by progression', () {
      schedule.prescriptionFor(week: 3, dayInWeek: 1);
      expect(_dayA.exercises.map((e) => e.sets), [4, 3]);
    });

    test('the same authored day is heavier in week 3 than in week 1', () {
      // Day 1 of weeks 1 and 3 are both "Power" (3 authored days, 3
      // sessions/week), so this compares like with like.
      final week1 = schedule.prescriptionFor(week: 1, dayInWeek: 1);
      final week3 = schedule.prescriptionFor(week: 3, dayInWeek: 1);

      expect(week3.focus, week1.focus);
      for (var i = 0; i < week1.exercises.length; i++) {
        expect(week3.exercises[i].sets, greaterThan(week1.exercises[i].sets));
      }
    });
  });

  group('deload weeks', () {
    final schedule = TrainingSchedule(_program(weeks: 8));

    test('every 4th week is a deload', () {
      expect(schedule.isDeloadWeek(4), isTrue);
      expect([1, 2, 3, 5, 6, 7].any(schedule.isDeloadWeek), isFalse);
    });

    test('a deload week is clearly lighter than the week before it', () {
      expect(
        schedule.setsFor(baseSets: 4, week: 4),
        lessThan(schedule.setsFor(baseSets: 4, week: 3)),
      );
      expect(
        schedule.setsFor(baseSets: 4, week: 4),
        lessThan(schedule.setsFor(baseSets: 4, week: 1)),
      );
    });

    test('a later deload sits below its own block, not below the last one', () {
      final long = TrainingSchedule(_program(weeks: 20));
      expect(
        long.setsFor(baseSets: 4, week: 8),
        lessThan(long.setsFor(baseSets: 4, week: 7)),
      );
      expect(
        long.setsFor(baseSets: 4, week: 8),
        lessThan(long.setsFor(baseSets: 4, week: 5)),
      );
      expect(
        long.setsFor(baseSets: 4, week: 8),
        greaterThan(long.setsFor(baseSets: 4, week: 4)),
      );
    });

    test('the final week is never a deload, even on the 4th slot', () {
      expect(TrainingSchedule(_program(weeks: 8)).isDeloadWeek(8), isFalse);
      expect(TrainingSchedule(_program(weeks: 12)).isDeloadWeek(12), isFalse);
      // …and it trains at the block's peak volume.
      final eight = TrainingSchedule(_program(weeks: 8));
      expect(
        eight.setsFor(baseSets: 4, week: 8),
        greaterThanOrEqualTo(eight.setsFor(baseSets: 4, week: 6)),
      );
    });

    test('a 10-week program deloads on weeks 4 and 8 only', () {
      final ten = TrainingSchedule(_program(weeks: 10));
      final deloads = [
        for (var w = 1; w <= 10; w++)
          if (ten.isDeloadWeek(w)) w,
      ];
      expect(deloads, [4, 8]);
    });

    test('the whole week is flagged as deload, rest days included', () {
      final week4 = schedule.weekAt(4);
      expect(week4.isDeload, isTrue);
      expect(week4.days.every((d) => d.isDeload), isTrue);
    });
  });

  group('today()', () {
    final schedule = TrainingSchedule(_program(weeks: 8, sessionsPerWeek: 3));

    test('a fresh athlete starts on week 1, day 1', () {
      final plan = schedule.today(completedSessions: 0);
      expect(plan.week, 1);
      expect(plan.dayInWeek, 1);
      expect(plan.sessionNumber, 1);
      expect(plan.weekday, DateTime.monday);
      expect(plan.isDeloadWeek, isFalse);
      expect(plan.isRestDay, isFalse);
      expect(plan.isProgramComplete, isFalse);
      expect(plan.positionLabel, 'WEEK 1 · DAY 1 OF 3');
    });

    test('four completed sessions puts the athlete on week 2, day 2', () {
      final plan = schedule.today(completedSessions: 4);
      expect(plan.week, 2);
      expect(plan.dayInWeek, 2);
      expect(plan.sessionNumber, 5);
      expect(plan.weekday, DateTime.wednesday);
      expect(plan.positionLabel, 'WEEK 2 · DAY 2 OF 3');
    });

    test('a deload week is reported as such', () {
      // Weeks 1-3 done = 9 sessions → next session opens week 4.
      final plan = schedule.today(completedSessions: 9);
      expect(plan.week, 4);
      expect(plan.isDeloadWeek, isTrue);
    });

    test('restToday flags rest without hiding the next session', () {
      final plan = schedule.today(completedSessions: 3, restToday: true);
      expect(plan.isRestDay, isTrue);
      expect(plan.sessionNumber, 4);
      expect(plan.day.exercises, isNotEmpty);
    });

    test('a finished program reports complete and is never a rest day', () {
      final plan = schedule.today(completedSessions: 24, restToday: true);
      expect(plan.isProgramComplete, isTrue);
      expect(plan.isRestDay, isFalse);
      expect(plan.sessionNumber, 24);
      expect(plan.week, 8);
    });

    test('negative or overshooting counts stay inside the program', () {
      expect(schedule.today(completedSessions: -5).sessionNumber, 1);
      expect(schedule.today(completedSessions: 999).sessionNumber, 24);
    });
  });

  group('never returns an empty training day', () {
    test('every scheduled session of every week has exercises', () {
      for (final sessionsPerWeek in [2, 3, 4, 5, 6, 7]) {
        final schedule = TrainingSchedule(
          _program(weeks: 10, sessionsPerWeek: sessionsPerWeek),
        );
        for (var week = 1; week <= 10; week++) {
          final scheduledWeek = schedule.weekAt(week);
          expect(scheduledWeek.trainingDays.length, sessionsPerWeek);
          for (final day in scheduledWeek.trainingDays) {
            expect(day.day, isNotNull);
            expect(day.day!.exercises, isNotEmpty);
            expect(day.day!.exercises.every((e) => e.sets >= 1), isTrue);
            expect(day.day!.focus, isNotEmpty);
            expect(day.day!.warmUp, isNotEmpty);
          }
        }
      }
    });

    test('a program with no authored days throws rather than showing nothing',
        () {
      const empty = TrainingProgram(
        id: 'empty',
        name: 'Empty',
        weeks: 4,
        sessionsPerWeek: 3,
        sampleDays: [],
      );
      expect(
        () => const TrainingSchedule(empty).prescriptionForSession(1),
        throwsStateError,
      );
    });

    test('a day authored with no exercises throws rather than showing nothing',
        () {
      const hollow = TrainingProgram(
        id: 'hollow',
        name: 'Hollow',
        weeks: 4,
        sessionsPerWeek: 3,
        sampleDays: [
          ProgramDay(day: 1, focus: 'Power', warmUp: 'x', exercises: []),
        ],
      );
      expect(
        () => const TrainingSchedule(hollow).prescriptionForSession(1),
        throwsStateError,
      );
    });
  });

  group('week boundaries', () {
    test('weekAt clamps to the program length', () {
      final schedule = TrainingSchedule(_program(weeks: 8));
      expect(schedule.weekAt(0).weekNumber, 1);
      expect(schedule.weekAt(99).weekNumber, 8);
    });

    test('a one-week program has no deload and no progression', () {
      final schedule = TrainingSchedule(_program(weeks: 1));
      expect(schedule.isDeloadWeek(1), isFalse);
      expect(schedule.setsFor(baseSets: 4, week: 1), 4);
    });
  });
}
