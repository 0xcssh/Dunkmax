import 'dart:math' as math;

import 'pose_jump_detector.dart';

/// Whether the athlete left the floor off one foot or two.
enum TakeoffType {
  oneFoot('One-foot takeoff'),
  twoFoot('Two-foot takeoff');

  final String label;
  const TakeoffType(this.label);
}

/// One of the four form scores.
///
/// A score is either **measured** — a 0–100 number derived from landmarks
/// actually tracked in *this* clip, with [detail] naming the raw quantity it
/// came from — or **unavailable**, with a plain-English [unavailableReason].
/// There is no third state and no default: a metric whose inputs were not
/// found is absent, never zero and never an average. Filling it in would be
/// fabricated data, which this project does not ship.
class FormScore {
  /// Display name ("Bounce", "Power", …).
  final String label;

  /// 0–100, or null when the metric could not be measured on this clip.
  final int? value;

  /// The measurement behind [value], in the units it was measured in — so the
  /// number on screen can always be traced to something observed.
  final String? detail;

  /// Why there is no number, phrased for the athlete. Null when there is one.
  final String? unavailableReason;

  const FormScore._({
    required this.label,
    this.value,
    this.detail,
    this.unavailableReason,
  });

  factory FormScore.measured(String label, double raw, String detail) {
    final clamped = raw.isNaN ? 0.0 : raw.clamp(0.0, 100.0);
    return FormScore._(
      label: label,
      value: clamped.round(),
      detail: detail,
    );
  }

  const FormScore.unavailable(String label, String reason)
      : this._(label: label, unavailableReason: reason);

  bool get isAvailable => value != null;
}

/// The four form scores for one analysed jump, plus the takeoff type when the
/// footwork was clear enough to call.
class JumpFormScores {
  final FormScore bounce;
  final FormScore power;
  final FormScore control;
  final FormScore form;

  /// One-foot vs two-foot, or null when the two ankles left the ground too
  /// close together to be sure they were apart, yet too far apart to be sure
  /// they were together.
  final TakeoffType? takeoffType;

  const JumpFormScores({
    required this.bounce,
    required this.power,
    required this.control,
    required this.form,
    this.takeoffType,
  });

  List<FormScore> get all => [bounce, power, control, form];

  bool get hasAnyScore => all.any((s) => s.isAvailable);
}

/// Scores *how the jump looked* from the same pose series that timed it.
///
/// The headline vertical comes from flight time and is physics. Everything
/// here is coaching judgement laid over real measurements, and the two are
/// kept strictly apart: this file measures a handful of body quantities from
/// the tracked landmarks, then maps each through a documented threshold band
/// to a 0–100 score. The measurements are observations; **the bands are
/// informed heuristics, not validated norms** — they are the ranges a jump
/// coach would call good, not percentiles from a studied population, and
/// every one of them is written out below so nothing on screen rests on an
/// undocumented constant. No citations are given because there are none to
/// give.
///
/// ## Scale invariance
///
/// Every distance is divided by the athlete's own torso length in that frame
/// (shoulder midpoint to hip midpoint), exactly as
/// [PoseJumpDetector] does and for exactly the same reason: an athlete who
/// stands closer to the camera is bigger in pixels, and a score that moved
/// with camera distance would be measuring the camera, not the jump. Timing
/// quantities are in seconds, which are already absolute. Angles are ratios of
/// pixel distances, so they are invariant too.
///
/// ## When a score is absent
///
/// Each metric needs particular landmarks over a particular slice of the clip.
/// If the pose model did not confidently find them — wrists out of frame,
/// hips lost during the dip, no approach step in the trimmed range — that one
/// score comes back unavailable with the reason. The other three still stand.
abstract class JumpFormScoring {
  // ---------------------------------------------------------------------
  // Bounce — ground contact time (seconds)
  //
  // Reactive strength: how briefly the feet stay down between the plant and
  // the takeoff. A short contact means the stretch-shortening cycle is being
  // used rather than the athlete re-generating force from a dead stop.
  //
  // Heuristic band: 0.15 s or less scores 100, 0.45 s or more scores 0,
  // linear between. That spread is the range a coach watching approach jumps
  // would call "springy" through "heavy"; it is not a measured percentile,
  // and it is deliberately generous at the slow end because phone-frame
  // timing resolution is tens of milliseconds.
  // ---------------------------------------------------------------------
  static const double contactSecondsForFullScore = 0.15;
  static const double contactSecondsForZeroScore = 0.45;

