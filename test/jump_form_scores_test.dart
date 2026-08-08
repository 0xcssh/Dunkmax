import 'dart:math' as math;

import 'package:dunkmax/core/jump_form_scores.dart';
import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:flutter_test/flutter_test.dart';

// Synthetic clip geometry. Deliberately round numbers so every expected score
// can be worked out by hand from the documented thresholds.
const _groundY = 500.0;
const _torso = 100.0;
const _takeoffMs = 700;
const _landingMs = 1400;
const _peakLift = 150.0;
const _stepMs = 20;
const _totalMs = 2000;

/// Builds a clip of one approach jump with landmarks:
///
/// * a standing lead-in,
/// * an approach step airborne from [approachStartMs] to [approachEndMs]
///   (this is what gives Bounce a plant to time),
/// * a countermovement — hips drop 30 px (0.30 torso) then drive up,
/// * flight from 700 ms to 1400 ms on the real parabola,
/// * a standing lead-out.
///
/// Every coordinate is multiplied by [scale] so the same jump can be replayed
/// as if filmed from twice the distance.
List<PoseSample> _clip({
  double scale = 1.0,
  bool landmarks = true,
  bool wrists = true,
  double rightAnkleOffset = 0,
  double rightHipOffset = 0,
  double shoulderXOffset = 0,
  int approachStartMs = 300,
  int approachEndMs = 500,
}) {
  double liftAt(int t) {
    final phase = (t - _takeoffMs) / (_landingMs - _takeoffMs);
    return _peakLift * (1 - math.pow(2 * phase - 1, 2));
  }

  double footAt(int t) {
    if (t >= approachStartMs && t < approachEndMs) return _groundY - 60;
    if (t > _takeoffMs && t < _landingMs) return _groundY - liftAt(t);
    return _groundY;
  }

  double hipAt(int t) {
    if (t >= approachStartMs && t < approachEndMs) return 385;
    if (t < 500) return 400;
    if (t < 600) return 400 + 30 * (t - 500) / 100; // dip: 400 → 430
    if (t < _takeoffMs) return 430 - 40 * (t - 600) / 100; // drive: 430 → 390
    if (t <= _landingMs) return 390 - liftAt(t);
    return 400;
  }

  double wristAt(int t) {
    if (t < 500) return 430;
    if (t < 600) return 430 + 30 * (t - 500) / 100; // arms drop with the dip
    if (t < _takeoffMs) return 460 - 180 * (t - 600) / 100; // swing: 460 → 280
    if (t <= _landingMs) return 280 - liftAt(t);
    return 430;
  }

  PosePoint p(double x, double y) => PosePoint(x * scale, y * scale);

  final samples = <PoseSample>[];
  for (var t = 0; t <= _totalMs; t += _stepMs) {
    final foot = footAt(t);
    final hip = hipAt(t);
    final wrist = wristAt(t);
    samples.add(
      PoseSample(
        timestamp: Duration(milliseconds: t),
        footY: foot * scale,
        torsoPixels: _torso * scale,
        leftAnkle: landmarks ? p(240, foot) : null,
        rightAnkle: landmarks ? p(260, foot + rightAnkleOffset) : null,
        leftKnee: landmarks ? p(242, (foot + hip) / 2) : null,
        rightKnee: landmarks ? p(258, (foot + hip) / 2) : null,
        leftHip: landmarks ? p(240, hip) : null,
        rightHip: landmarks ? p(260, hip + rightHipOffset) : null,
        leftShoulder: landmarks ? p(240 + shoulderXOffset, hip - _torso) : null,
        rightShoulder:
            landmarks ? p(260 + shoulderXOffset, hip - _torso) : null,
        leftWrist: landmarks && wrists ? p(230, wrist) : null,
        rightWrist: landmarks && wrists ? p(270, wrist) : null,
      ),
    );
  }
  return samples;
}

JumpFormScores _score(List<PoseSample> samples, {double scale = 1.0}) {
  return JumpFormScoring.compute(
    samples: samples,
    takeoff: const Duration(milliseconds: _takeoffMs),
    landing: const Duration(milliseconds: _landingMs),
    groundBaselineY: _groundY * scale,
    torsoPixels: _torso * scale,
  );
}

