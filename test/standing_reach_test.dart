import 'package:dunkmax/core/standing_reach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('plausibility', () {
    test('accepts values inside the bounds, inclusive', () {
      expect(StandingReach.isPlausible(StandingReach.minInches), isTrue);
      expect(StandingReach.isPlausible(StandingReach.maxInches), isTrue);
      expect(StandingReach.isPlausible(97), isTrue);
    });

    test('rejects values a human could not have measured', () {
      expect(StandingReach.isPlausible(StandingReach.minInches - 1), isFalse);
      expect(StandingReach.isPlausible(StandingReach.maxInches + 1), isFalse);
      expect(StandingReach.isPlausible(0), isFalse);
      expect(StandingReach.isPlausible(-5), isFalse);
    });
  });

  group('clampInches', () {
    test('leaves in-range values alone', () {
      expect(StandingReach.clampInches(97), 97);
    });

    test('pulls out-of-range values to the nearest bound', () {
      expect(StandingReach.clampInches(0), StandingReach.minInches);
      expect(StandingReach.clampInches(500), StandingReach.maxInches);
    });
  });

  group('sanitize', () {
    test('passes null through', () {
      expect(StandingReach.sanitize(null), isNull);
    });

    test('keeps a plausible measurement', () {
      expect(StandingReach.sanitize(97), 97);
    });

    test('drops an implausible one so callers fall back to the estimate', () {
      expect(StandingReach.sanitize(0), isNull);
      expect(StandingReach.sanitize(400), isNull);
    });
  });

  test('label renders feet and inches', () {
    expect(StandingReach.label(97), "8'1\"");
    expect(StandingReach.label(96), "8'0\"");
  });
}