  /// How far back before takeoff a preceding airborne phase still counts as
  /// this jump's approach step. Beyond this the athlete was simply standing.
  static const double _contactSearchSeconds = 1.5;

  // ---------------------------------------------------------------------
  // Power — countermovement depth (torso lengths) + hip rise rate
  //
  // Depth is a plateau, not a ramp: too shallow wastes the stretch reflex,
  // too deep turns a jump into a slow squat. A torso (shoulder-mid to
  // hip-mid) is roughly 29 % of standing height, so the full-credit band
  // 0.40–0.70 torso lengths is a hip drop of roughly 21–37 cm for a 1.83 m
  // athlete — a quarter to a half squat. Credit falls to zero below 0.15 and
  // above 1.05 torso lengths.
  //
  // Rise rate is the *fastest* the hips travel upward during the drive, in
  // torso lengths per second — a velocity, not an average across the drive.
  // 4.5 and above scores 100, 1.5 and below scores 0. For the same athlete
  // 4.5 torso/s is about 2.4 m/s of hip velocity, which sits sensibly under
  // the ~3.7 m/s takeoff velocity a 28" jump requires.
  //
  // Both are informed coaching bands, not norms. The two halves are averaged
  // equally: depth without speed is a squat, speed without depth is a hop.
  // ---------------------------------------------------------------------
  static const double dipZeroLow = 0.15;
  static const double dipFullLow = 0.40;
  static const double dipFullHigh = 0.70;
  static const double dipZeroHigh = 1.05;
  static const double riseTorsoPerSecondForZeroScore = 1.5;
  static const double riseTorsoPerSecondForFullScore = 4.5;

  /// Shortest interval a rise rate may be measured over. Consecutive frames
  /// can be 15 ms apart in the dense sampling pass, where a pixel or two of
  /// landmark jitter becomes an enormous apparent velocity.
  static const double _riseBaselineSeconds = 0.04;

  /// Slice before takeoff searched for the countermovement on a jump from
  /// standing, where the dip is a deliberate, fairly slow squat.
  static const double _standingDipSearchSeconds = 0.8;

  /// How far *before* the plant the search starts on an approach jump. The
  /// hips are already dropping as the foot comes down, so the low point sits
  /// slightly after the plant, but the descent begins just before it.
  static const double _approachDipLeadSeconds = 0.25;

  // ---------------------------------------------------------------------
  // Control — left/right symmetry and torso lean
  //
  // Three independent observations, averaged over whichever are available:
  //
  //  * mean |left ankle y − right ankle y|, in torso lengths: 0.05 or less
  //    scores 100, 0.35 or more scores 0.
  //  * mean |left hip y − right hip y|, in torso lengths: 0.03 or less scores
  //    100, 0.20 or more scores 0. Tighter than the ankles because the pelvis
  //    should stay level even when the legs do not.
  //  * mean deviation of the shoulder-midpoint→hip-midpoint line from
  //    vertical: 5° or less scores 100, 28° or more scores 0.
  //
  // On a **one-foot takeoff the ankle term is dropped**, because scissoring
  // the legs is the technique, not a fault — scoring it as asymmetry would
  // punish a correctly executed jump. Fewer than two available terms yields
  // no score rather than a score resting on one weak signal.
  // ---------------------------------------------------------------------
  static const double ankleAsymmetryForFullScore = 0.05;
  static const double ankleAsymmetryForZeroScore = 0.35;
  static const double hipAsymmetryForFullScore = 0.03;
  static const double hipAsymmetryForZeroScore = 0.20;
  static const double leanDegreesForFullScore = 5;
  static const double leanDegreesForZeroScore = 28;

