import 'package:dunkmax/core/program_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgramProgress', () {
    test('fresh program reports full remaining and 0%', () {
      const p = ProgramProgress(totalSessions: 56, completedSessions: 0);
      expect(p.remaining, 56);
      expect(p.percentComplete, 0);
      expect(p.isComplete, isFalse);
    });

    test('percent rounds to nearest whole', () {
      const p = ProgramProgress(totalSessions: 8, completedSessions: 1);
      // 12.5% -> 13
      expect(p.percentComplete, 13);
    });

    test('finished program is complete at 100%', () {
      const p = ProgramProgress(totalSessions: 40, completedSessions: 40);
      expect(p.percentComplete, 100);
      expect(p.remaining, 0);
      expect(p.isComplete, isTrue);
    });

    test('zero-total never divides by zero', () {
      const p = ProgramProgress(totalSessions: 0, completedSessions: 0);
      expect(p.fraction, 0);
      expect(p.percentComplete, 0);
      expect(p.isComplete, isFalse);
    });

    test('over-completion clamps instead of going past 100% or negative', () {
      const p = ProgramProgress(totalSessions: 10, completedSessions: 15);
      expect(p.fraction, 1.0);
      expect(p.percentComplete, 100);
      expect(p.remaining, 0);
    });
  });
}
