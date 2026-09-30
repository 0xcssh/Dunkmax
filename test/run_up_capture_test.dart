import 'dart:math' as math;

import 'package:dunkmax/core/jump_analysis_pipeline.dart';
import 'package:dunkmax/core/jump_form_scores.dart';
import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/run_up_away_capture.dart';

/// Serves the capture the way the frame extractor serves a clip: the frame at
/// or after each requested instant, stamped with the instant that was asked
/// for.
Future<List<PoseSample>> _sampleCapture(List<Duration> timestamps) async {
  final frames = runUpAwayCapture();
  return [
    for (final t in timestamps)
      () {
        final f = frames.firstWhere(
          (f) => f.timestamp >= t,
          orElse: () => frames.last,
        );
        return PoseSample(
          timestamp: t,
          foot: f.foot,
          footY: f.footY,
          torsoPixels: f.torsoPixels,
          leftAnkle: f.leftAnkle,
          rightAnkle: f.rightAnkle,
          leftKnee: f.leftKnee,
          rightKnee: f.rightKnee,
          leftHip: f.leftHip,
          rightHip: f.rightHip,
          leftShoulder: f.leftShoulder,
          rightShoulder: f.rightShoulder,
          leftWrist: f.leftWrist,
          rightWrist: f.rightWrist,
        );
      }(),
  ];
}

const _clip = Duration(milliseconds: 4035);

void main() {
  // A run-up straight away from the camera, then the jump, five metres out.
  // Read off the fixture by hand: the feet are planted at ~662 px from 1657 ms
  // to 1822 ms, are 14 px up by 1855 ms, peak at 2053 ms, and are back on a
  // floor that is now at ~652 px by 2284–2317 ms. So: takeoff between the
  // 1822 and 1855 ms frames, landing between 2251 and 2317 ms, ~0.45 s.
  group('run-up away from the camera (real capture)', () {
    test('the jump is measured', () async {
      final d = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: _clip,
        clipDuration: _clip,
        sample: _sampleCapture,
      );

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.result!.airborneSeconds, closeTo(0.45, 0.04));
      expect(d.crossingTakeoff!.inMilliseconds, inInclusiveRange(1822, 1888));
      expect(d.crossingLanding!.inMilliseconds, inInclusiveRange(2218, 2317));
    });

    test('the run-up is not mistaken for the flight', () async {
      // What the detector did before it had a ground envelope: the rolling
      // percentile lagged the floor sliding up the frame, every stride of the
      // run-up read as airborne, and it timed 1413–1816 ms — the run-up —
      // and reported a vertical for it.
      final d = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: _clip,
        clipDuration: _clip,
        sample: _sampleCapture,
      );

      expect(d.result!.takeoff.inMilliseconds, greaterThan(1750));
      // The floor really did move under him, by far more than he jumped.
      final floors = [
        for (final b in d.localGroundBaselines)
          if (b != null) b,
      ];
      final travel = floors.reduce(math.max) - floors.reduce(math.min);
      expect(travel, greaterThan(2 * d.peakLiftPixels));
    });

    test('the local floor follows the run-up instead of lagging it', () async {
      final d = PoseJumpDetector.detectWithDiagnostics(runUpAwayCapture());

      // Mid run-up: no sample there may read as anything like the jump.
      // Running strides are real, brief flights and are allowed theirs — the
      // biggest in this clip lifts the feet ~23 px against the jump's 44.
      for (var i = 0; i < d.samples.length; i++) {
        final ms = d.samples[i].timestamp.inMilliseconds;
        final floor = d.localGroundBaselines[i];
        final foot = d.samples[i].footDescent(d.bodyAxis);
        if (floor == null || foot == null) continue;
        if (ms >= 1100 && ms <= 1800) {
          expect(floor - foot, lessThan(d.peakLiftPixels * 0.7),
              reason: 'frame at $ms ms');
        }
      }
    });

    test('a trim around the jump measures the same flight', () async {
      final whole = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: _clip,
        clipDuration: _clip,
        sample: _sampleCapture,
      );
      final trimmed = await JumpAnalysisPipeline.run(
        rangeStart: const Duration(milliseconds: 1200),
        rangeEnd: const Duration(milliseconds: 3000),
        clipDuration: _clip,
        sample: _sampleCapture,
      );

      expect(trimmed.rejection, PoseDetectionRejection.none);
      expect(trimmed.result!.airborneSeconds,
          closeTo(whole.result!.airborneSeconds, 0.03));
    });

    test('the form scores do not fall over on it', () async {
      final d = await JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: _clip,
        clipDuration: _clip,
        sample: _sampleCapture,
      );

      final scores = JumpFormScoring.fromDiagnostics(d);
      expect(scores, isNotNull);
      for (final score in scores!.all) {
        if (score.isAvailable) expect(score.value, inInclusiveRange(0, 100));
      }
    });
  });

  group('run-up along the camera axis (synthetic)', () {
    // The same shape with known numbers: standing, a run that slides the
    // floor [travel] px in 0.8 s, a 0.2 s plant, then the flight.
    Future<PoseJumpDiagnostics> analyze(double travel) {
      const torso = 80.0;
      const flightMs = 480;
      const takeoffMs = 2200;
      final peak = 9.81 * 0.48 * 0.48 / 8 * torso / 0.53;
      double floorAt(int t) {
        if (t <= 1200) return 800;
        if (t >= 2000) return 800 + travel;
        return 800 + travel * (t - 1200) / 800;
      }

      return JumpAnalysisPipeline.run(
        rangeStart: Duration.zero,
        rangeEnd: const Duration(milliseconds: 4200),
        clipDuration: const Duration(milliseconds: 4200),
        sample: (times) async => [
          for (final time in times)
            () {
              final t = time.inMilliseconds;
              var lift = 0.0;
              if (t > takeoffMs && t < takeoffMs + flightMs) {
                final phase = (t - takeoffMs) / flightMs;
                lift = peak * (1 - math.pow(2 * phase - 1, 2));
              }
              return PoseSample(
                timestamp: time,
                footY: floorAt(t) - lift + 1.2 * math.sin(t * 0.37),
                torsoPixels: torso,
              );
            }(),
        ],
      );
    }

    for (final travel in [-160.0, -80.0, 80.0, 160.0]) {
      test('floor sliding ${travel.round()} px in the run-up', () async {
        final d = await analyze(travel);

        expect(d.rejection, PoseDetectionRejection.none);
        expect(d.result!.airborneSeconds, closeTo(0.48, 0.03));
        expect(d.result!.takeoff.inMilliseconds, closeTo(2200, 40));
      });
    }
  });
}