  /// Control is judged over the jump itself, starting slightly before takeoff
  /// so the drive phase is included.
  static const double _controlLeadSeconds = 0.3;

  // ---------------------------------------------------------------------
  // Form — arm swing amplitude and timing
  //
  // The arms are measured **relative to the athlete's own hips**, as
  // (hip-mid y − wrist y) / torso, so the whole body rising through flight
  // does not masquerade as an arm swing. Amplitude is the range of that
  // quantity across the swing window; 1.8 torso lengths or more scores 100,
  // 0.5 or less scores 0. A full swing runs from wrists hanging below the
  // hips to wrists above the head, which is roughly 2.5 torso lengths, so
  // 1.8 is a strong-but-reachable swing.
  //
  // Timing is when that arm raise peaks relative to takeoff. Full credit from
  // 0.10 s before takeoff to 0.02 s after — the arms should be finishing as
  // the feet leave. Credit falls to zero at 0.40 s early (swing spent long
  // before the drive) and at 0.25 s late (arms still rising after the feet
  // are gone, which adds nothing to the jump). Lateness is punished over a
  // shorter span than earliness because it is the more costly error.
  //
  // Amplitude is weighted 0.6 against timing 0.4: a swing that does not
  // happen cannot be well timed. All of this is coaching judgement.
  // ---------------------------------------------------------------------
  static const double armSwingTorsoForZeroScore = 0.5;
  static const double armSwingTorsoForFullScore = 1.8;
  static const double armPeakZeroEarlySeconds = -0.40;
  static const double armPeakFullEarlySeconds = -0.10;
  static const double armPeakFullLateSeconds = 0.02;
  static const double armPeakZeroLateSeconds = 0.25;
  static const double _armWindowLeadSeconds = 0.8;
  static const double _armWindowTrailSeconds = 0.15;

  // ---------------------------------------------------------------------
  // Takeoff type
  //
  // The two ankles are timed separately across the same ground threshold the
  // detector uses. Within 0.07 s of each other is two-foot; 0.15 s or more
  // apart is one-foot; in between is honestly undetermined rather than
  // guessed. The gap between the bands is where a phone's frame step and a
  // sloppy two-foot plant become indistinguishable.
  // ---------------------------------------------------------------------
  static const double twoFootMaxSplitSeconds = 0.07;
  static const double oneFootMinSplitSeconds = 0.15;
  static const double _ankleSearchLeadSeconds = 0.6;
  static const double _ankleSearchTrailSeconds = 0.4;

  /// Fewest tracked frames worth scoring anything from at all.
  static const int minTrackedSamples = 8;

  static const String _noTracking =
      'not enough tracked frames in this clip';

  /// Convenience wrapper over a completed pose pass. Returns null when the
  /// pose detector produced no measurement — there is no airborne window to
  /// hang the metrics off, so there is nothing to score.
  static JumpFormScores? fromDiagnostics(PoseJumpDiagnostics diagnostics) {
    final measurement = diagnostics.result;
    if (measurement == null) return null;
    return compute(
      samples: diagnostics.samples,
      takeoff: measurement.takeoff,
      landing: measurement.landing,
      groundBaselineY: diagnostics.groundBaselineY,
      torsoPixels: diagnostics.torsoPixels,
    );
  }

