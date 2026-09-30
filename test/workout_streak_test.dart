import 'package:dunkmax/core/workout_streak.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 8, 5);

  DateTime daysAgo(int n) => today.subtract(Duration(days: n));

  group('WorkoutStreak.currentStreak', () {
    test('empty list returns 0', () {
      expect(WorkoutStreak.currentStreak(const [], asOf: today), 0);
    });

    test('single completion today returns 1', () {
      expect(WorkoutStreak.currentStreak([today], asOf: today), 1);
    });

    test('today + yesterday + day before returns 3', () {
      final dates = [daysAgo(0), daysAgo(1), daysAgo(2)];
      expect(WorkoutStreak.currentStreak(dates, asOf: today), 3);
    });

    test('a gap in the middle breaks the streak count', () {
      // today, yesterday, then a gap, then 3 days ago.
      final dates = [daysAgo(0), daysAgo(1), daysAgo(3)];
      expect(WorkoutStreak.currentStreak(dates, asOf: today), 2);
    });

    test('last completion was yesterday — streak still counts, not zeroed', () {
      final dates = [daysAgo(1), daysAgo(2)];
      expect(WorkoutStreak.currentStreak(dates, asOf: today), 2);
    });

    test('no completion today or yesterday returns 0', () {
      final dates = [daysAgo(2), daysAgo(3)];
      expect(WorkoutStreak.currentStreak(dates, asOf: today), 0);
    });

    test('duplicate and unsorted dates are handled correctly', () {
      final dates = [
        daysAgo(1),
        daysAgo(0),
        daysAgo(0), // duplicate
        daysAgo(2),
        daysAgo(1), // duplicate
      ];
      expect(WorkoutStreak.currentStreak(dates, asOf: today), 3);
    });

    test('time-of-day differences on the same calendar day still count as one day', () {
      final dates = [
        DateTime(2026, 8, 5, 7, 0),
        DateTime(2026, 8, 4, 23, 59),
      ];
      expect(WorkoutStreak.currentStreak(dates, asOf: today), 2);
    });

    test('a streak survives a daylight-saving change', () {
      // A local day is 23 or 25 hours long at a clock change, so stepping
      // back by a 24-hour Duration leaves midnight and the streak broke
      // there. These spans cross the 2026 changes in both Europe (29 Mar,
      // 25 Oct) and the US (8 Mar, 1 Nov). The regression only bites when the
      // test machine's own zone observes one of them — CI runs in UTC, where
      // this is just a month-boundary check — but the dates are built from
      // calendar fields, so it is correct everywhere.
      for (final end in [
        DateTime(2026, 3, 10),
        DateTime(2026, 3, 31),
        DateTime(2026, 10, 27),
        DateTime(2026, 11, 3),
      ]) {
        final dates = [
          for (var i = 0; i < 5; i++)
            DateTime(end.year, end.month, end.day - i, 18, 30),
        ];
        expect(WorkoutStreak.currentStreak(dates, asOf: end), 5,
            reason: 'streak ending $end');
      }
    });

    test('a streak runs back across a month and a year boundary', () {
      final end = DateTime(2027, 1, 2, 9);
      final dates = [
        DateTime(2027, 1, 2),
        DateTime(2027, 1, 1),
        DateTime(2026, 12, 31),
        DateTime(2026, 12, 30),
      ];
      expect(WorkoutStreak.currentStreak(dates, asOf: end), 4);
    });
  });
}
