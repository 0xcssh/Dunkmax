import 'package:dunkmax/core/flight_time.dart';
import 'package:dunkmax/core/jump_auto_detector.dart';
import 'package:dunkmax/core/models/motion_sample.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a clean clip: [leadInCount] high-energy samples, then
/// [lowCount] low-energy samples, then [leadOutCount] high-energy samples,
/// all spaced [spacingMs] apart starting at t=0.
List<MotionSample> _clip({
  required int leadInCount,
  required int lowCount,
  required int leadOutCount,
  required int spacingMs,
  double highEnergy = 0.8,
  double lowEnergy = 0.05,
}) {
  final samples = <MotionSample>[];
  var index = 0;
  void addRange(int count, double energy) {
    for (var i = 0; i < count; i++) {
      samples.add(
        MotionSample(
          timestamp: Duration(milliseconds: index * spacingMs),
          energy: energy,
        ),
      );
      index++;
    }
  }

  addRange(leadInCount, highEnergy);
  addRange(lowCount, lowEnergy);
  addRange(leadOutCount, highEnergy);
  return samples;
}

void main() {
  group('JumpAutoDetector.detect', () {
    test('clean signal: quiet window bounded by motion is detected', () {
      final samples = _clip(
        leadInCount: 5,
        lowCount: 10,
        leadOutCount: 5,
        spacingMs: 50,
      );

      final result = JumpAutoDetector.detect(samples);

      expect(result, isNotNull);
      expect(result!.takeoff, const Duration(milliseconds: 200));
      expect(result.landing, const Duration(milliseconds: 750));
      expect(result.airborneSeconds, closeTo(0.55, 0.001));
      expect(result.isValid, isTrue);
    });

    test('uniformly high motion with no quiet window returns null', () {
      // Alternating high energies, spaced too tightly for any isolated
      // low-energy sample to bound a plausible airborne duration.
      final samples = <MotionSample>[
        for (var i = 0; i < 20; i++)
          MotionSample(
            timestamp: Duration(milliseconds: i * 50),
            energy: i.isEven ? 0.9 : 0.7,
          ),
      ];

      expect(JumpAutoDetector.detect(samples), isNull);
    });

    test('a quiet run shorter than the minimum airborne time returns null', () {
      // idx0 high, idx1-2 low, idx3-4 high, spaced 40ms apart: the bounded
      // window (idx0 -> idx3) spans 120ms, under FlightTime.minAirborneSeconds
      // (150ms).
      final samples = <MotionSample>[
        const MotionSample(timestamp: Duration(milliseconds: 0), energy: 0.8),
        const MotionSample(timestamp: Duration(milliseconds: 40), energy: 0.05),
        const MotionSample(timestamp: Duration(milliseconds: 80), energy: 0.05),
        const MotionSample(timestamp: Duration(milliseconds: 120), energy: 0.8),
        const MotionSample(timestamp: Duration(milliseconds: 160), energy: 0.8),
      ];

      expect(
        Duration(milliseconds: 120).inMicroseconds /
            Duration.microsecondsPerSecond,
        lessThan(FlightTime.minAirborneSeconds),
      );
      expect(JumpAutoDetector.detect(samples), isNull);
    });

    test('picks the lower-average-energy window among two candidates', () {
      final samples = <MotionSample>[];
      var index = 0;
      void addRange(int count, double energy) {
        for (var i = 0; i < count; i++) {
          samples.add(
            MotionSample(
              timestamp: Duration(milliseconds: index * 50),
              energy: energy,
            ),
          );
          index++;
        }
      }

      addRange(1, 0.8); // idx0: separator
      addRange(10, 0.10); // idx1-10: noisier quiet window
      addRange(1, 0.8); // idx11: separator
      addRange(10, 0.03); // idx12-21: quieter window
      addRange(1, 0.8); // idx22: separator

      final result = JumpAutoDetector.detect(samples);

      expect(result, isNotNull);
      // The quieter (lower average energy) window, idx12-21, bounded by the
      // separators at idx11 and idx22, should win over the noisier one.
      expect(result!.takeoff, const Duration(milliseconds: 550));
      expect(result.landing, const Duration(milliseconds: 1100));
    });

    test('out-of-order input is sorted before detection', () {
      final samples = _clip(
        leadInCount: 5,
        lowCount: 10,
        leadOutCount: 5,
        spacingMs: 50,
      );
      final shuffled = samples.reversed.toList();

      final result = JumpAutoDetector.detect(shuffled);

      expect(result, isNotNull);
      expect(result!.takeoff, const Duration(milliseconds: 200));
      expect(result.landing, const Duration(milliseconds: 750));
      expect(result.airborneSeconds, closeTo(0.55, 0.001));
    });

    test('fewer than three samples returns null', () {
      final samples = [
        const MotionSample(timestamp: Duration.zero, energy: 0.5),
        const MotionSample(timestamp: Duration(milliseconds: 50), energy: 0.5),
      ];

      expect(JumpAutoDetector.detect(samples), isNull);
    });
  });
}