  /// Scores the jump bounded by [takeoff]/[landing] from the landmark series
  /// in [samples].
  ///
  /// [groundBaselineY] and [torsoPixels] come from the detector that found
  /// that window, so the ground threshold used here is the same one the
  /// timing used.
  static JumpFormScores compute({
    required List<PoseSample> samples,
    required Duration takeoff,
    required Duration landing,
    required double groundBaselineY,
    required double torsoPixels,
  }) {
    final tracked = [...samples.where((s) => s.isDetected)]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (torsoPixels <= 0 || tracked.length < minTrackedSamples) {
      return JumpFormScores(
        bounce: const FormScore.unavailable('Bounce', _noTracking),
        power: const FormScore.unavailable('Power', _noTracking),
        control: const FormScore.unavailable('Control', _noTracking),
        form: const FormScore.unavailable('Form', _noTracking),
      );
    }

    final takeoffSeconds = _seconds(takeoff);
    final landingSeconds = _seconds(landing);
    final thresholdY =
        groundBaselineY - torsoPixels * PoseJumpDetector.liftTorsoFraction;

    final takeoffType = _takeoffType(tracked, thresholdY, takeoffSeconds);
    final plantSeconds =
        _approachPlantSeconds(tracked, thresholdY, takeoffSeconds);

    return JumpFormScores(
      bounce: _bounce(tracked, thresholdY, takeoffSeconds),
      power: _power(
        tracked,
        torsoPixels,
        takeoffSeconds,
        approachPlantSeconds: plantSeconds,
      ),
      control: _control(
        tracked,
        torsoPixels,
        takeoffSeconds,
        landingSeconds,
        takeoffType,
      ),
      form: _form(tracked, torsoPixels, takeoffSeconds),
      takeoffType: takeoffType,
    );
  }

  // ------------------------------------------------------------------ Bounce

  /// Instant the athlete's feet came down for the final plant, i.e. the end of
  /// the approach step. Null when the jump started from standing, which is
  /// also the signal that this is not an approach jump at all — [_power] needs
  /// to know that as much as [_bounce] does.
  static double? _approachPlantSeconds(
    List<PoseSample> tracked,
    double thresholdY,
    double takeoffSeconds,
  ) {
    final before = tracked
        .where((s) =>
            _seconds(s.timestamp) <= takeoffSeconds &&
            _seconds(s.timestamp) >= takeoffSeconds - _contactSearchSeconds)
        .toList();
    if (before.length < 2) return null;

    int? lastGrounded;
    for (var i = before.length - 1; i >= 0; i--) {
      if (before[i].footY! >= thresholdY) {
        lastGrounded = i;
        break;
      }
    }
    if (lastGrounded == null) return null;

    int? lastAirborne;
    for (var i = lastGrounded - 1; i >= 0; i--) {
      if (before[i].footY! < thresholdY) {
        lastAirborne = i;
        break;
      }
    }
    if (lastAirborne == null) return null;

    return _crossingSeconds(
      before[lastAirborne],
      before[lastAirborne + 1],
      thresholdY,
    );
  }

  static FormScore _bounce(
    List<PoseSample> tracked,
    double thresholdY,
    double takeoffSeconds,
  ) {
    // Samples from the approach up to the takeoff instant.
    final before = tracked
        .where((s) =>
            _seconds(s.timestamp) <= takeoffSeconds &&
            _seconds(s.timestamp) >= takeoffSeconds - _contactSearchSeconds)
        .toList();
    if (before.length < 2) {
      return const FormScore.unavailable(
        'Bounce',
        'the run-up before takeoff is not in this clip',
      );
    }

    // The plant is where the feet last came *down* through the ground
    // threshold: the end of the previous airborne phase (the approach step).
    // A jump from a standing start has no such phase, and inventing a contact
    // time for it would be fabricating the measurement.
    //
    // The last *grounded* sample is found first, so a takeoff timed a frame or
    // two late (the detector's window is corrected physics, not a sample
    // index) leaves a trailing airborne sample that is skipped rather than
    // mistaken for the plant.
    int? lastGrounded;
    for (var i = before.length - 1; i >= 0; i--) {
      if (before[i].footY! >= thresholdY) {
        lastGrounded = i;
        break;
      }
    }
    int? lastAirborne;
    if (lastGrounded != null) {
      for (var i = lastGrounded - 1; i >= 0; i--) {
        if (before[i].footY! < thresholdY) {
          lastAirborne = i;
          break;
        }
      }
    }
    if (lastAirborne == null) {
      return const FormScore.unavailable(
        'Bounce',
        'no approach step before takeoff, so there is no contact to time',
      );
    }

    final plant = _crossingSeconds(
      before[lastAirborne],
      before[lastAirborne + 1],
      thresholdY,
    );
    final contact = takeoffSeconds - plant;
    if (contact <= 0.02) {
      return const FormScore.unavailable(
        'Bounce',
        'the plant and the takeoff fall in the same frame',
      );
    }

    return FormScore.measured(
      'Bounce',
      _ramp(
        contact,
        zeroAt: contactSecondsForZeroScore,
        fullAt: contactSecondsForFullScore,
      ),
      '${contact.toStringAsFixed(2)} s on the floor before takeoff',
    );
  }

