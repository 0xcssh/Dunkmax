/// Consecutive-day training streak, computed from raw completion
/// timestamps. Pure, deterministic given an injectable "now" for tests.
abstract class WorkoutStreak {
  /// Streak of consecutive calendar days with at least one completed
  /// session, ending today. Survives one day into "yesterday" so it
  /// doesn't zero out before the athlete has had a chance to train today.
  /// [asOf] defaults to `DateTime.now()`; inject it in tests.
  static int currentStreak(List<DateTime> completedDates, {DateTime? asOf}) {
    if (completedDates.isEmpty) return 0;
    final today = _dateOnly(asOf ?? DateTime.now());
    final days = completedDates.map(_dateOnly).toSet();

    var cursor = today;
    if (!days.contains(cursor)) {
      cursor = _previousDay(cursor);
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = _previousDay(cursor);
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Calendar arithmetic, not `subtract(Duration(days: 1))`: a local day is
  /// 23 or 25 hours long across a daylight-saving change, so stepping back 24
  /// hours from midnight lands at 23:00 or 01:00 — no longer a midnight, so
  /// it never matches a [_dateOnly] value and the streak breaks (or skips a
  /// day) at the clock change. The constructor normalises day 0 to the last
  /// day of the previous month.
  static DateTime _previousDay(DateTime d) =>
      DateTime(d.year, d.month, d.day - 1);
}
