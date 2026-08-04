import 'models/jump_log_entry.dart';

/// Latest vertical + movement since the athlete's first logged test.
class JumpTrend {
  final int latestVerticalInches;
  final DateTime latestRecordedAt;
  final int deltaFromFirstInches; // latest - first; can be 0 or negative

  const JumpTrend({
    required this.latestVerticalInches,
    required this.latestRecordedAt,
    required this.deltaFromFirstInches,
  });

  bool get isImproving => deltaFromFirstInches > 0;
}

/// Pure aggregation over a jump-log history. Returns null on an empty list —
/// callers must render an honest empty state, never a fabricated number.
abstract class JumpTrendCalculator {
  static JumpTrend? compute(List<JumpLogEntry> entries) {
    if (entries.isEmpty) return null;
    final sorted = [...entries]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final first = sorted.first;
    final latest = sorted.last;
    return JumpTrend(
      latestVerticalInches: latest.verticalInches,
      latestRecordedAt: latest.recordedAt,
      deltaFromFirstInches: latest.verticalInches - first.verticalInches,
    );
  }
}