  // ------------------------------------------------------------------- Power

  static FormScore _power(
    List<PoseSample> tracked,
    double torsoPixels,
    double takeoffSeconds, {
    double? approachPlantSeconds,
  }) {
    // Where to look for the dip. Searching a fixed second-plus before takeoff
    // was wrong on an approach jump: the run-up bobs the hips every stride, so
    // the "lowest hip" landed on some random stride and the drive rate came
    // out at 1.1 torso/s -- physically impossible next to a 28" jump, whose
    // takeoff velocity is around 7 torso/s. On an approach jump the only dip
    // that means anything is the one in the plant, so the search starts there.
    final windowStart = approachPlantSeconds != null
        ? approachPlantSeconds - _approachDipLeadSeconds
        : takeoffSeconds - _standingDipSearchSeconds;

    final hips = <({double t, double y})>[];
    for (final s in tracked) {
      final t = _seconds(s.timestamp);
      if (t > takeoffSeconds || t < windowStart) continue;
      final y = _midY(s.leftHip, s.rightHip);
      if (y != null) hips.add((t: t, y: y));
    }
    if (hips.length < 4) {
      return const FormScore.unavailable(
        'Power',
        'hips not tracked well enough before takeoff',
      );
    }

    // Lowest hip position = largest y (image coordinates grow downward).
    var lowIndex = 0;
    for (var i = 1; i < hips.length; i++) {
      if (hips[i].y > hips[lowIndex].y) lowIndex = i;
    }
    // A standing jump needs a couple of samples above the low point to prove
    // the athlete actually descended into it. An approach jump's window starts
    // at the plant, where the hips are already near their lowest, so demanding
    // a visible descent there would reject the normal case.
    if (approachPlantSeconds == null && lowIndex < 2) {
      return const FormScore.unavailable(
        'Power',
        'the dip before takeoff starts before this clip does',
      );
    }
    if (lowIndex >= hips.length - 1) {
      return const FormScore.unavailable(
        'Power',
        'the drive out of the dip is not in this clip',
      );
    }

    // Depth against a standing reference: the median hip height before the
    // athlete dipped, a median rather than a single frame so one snapped
    // landmark cannot set the depth on its own.
    //
    // On an approach jump the window can open at the low point itself, leaving
    // nothing above it to average; depth is unused in that branch, so it is
    // simply zero rather than a median of an empty list.
    final depth = lowIndex == 0
        ? 0.0
        : (hips[lowIndex].y -
                _median([for (var i = 0; i < lowIndex; i++) hips[i].y])) /
            torsoPixels;

    // Fastest the hips travel upward during the drive, not the average across
    // it.
    //
    // The band below is written as a *velocity* — its own comment calls 4.5
    // torso/s "about 2.4 m/s of hip velocity" — but this measured the mean
    // from the low point to takeoff. A body accelerating from rest to takeoff
    // averages about half its final speed, so the code was reporting roughly
    // half of what the band was written to judge, and a real 28" jump scored
    // 9/100. That is a definition mismatch, not an athlete being slow.
    //
    // Rates are taken over pairs at least [_riseBaselineSeconds] apart so one
    // jittery landmark across a 15 ms gap cannot invent a spike.
    var riseRate = 0.0;
    var measuredAny = false;
    for (var i = lowIndex; i < hips.length; i++) {
      for (var j = i + 1; j < hips.length; j++) {
        final dt = hips[j].t - hips[i].t;
        if (dt < _riseBaselineSeconds) continue;
        final rate = (hips[i].y - hips[j].y) / torsoPixels / dt;
        if (!measuredAny || rate > riseRate) {
          riseRate = rate;
          measuredAny = true;
        }
        break;
      }
    }
    if (!measuredAny) {
      return const FormScore.unavailable(
        'Power',
        'the drive out of the dip is not in this clip',
      );
    }

    final riseScore = _ramp(
      riseRate,
      zeroAt: riseTorsoPerSecondForZeroScore,
      fullAt: riseTorsoPerSecondForFullScore,
    );

    // On an approach jump the dip is *supposed* to be shallow: the athlete is
    // converting run-up speed through a stiff, fast plant, not squatting. The
    // countermovement depth band describes a standing jump, and applying it
    // here scored correct technique at zero. So depth only counts when the
    // athlete jumped from standing; on an approach, how fast the hips drive is
    // the whole measurement.
    if (approachPlantSeconds != null) {
      return FormScore.measured(
        'Power',
        riseScore,
        'driving up at ${riseRate.toStringAsFixed(1)}× torso/s '
        'off the plant',
      );
    }

    final depthScore = _plateau(
      depth,
      zeroLow: dipZeroLow,
      fullLow: dipFullLow,
      fullHigh: dipFullHigh,
      zeroHigh: dipZeroHigh,
    );

    return FormScore.measured(
      'Power',
      (depthScore + riseScore) / 2,
      'dip ${depth.toStringAsFixed(2)}× torso, '
      'driving up at ${riseRate.toStringAsFixed(1)}× torso/s',
    );
  }

