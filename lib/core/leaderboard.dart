import 'models/jump_log_entry.dart';

/// One row of a ranked board: a jump plus the position it earned.
class RankedJump {
  /// 1-based position on the board (1 = best).
  final int rank;
  final JumpLogEntry entry;

  const RankedJump({required this.rank, required this.entry});
}

/// Pure ranking over a jump history — the athlete's personal leaderboard.
///
/// There is no backend and no user accounts, so the only honest board we can
/// build is one over the user's OWN logged jumps (see CLAUDE.md: no
/// fabricated social proof). Deterministic: best vertical first, ties broken
/// by the earlier `recordedAt` so the athlete who hit the number first keeps
/// the better rank.
abstract class Leaderboard {
  /// Ranks [entries] best-first. [limit] caps the returned rows (a
  /// non-positive limit returns nothing); omit it to rank everything.
  static List<RankedJump> rank(List<JumpLogEntry> entries, {int? limit}) {
    if (limit != null && limit <= 0) return const [];

    final sorted = [...entries]..sort((a, b) {
        final byVertical = b.verticalInches.compareTo(a.verticalInches);
        if (byVertical != 0) return byVertical;
        return a.recordedAt.compareTo(b.recordedAt);
      });

    final capped = (limit != null && limit < sorted.length)
        ? sorted.sublist(0, limit)
        : sorted;

    return [
      for (var i = 0; i < capped.length; i++)
        RankedJump(rank: i + 1, entry: capped[i]),
    ];
  }
}