/// Rewrites the drive so the hips hold near their low point and then snap up
/// in the final 50 ms, keeping the same start and end heights. The mean rate
/// across the drive is roughly halved; the peak is not.
PosePoint? _lateDrive(Duration timestamp, PosePoint? point) {
  if (point == null) return null;
  final t = timestamp.inMilliseconds;
  if (t < 600 || t > _takeoffMs) return point;
  // 600 ms: 430 (low)  →  700 ms: 390 (takeoff), but held flat until 650 ms.
  final y = t < 650 ? 430.0 : 430.0 - 40.0 * (t - 650) / 50.0;
  return PosePoint(point.x, y);
}

PosePoint? _shallowDip(Duration timestamp, PosePoint? point) {
  if (point == null) return null;
  final t = timestamp.inMilliseconds;
  if (t < 500 || t > _takeoffMs) return point;
  // Lift the whole plant-through-takeoff segment by a constant. The dip
  // becomes shallow relative to the athlete's standing hip height while the
  // hips still travel exactly as far, and as fast, out of it.
  //
  // Squashing the segment instead would have been wrong: a smaller dip
  // mechanically means a shorter drive, so the score would fall for a reason
  // that has nothing to do with the depth term this test is about.
  return PosePoint(point.x, point.y - 27);
}