  // ----------------------------------------------------------------- Control

  static FormScore _control(
    List<PoseSample> tracked,
    double torsoPixels,
    double takeoffSeconds,
    double landingSeconds,
    TakeoffType? takeoffType,
  ) {
    final ankleGaps = <double>[];
    final hipGaps = <double>[];
    final leanDegrees = <double>[];

    for (final s in tracked) {
      final t = _seconds(s.timestamp);
      if (t < takeoffSeconds - _controlLeadSeconds || t > landingSeconds) {
        continue;
      }

      final la = s.leftAnkle;
      final ra = s.rightAnkle;
      if (la != null && ra != null) {
        ankleGaps.add((la.y - ra.y).abs() / torsoPixels);
      }

      final lh = s.leftHip;
      final rh = s.rightHip;
      if (lh != null && rh != null) {
        hipGaps.add((lh.y - rh.y).abs() / torsoPixels);
      }

      final ls = s.leftShoulder;
      final rs = s.rightShoulder;
      if (ls != null && rs != null && lh != null && rh != null) {
        final dx = (lh.x + rh.x) / 2 - (ls.x + rs.x) / 2;
        final dy = (lh.y + rh.y) / 2 - (ls.y + rs.y) / 2;
        if (dx != 0 || dy != 0) {
          leanDegrees.add(
            math.atan2(dx.abs(), dy.abs()) * 180 / math.pi,
          );
        }
      }
    }

    final parts = <double>[];
    final detail = <String>[];

    // A one-foot takeoff scissors the legs on purpose; scoring that as an
    // asymmetry would mark down a correctly executed jump.
    if (takeoffType != TakeoffType.oneFoot && ankleGaps.isNotEmpty) {
      final mean = _mean(ankleGaps);
      parts.add(_ramp(
        mean,
        zeroAt: ankleAsymmetryForZeroScore,
        fullAt: ankleAsymmetryForFullScore,
      ));
      detail.add('feet ${mean.toStringAsFixed(2)}× torso apart in height');
    }
    if (hipGaps.isNotEmpty) {
      final mean = _mean(hipGaps);
      parts.add(_ramp(
        mean,
        zeroAt: hipAsymmetryForZeroScore,
        fullAt: hipAsymmetryForFullScore,
      ));
      detail.add('hips ${mean.toStringAsFixed(2)}× torso off level');
    }
    if (leanDegrees.isNotEmpty) {
      final mean = _mean(leanDegrees);
      parts.add(_ramp(
        mean,
        zeroAt: leanDegreesForZeroScore,
        fullAt: leanDegreesForFullScore,
      ));
      detail.add('torso ${mean.toStringAsFixed(0)}° off vertical');
    }

    if (parts.length < 2) {
      return const FormScore.unavailable(
        'Control',
        'not enough of your body was tracked through the jump',
      );
    }

    return FormScore.measured('Control', _mean(parts), detail.join(' · '));
  }

