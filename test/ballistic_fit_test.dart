import 'dart:math' as math;

import 'package:dunkmax/core/ballistic_fit.dart';
import 'package:dunkmax/core/flight_time.dart';
import 'package:flutter_test/flutter_test.dart';

const _groundY = 900.0;

/// Samples a real flight arc in image coordinates.
///
/// [pixelsPerMetre] sets the scene scale; the arc is then generated from
/// physics alone, so the fit has to recover both the timing and that scale.
/// Sampling starts at [startOffsetMs] into the flight and steps every
/// [stepMs] — deliberately never landing on takeoff or landing, which is the
/// whole point of fitting rather than frame-hunting.
List<({double seconds, double y})> _arc({
  required double flightSeconds,
  double pixelsPerMetre = 300,
  int stepMs = 40,
  int startOffsetMs = 17,
  double clipStartSeconds = 0,
  double Function(int index)? noise,
}) {
  final samples = <({double seconds, double y})>[];
  final g = 9.81 * pixelsPerMetre; // px/s²
  final halfT = flightSeconds / 2;
  var index = 0;

  for (var ms = startOffsetMs;
      ms < flightSeconds * 1000;
      ms += stepMs, index++) {
    final t = ms / 1000.0;
    // Rise above ground: starts and ends at 0, apex at t = halfT.
    final lift = 0.5 * g * (halfT * halfT - (t - halfT) * (t - halfT));
    samples.add((
      seconds: clipStartSeconds + t,
      y: _groundY - lift + (noise?.call(index) ?? 0),
    ));
  }
  return samples;
}

void main() {
  group('BallisticFit.fit', () {
    test('recovers the flight time of a clean arc', () {
      final fit = BallisticFit.fit(_arc(flightSeconds: 0.770))!;

      expect(fit.airborneSeconds(_groundY), closeTo(0.770, 0.002));
    });

    test('recovers gravity, and so the scene scale, from the curvature alone',
        () {
      final fit = BallisticFit.fit(
        _arc(flightSeconds: 0.770, pixelsPerMetre: 420),
      )!;

      expect(fit.pixelsPerMetre, closeTo(420, 1));
      expect(fit.gravityPixelsPerSecSq, closeTo(9.81 * 420, 10));
    });

    test('is unaffected by where in the clip the jump happens', () {
      // Raw timestamps late in a clip make the normal equations badly
      // conditioned; the fit re-centres time to avoid that.
      final early = BallisticFit.fit(_arc(flightSeconds: 0.770))!;
      final late = BallisticFit.fit(
        _arc(flightSeconds: 0.770, clipStartSeconds: 47),
      )!;

      expect(
        late.airborneSeconds(_groundY),
        closeTo(early.airborneSeconds(_groundY)!, 0.005),
      );
    });

    test('needs no sample near takeoff or landing', () {
      // Only the middle of the arc: the first sample lands 220 ms after
      // takeoff and sampling stops well before landing. Frame-crossing
      // methods have nothing to work with here; the parabola is fully
      // determined regardless.
      final full = _arc(flightSeconds: 0.770);
      final middle = full
          .where((s) => s.seconds > 0.22 && s.seconds < 0.55)
          .toList();

      expect(middle.length, greaterThanOrEqualTo(4));
      final fit = BallisticFit.fit(middle)!;

      expect(fit.airborneSeconds(_groundY), closeTo(0.770, 0.02));
    });

    test('survives a coarse sample rate', () {
      // ~10 samples per second, the order the app actually achieves, and far
      // below the 240 fps the flight-time literature asks for when the
      // takeoff and landing frames have to be identified directly.
      final fit = BallisticFit.fit(
        _arc(flightSeconds: 0.770, stepMs: 100),
      )!;

      expect(fit.airborneSeconds(_groundY), closeTo(0.770, 0.01));
    });

    test('landmark jitter degrades the answer gracefully, not catastrophically',
        () {
      // +/- 6 px of alternating landmark noise on every sample.
      final fit = BallisticFit.fit(
        _arc(
          flightSeconds: 0.770,
          noise: (i) => i.isEven ? 6.0 : -6.0,
        ),
      )!;

      expect(fit.airborneSeconds(_groundY), closeTo(0.770, 0.03));
      expect(fit.rmsResidualPixels, greaterThan(1));
    });

    test('a clean arc has a near-zero residual and a noisy one does not', () {
      final clean = BallisticFit.fit(_arc(flightSeconds: 0.770))!;
      final noisy = BallisticFit.fit(
        _arc(flightSeconds: 0.770, noise: (i) => i.isEven ? 9.0 : -9.0),
      )!;

      expect(clean.rmsResidualPixels, lessThan(0.5));
      expect(noisy.rmsResidualPixels, greaterThan(clean.rmsResidualPixels));
    });

    test('the fitted flight time reproduces the expected jump height', () {
      // 0.770 s of hang is ~28.6" by h = g·T²/8 — the value this clip's
      // ground truth was independently measured at.
      final fit = BallisticFit.fit(_arc(flightSeconds: 0.770))!;
      final seconds = fit.airborneSeconds(_groundY)!;

      expect(FlightTime.heightInches(seconds), closeTo(28.6, 0.5));
    });

    test('apex is the top of the arc, halfway through the flight', () {
      final fit = BallisticFit.fit(_arc(flightSeconds: 0.770))!;

      expect(fit.apexSeconds, closeTo(0.385, 0.01));
      expect(fit.apexY, lessThan(_groundY));
    });

    test('returns null with too few samples to judge a fit by', () {
      final arc = _arc(flightSeconds: 0.770);

      expect(BallisticFit.fit(arc.take(3).toList()), isNull);
      expect(BallisticFit.fit(const []), isNull);
    });

    test('returns null when every sample shares a timestamp', () {
      final degenerate = [
        for (var i = 0; i < 6; i++) (seconds: 1.0, y: 800.0 + i),
      ];

      expect(BallisticFit.fit(degenerate), isNull);
    });

    test('an arc that never reaches the ground yields no airborne time', () {
      final fit = BallisticFit.fit(_arc(flightSeconds: 0.770))!;

      // Ask where it crosses a line above the apex: it never does.
      expect(fit.airborneSeconds(fit.apexY - 50), isNull);
    });

    test('a downward-curving arc is not a jump', () {
      // A body that accelerates upward is not in free flight; a fits <= 0
      // must never produce a duration.
      final inverted = [
        for (var i = 0; i < 8; i++)
          (seconds: i * 0.04, y: 900.0 + math.pow(i * 0.04, 2) * -1000),
      ];
      final fit = BallisticFit.fit(inverted)!;

      expect(fit.a, lessThan(0));
      expect(fit.airborneSeconds(_groundY), isNull);
    });
  });
}
