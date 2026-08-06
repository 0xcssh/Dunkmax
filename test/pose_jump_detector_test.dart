import 'dart:math' as math;

import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const _groundY = 900.0;
const _torso = 200.0;

/// Builds a synthetic clip of a jump with a *known* flight time.
///
/// The athlete stands still (feet exactly on [_groundY]) for [leadInMs], is
/// airborne for [flightMs] following the real parabola `lift(τ) = H · (1 −
/// (2τ/T − 1)²)`, then stands still again for [leadOutMs]. Samples are taken
/// every [stepMs] from t = 0 — deliberately *not* aligned with takeoff or
/// landing, so the detector has to interpolate the crossings rather than
/// stumble onto them.
///
/// [peakLiftPixels] is the apex foot lift, defaulting to a lift consistent
/// with a real jump: a 6'1" athlete has a ~200 px torso here, and a ~28" jump
/// is roughly 1.35 torso lengths.
List<PoseSample> _jumpClip({
  int leadInMs = 800,
  int flightMs = 770,
  int leadOutMs = 800,
  int stepMs = 40,
  double peakLiftPixels = 270,
  bool Function(int index)? dropDetection,
}) {
  final samples = <PoseSample>[];
  final totalMs = leadInMs + flightMs + leadOutMs;
  final takeoffMs = leadInMs;
  final landingMs = leadInMs + flightMs;

  var index = 0;
  for (var t = 0; t <= totalMs; t += stepMs, index++) {
    double footY;
    if (t <= takeoffMs || t >= landingMs) {
      footY = _groundY;
    } else {
      final phase = (t - takeoffMs) / flightMs; // 0..1
      final lift = peakLiftPixels * (1 - math.pow(2 * phase - 1, 2));
      footY = _groundY - lift;
    }

    final dropped = dropDetection?.call(index) ?? false;
    samples.add(
      PoseSample(
        timestamp: Duration(milliseconds: t),
        footY: dropped ? null : footY,
        torsoPixels: dropped ? null : _torso,
      ),
    );
  }
  return samples;
}

List<PoseSample> _standingClip({int count = 40, int stepMs = 40}) {
  return [
    for (var i = 0; i < count; i++)
      PoseSample(
        timestamp: Duration(milliseconds: i * stepMs),
        // A little landmark jitter, well under the detection threshold.
        footY: _groundY + (i.isEven ? 1.5 : -1.5),
        torsoPixels: _torso,
      ),
  ];
}