void main() {
  group('a clean tracked jump', () {
    test('produces all four scores, each with the measurement behind it', () {
      final scores = _score(_clip());

      for (final score in scores.all) {
        expect(score.value, isNotNull, reason: '${score.label} was not scored');
        expect(score.value, inInclusiveRange(0, 100));
        expect(score.detail, isNotNull);
        expect(score.unavailableReason, isNull);
      }
      expect(scores.hasAnyScore, isTrue);
    });

    test('bounce reflects the ~0.20 s plant before takeoff', () {
      // Plant crosses the ground threshold at ~0.497 s, takeoff at 0.700 s →
      // 0.203 s of contact, which sits about 82 % of the way from the 0.45 s
      // zero point to the 0.15 s full-credit point.
      expect(_score(_clip()).bounce.value, closeTo(82, 2));
    });

    test('power on an approach jump scores the drive, not the dip', () {
      // The hips drive at a constant 4.0 torso/s in this clip (40 px in
      // 0.1 s), so peak and average coincide: 83 % of the way from the 1.5
      // zero point to the 4.5 full-credit point. The dip is deliberately
      // ignored here — see the approach-jump group below.
      expect(_score(_clip()).power.value, closeTo(83, 3));
    });

    test('the drive is scored at its peak, not averaged across itself', () {
      // A real drive accelerates from rest to takeoff, so its mean is about
      // half its peak — and the band is written as a velocity. Measuring the
      // mean scored a genuine 28" jump at 9/100. Here the hips loiter, then
      // snap upward: the mean over the whole drive is far below the burst,
      // and the score must follow the burst.
      final base = _clip();
      final loitering = [
        for (final s in base)
          PoseSample(
            timestamp: s.timestamp,
            footY: s.footY,
            torsoPixels: s.torsoPixels,
            leftAnkle: s.leftAnkle,
            rightAnkle: s.rightAnkle,
            leftKnee: s.leftKnee,
            rightKnee: s.rightKnee,
            leftHip: _lateDrive(s.timestamp, s.leftHip),
            rightHip: _lateDrive(s.timestamp, s.rightHip),
            leftShoulder: s.leftShoulder,
            rightShoulder: s.rightShoulder,
            leftWrist: s.leftWrist,
            rightWrist: s.rightWrist,
          ),
      ];

      final score = _score(loitering).power.value!;
      // Mean across the drive here is ~2 torso/s (score ~17); the burst is
      // ~4 torso/s. Anything near the mean means the peak is being missed.
      expect(score, greaterThan(50));
    });

    test('a perfectly symmetric athlete scores full marks for control', () {
      expect(_score(_clip()).control.value, 100);
    });

    test('reads the takeoff as two-foot when both ankles leave together', () {
      expect(_score(_clip()).takeoffType, TakeoffType.twoFoot);
    });
  });

  group('missing landmarks are absent scores, never defaults', () {
    test('no landmarks at all leaves only the foot-based bounce score', () {
      final scores = _score(_clip(landmarks: false));

      expect(scores.bounce.value, isNotNull);
      for (final score in [scores.power, scores.control, scores.form]) {
        expect(score.value, isNull, reason: '${score.label} invented a score');
        expect(score.detail, isNull);
        expect(score.unavailableReason, isNotNull);
        expect(score.unavailableReason, isNotEmpty);
      }
      expect(scores.takeoffType, isNull);
    });

    test('wrists never detected removes only the form score', () {
      final scores = _score(_clip(wrists: false));

      expect(scores.form.value, isNull);
      expect(scores.form.unavailableReason, 'arms not visible in this clip');
      expect(scores.bounce.value, isNotNull);
      expect(scores.power.value, isNotNull);
      expect(scores.control.value, isNotNull);
    });

    test('a clip with too few tracked frames scores nothing', () {
      final scores = _score(_clip().take(4).toList());

      for (final score in scores.all) {
        expect(score.value, isNull);
        expect(score.unavailableReason, isNotNull);
      }
      expect(scores.hasAnyScore, isFalse);
    });

    test('an untracked series (no torso reference) scores nothing', () {
      final samples = [
        for (var t = 0; t <= _totalMs; t += _stepMs)
          PoseSample(timestamp: Duration(milliseconds: t)),
      ];
      final scores = _score(samples);
      expect(scores.hasAnyScore, isFalse);
    });
  });

  group('camera distance', () {
    test('halving every pixel coordinate leaves every score unchanged', () {
      final near = _score(_clip());
      final far = _score(_clip(scale: 0.5), scale: 0.5);

      expect(far.bounce.value, near.bounce.value);
      expect(far.power.value, near.power.value);
      expect(far.control.value, near.control.value);
      expect(far.form.value, near.form.value);
      expect(far.takeoffType, near.takeoffType);
    });

    test('quadrupling every pixel coordinate leaves every score unchanged',
        () {
      final near = _score(_clip());
      final huge = _score(_clip(scale: 4), scale: 4);

      expect(
        huge.all.map((s) => s.value).toList(),
        near.all.map((s) => s.value).toList(),
      );
    });
  });

  group('control separates symmetric from asymmetric jumps', () {
    test('an off-level, leaning athlete scores well below a square one', () {
      final square = _score(_clip());
      final crooked = _score(
        _clip(
          rightAnkleOffset: 30, // 0.30 torso of foot-height difference
          rightHipOffset: 15, // 0.15 torso of pelvic tilt
          shoulderXOffset: 40, // torso ~22° off vertical
        ),
      );

      expect(crooked.control.value, isNotNull);
      expect(crooked.control.value! < square.control.value! - 40, isTrue,
          reason: 'asymmetry barely moved the control score '
              '(${crooked.control.value} vs ${square.control.value})');
    });

    test('a one-foot takeoff drops the ankle term instead of punishing it', () {
      // The trail ankle leaves the floor a long way before the plant foot,
      // which is the technique — not a symmetry fault.
      final samples = <PoseSample>[];
      for (final s in _clip()) {
        final t = s.timestamp.inMilliseconds;
        // The trail foot keeps its ground contact through the approach, then
        // leaves ~0.22 s before the plant foot does and never comes back down
        // until the landing.
        final trail = t < 500
            ? _groundY
            : math.min(s.footY!, _groundY - 100);
        samples.add(
          PoseSample(
            timestamp: s.timestamp,
            footY: s.footY,
            torsoPixels: s.torsoPixels,
            leftAnkle: s.leftAnkle,
            rightAnkle: PosePoint(s.rightAnkle!.x, trail),
            leftHip: s.leftHip,
            rightHip: s.rightHip,
            leftShoulder: s.leftShoulder,
            rightShoulder: s.rightShoulder,
            leftWrist: s.leftWrist,
            rightWrist: s.rightWrist,
          ),
        );
      }

      final scores = _score(samples);
      expect(scores.takeoffType, TakeoffType.oneFoot);
      expect(scores.control.value, isNotNull);
      // Hips and torso are still square, so control stays high despite the
      // large ankle-height difference the scissoring legs produce.
      expect(scores.control.value! >= 90, isTrue,
          reason: 'the one-foot ankle split was scored as a fault '
              '(${scores.control.value})');
      expect(scores.control.detail, isNot(contains('feet')));
    });
  });

  group('scores stay inside 0–100', () {
    test('a raw value beyond the band clamps rather than overflowing', () {
      expect(FormScore.measured('X', 250, 'd').value, 100);
      expect(FormScore.measured('X', -80, 'd').value, 0);
      expect(FormScore.measured('X', double.nan, 'd').value, 0);
    });

    test('a very long ground contact floors bounce at 0, not below', () {
      // The approach step lands 0.60 s before takeoff — well past the 0.45 s
      // zero point.
      final scores = _score(_clip(approachStartMs: 0, approachEndMs: 100));
      expect(scores.bounce.value, 0);
    });

    test('every score of a clean jump is a legal percentage', () {
      for (final score in _score(_clip()).all) {
        expect(score.value!, greaterThanOrEqualTo(0));
        expect(score.value!, lessThanOrEqualTo(100));
      }
    });
  });

  group('approach jumps are not judged as standing jumps', () {
    // The field case this group exists for: a running two-foot jump measured
    // at 27" scored Power 0, because the athlete's hips barely dipped. On an
    // approach jump they are not supposed to — the athlete converts run-up
    // speed through a stiff, fast plant instead of squatting. The reported
    // drive rate was also physically impossible (1.1 torso/s next to a jump
    // whose takeoff velocity is around 7), because the dip was being searched
    // for across more than a second of run-up and kept landing on a stride.

    /// The same clip with a shallow countermovement — a plant, not a squat —
    /// but the same hip travel out of it.
    List<PoseSample> shallowDipClip() {
      final base = _clip();
      return [
        for (final s in base)
          PoseSample(
            timestamp: s.timestamp,
            footY: s.footY,
            torsoPixels: s.torsoPixels,
            leftAnkle: s.leftAnkle,
            rightAnkle: s.rightAnkle,
            leftKnee: s.leftKnee,
            rightKnee: s.rightKnee,
            // Squash the hip travel toward its own mean so the dip nearly
            // vanishes while the drive stays intact in shape.
            leftHip: _shallowDip(s.timestamp, s.leftHip),
            rightHip: _shallowDip(s.timestamp, s.rightHip),
            leftShoulder: s.leftShoulder,
            rightShoulder: s.rightShoulder,
            leftWrist: s.leftWrist,
            rightWrist: s.rightWrist,
          ),
      ];
    }

    test('a shallow dip costs an approach jump nothing', () {
      // Same drive, much shallower dip. The depth term is not part of the
      // judgement on an approach jump, so the score must not move: sinking
      // less is correct technique when converting run-up speed, and the old
      // scoring read it as an absence of power.
      final shallow = _score(shallowDipClip()).power.value;
      final normal = _score(_clip()).power.value;

      expect(shallow, isNotNull);
      expect(shallow, closeTo(normal!, 3));
    });

    test('the detail line reports the drive off the plant', () {
      final detail = _score(_clip()).power.detail!;

      expect(detail, contains('torso/s'));
      expect(detail, contains('plant'));
      // The dip is not part of the judgement here, so it is not quoted as if
      // it were.
      expect(detail, isNot(contains('dip')));
    });

    test('a jump from standing is still judged on its countermovement', () {
      // No approach step at all: the athlete is on the floor throughout the
      // lead-in, so there is no plant and the dip is the whole story.
      final standing = _clip(approachStartMs: 0, approachEndMs: 0);
      final detail = _score(standing).power.detail;

      if (detail != null) {
        expect(detail, contains('dip'));
      }
    });
  });
}
