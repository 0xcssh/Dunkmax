import 'package:dunkmax/core/models/leaderboard_athlete.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  Object? athleteId = 'athlete-1',
  Object? displayName = 'Marcus',
  Object? verticalInches = 43,
  Object? heightInches = 68,
  Object? recordedAt = '2026-08-01T10:00:00Z',
}) =>
    {
      'athlete_id': athleteId,
      'display_name': displayName,
      'vertical_inches': verticalInches,
      'height_inches': heightInches,
      'recorded_at': recordedAt,
    };

void main() {
  group('LeaderboardAthlete.fromMap', () {
    test('parses a well-formed row', () {
      final athlete = LeaderboardAthlete.fromMap(_row());

      expect(athlete, isNotNull);
      expect(athlete!.athleteId, 'athlete-1');
      expect(athlete.displayName, 'Marcus');
      expect(athlete.verticalInches, 43);
      expect(athlete.heightInches, 68);
      expect(athlete.recordedAt.toUtc(), DateTime.utc(2026, 8, 1, 10));
    });

    test('accepts numbers that arrive as doubles or strings', () {
      final fromDouble =
          LeaderboardAthlete.fromMap(_row(verticalInches: 43.0));
      final fromString =
          LeaderboardAthlete.fromMap(_row(heightInches: '68'));

      expect(fromDouble?.verticalInches, 43);
      expect(fromString?.heightInches, 68);
    });

    test('drops rows with a missing or ill-typed field', () {
      expect(LeaderboardAthlete.fromMap(const {}), isNull);
      expect(LeaderboardAthlete.fromMap(_row(displayName: null)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(displayName: 42)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(verticalInches: null)), isNull);
      expect(
        LeaderboardAthlete.fromMap(_row(verticalInches: 'not a number')),
        isNull,
      );
      expect(LeaderboardAthlete.fromMap(_row(heightInches: null)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(recordedAt: null)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(recordedAt: 'yesterday')), isNull);
    });

    test('drops implausible measurements rather than showing them', () {
      expect(LeaderboardAthlete.fromMap(_row(verticalInches: 0)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(verticalInches: 500)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(heightInches: 2)), isNull);
      expect(LeaderboardAthlete.fromMap(_row(heightInches: 300)), isNull);
    });

    test('a blank name is not a row', () {
      expect(LeaderboardAthlete.fromMap(_row(displayName: '   ')), isNull);
    });

    test('a missing athlete id still yields a usable row', () {
      final athlete = LeaderboardAthlete.fromMap(_row(athleteId: null));
      expect(athlete, isNotNull);
      expect(athlete!.athleteId, isNull);
    });

    test('round-trips through toMap', () {
      final original = LeaderboardAthlete.fromMap(_row())!;
      final again = LeaderboardAthlete.fromMap(original.toMap())!;

      expect(again.displayName, original.displayName);
      expect(again.verticalInches, original.verticalInches);
      expect(again.heightInches, original.heightInches);
      expect(again.recordedAt.toUtc(), original.recordedAt.toUtc());
      expect(again.athleteId, original.athleteId);
    });
  });

  group('LeaderboardAthlete.sanitizeDisplayName', () {
    test('trims and collapses whitespace', () {
      expect(LeaderboardAthlete.sanitizeDisplayName('  Big   Mike  '),
          'Big Mike');
    });

    test('rejects names that are empty once trimmed', () {
      expect(LeaderboardAthlete.sanitizeDisplayName(''), isNull);
      expect(LeaderboardAthlete.sanitizeDisplayName('   \n\t '), isNull);
    });

    test('strips control characters', () {
      final withBell = 'Mar${String.fromCharCode(7)}cus';
      expect(LeaderboardAthlete.sanitizeDisplayName(withBell), 'Mar cus');
    });

    test('caps the length', () {
      final long = 'A' * 40;
      final sanitized = LeaderboardAthlete.sanitizeDisplayName(long);
      expect(sanitized, hasLength(LeaderboardAthlete.maxDisplayNameLength));
    });
  });

  group('formatting', () {
    test('height reads as feet and inches', () {
      expect(LeaderboardAthlete.formatHeight(68), "5'8\"");
      expect(LeaderboardAthlete.formatHeight(72), "6'0\"");
      expect(LeaderboardAthlete.formatHeight(0), "0'0\"");
      expect(LeaderboardAthlete.formatHeight(-5), "0'0\"");
    });

    test('vertical reads as inches', () {
      final athlete = LeaderboardAthlete.fromMap(_row())!;
      expect(athlete.formattedVertical, '43" vert');
      expect(athlete.formattedHeight, "5'8\"");
    });
  });
}