  // -------------------------------------------------------------------- Form

  static FormScore _form(
    List<PoseSample> tracked,
    double torsoPixels,
    double takeoffSeconds,
  ) {
    // Arm raise measured against the athlete's own hips, so the body rising
    // through flight is not mistaken for an arm swing.
    final raise = <({double t, double v})>[];
    for (final s in tracked) {
      final t = _seconds(s.timestamp);
      if (t < takeoffSeconds - _armWindowLeadSeconds ||
          t > takeoffSeconds + _armWindowTrailSeconds) {
        continue;
      }
      final wrist = _midY(s.leftWrist, s.rightWrist);
      final hip = _midY(s.leftHip, s.rightHip);
      if (wrist == null || hip == null) continue;
      raise.add((t: t, v: (hip - wrist) / torsoPixels));
    }
    if (raise.length < 4) {
      return const FormScore.unavailable(
        'Form',
        'arms not visible in this clip',
      );
    }

    var lowest = raise.first.v;
    var peakIndex = 0;
    for (var i = 1; i < raise.length; i++) {
      if (raise[i].v < lowest) lowest = raise[i].v;
      if (raise[i].v > raise[peakIndex].v) peakIndex = i;
    }
    final amplitude = raise[peakIndex].v - lowest;
    final peakOffset = raise[peakIndex].t - takeoffSeconds;

    final amplitudeScore = _ramp(
      amplitude,
      zeroAt: armSwingTorsoForZeroScore,
      fullAt: armSwingTorsoForFullScore,
    );
    final timingScore = _plateau(
      peakOffset,
      zeroLow: armPeakZeroEarlySeconds,
      fullLow: armPeakFullEarlySeconds,
      fullHigh: armPeakFullLateSeconds,
      zeroHigh: armPeakZeroLateSeconds,
    );

    final timing = peakOffset.abs() < 0.005
        ? 'peaking right at takeoff'
        : peakOffset < 0
            ? 'peaking ${(-peakOffset).toStringAsFixed(2)} s before takeoff'
            : 'peaking ${peakOffset.toStringAsFixed(2)} s after takeoff';

    return FormScore.measured(
      'Form',
      0.6 * amplitudeScore + 0.4 * timingScore,
      'arm swing ${amplitude.toStringAsFixed(2)}× torso, $timing',
    );
  }

  // ------------------------------------------------------------ Takeoff type

  static TakeoffType? _takeoffType(
    List<PoseSample> tracked,
    double thresholdY,
    double takeoffSeconds,
  ) {
    final left = _ankleLiftSeconds(
      tracked,
      (s) => s.leftAnkle,
      thresholdY,
      takeoffSeconds,
    );
    final right = _ankleLiftSeconds(
      tracked,
      (s) => s.rightAnkle,
      thresholdY,
      takeoffSeconds,
    );
    if (left == null || right == null) return null;

    final split = (left - right).abs();
    if (split <= twoFootMaxSplitSeconds) return TakeoffType.twoFoot;
    if (split >= oneFootMinSplitSeconds) return TakeoffType.oneFoot;
    return null;
  }

