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

    test(
        'a long, perfectly still pre-jump pause loses to the shorter real '
        'jump window bounded by explosive spikes (regression for the '
        '"reports 1-2 inches" bug)', () {
      // Real-world pattern that was mis-detected: the athlete settles into
      // frame (moderate motion), stands PERFECTLY still for a while gearing
      // up (energy ~0.01 — often quieter than the actual airborne phase,
      // since a still standing body produces almost zero frame difference),
      // then explodes into the jump (spike), is airborne with low-but-real
      // motion from the body translating through frame (energy ~0.07,
      // noticeably above the stillness), then lands (spike), then settles.
      final samples = <MotionSample>[
        const MotionSample(timestamp: Duration(milliseconds: 0), energy: 0.5), // settling in
        for (var i = 1; i <= 7; i++)
          MotionSample(timestamp: Duration(milliseconds: i * 50), energy: 0.01), // standing still, 350ms
        const MotionSample(timestamp: Duration(milliseconds: 400), energy: 0.85), // takeoff drive
        for (var i = 9; i <= 14; i++)
          MotionSample(timestamp: Duration(milliseconds: i * 50), energy: 0.07), // airborne, 300ms
        const MotionSample(timestamp: Duration(milliseconds: 750), energy: 0.9), // landing impact
        const MotionSample(timestamp: Duration(milliseconds: 800), energy: 0.3), // settling after
      ];

      final result = JumpAutoDetector.detect(samples);

      expect(result, isNotNull);
      // Must land on the real jump window (400ms -> 750ms), not the
      // stiller-but-irrelevant pre-jump pause (0ms -> 400ms).
      expect(result!.takeoff, const Duration(milliseconds: 400));
      expect(result.landing, const Duration(milliseconds: 750));
    });

    test('a plausible-but-sub-4" window is discarded by the stricter auto-detection floor', () {
      // 250ms is within FlightTime's global plausible range (>=150ms) but
      // below the auto-detector's own stricter floor (280ms) — should not
      // be selected even as the only candidate.
      final samples = <MotionSample>[
        const MotionSample(timestamp: Duration(milliseconds: 0), energy: 0.8),
        const MotionSample(timestamp: Duration(milliseconds: 50), energy: 0.05),
        const MotionSample(timestamp: Duration(milliseconds: 100), energy: 0.05),
        const MotionSample(timestamp: Duration(milliseconds: 150), energy: 0.05),
        const MotionSample(timestamp: Duration(milliseconds: 200), energy: 0.05),
        const MotionSample(timestamp: Duration(milliseconds: 250), energy: 0.8),
      ];

      expect(JumpAutoDetector.detect(samples), isNull);
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

  group('JumpAutoDetector.detectWithDiagnostics', () {
    test('reports sample stats and every plausible candidate, with the winner flagged', () {
      final samples = _clip(
        leadInCount: 5,
        lowCount: 10,
        leadOutCount: 5,
        spacingMs: 50,
      );

      final diagnostics = JumpAutoDetector.detectWithDiagnostics(samples);

      expect(diagnostics.sampleCount, samples.length);
      expect(diagnostics.minEnergy, 0.05);
      expect(diagnostics.maxEnergy, 0.8);
      expect(diagnostics.candidates, isNotEmpty);
      expect(diagnostics.result, isNotNull);

      final chosen = diagnostics.candidates.where((c) => c.chosen);
      expect(chosen, hasLength(1));
      expect(chosen.first.takeoff, diagnostics.result!.takeoff);
      expect(chosen.first.landing, diagnostics.result!.landing);
    });

    test('empty input yields JumpDetectionDiagnostics.empty-shaped output', () {
      final diagnostics = JumpAutoDetector.detectWithDiagnostics(const []);
      expect(diagnostics.sampleCount, 0);
      expect(diagnostics.candidates, isEmpty);
      expect(diagnostics.result, isNull);
    });

    test('detect() and detectWithDiagnostics().result always agree', () {
      final samples = _clip(leadInCount: 5, lowCount: 10, leadOutCount: 5, spacingMs: 50);
      final viaDetect = JumpAutoDetector.detect(samples);
      final viaDiagnostics = JumpAutoDetector.detectWithDiagnostics(samples).result;
      expect(viaDetect, isNotNull);
      expect(viaDetect!.takeoff, viaDiagnostics!.takeoff);
      expect(viaDetect.landing, viaDiagnostics.landing);

      expect(JumpAutoDetector.detect(const []), isNull);
      expect(JumpAutoDetector.detectWithDiagnostics(const []).result, isNull);
    });
  });

  group('JumpAutoDetector alternative estimates', () {
    test('the reported result is always the outer-bound reading', () {
      final samples =
          _clip(leadInCount: 5, lowCount: 10, leadOutCount: 5, spacingMs: 50);
      final diagnostics = JumpAutoDetector.detectWithDiagnostics(samples);

      expect(diagnostics.result, isNotNull);
      expect(diagnostics.estimates.outerBoundSeconds, isNotNull);
      expect(
        diagnostics.estimates.outerBoundSeconds!,
        closeTo(diagnostics.result!.airborneSeconds, 1e-9),
      );
    });

    test('threshold-crossing reading never exceeds the outer bound', () {
      // The outer bound takes the samples just outside the quiet run, so it
      // includes up to a full sample step of ground phase at each end; the
      // interpolated crossing lands inside that span by construction.
      final samples =
          _clip(leadInCount: 4, lowCount: 12, leadOutCount: 4, spacingMs: 40);
      final estimates = JumpAutoDetector.detectWithDiagnostics(samples).estimates;

      expect(estimates.crossingSeconds, isNotNull);
      expect(
        estimates.crossingSeconds!,
        lessThanOrEqualTo(estimates.outerBoundSeconds!),
      );
      expect(estimates.crossingSeconds!, greaterThan(0));
    });

    test('apex-symmetry reading is positive and physically plausible', () {
      final samples =
          _clip(leadInCount: 4, lowCount: 12, leadOutCount: 4, spacingMs: 40);
      final estimates = JumpAutoDetector.detectWithDiagnostics(samples).estimates;

      expect(estimates.apexSymmetrySeconds, isNotNull);
      expect(estimates.apexSymmetrySeconds!, greaterThan(0));
    });

    test('no window found leaves every estimate null', () {
      // Uniform energy: nothing stands out as a quiet flight phase.
      final flat = [
        for (var i = 0; i < 10; i++)
          MotionSample(
            timestamp: Duration(milliseconds: i * 50),
            energy: 0.5,
          ),
      ];
      final diagnostics = JumpAutoDetector.detectWithDiagnostics(flat);

      if (diagnostics.result == null) {
        expect(diagnostics.estimates.outerBoundSeconds, isNull);
        expect(diagnostics.estimates.crossingSeconds, isNull);
        expect(diagnostics.estimates.apexSymmetrySeconds, isNull);
      }
    });
  });
}
