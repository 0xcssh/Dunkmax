import 'dart:math' as math;

import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:flutter_test/flutter_test.dart';

const _groundY = 900.0;
const _torso = 200.0;
const _footX = 500.0;

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
  bool landmarks = false,
  double Function(int t)? shoulderXOffset,
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
    if (dropped) {
      samples.add(PoseSample(timestamp: Duration(milliseconds: t)));
      continue;
    }

    // Upright body geometry hung off the foot: hips 340 px above it, shoulders
    // a torso (200 px) above those, so the hip→shoulder up-vector is exactly
    // (0, −1) and `torsoPixels` is exactly the landmark distance.
    final hipY = footY - 340;
    final shoulderY = hipY - _torso;
    final shoulderDx = shoulderXOffset?.call(t) ?? 0.0;
    samples.add(
      PoseSample(
        timestamp: Duration(milliseconds: t),
        footY: footY,
        foot: landmarks ? PosePoint(_footX, footY) : null,
        torsoPixels: _torso,
        leftHip: landmarks ? PosePoint(_footX - 30, hipY) : null,
        rightHip: landmarks ? PosePoint(_footX + 30, hipY) : null,
        leftShoulder:
            landmarks ? PosePoint(_footX - 30 + shoulderDx, shoulderY) : null,
        rightShoulder:
            landmarks ? PosePoint(_footX + 30 + shoulderDx, shoulderY) : null,
      ),
    );
  }
  return samples;
}

/// Rotates every coordinate of a landmark clip by [degrees] about [pivot].
///
/// This is what an unapplied rotation flag does to the frames handed to the
/// pose model: nothing about the jump changes, only the coordinate system it
/// is expressed in. The pivot is deliberately away from the origin, so the
/// clip is translated as well as rotated and nothing can pass by accident.
///
/// `footY` is carried across as the rotated point's y — i.e. the number a
/// detector reading image y would see, which is no longer a height at all.
List<PoseSample> _rotateClip(
  List<PoseSample> clip,
  double degrees, {
  double pivotX = 960,
  double pivotY = 540,
}) {
  final radians = degrees * math.pi / 180;
  final cos = math.cos(radians);
  final sin = math.sin(radians);

  PosePoint? turn(PosePoint? p) {
    if (p == null) return null;
    final dx = p.x - pivotX;
    final dy = p.y - pivotY;
    return PosePoint(
      pivotX + dx * cos - dy * sin,
      pivotY + dx * sin + dy * cos,
    );
  }

  return [
    for (final s in clip)
      PoseSample(
        timestamp: s.timestamp,
        footY: turn(s.foot)?.y,
        foot: turn(s.foot),
        // A distance, so no rotation can change it.
        torsoPixels: s.foot == null ? null : s.torsoPixels,
        leftHip: turn(s.leftHip),
        rightHip: turn(s.rightHip),
        leftShoulder: turn(s.leftShoulder),
        rightShoulder: turn(s.rightShoulder),
      ),
  ];
}

