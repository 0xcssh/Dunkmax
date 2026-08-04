import 'package:dunkmax/core/jump_trend.dart';
import 'package:dunkmax/core/models/jump_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JumpTrendCalculator.compute', () {
    test('empty list returns null', () {
      expect(JumpTrendCalculator.compute(const []), isNull);
    });

    test('single entry has zero delta and is not improving', () {
      final entry = JumpLogEntry(verticalInches: 24, recordedAt: DateTime(2026, 8, 1));
      final trend = JumpTrendCalculator.compute([entry]);
      expect(trend, isNotNull);
      expect(trend!.latestVerticalInches, 24);
      expect(trend.deltaFromFirstInches, 0);
      expect(trend.isImproving, isFalse);
    });

    test('multiple entries out of chronological order still resolve correct first/latest', () {
      final entries = [
        JumpLogEntry(verticalInches: 26, recordedAt: DateTime(2026, 8, 3)),
        JumpLogEntry(verticalInches: 22, recordedAt: DateTime(2026, 8, 1)),
        JumpLogEntry(verticalInches: 24, recordedAt: DateTime(2026, 8, 2)),
      ];
      final trend = JumpTrendCalculator.compute(entries);
      expect(trend, isNotNull);
      expect(trend!.latestVerticalInches, 26);
      expect(trend.latestRecordedAt, DateTime(2026, 8, 3));
      expect(trend.deltaFromFirstInches, 4); // 26 - 22
    });

    test('positive delta means isImproving is true', () {
      final entries = [
        JumpLogEntry(verticalInches: 20, recordedAt: DateTime(2026, 7, 1)),
        JumpLogEntry(verticalInches: 25, recordedAt: DateTime(2026, 8, 1)),
      ];
      final trend = JumpTrendCalculator.compute(entries);
      expect(trend!.deltaFromFirstInches, 5);
      expect(trend.isImproving, isTrue);
    });

    test('negative delta means isImproving is false', () {
      final entries = [
        JumpLogEntry(verticalInches: 25, recordedAt: DateTime(2026, 7, 1)),
        JumpLogEntry(verticalInches: 21, recordedAt: DateTime(2026, 8, 1)),
      ];
      final trend = JumpTrendCalculator.compute(entries);
      expect(trend!.deltaFromFirstInches, -4);
      expect(trend.isImproving, isFalse);
    });
  });
}
