import 'package:dunkmax/core/leaderboard.dart';
import 'package:dunkmax/core/models/jump_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

JumpLogEntry _entry(int inches, DateTime at) =>
    JumpLogEntry(verticalInches: inches, recordedAt: at);

void main() {
  group('Leaderboard.rank', () {
    test('empty list returns no rows', () {
      expect(Leaderboard.rank(const []), isEmpty);
    });

    test('orders best vertical first and numbers ranks from 1', () {
      final ranked = Leaderboard.rank([
        _entry(24, DateTime(2026, 8, 1)),
        _entry(31, DateTime(2026, 8, 2)),
        _entry(28, DateTime(2026, 8, 3)),
      ]);

      expect(ranked.map((r) => r.rank), [1, 2, 3]);
      expect(ranked.map((r) => r.entry.verticalInches), [31, 28, 24]);
    });

    test('ties are broken by the earlier recording, which keeps the better rank', () {
      final earlier = _entry(30, DateTime(2026, 7, 1));
      final later = _entry(30, DateTime(2026, 8, 1));

      // Input order must not matter — the result is deterministic.
      final ranked = Leaderboard.rank([later, earlier]);

      expect(ranked[0].entry.recordedAt, earlier.recordedAt);
      expect(ranked[1].entry.recordedAt, later.recordedAt);
      expect(Leaderboard.rank([earlier, later])[0].entry.recordedAt,
          earlier.recordedAt);
    });

    test('limit caps the number of rows, keeping the best ones', () {
      final ranked = Leaderboard.rank(
        [
          _entry(20, DateTime(2026, 8, 1)),
          _entry(33, DateTime(2026, 8, 2)),
          _entry(27, DateTime(2026, 8, 3)),
          _entry(29, DateTime(2026, 8, 4)),
        ],
        limit: 2,
      );

      expect(ranked, hasLength(2));
      expect(ranked.map((r) => r.entry.verticalInches), [33, 29]);
      expect(ranked.map((r) => r.rank), [1, 2]);
    });

    test('a limit larger than the history returns everything', () {
      final ranked = Leaderboard.rank(
        [_entry(22, DateTime(2026, 8, 1))],
        limit: 10,
      );
      expect(ranked, hasLength(1));
    });

    test('a non-positive limit returns no rows', () {
      final entries = [_entry(22, DateTime(2026, 8, 1))];
      expect(Leaderboard.rank(entries, limit: 0), isEmpty);
      expect(Leaderboard.rank(entries, limit: -3), isEmpty);
    });

    test('does not mutate the caller list', () {
      final entries = [
        _entry(20, DateTime(2026, 8, 1)),
        _entry(30, DateTime(2026, 8, 2)),
      ];
      Leaderboard.rank(entries);
      expect(entries.first.verticalInches, 20);
    });
  });
}