/// Strips a clip back to the scalar `footY` the detector used to read, keeping
/// nothing it could infer an up-axis from.
List<PoseSample> _scalarOnly(List<PoseSample> clip) => [
      for (final s in clip)
        PoseSample(
          timestamp: s.timestamp,
          footY: s.footY,
          torsoPixels: s.torsoPixels,
        ),
    ];

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

    test('rejects a clip where the athlete is lost during the flight', () {
      // Dropping every other frame holes the flight itself, which is what
      // actually costs the timing its accuracy.
      //
      // This used to assert `tooManyMissing` — a clip-wide ratio — but that
      // rule was wrong in the field: a real capture had no person in 38 of
      // 60 frames simply because those frames showed something else, while
      // tracking the jump perfectly, and got thrown away. The judgement now
      // happens over the window, so the reason changed even though the
      // verdict on this clip did not.
      final d = PoseJumpDetector.detectWithDiagnostics(
        _jumpClip(dropDetection: (i) => i % 2 == 0),
      );

      expect(d.rejection, PoseDetectionRejection.gappyWindow);
      expect(d.result, isNull);
    });

    test('gaps outside the flight do not reject a cleanly tracked jump', () {
      // The field case, in miniature: a long clip in which the athlete is
      // absent from most frames, but present continuously across the jump
      // and for a good stretch of ground on either side of it. Roughly 70%
      // of the clip has no pose — twice what the old clip-wide rule allowed.
      final clip = _jumpClip(leadInMs: 3000, leadOutMs: 3000);
      final holed = [
        for (final s in clip)
          (s.timestamp.inMilliseconds >= 2400 &&
                  s.timestamp.inMilliseconds <= 4400)
              ? s
              : PoseSample(
                  timestamp: s.timestamp, footY: null, torsoPixels: null),
      ];

      final d = PoseJumpDetector.detectWithDiagnostics(holed);

      expect(d.missingCount / d.sampleCount, greaterThan(0.5));
      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.correctedSeconds, closeTo(0.770, 0.06));
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

    test('measures the best of several jumps instead of refusing', () {
      // Two jumps in one clip. Refusing here used to push the athlete into
      // marking a clip by hand that the detector had understood perfectly
      // well; "analyse my jump" means the one worth looking at, so the
      // higher jump wins.
      final first = _jumpClip(leadInMs: 600, flightMs: 500, leadOutMs: 200);
      final second = _jumpClip(leadInMs: 200, flightMs: 700, leadOutMs: 600);
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
      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.airborneWindowsSeen, 2);
      // The 700 ms jump, not the 500 ms one.
      expect(d.result!.airborneSeconds, closeTo(0.700, 0.06));
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

  // The bug this group exists for: a real camera clip with an unmistakable
  // jump came back `noAirborneWindow`. `ffprobe` on it: 1920x1080,
  // rotation=-90 — an iPhone portrait recording, stored landscape with a
  // rotation flag. Players apply the flag; the frame extractor need not, so
  // the pose model saw the athlete lying on his side, and a vertical jump
  // moved the feet almost entirely *horizontally* in image coordinates. The
  // fix is to measure along the athlete's own up-axis, which also survives a
  // camera propped at an angle — something reading the rotation flag would
  // not.
  group('frame orientation', () {
    test('the upright case still resolves to the image vertical', () {
      final d = PoseJumpDetector.detectWithDiagnostics(_jumpClip(landmarks: true));

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.bodyAxis.isImageVertical, isTrue);
      expect(d.bodyAxis.tiltDegrees, closeTo(0, 1e-9));
      expect(d.axisSampleCount, greaterThan(0));
      // Identical to the scalar-only clip: adding landmarks cannot move the
      // answer on an upright frame.
      expect(
        d.correctedSeconds,
        closeTo(
          PoseJumpDetector.detectWithDiagnostics(_jumpClip()).correctedSeconds!,
          1e-9,
        ),
      );
    });

    test('a foot that rises reads as a *smaller* descent', () {
      // The sign convention, pinned. Image y grows downward and so does the
      // projected descent, so lift = baseline − descent must be positive at
      // the apex and zero on the ground.
      final d = PoseJumpDetector.detectWithDiagnostics(_jumpClip(landmarks: true));
      final samples = d.samples.where((s) => s.isDetected).toList();

      final grounded = samples.first.footDescent(d.bodyAxis)!;
      final apex = samples
          .map((s) => s.footDescent(d.bodyAxis)!)
          .reduce((a, b) => a < b ? a : b);

      expect(apex, lessThan(grounded));
      expect(grounded - apex, closeTo(270, 1));
      expect(d.groundBaselineY, closeTo(grounded, 1));
      expect(d.peakLiftPixels, closeTo(270, 5));
    });

    test('the same jump rotated 90° measures the same flight time', () {
      final upright =
          PoseJumpDetector.detectWithDiagnostics(_jumpClip(landmarks: true));
      final sideways = PoseJumpDetector.detectWithDiagnostics(
        _rotateClip(_jumpClip(landmarks: true), 90),
      );

      expect(sideways.rejection, PoseDetectionRejection.none);
      expect(sideways.bodyAxis.tiltDegrees, closeTo(90, 1e-6));
      expect(sideways.correctedSeconds, closeTo(upright.correctedSeconds!, 1e-4));
      expect(
        sideways.result!.airborneSeconds,
        closeTo(upright.result!.airborneSeconds, 1e-3),
      );
      expect(sideways.result!.verticalInches, inInclusiveRange(28, 30));
    });

    test('that 90° clip is exactly what image y rejects', () {
      // Same rotated clip with the foot *point* and the torso landmarks
      // stripped, leaving only the image y the old detector read. This is the
      // field report, reproduced: the feet appear to stay at one height, so
      // there is no airborne window to find.
      final d = PoseJumpDetector.detectWithDiagnostics(
        _scalarOnly(_rotateClip(_jumpClip(landmarks: true), 90)),
      );

      expect(d.rejection, PoseDetectionRejection.noAirborneWindow);
      expect(d.result, isNull);
    });

    test('an arbitrary 20° camera tilt measures the same flight time', () {
      // A tilted tripod, not a metadata flag — which is why the fix is the
      // pose axis rather than reading the rotation tag.
      final upright =
          PoseJumpDetector.detectWithDiagnostics(_jumpClip(landmarks: true));
      final tilted = PoseJumpDetector.detectWithDiagnostics(
        _rotateClip(_jumpClip(landmarks: true), 20),
      );

      expect(tilted.rejection, PoseDetectionRejection.none);
      expect(tilted.bodyAxis.tiltDegrees, closeTo(20, 1e-6));
      expect(tilted.correctedSeconds, closeTo(upright.correctedSeconds!, 1e-4));
    });

    test('an upside-down frame is measured, not inverted', () {
      // 180°: a rising foot now has a *larger* image y. Anything still reading
      // image y as height would call the whole clip grounded.
      final upright =
          PoseJumpDetector.detectWithDiagnostics(_jumpClip(landmarks: true));
      final flipped = PoseJumpDetector.detectWithDiagnostics(
        _rotateClip(_jumpClip(landmarks: true), 180),
      );

      expect(flipped.rejection, PoseDetectionRejection.none);
      expect(flipped.bodyAxis.tiltDegrees.abs(), closeTo(180, 1e-6));
      expect(flipped.correctedSeconds, closeTo(upright.correctedSeconds!, 1e-4));
    });

    test('the axis comes from the grounded frames, not the airborne ones', () {
      // The athlete tucks and leans hard in flight. A per-frame axis — or one
      // averaged over the whole clip without regard to ground contact — would
      // fold that tilt into the very measurement it is meant to stabilise.
      final leaning = _jumpClip(
        landmarks: true,
        shoulderXOffset: (t) => (t > 800 && t < 1570) ? 150.0 : 0.0,
      );

      final d = PoseJumpDetector.detectWithDiagnostics(leaning);

      expect(d.rejection, PoseDetectionRejection.none);
      expect(d.bodyAxis.isImageVertical, isTrue);
      expect(d.correctedSeconds, closeTo(0.770, 0.02));
    });

    test('a series with no torso keeps the image vertical, unchanged', () {
      final d = PoseJumpDetector.detectWithDiagnostics(_jumpClip());

      expect(d.bodyAxis.isImageVertical, isTrue);
      expect(d.axisSampleCount, 0);
    });
  });

  group('real device capture', () {
    /// Verbatim `footY` series reported by the app on a real clip, at the
    /// 132.6 ms sampling step it used (60 frames over a 7.95 s clip). Only 22
    /// of the 60 frames contained a person at all — the rest were UI, a
    /// leaderboard and static screens — and the detector rejected the whole
    /// clip on a clip-wide missing-frame ratio, falling back to frame motion,
    /// which reported 8" for a jump independently measured at 28-29".
    ///
    /// The jump is tracked cleanly in the frames that do contain it, so the
    /// window is measurable; this pins that it now is.
    List<PoseSample> deviceCapture() {
      const footY = <int, double?>{
        0: 875, 1: 887, 2: 866, 3: 897, 4: 897, 5: 852, 6: null,
        7: 788, 8: 820, 9: 821, 10: 906, 11: null, 12: null, 13: null,
        14: null, 15: null, 16: null, 17: null, 18: null, 19: null,
        20: null, 21: null, 22: null, 23: null, 24: null, 25: null,
        26: null, 27: null, 28: null, 29: null, 30: null, 31: null,
        32: null, 33: null, 34: null, 35: null, 36: null,
        37: 859, 38: 881, 39: 881, 40: 889, 41: 897, 42: 869, 43: null,
        44: 799, 45: 797, 46: 829, 47: 900, 48: 898, 49: null, 50: null,
        51: null, 52: null, 53: null, 54: null, 55: null,
        // A stray detection on an unrelated on-screen thumbnail — the kind
        // of outlier a percentile baseline has to survive.
        56: 1361,
        57: null, 58: null, 59: null,
      };

      return [
        for (var i = 0; i < 60; i++)
          PoseSample(
            timestamp: Duration(milliseconds: (i * 132.6).round()),
            footY: footY[i],
            // Not reported per-frame by the device; the athlete's apparent
            // size barely changes across the clip, so a constant is faithful.
            torsoPixels: footY[i] == null ? null : 100.0,
          ),
      ];
    }

    test('frames with no person outside the jump no longer veto the clip', () {
      // The old clip-wide ratio rejected this outright as
      // `tooManyMissing`. Whatever it decides now, it must get far enough to
      // have placed a baseline and looked at real windows.
      final diagnostics =
          PoseJumpDetector.detectWithDiagnostics(deviceCapture());

      expect(diagnostics.rejection, isNot(PoseDetectionRejection.tooManyMissing));
      expect(diagnostics.groundBaselineY, isNotNull);
    });

    test('the stray 1361px detection does not drag the ground baseline', () {
      // One frame found a "person" in an unrelated on-screen thumbnail. A
      // max-based baseline would sit at 1361 and call the entire clip
      // airborne; the percentile has to absorb it.
      final diagnostics =
          PoseJumpDetector.detectWithDiagnostics(deviceCapture());

      expect(diagnostics.groundBaselineY, closeTo(897, 12));
    });

    test('the same jump played twice is measured, not refused', () {
      // The clip is a screen recording in which the source video is played
      // through twice. Both playbacks are the same jump, so picking the
      // higher one is right and asking the athlete to disambiguate was not.
      final diagnostics =
          PoseJumpDetector.detectWithDiagnostics(deviceCapture());

      expect(diagnostics.rejection, PoseDetectionRejection.none);
      expect(diagnostics.airborneWindowsSeen, greaterThan(1));
      expect(diagnostics.result!.verticalInches, inInclusiveRange(20, 34));
    });

    test('one playback of it measures the independently verified jump', () {
      // Ground truth established frame by frame with ffmpeg: takeoff
      // 0.558 s, landing ~1.32 s, ~0.77 s of hang, 28-29".
      final single = deviceCapture()
          .where((s) => s.timestamp.inMilliseconds <= 2000)
          .toList();

      final result = PoseJumpDetector.detect(single);

      expect(result, isNotNull);
      expect(result!.airborneSeconds, closeTo(0.77, 0.08));
      expect(result.verticalInches, inInclusiveRange(25, 32));
    });
  });
}