  /// Instant one ankle crossed up through the ground threshold, interpolated
  /// between samples exactly as the detector interpolates the foot crossing.
  ///
  /// A clip can hold several upward crossings — the approach steps each lift a
  /// foot off the floor — so the one *nearest the measured takeoff* is the
  /// one taken. Picking the first would time a run-up stride instead.
  static double? _ankleLiftSeconds(
    List<PoseSample> tracked,
    PosePoint? Function(PoseSample) pick,
    double thresholdY,
    double takeoffSeconds,
  ) {
    final series = <({double t, double y})>[];
    for (final s in tracked) {
      final t = _seconds(s.timestamp);
      if (t < takeoffSeconds - _ankleSearchLeadSeconds ||
          t > takeoffSeconds + _ankleSearchTrailSeconds) {
        continue;
      }
      final p = pick(s);
      if (p != null) series.add((t: t, y: p.y));
    }

    double? best;
    for (var i = 1; i < series.length; i++) {
      if (series[i].y < thresholdY && series[i - 1].y >= thresholdY) {
        final span = series[i - 1].y - series[i].y;
        final crossing = span == 0
            ? series[i].t
            : series[i - 1].t +
                (series[i].t - series[i - 1].t) *
                    ((series[i - 1].y - thresholdY) / span).clamp(0.0, 1.0);
        if (best == null ||
            (crossing - takeoffSeconds).abs() <
                (best - takeoffSeconds).abs()) {
          best = crossing;
        }
      }
    }
    return best;
  }

  // ----------------------------------------------------------------- helpers

  /// Linear score that is 0 at [zeroAt] and 100 at [fullAt], clamped outside.
  /// Works in either direction, so a "smaller is better" quantity (contact
  /// time) uses the same helper as a "bigger is better" one.
  static double _ramp(
    double value, {
    required double zeroAt,
    required double fullAt,
  }) {
    if (fullAt == zeroAt) return 0;
    final t = (value - zeroAt) / (fullAt - zeroAt);
    return t.clamp(0.0, 1.0) * 100;
  }

  /// Score that is 100 across [fullLow]..[fullHigh] and falls linearly to 0 at
  /// [zeroLow] and [zeroHigh] — for quantities where both too little and too
  /// much are wrong.
  static double _plateau(
    double value, {
    required double zeroLow,
    required double fullLow,
    required double fullHigh,
    required double zeroHigh,
  }) {
    if (value <= zeroLow || value >= zeroHigh) return 0;
    if (value >= fullLow && value <= fullHigh) return 100;
    if (value < fullLow) {
      return (value - zeroLow) / (fullLow - zeroLow) * 100;
    }
    return (zeroHigh - value) / (zeroHigh - fullHigh) * 100;
  }

  /// Mean y of two landmarks, or the one that was found, or null.
  static double? _midY(PosePoint? a, PosePoint? b) {
    if (a != null && b != null) return (a.y + b.y) / 2;
    return a?.y ?? b?.y;
  }

  static double _mean(List<double> values) =>
      values.reduce((a, b) => a + b) / values.length;

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  static double _seconds(Duration d) =>
      d.inMicroseconds / Duration.microsecondsPerSecond;

  /// Where the interpolated foot line between [a] and [b] crosses
  /// [thresholdY], in seconds.
  static double _crossingSeconds(
    PoseSample a,
    PoseSample b,
    double thresholdY,
  ) {
    final ya = a.footY!;
    final yb = b.footY!;
    final ta = _seconds(a.timestamp);
    final tb = _seconds(b.timestamp);
    final span = yb - ya;
    if (span == 0) return tb;
    final fraction = ((thresholdY - ya) / span).clamp(0.0, 1.0);
    return ta + (tb - ta) * fraction;
  }
}
