import 'dart:math' as math;

import 'package:dunkmax/core/jump_analysis_pipeline.dart';
import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// A synthetic athlete filmed for [durationMs]: standing, one jump of
/// [flightMs] starting at [takeoffMs], standing again.
///
/// The jump is *physically consistent*: the apex lift in pixels follows from
/// the flight time (`h = g·T²/8`) and the athlete's size in frame, a torso
/// being about 0.53 m. That matters — gravity fixes how fast a foot falls away
/// from the apex, and a detector tuned on a lift that is too generous for its
/// flight time passes tests a real clip fails.
class _Clip {
  final int durationMs;
  final int takeoffMs;
  final int flightMs;
  final double torso;
  final double driftPixelsPerSecond;
  final double jitterPixels;

  /// Frames the sampler was asked for, across every pass.
  int framesRequested = 0;

  _Clip({
    required this.durationMs,
    required this.takeoffMs,
    this.flightMs = 550,
    this.torso = 190,
    this.driftPixelsPerSecond = 0,
    this.jitterPixels = 1.5,
  });

  double get flightSeconds => flightMs / 1000;

  double get peakLiftPixels =>
      9.81 * flightSeconds * flightSeconds / 8 * torso / 0.53;

  PoseSample at(Duration timestamp) {
    final t = timestamp.inMilliseconds;
    final ground = 900 + driftPixelsPerSecond * t / 1000;
    var lift = 0.0;
    if (t > takeoffMs && t < takeoffMs + flightMs) {
      final phase = (t - takeoffMs) / flightMs;
      lift = peakLiftPixels * (1 - math.pow(2 * phase - 1, 2));
    }
    // Deterministic landmark jitter, so a failure reproduces.
    final jitter = jitterPixels * math.sin(t * 0.37);
    return PoseSample(
      timestamp: timestamp,
      footY: ground - lift + jitter,
      torsoPixels: torso,
    );
  }

  Future<List<PoseSample>> sample(List<Duration> timestamps) async {
    framesRequested += timestamps.length;
    return [
      for (final t in timestamps)
        if (t.inMilliseconds >= 0 && t.inMilliseconds < durationMs) at(t),
    ];
  }

  Future<PoseJumpDiagnostics> analyze({int? fromMs, int? toMs}) =>
      JumpAnalysisPipeline.run(
        rangeStart: Duration(milliseconds: fromMs ?? 0),
        rangeEnd: Duration(milliseconds: toMs ?? durationMs),
        clipDuration: Duration(milliseconds: durationMs),
        sample: sample,
      );
}

/// Mean gap between consecutive samples of the series a result came from.
double _stepMs(PoseJumpDiagnostics d) =>
    (d.samples.last.timestamp - d.samples.first.timestamp).inMilliseconds /
    (d.samples.length - 1);

