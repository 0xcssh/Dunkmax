import 'package:dunkmax/core/models/jump_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JumpMeasurement', () {
    test('a plausible mark pair yields a positive vertical', () {
      final m = JumpMeasurement(
        takeoff: const Duration(milliseconds: 1000),
        landing: const Duration(milliseconds: 1600), // 0.6s airborne
      );
      expect(m.isValid, isTrue);
      expect(m.verticalInches, greaterThan(0));
    });

    test('landing before or equal to takeoff is invalid', () {
      final same = JumpMeasurement(
        takeoff: const Duration(milliseconds: 500),
        landing: const Duration(milliseconds: 500),
      );
      final backwards = JumpMeasurement(
        takeoff: const Duration(milliseconds: 900),
        landing: const Duration(milliseconds: 500),
      );
      expect(same.isValid, isFalse);
      expect(same.verticalInches, 0);
      expect(backwards.isValid, isFalse);
    });

    test('an implausibly long airborne time is invalid (bad marks)', () {
      final m = JumpMeasurement(
        takeoff: Duration.zero,
        landing: const Duration(seconds: 3),
      );
      expect(m.isValid, isFalse);
      expect(m.verticalInches, 0);
    });
  });
}
