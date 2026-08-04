import 'package:dunkmax/core/flight_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlightTime.heightInches', () {
    test('zero or negative airborne time is zero height', () {
      expect(FlightTime.heightInches(0), 0);
      expect(FlightTime.heightInches(-1), 0);
    });

    test('a known elite vertical (~40") matches its known hang time (~0.91s)', () {
      // t = sqrt(8h/g); for h=40", g=386.09 in/s² => t ≈ 0.9095s.
      const t = 0.9095;
      expect(FlightTime.heightInches(t), closeTo(40, 0.5));
    });

    test('height scales with the square of airborne time', () {
      final h1 = FlightTime.heightInches(0.5);
      final h2 = FlightTime.heightInches(1.0);
      // Doubling time should ~4x the height (h ∝ t²).
      expect(h2 / h1, closeTo(4, 0.001));
    });
  });

  group('FlightTime.isPlausible', () {
    test('rejects too-short and too-long airborne times', () {
      expect(FlightTime.isPlausible(0.05), isFalse);
      expect(FlightTime.isPlausible(2.0), isFalse);
    });

    test('accepts a realistic human vertical-jump hang time', () {
      expect(FlightTime.isPlausible(0.6), isTrue);
    });
  });
}