void main() {
  group('clip length does not reach the measurement', () {
    // The bug this file exists for. A fixed frame count meant a short clip was
    // sampled every 20-30 ms and a long one every 130 ms; each fix for one
    // regime broke the other. The same jump must now measure the same at
    // every length.
    for (final seconds in [1.2, 2.0, 3.0, 4.0, 6.0, 8.0, 10.0, 15.0, 30.0]) {
      test('a ${seconds}s clip measures the jump', () async {
        final durationMs = (seconds * 1000).round();
        final clip = _Clip(
          durationMs: durationMs,
          takeoffMs: (durationMs * 0.4).round() - 150,
        );

        final d = await clip.analyze();

        expect(d.rejection, PoseDetectionRejection.none);
        expect(d.result!.airborneSeconds, closeTo(0.550, 0.03));
        // Always the dense series, never the scan.
        expect(_stepMs(d), closeTo(JumpSamplingPlan.measureStepMs, 1));
        expect(
          clip.framesRequested,
          lessThanOrEqualTo(
            JumpSamplingPlan.frameBudget(
              Duration.zero,
              Duration(milliseconds: durationMs),
            ),
          ),
        );
      });
    }

    test('timestamps stay on the original clip timeline', () async {
      final clip = _Clip(durationMs: 10000, takeoffMs: 6200);
      final d = await clip.analyze();

      expect(d.result!.takeoff.inMilliseconds, closeTo(6200, 30));
      expect(d.result!.landing.inMilliseconds, closeTo(6750, 30));
    });

    test('an athlete far from the camera measures the same', () async {
      final near = await _Clip(durationMs: 8000, takeoffMs: 3000, torso: 320)
          .analyze();
      final far = await _Clip(durationMs: 8000, takeoffMs: 3000, torso: 60)
          .analyze();

      expect(near.rejection, PoseDetectionRejection.none);
      expect(far.rejection, PoseDetectionRejection.none);
      expect(far.result!.airborneSeconds,
          closeTo(near.result!.airborneSeconds, 0.03));
    });

    test('a walk toward the camera on a long clip is still measured',
        () async {
      final clip = _Clip(
        durationMs: 9000,
        takeoffMs: 5000,
        driftPixelsPerSecond: 40,
      );
      final d = await clip.analyze();

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.result!.airborneSeconds, closeTo(0.550, 0.03));
    });

    test('a hop the scan catches in a single frame is still found', () async {
      // 30 s is scanned every 240 ms; a 0.42 s flight starting at 12.05 s has
      // exactly one scan sample in it (12.24 s). One airborne sample is not a
      // window, but it is enough to say where to look.
      final clip = _Clip(durationMs: 30000, takeoffMs: 12050, flightMs: 420);
      final d = await clip.analyze();

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.result!.airborneSeconds, closeTo(0.420, 0.03));
    });
  });

  group('sweep', () {
    test('300 random clips: every length, size, drift and jump is measured',
        () async {
      // Seeded, so a failure names a reproducible clip. The point is the
      // combinations nobody thought to write a named test for.
      final random = math.Random(20260930);
      final failures = <String>[];
      for (var i = 0; i < 300; i++) {
        final durationMs = 2000 + random.nextInt(28000);
        final flightMs = 380 + random.nextInt(450);
        // Anywhere the clip leaves half a second of ground either side.
        final latest = durationMs - flightMs - 500;
        final takeoffMs = 500 + random.nextInt(latest - 500 + 1);
        // Drift and landmark jitter both scale with the athlete's size in
        // frame: up to a fifth of a torso per second of walk-in either way,
        // and ~1.5 % of a torso of noise.
        final torso = 50 + random.nextDouble() * 300;
        final clip = _Clip(
          durationMs: durationMs,
          takeoffMs: takeoffMs,
          flightMs: flightMs,
          torso: torso,
          driftPixelsPerSecond: (random.nextDouble() - 0.5) * 0.4 * torso,
          jitterPixels: torso * 0.015,
        );

        final d = await clip.analyze();
        final error = d.result == null
            ? null
            : (d.result!.airborneSeconds - flightMs / 1000).abs();
        if (error == null || error > 0.04) {
          failures.add(
            '#$i ${durationMs}ms takeoff=$takeoffMs flight=$flightMs '
            'torso=${torso.round()} '
            'drift=${clip.driftPixelsPerSecond.round()} → '
            '${d.rejection.name} ${d.result?.airborneSeconds}',
          );
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });

  group('a trim cut too close', () {
    test('reaches past the trim when the clip has the frames', () async {
      // Trimmed *inside* the flight: no ground on either side, nothing to
      // time. The takeoff and landing are in the file, a second away.
      final clip = _Clip(durationMs: 6000, takeoffMs: 3000, flightMs: 600);
      final d = await clip.analyze(fromMs: 2950, toMs: 3650);

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.result!.airborneSeconds, closeTo(0.600, 0.03));
    });

    test('says so when the clip itself ends mid-air', () async {
      final clip = _Clip(durationMs: 1500, takeoffMs: 1200, flightMs: 600);
      final d = await clip.analyze();

      expect(d.result, isNull);
      expect(d.rejection, PoseDetectionRejection.noAirborneWindow);
    });

    test('the shortest trim the handles allow does not fall over', () async {
      final clip = _Clip(durationMs: 600, takeoffMs: 100, flightMs: 400);
      final d = await clip.analyze();

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.result!.airborneSeconds, closeTo(0.400, 0.03));
    });
  });

  group('a clip that cannot be read', () {
    test('is reported as unreadable, not as too short', () async {
      final d = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: const Duration(seconds: 4),
        clipDuration: const Duration(seconds: 4),
        sample: (_) async => const [],
      );

      expect(d.result, isNull);
      expect(d.rejection, PoseDetectionRejection.unreadable);
    });

    test('an empty range is refused without sampling anything', () async {
      var calls = 0;
      final d = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: Duration.zero,
        clipDuration: Duration.zero,
        sample: (_) async {
          calls++;
          return const [];
        },
      );

      expect(d.result, isNull);
      expect(calls, 0);
    });

    test('a clip with nobody in it is a tracking failure', () async {
      final d = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: const Duration(seconds: 5),
        clipDuration: const Duration(seconds: 5),
        sample: (times) async =>
            [for (final t in times) PoseSample(timestamp: t)],
      );

      expect(d.rejection, PoseDetectionRejection.tooManyMissing);
    });
  });

  group('JumpSamplingPlan', () {
    test('a short range is sampled whole at the measurement step', () {
      final times = JumpSamplingPlan.firstPass(
        const Duration(milliseconds: 500),
        const Duration(milliseconds: 2500),
      );

      expect(times.first, const Duration(milliseconds: 500));
      expect(times.last < const Duration(milliseconds: 2500), isTrue);
      expect(times[1] - times[0],
          const Duration(milliseconds: JumpSamplingPlan.measureStepMs));
    });

    test('a long range is scanned, and the step never outgrows a flight', () {
      final ten = JumpSamplingPlan.firstPass(
          Duration.zero, const Duration(seconds: 10));
      final sixty = JumpSamplingPlan.firstPass(
          Duration.zero, const Duration(seconds: 60));

      expect(ten[1] - ten[0],
          const Duration(milliseconds: JumpSamplingPlan.scanStepMs));
      expect(ten.length, lessThanOrEqualTo(JumpSamplingPlan.scanMaxFrames));
      // However long the clip, no gap a flight could hide in.
      expect(sixty[1] - sixty[0],
          const Duration(milliseconds: JumpSamplingPlan.scanMaxStepMs));
    });
  });

  group('dense sampling', () {
    // Before the rolling ground window had a minimum span in time, fifteen
    // samples at a fine step sat entirely inside the flight, and the apex of a
    // modest jump read as "on the ground".
    for (final stepMs in [15, 20, 25, 33]) {
      test('a modest jump sampled every $stepMs ms is measured', () {
        final clip = _Clip(
          durationMs: 2000,
          takeoffMs: 800,
          flightMs: 420,
          jitterPixels: 0,
        );
        final d = PoseJumpDetector.detectWithDiagnostics([
          for (var t = 0; t < clip.durationMs; t += stepMs)
            clip.at(Duration(milliseconds: t)),
        ]);

        expect(d.rejection, PoseDetectionRejection.none);
        expect(d.peakLiftPixels, closeTo(clip.peakLiftPixels, 4));
        expect(d.result!.airborneSeconds, closeTo(0.420, 0.02));
      });
    }
  });
}
