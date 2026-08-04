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
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }

    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