void main() {
  group('PoseJumpDetector.detect', () {
    test('recovers a known flight time from a clean parabolic jump', () {
      final d = PoseJumpDetector.detectWithDiagnostics(_jumpClip());

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.result, isNotNull);
      // The whole point of interpolating the crossings and correcting the
      // threshold bias: land within a few milliseconds of the truth, not
      // within a sample step (40 ms) of it.
      expect(d.correctedSeconds, closeTo(0.770, 0.02));
      expect(d.result!.airborneSeconds, closeTo(0.770, 0.02));
      expect(d.result!.isValid, isTrue);
      // 0.77 s → g·t²/8 ≈ 28.6"
      expect(d.result!.verticalInches, inInclusiveRange(28, 30));
    });

    test('recovers a shorter jump just as accurately', () {
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(flightMs: 420, peakLiftPixels: 120),
      );

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.correctedSeconds, closeTo(0.420, 0.02));
    });

    test('raw crossings are short and the parabola correction fixes them', () {
      final d = PoseJumpDetector.detectWithDiagnostics(_jumpClip());

      expect(d.rawCrossingSeconds, isNotNull);
      // The threshold sits above the ground, so the crossings are strictly
      // inside the real window.
      expect(d.rawCrossingSeconds! < 0.770, isTrue);
      expect(d.correctedSeconds! > d.rawCrossingSeconds!, isTrue);
    });

    test('places the ground baseline and threshold from the athlete scale', () {
      final d = PoseJumpDetector.detectWithDiagnostics(_jumpClip());

      expect(d.groundBaselineY, closeTo(_groundY, 1));
      expect(
        d.liftThresholdPixels,
        closeTo(_torso * PoseJumpDetector.liftTorsoFraction, 0.001),
      );
      expect(d.thresholdY, closeTo(_groundY - d.liftThresholdPixels, 1));
      expect(d.peakLiftPixels, closeTo(270, 5));
    });

    test('is invariant to how far the athlete is from the camera', () {
      final near = PoseJumpDetector.detectWithDiagnostics(_jumpClip());
      // Same jump, athlete filmed at half the pixel size: every distance
      // halves, including the torso the threshold is expressed against.
      final far = PoseJumpDetector.detectWithDiagnostics([
        for (final s in _jumpClip())
          PoseSample(
            timestamp: s.timestamp,
            footY: s.footY == null ? null : s.footY! / 2,
            torsoPixels: s.torsoPixels == null ? null : s.torsoPixels! / 2,
          ),
      ]);

      expect(far.rejection, PoseDetectionRejection.none);
      expect(far.correctedSeconds, closeTo(near.correctedSeconds!, 0.005));
    });

    test('out-of-order samples are sorted before anything is measured', () {
      final ordered = _jumpClip();
      final shuffled = [...ordered]..shuffle(math.Random(7));

      final a = PoseJumpDetector.detectWithDiagnostics(ordered);
      final b = PoseJumpDetector.detectWithDiagnostics(shuffled);

      expect(b.rejection, PoseDetectionRejection.none);
      expect(b.correctedSeconds, closeTo(a.correctedSeconds!, 1e-9));
      expect(b.result!.takeoff, a.result!.takeoff);
      expect(b.result!.landing, a.result!.landing);
      expect(
        b.samples.map((s) => s.timestamp).toList(),
        ordered.map((s) => s.timestamp).toList(),
      );
    });

    test('bridges scattered missing detections', () {
      // Drop roughly every 6th frame, including frames inside the flight.
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(dropDetection: (i) => i % 6 == 3),
      );

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.missingCount, greaterThan(0));
      expect(d.detectedCount, lessThan(d.sampleCount));
      // Missing frames coarsen the interpolation but must not break the run.
      expect(d.correctedSeconds, closeTo(0.770, 0.05));
    });

    test('rejects a clip where the athlete is rarely detected', () {
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(dropDetection: (i) => i % 2 == 0),
      );

      expect(d.rejection, PoseDetectionRejection.tooManyMissing);
      expect(d.result, isNull);
    });

    test('rejects a clip with too few sampled frames', () {
      final samples = _jumpClip().take(PoseJumpDetector.minSamples - 1).toList();
      final d = PoseJumpDetector.detectWithDiagnostics(samples);

      expect(d.rejection, PoseDetectionRejection.tooFewSamples);
      expect(d.result, isNull);
    });

    test('rejects an empty series', () {
      final d = PoseJumpDetector.detectWithDiagnostics(const []);
      expect(d.result, isNull);
      expect(d.rejection, PoseDetectionRejection.tooFewSamples);
    });

    test('rejects a clip where the athlete never leaves the ground', () {
      final d = PoseJumpDetector.detectWithDiagnostics(_standingClip());

      expect(d.rejection, PoseDetectionRejection.noAirborneWindow);
      expect(d.result, isNull);
      // It still reports what it saw, so a bad clip is diagnosable.
      expect(d.detectedCount, 40);
      expect(d.groundBaselineY, closeTo(_groundY, 2));
    });

    test('rejects a hop too small to time reliably', () {
      // Peak lift only ~1.2x the threshold: the parabola correction would be
      // dominated by noise, so no number is better than a wrong number.
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(flightMs: 400, peakLiftPixels: 24),
      );

      expect(d.rejection, PoseDetectionRejection.liftTooSmall);
      expect(d.result, isNull);
    });

    test('rejects an implausibly long airborne window', () {
      // 1.6 s of hang time would be ~124" — physically impossible.
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(flightMs: 1600, peakLiftPixels: 600),
      );

      expect(d.rejection, PoseDetectionRejection.implausibleDuration);
      expect(d.result, isNull);
    });

    test('refuses a clip with two comparable airborne windows', () {
      // Two back-to-back jumps: which one did the athlete mean?
      final first = _jumpClip(leadInMs: 600, flightMs: 600, leadOutMs: 200);
      final second = _jumpClip(leadInMs: 200, flightMs: 600, leadOutMs: 600);
      final offsetMs = first.last.timestamp.inMilliseconds + 40;
      final combined = [
        ...first,
        for (final s in second)
          PoseSample(
            timestamp: s.timestamp + Duration(milliseconds: offsetMs),
            footY: s.footY,
            torsoPixels: s.torsoPixels,
          ),
      ];

      final d = PoseJumpDetector.detectWithDiagnostics(combined);
      expect(d.rejection, PoseDetectionRejection.ambiguousWindows);
      expect(d.result, isNull);
    });

    test('ignores a flight that runs off the end of the clip', () {
      // Clip ends mid-air: the landing was never filmed, so there is nothing
      // to time.
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(leadOutMs: 0).where((s) {
          return s.timestamp.inMilliseconds < 800 + 400;
        }).toList(),
      );

      expect(d.result, isNull);
      expect(d.rejection, PoseDetectionRejection.noAirborneWindow);
    });

    test('detect() is the diagnostics result', () {
      final samples = _jumpClip();
      expect(
        PoseJumpDetector.detect(samples)!.airborneSeconds,
        PoseJumpDetector.detectWithDiagnostics(samples).result!.airborneSeconds,
      );
    });
  });
}
