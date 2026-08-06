import 'models/jump_log_entry.dart';
import 'models/leaderboard_athlete.dart';

/// One row of a ranked board: a jump plus the position it earned.
class RankedJump {
  /// 1-based position on the board (1 = best).
  final int rank;
  final JumpLogEntry entry;

  const RankedJump({required this.rank, required this.entry});
}

/// One row of the global board: an athlete plus the position they earned.
class RankedAthlete {
  /// 1-based position on the board (1 = best).
  final int rank;
  final LeaderboardAthlete athlete;

  const RankedAthlete({required this.rank, required this.athlete});
}

/// Pure ranking, shared by both boards the Feed tab shows.
///
/// * [rank] ranks the athlete's OWN logged jumps (no accounts needed).
/// * [rankAthletes] ranks the global board's rows, which arrive from the
///   backend already ordered but must not be *trusted* to be: the server can
///   change, rows can be filtered out by defensive parsing, and the numbering
///   the UI paints has to be ours. Same rules for both, so the two boards can
///   never disagree about what "better" means.
///
/// Deterministic in both cases: best vertical first, ties broken by the
/// earlier timestamp so whoever hit the number first keeps the better rank.
/// The global board adds a final name tie-break so two athletes who hit the
/// same number at the same instant still order stably.
abstract class Leaderboard {
  /// Ranks [entries] best-first. [limit] caps the returned rows (a
  /// non-positive limit returns nothing); omit it to rank everything.
  static List<RankedJump> rank(List<JumpLogEntry> entries, {int? limit}) {
    final capped = _sortedAndCapped<JumpLogEntry>(
      entries,
      verticalOf: (e) => e.verticalInches,
      recordedAtOf: (e) => e.recordedAt,
      limit: limit,
    );

    return [
      for (var i = 0; i < capped.length; i++)
        RankedJump(rank: i + 1, entry: capped[i]),
    ];
  }

  /// Ranks global-board rows best-first, same rules as [rank].
  static List<RankedAthlete> rankAthletes(
    List<LeaderboardAthlete> athletes, {
    int? limit,
  }) {
    final capped = _sortedAndCapped<LeaderboardAthlete>(
      athletes,
      verticalOf: (a) => a.verticalInches,
      recordedAtOf: (a) => a.recordedAt,
      labelOf: (a) => a.displayName,
      limit: limit,
    );

    return [
      for (var i = 0; i < capped.length; i++)
        RankedAthlete(rank: i + 1, athlete: capped[i]),
    ];
  }

  /// Sorts best-first and applies [limit], without mutating [items].
  static List<T> _sortedAndCapped<T>(
    List<T> items, {
    required int Function(T) verticalOf,
    required DateTime Function(T) recordedAtOf,
    String Function(T)? labelOf,
    int? limit,
  }) {
    if (limit != null && limit <= 0) return const [];

    final sorted = [...items]..sort((a, b) {
        final byVertical = verticalOf(b).compareTo(verticalOf(a));
        if (byVertical != 0) return byVertical;
        final byDate = recordedAtOf(a).compareTo(recordedAtOf(b));
        if (byDate != 0 || labelOf == null) return byDate;
        return labelOf(a).compareTo(labelOf(b));
      });

    return (limit != null && limit < sorted.length)
        ? sorted.sublist(0, limit)
        : sorted;
  }
}
