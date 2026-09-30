import 'dart:math' as math;

import 'ballistic_fit.dart';
import 'flight_time.dart';
import 'models/jump_measurement.dart';

/// One tracked body landmark, in image pixels.
///
/// Same coordinate convention as [PoseSample]: x grows to the right, y grows
/// *downward* from a top-left origin. A landmark the model was not confident
/// about is represented by a null [PosePoint], never by a zeroed one.
class PosePoint {
  final double x;
  final double y;

  const PosePoint(this.x, this.y);

  /// Midpoint of two landmarks, or whichever single one was found, or null.
  ///
  /// The single-landmark fallback matches [PoseSample]'s rule: a landmark the
  /// model was not confident about is absent, and the other side of a pair is
  /// a better answer than nothing. It is not an invented position.
  static PosePoint? mid(PosePoint? a, PosePoint? b) {
    if (a != null && b != null) {
      return PosePoint((a.x + b.x) / 2, (a.y + b.y) / 2);
    }
    return a ?? b;
  }

  @override
  String toString() =>
      'PosePoint(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Which way is *up* for the athlete, in image coordinates.
///
/// ## Why the image's own vertical is not good enough
///
/// The detector used to read image `y` as height. That silently assumes the
/// frames handed to the pose model are upright, and on a phone they are not:
/// an iPhone portrait recording is stored **landscape with a rotation flag**
/// (`ffprobe` on a rejected real clip: `1920x1080`, `rotation=-90`). Players
/// apply the flag; a frame extractor need not. If the pose model sees the raw
/// stored frame, the athlete is lying on their side — and a vertical jump then
/// moves the feet almost entirely *horizontally* in image coordinates, leaving
/// `y` nearly unchanged. That is exactly how a plainly visible jump came back
/// as `noAirborneWindow`.
///
/// Reading the rotation flag and rotating the frames would fix that one case
/// and nothing else: it depends on how each of the frame extractor and the
/// pose model already handle orientation (neither verifiable off-device), and
/// it still fails on a camera propped at an angle. Measuring along the
/// athlete's own up-axis fixes both, and needs no metadata at all.
///
/// ## Convention
///
/// [upX]/[upY] are a unit vector pointing from the athlete's hips toward their
/// shoulders. Image y grows *downward*, so the upright case is `(0, -1)` —
/// see [image]. Every measurement below is expressed as a **descent**: how far
/// down the axis a point sits, so that larger still means lower, exactly as
/// raw image y did. With [image] that arithmetic is the identity, which is why
/// nothing downstream had to change its sign conventions.
class BodyAxis {
  /// Unit vector, in image coordinates, pointing along the athlete's spine
  /// from hips to shoulders.
  final double upX;
  final double upY;

  const BodyAxis._(this.upX, this.upY);

  /// The frame's own vertical — what the detector assumed before this existed,
  /// and still the fallback when the pose gives no torso to measure against.
  static const image = BodyAxis._(0.0, -1.0);

  /// Normalises an up-vector into an axis. Null when it has no usable length
  /// (a collapsed torso, or landmarks that landed on top of each other).
  static BodyAxis? fromUpVector(double x, double y) {
    final length = math.sqrt(x * x + y * y);
    if (!length.isFinite || length < 1e-9) return null;
    return BodyAxis._(x / length, y / length);
  }

  /// How far *down* this axis the point ([x], [y]) sits, in pixels.
  ///
  /// Same sense as raw image y — bigger is lower — so a ground baseline is
  /// still a high percentile and a foot that rises still produces a smaller
  /// number. The zero point is arbitrary (it moves with the frame origin),
  /// which is fine: every use of it is a *difference* against the baseline.
  double descent(double x, double y) => -(x * upX + y * upY);

  double descentOf(PosePoint p) => descent(p.x, p.y);

  /// Acute angle, in degrees, between the vector ([x], [y]) and this axis.
  /// Used for the torso-lean term of the form scores.
  double acuteAngleDegrees(double x, double y) {
    final along = descent(x, y).abs();
    final across = (y * upX - x * upY).abs();
    return math.atan2(across, along) * 180 / math.pi;
  }

  /// True when this is the frame's own vertical, i.e. no rotation was inferred.
  bool get isImageVertical => upX == 0.0 && upY == -1.0;

  /// How far this axis is rotated from image-up, in degrees, clockwise
  /// positive. 0 on an upright frame, ±90 on a phone clip whose rotation flag
  /// was never applied. Reported in the developer-facing diagnostics.
  double get tiltDegrees => math.atan2(upX, -upY) * 180 / math.pi;

  @override
  String toString() =>
      'BodyAxis(${upX.toStringAsFixed(3)}, ${upY.toStringAsFixed(3)})';
}

/// One sampled instant of a jump clip, as seen by an on-device pose model.
///
/// Image coordinates: y grows *downward* (the top-left origin every image
/// coordinate system uses). So a foot that is higher off the ground has a
/// *smaller* [footY].
///
/// Both measurements are null when no athlete was found in that frame — a
/// missing detection is never a zero. Zero is a real position (the very top
/// of the frame) and treating "not found" as "at the top of the frame" would
/// invent a spectacular jump out of a failed inference.
class PoseSample {
  /// Position of this frame in the clip's timeline.
  final Duration timestamp;

  /// Lowest tracked foot/ankle y (i.e. the *largest* y of the two feet — the
  /// one nearer the ground). Null when no pose was detected.
  ///
  /// Kept as the scalar it always was, but it is only the whole story on an
  /// upright frame. Prefer [foot] and [footDescent]; see [BodyAxis].
  final double? footY;

  /// The ground-contact landmark [footY] was read from, as a full point.
  ///
  /// This is what lets the detector measure along the athlete's own up-axis
  /// rather than the image's (see [BodyAxis]). Null on a series that only ever
  /// carried the scalar — older fixtures and the pinned real-device capture —
  /// and a series like that keeps the image's vertical, unchanged.
  final PosePoint? foot;

  /// Shoulder-midpoint to hip-midpoint distance, in pixels: the athlete's own
  /// scale reference. Null when no pose was detected.
  ///
  /// This must be the **full 2-D distance** between the two midpoints, not the
  /// difference of their y coordinates. On a frame whose rotation flag was
  /// never applied the athlete lies sideways and a y-only torso collapses to
  /// nearly zero, which took the scale reference — and with it the threshold
  /// every distance is judged against — down with it.
  ///
  /// The torso is used rather than a full head-to-ankle span because the legs
  /// tuck in mid-flight, which would make a leg-inclusive "body height" shrink
  /// exactly during the phase we are trying to measure. The torso is
  /// effectively rigid through a jump, so its pixel length tracks only the one
  /// thing we want it to track: how big the athlete is in this frame, i.e.
  /// how far they are from the camera.
  final double? torsoPixels;

  /// Individual landmarks, for the *form* scores rather than the timing (see
  /// `core/jump_form_scores.dart`). Each is null whenever the pose model was
  /// not confident about that specific landmark in this frame — the same rule
  /// as [footY] and [torsoPixels], and for the same reason: a guessed joint
  /// position is fabricated data, and a zeroed one would read as "pinned to
  /// the top-left corner of the frame".
  ///
  /// The timing rule reads only [foot]/[footY], [torsoPixels] and — via
  /// [torsoUpVector] — the shoulders and hips, which are what [BodyAxis] is
  /// derived from. The knees, wrists and ankles are for the form scores alone.
  final PosePoint? leftAnkle;
  final PosePoint? rightAnkle;
  final PosePoint? leftKnee;
  final PosePoint? rightKnee;
  final PosePoint? leftHip;
  final PosePoint? rightHip;
  final PosePoint? leftShoulder;
  final PosePoint? rightShoulder;
  final PosePoint? leftWrist;
  final PosePoint? rightWrist;

  const PoseSample({
    required this.timestamp,
    this.footY,
    this.foot,
    this.torsoPixels,
    this.leftAnkle,
    this.rightAnkle,
    this.leftKnee,
    this.rightKnee,
    this.leftHip,
    this.rightHip,
    this.leftShoulder,
    this.rightShoulder,
    this.leftWrist,
    this.rightWrist,
  });

  /// True when the pose model actually found the athlete in this frame.
  bool get isDetected => footY != null && torsoPixels != null;

  /// Midpoint of the two shoulders, or the one that was found, or null.
  PosePoint? get shoulderMid => PosePoint.mid(leftShoulder, rightShoulder);

  /// Midpoint of the two hips, or the one that was found, or null.
  PosePoint? get hipMid => PosePoint.mid(leftHip, rightHip);

  /// Vector from the hip midpoint to the shoulder midpoint — this frame's
  /// reading of which way the athlete is standing. Null when either midpoint
  /// is missing. Not normalised, and not to be used on its own: a single
  /// frame's torso tilts through the jump, which is why [BodyAxis] is derived
  /// from a robust average over the *grounded* frames instead.
  ({double x, double y})? get torsoUpVector {
    final s = shoulderMid;
    final h = hipMid;
    if (s == null || h == null) return null;
    return (x: s.x - h.x, y: s.y - h.y);
  }

  /// This frame's foot position measured *down* [axis], in pixels.
  ///
  /// Falls back to raw [footY] when no [foot] point was captured, which is
  /// exact for [BodyAxis.image] and only ever reached for that axis — a series
  /// missing foot points is never allowed a tilted axis (see
  /// `PoseJumpDetector._resolveAxis`). Null when nothing was detected.
  double? footDescent(BodyAxis axis) {
    final f = foot;
    if (f != null) return axis.descentOf(f);
    return footY;
  }
}

/// Why [PoseJumpDetector] declined to report a measurement. Surfaced in the
/// diagnostics so a real-device report says what went wrong instead of just
/// "it fell back to the old detector".
enum PoseDetectionRejection {
  none('measured'),
  unreadable('no frames could be read from the clip'),
  tooFewSamples('too few sampled frames'),
  tooManyMissing('athlete not found in enough frames'),
  gappyWindow('athlete lost during the jump itself'),
  noScaleReference('no usable body-scale reference'),
  noAirborneWindow('feet never left the ground baseline'),
  liftTooSmall('foot lift too small to time reliably'),
  implausibleDuration('airborne time outside the plausible range');

  final String label;
  const PoseDetectionRejection(this.label);
}

/// Everything [PoseJumpDetector.detectWithDiagnostics] measured and decided,
/// in the same spirit as `JumpDetectionDiagnostics` in
/// `core/jump_auto_detector.dart`: the result screen shows this verbatim so
/// the next real-device report can be diagnosed instead of guessed at.
class PoseJumpDiagnostics {
  /// Frames handed to the detector (including ones with no pose).
  final int sampleCount;

  /// Frames in which the pose model actually found the athlete.
  final int detectedCount;

  /// Median torso length in pixels across the detected frames — the scale
  /// every distance below is expressed against.
  final double torsoPixels;

  /// Which way the detector decided "up" was for this athlete. [BodyAxis.image]
  /// means it fell back to the frame's own vertical — see [BodyAxis].
  final BodyAxis bodyAxis;

  /// How many grounded frames the axis was averaged over. 0 when the axis is
  /// the image default.
  final int axisSampleCount;

  /// Ground level over the **whole clip**: the robust high percentile of the
  /// foot's descent along [bodyAxis] (which is raw [PoseSample.footY] when that
  /// axis is the image's own vertical).
  ///
  /// Reported for reference and as the fallback the local estimate degrades to,
  /// but it is **not** what the timing is measured against — see
  /// [localGroundBaselines].
  final double groundBaselineY;

  /// The clip-wide airborne threshold, along [bodyAxis] (above
  /// [groundBaselineY], so numerically *smaller* than it). Reported for
  /// reference; the run detection uses [liftThresholdPixels] against the
  /// *local* baseline.
  final double thresholdY;

  /// Ground level estimated **near each sample in time**, aligned one-to-one
  /// with [samples] and null wherever no pose was detected.
  ///
  /// This is what the timing is actually measured against. An athlete who walks
  /// toward the camera grows in frame, so their standing foot position drifts
  /// down the image over seconds — on the capture that motivated this, by
  /// 116 px while the jump itself was only 87 px. One baseline for the clip
  /// cannot describe both ends of that; a rolling one can. See
  /// [PoseJumpDetector] rule 1.
  final List<double?> localGroundBaselines;

  /// The local ground level at the takeoff end of the measured window — the
  /// number the *form* scores should judge ground contact against (see
  /// `core/jump_form_scores.dart`). Null when no window was found.
  final double? localBaselineAtTakeoff;

  /// How far above the baseline [thresholdY] sits, in pixels.
  final double liftThresholdPixels;

  /// Highest the feet actually got above the baseline, in pixels. 0 when no
  /// window was found.
  final double peakLiftPixels;

  /// Interpolated threshold crossings for the chosen window, before the
  /// parabola correction. Null when no window was found.
  final Duration? crossingTakeoff;
  final Duration? crossingLanding;

  /// Airborne time straight off the threshold crossings (systematically short
  /// — see [PoseJumpDetector]) and after correcting it back to the instants
  /// the feet were at ground level.
  final double? rawCrossingSeconds;
  final double? correctedSeconds;

  /// Airborne time from the least-squares parabola fit — the preferred
  /// figure, and null when the window was too short to fit.
  final double? fittedSeconds;

  /// Root-mean-square residual of that fit, in pixels: how convincingly
  /// the tracked feet actually followed a ballistic arc.
  final double? fitResidualPixels;

  /// Scene scale gravity itself implies, in pixels per metre. A free
  /// by-product of the fit's curvature, and an independent sanity check.
  final double? pixelsPerMetre;

  /// How many separate airborne windows the clip contained. More than one
  /// is not an error — the highest is the one measured.
  final int airborneWindowsSeen;

  /// Every sample, sorted by time, exactly as the detector read them.
  final List<PoseSample> samples;

  final PoseDetectionRejection rejection;
  final JumpMeasurement? result;

  const PoseJumpDiagnostics({
    required this.sampleCount,
    required this.detectedCount,
    required this.torsoPixels,
    this.bodyAxis = BodyAxis.image,
    this.axisSampleCount = 0,
    required this.groundBaselineY,
    this.localGroundBaselines = const [],
    this.localBaselineAtTakeoff,
    required this.thresholdY,
    required this.liftThresholdPixels,
    required this.peakLiftPixels,
    required this.crossingTakeoff,
    required this.crossingLanding,
    required this.rawCrossingSeconds,
    required this.correctedSeconds,
    this.fittedSeconds,
    this.fitResidualPixels,
    this.pixelsPerMetre,
    this.airborneWindowsSeen = 0,
    required this.samples,
    required this.rejection,
    required this.result,
  });

  int get missingCount => sampleCount - detectedCount;

  static const empty = PoseJumpDiagnostics(
    sampleCount: 0,
    detectedCount: 0,
    torsoPixels: 0,
    groundBaselineY: 0,
    thresholdY: 0,
    liftThresholdPixels: 0,
    peakLiftPixels: 0,
    crossingTakeoff: null,
    crossingLanding: null,
    rawCrossingSeconds: null,
    correctedSeconds: null,
    samples: [],
    rejection: PoseDetectionRejection.tooFewSamples,
    result: null,
  );

  /// The clip gave the detector nothing to look at — the frame extractor or
  /// the pose model failed outright. Kept apart from [empty]'s
  /// `tooFewSamples` so the athlete is never told a clip was "too short" when
  /// the truth is that it could not be read.
  static const unreadable = PoseJumpDiagnostics(
    sampleCount: 0,
    detectedCount: 0,
    torsoPixels: 0,
    groundBaselineY: 0,
    thresholdY: 0,
    liftThresholdPixels: 0,
    peakLiftPixels: 0,
    crossingTakeoff: null,
    crossingLanding: null,
    rawCrossingSeconds: null,
    correctedSeconds: null,
    samples: [],
    rejection: PoseDetectionRejection.unreadable,
    result: null,
  );

  static PoseJumpDiagnostics _rejected(
    PoseDetectionRejection rejection, {
    required List<PoseSample> samples,
    required int detectedCount,
    double torsoPixels = 0,
    BodyAxis bodyAxis = BodyAxis.image,
    int axisSampleCount = 0,
    double groundBaselineY = 0,
    List<double?> localGroundBaselines = const [],
    double thresholdY = 0,
    double liftThresholdPixels = 0,
    double peakLiftPixels = 0,
    Duration? crossingTakeoff,
    Duration? crossingLanding,
    double? rawCrossingSeconds,
    double? correctedSeconds,
  }) {
    return PoseJumpDiagnostics(
      sampleCount: samples.length,
      detectedCount: detectedCount,
      torsoPixels: torsoPixels,
      bodyAxis: bodyAxis,
      axisSampleCount: axisSampleCount,
      groundBaselineY: groundBaselineY,
      localGroundBaselines: localGroundBaselines,
      thresholdY: thresholdY,
      liftThresholdPixels: liftThresholdPixels,
      peakLiftPixels: peakLiftPixels,
      crossingTakeoff: crossingTakeoff,
      crossingLanding: crossingLanding,
      rawCrossingSeconds: rawCrossingSeconds,
      correctedSeconds: correctedSeconds,
      samples: samples,
      rejection: rejection,
      result: null,
    );
  }
}

/// Finds a jump's airborne window by *tracking the athlete's feet*, not by
/// measuring how much of the frame changed.
///
/// ## Why this exists
///
/// The previous detector (`core/jump_auto_detector.dart`) reads whole-frame
/// motion energy: the mean absolute pixel difference between sampled frames.
/// That quantity is a ratio of moving area to total area, so it is
/// **scale-invariant** — an athlete who occupies a small part of the frame
/// produces a tiny number no matter how many pixels you sample. Measured on a
/// real clip: the athlete's own motion registered 0.013 while unrelated UI
/// transitions in the same footage hit 0.30, and re-sampling at 96 px instead
/// of 32 px moved the athlete's energy from 0.012 to 0.012. The jump was
/// quieter than the noise. No threshold tuning fixes that; only tracking the
/// body does.
///
/// ## The rule
///
/// 0. **"Up" is the athlete's up, not the image's.** Every height below is a
///    *descent along [BodyAxis]* — the athlete's own hip-to-shoulder direction,
///    taken as a robust average over the frames in which they are on the
///    ground. Image y is only the right answer when the frames happen to be
///    upright, and phone-camera clips routinely are not (see [BodyAxis] for
///    the clip that proved it). The axis is averaged over the **grounded**
///    frames rather than computed per frame because the torso tilts in flight,
///    and a per-frame axis would feed that tilt straight back into the
///    measurement it exists to stabilise. On an upright frame the axis is
///    exactly `(0, -1)` and every formula below is arithmetically unchanged.
/// 1. **Ground baseline — local in time, not one number for the clip.** While
///    the athlete is on the ground, the foot's descent sits in a tight cluster,
///    and the baseline is the [_groundPercentile] percentile of that cluster —
///    a high percentile because descent grows downward, so "on the ground"
///    means "large", and a percentile rather than the max because one mis-fit
///    landmark snapping to the bottom of the image would destroy a max and the
///    whole measurement rides on this number.
///
///    That cluster is only tight over a *short* stretch of clip. An athlete who
///    walks toward the camera grows in frame, so their standing foot position
///    slides down the image over seconds. On the capture that forced this
///    change the drift was **116 px while the jump itself was only 87 px**: a
///    single clip-wide baseline (the 75th percentile, 987 px, dominated by the
///    late close-to-camera frames) put the *early standing* frames 55 px
///    "airborne", so every sample from the start of the clip to the landing
///    formed one run that began at the first sample — and the rule below that a
///    jump must be bounded by ground on both sides correctly threw it away. The
///    guard was right; the global baseline was wrong.
///
///    So the baseline is estimated **near each sample**, in two passes, for
///    the same reason the body axis takes two (`_resolveAxis`). The first is
///    [_groundPercentile] over a rolling window and only decides which samples
///    are grounded: it tolerates a long flight but sits high in the cluster and
///    so lags a drift. The second places the floor as a **straight line
///    between the grounded samples just before and just after** each sample
///    (`_bridgedGround`) — unbiased while standing, and under a flight it is
///    what the ground actually does when the athlete lands nearer the camera
///    than they took off. See [_localGroundBaselines] for why the window is
///    both a count and a span. A clip with fewer than [_minBaselineSamples]
///    usable samples falls back to the clip-wide baseline.
///
///    Everything downstream then works on the *lift above the local baseline*
///    rather than on raw descent, so the torso-length threshold, the
///    interpolated crossings, the parabola correction and [BallisticFit] are
///    untouched. On a clip with a flat ground — every synthetic fixture, and
///    any athlete who does not travel — the local baseline is that same flat
///    value, and nothing moves at all.
///
///    Limit, stated plainly: the first pass can only follow a drift of roughly
///    `liftThreshold / 0.17 s`. Faster than that (a camera being carried) and
///    standing samples read as airborne; the detector then refuses rather than
///    silently inventing a number, which is the failure mode we want.
/// 2. **Airborne = feet measurably above the baseline.** The threshold sits
///    [_liftTorsoFraction] of the athlete's own median torso length above the
///    baseline. Expressing it against the athlete's pixel size — rather than a
///    fixed pixel count — is what keeps it working when the camera is closer,
///    further, or the clip is a different resolution. The default works out to
///    roughly 3 % of standing height (~2" for a 6'1" athlete): comfortably
///    above landmark jitter, comfortably below any real jump.
/// 3. **Interpolated crossings.** Takeoff and landing are the instants the
///    interpolated `footY` line crosses that threshold *between* samples, not
///    the nearest sample. At a ~40 ms sample step, snapping to samples costs
///    up to 80 ms of window, which at a 0.77 s hang time is ~3 inches of
///    reported vertical. This is the single cheapest accuracy win available.
/// 4. **Parabola correction — the threshold's bias, removed exactly.**
///    Because the threshold sits *above* the ground, the crossings are inside
///    the true flight window: takeoff is detected late and landing early, so
///    the raw crossing time is systematically short. That bias is not a
///    mystery, it is a parabola. During flight the foot lift follows
///    `lift(τ) = H · (1 − (2τ/T − 1)²)` with apex lift `H` and true flight
///    time `T`, so the two crossings at `lift = L` are separated by
///    `T · √(1 − L/H)`. Both `L` (our chosen threshold) and `H` (the peak lift
///    actually observed) are measured, so the true time comes straight back
///    out: `T = T_crossing / √(1 − L/H)`. This is exact physics, not a fudge
///    factor, and it is what makes the exact choice of `L` non-critical.
///    (`H` is the highest lift actually *sampled*, so it very slightly
///    underestimates the true apex and the correction very slightly
///    overestimates `T`. The parabola is flat at its apex, so with the sample
///    step used here the error is well under a millisecond of flight time.)
///
/// ## When it returns null
///
/// Too few frames, too many frames with no athlete found, no usable scale, no
/// single clean airborne window, a lift too small to time, or an implausible
/// airborne time (see [FlightTime.isPlausible]). Returning null so the app can
/// tell the athlete why (there is no second detector behind this one — see
/// `core/jump_analysis_pipeline.dart`) is always better than reporting a
/// fabricated number.
abstract class PoseJumpDetector {
  /// Fewest sampled frames worth reasoning about at all. Below this there is
  /// not enough of a ground cluster to place a baseline.
  static const int minSamples = 6;

  /// Most of the *flight window's* frames that may have no pose before the
  /// timing is untrustworthy.
  ///
  /// Judged over the window, not the clip. A global ratio was tried first and
  /// was wrong: on a real clip the athlete appeared in only 22 of 60 frames —
  /// the other 38 genuinely had no person in them — and the jump itself was
  /// tracked cleanly throughout. Rejecting on the clip-wide ratio threw away
  /// a window that, recomputed by hand, gave the correct answer to within an
  /// inch. What actually degrades the measurement is a gap *between* takeoff
  /// and landing; a gap before or after is simply footage of something else.
  static const double maxWindowMissingFraction = 0.4;

  /// Percentile of the foot's descent along [BodyAxis] taken as ground level.
  /// High, because descent grows downward. 0.75 sits safely inside the ground
  /// cluster even when the
  /// athlete is airborne for a third of the sampled clip.
  static const double _groundPercentile = 0.75;

  /// Fewest samples the first baseline pass draws on around each sample,
  /// however sparsely the clip was sampled — see [_localGroundBaselines] and
  /// [_baselineMinHalfSpanSeconds] for the other half of the rule.
  static const int _baselineWindowSamples = 15;

  /// The first baseline pass never looks at less than this much clip either
  /// side of a sample, however densely the clip was sampled.
  ///
  /// A count alone breaks the other way from a span alone. At a 20 ms step,
  /// fifteen samples cover ±0.14 s — and gravity fixes how much a foot drops
  /// in that time: `g·τ²/2` with τ = 0.75 × 0.14 s (where the window's 75th
  /// percentile sits) is about 2", i.e. *exactly the lift threshold*, whatever
  /// the jump height. So a window that narrow, centred on the apex, reads the
  /// apex itself as "within a threshold of the ground", the second pass then
  /// takes its floor from mid-air samples, and a cleanly tracked jump comes
  /// back as too small to time or not airborne at all. That is the failure a
  /// short, tightly trimmed clip hit, back when a fixed frame budget landed on
  /// it as a very fine step. ±0.35 s puts the percentile more than six
  /// thresholds below the apex, and still lags a walk-in drift by only
  /// ~0.17 s of it.
  static const double _baselineMinHalfSpanSeconds = 0.35;

  /// Fewest samples (pass 1) or grounded samples (pass 2) a clip must hold
  /// before a local floor is trusted over the clip-wide baseline. Below this
  /// there is not enough of anything to place a floor locally.
  static const int _minBaselineSamples = 8;

  /// Airborne threshold, as a fraction of the athlete's median torso length.
  /// The torso is roughly 29 % of standing height, so 0.10 ≈ 3 % of standing
  /// height ≈ 2" for a 6'1" athlete.
  static const double liftTorsoFraction = 0.10;

  /// Airborne samples required in the chosen window. One sample is a single
  /// frame of lift — indistinguishable from a landmark glitch.
  static const int _minAirborneSamples = 2;

  /// The peak lift must clear the threshold by this factor before the parabola
  /// correction is trustworthy (`√(1 − L/H)` blows up as `H` approaches `L`).
  /// At 2.5 the correction is at most ×1.29.
  static const double _minPeakToThresholdRatio = 2.5;

  /// Airborne samples the parabola fit needs before its curvature is worth
  /// believing. Four is the algebraic minimum; six is where the answer stops
  /// swinging on one noisy landmark.
  static const int _minFitSamples = 6;

  /// Largest fit residual, as a fraction of the peak lift, still consistent
  /// with feet genuinely following a ballistic arc. Above it the tracking is
  /// too ragged for the fit to beat the crossings.
  static const double _maxFitResidualFraction = 0.12;

  /// Furthest the parabola fit may sit from the corrected crossing time, as a
  /// fraction of it, and still be the reported figure.
  static const double _maxFitCrossingDisagreement = 0.12;

  static JumpMeasurement? detect(List<PoseSample> samples) =>
      detectWithDiagnostics(samples).result;

  /// Same rule as [detect], but also returns the baseline, threshold, the
  /// per-sample series, how many frames had no pose, and the window it landed
  /// on — so a wrong answer on a real device is diagnosable.
  static PoseJumpDiagnostics detectWithDiagnostics(List<PoseSample> samples) {
    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final detected = sorted.where((s) => s.isDetected).toList();

    if (sorted.length < minSamples) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.tooFewSamples,
        samples: sorted,
        detectedCount: detected.length,
      );
    }
    // Enough detections to place a ground baseline at all. Deliberately not a
    // clip-wide ratio — see [maxWindowMissingFraction].
    if (detected.length < minSamples) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.tooManyMissing,
        samples: sorted,
        detectedCount: detected.length,
      );
    }

    final torso = _percentile(
      detected.map((s) => s.torsoPixels!).toList(),
      0.5,
    );
    if (torso <= 0) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.noScaleReference,
        samples: sorted,
        detectedCount: detected.length,
      );
    }

    // Which way is up for *this athlete*, before any height is measured.
    final resolved = _resolveAxis(detected, torso);
    final axis = resolved.axis;
    final axisSampleCount = resolved.frameCount;

    // Every height below is a descent along that axis. On an upright frame
    // this list is exactly the raw `footY` series.
    final footDown = [for (final s in detected) s.footDescent(axis)!];

    final baseline = _percentile(footDown, _groundPercentile);
    final lift = torso * liftTorsoFraction;
    final thresholdY = baseline - lift;

    // Ground level near each sample rather than once for the clip (rule 1).
    final seconds = [
      for (final s in detected)
        s.timestamp.inMicroseconds / Duration.microsecondsPerSecond,
    ];
    final localBaseline =
        _localGroundBaselines(seconds, footDown, lift, baseline);
    // Aligned with `sorted`, so the diagnostics can be read frame by frame.
    final alignedBaselines = _alignToSamples(sorted, detected, localBaseline);

    // Foot height *relative to the ground under it*: 0 while standing,
    // negative while airborne (descent grows downward). Everything from here
    // down is the arithmetic that used to run on `footDown` against a single
    // `baseline`, with the ground pinned to zero instead.
    final relative = [
      for (var i = 0; i < footDown.length; i++) footDown[i] - localBaseline[i],
    ];
    const groundLevel = 0.0;
    final relativeThreshold = groundLevel - lift;

    // Contiguous runs of detected samples whose feet are above the threshold.
    // Runs are built over the *detected* samples only, so an isolated frame
    // where the model lost the athlete does not chop a real flight in two.
    final runs = <_Run>[];
    int? start;
    for (var i = 0; i < detected.length; i++) {
      final airborne = relative[i] < relativeThreshold;
      if (airborne && start == null) {
        start = i;
      } else if (!airborne && start != null) {
        runs.add(_Run(start, i - 1));
        start = null;
      }
    }
    if (start != null) runs.add(_Run(start, detected.length - 1));

    // A jump is bounded by ground on both sides. A run that reaches either end
    // of the clip means we never saw the takeoff or never saw the landing, so
    // there is no window to time — the clip simply starts or ends mid-air.
    final usable = runs
        .where((r) =>
            r.start > 0 &&
            r.end < detected.length - 1 &&
            r.length >= _minAirborneSamples)
        .toList();

    if (usable.isEmpty) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.noAirborneWindow,
        samples: sorted,
        detectedCount: detected.length,
        torsoPixels: torso,
        bodyAxis: axis,
        axisSampleCount: axisSampleCount,
        groundBaselineY: baseline,
        localGroundBaselines: alignedBaselines,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
      );
    }

    // Several airborne windows means the clip holds several jumps — a warm-up
    // hop, a second attempt, a clip played through twice. This used to be a
    // refusal, which pushed the athlete into marking the jump by hand on a
    // clip the detector had actually understood perfectly well. "Analyse my
    // jump" means the jump worth looking at, so take the highest one and say
    // in the diagnostics how many were seen.
    double peakLiftOf(_Run r) {
      var peak = 0.0;
      for (var i = r.start; i <= r.end; i++) {
        final l = groundLevel - relative[i];
        if (l > peak) peak = l;
      }
      return peak;
    }

    usable.sort((a, b) => peakLiftOf(b).compareTo(peakLiftOf(a)));
    final best = usable.first;
    final windowsSeen = usable.length;

    // Gaps *inside* the flight are what cost accuracy, so the missing-frame
    // check happens here, over the window, rather than over the whole clip.
    final windowStart = detected[best.start - 1].timestamp;
    final windowEnd = detected[best.end + 1].timestamp;
    final inWindow = sorted
        .where((s) => s.timestamp >= windowStart && s.timestamp <= windowEnd)
        .toList();
    final missingInWindow = inWindow.where((s) => !s.isDetected).length;
    if (inWindow.isNotEmpty &&
        missingInWindow / inWindow.length > maxWindowMissingFraction) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.gappyWindow,
        samples: sorted,
        detectedCount: detected.length,
        torsoPixels: torso,
        bodyAxis: axis,
        axisSampleCount: axisSampleCount,
        groundBaselineY: baseline,
        localGroundBaselines: alignedBaselines,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
      );
    }

    // Interpolated threshold crossings. On the takeoff side the ground sample
    // precedes the run; on the landing side it follows it.
    final takeoff = _crossing(
      detected[best.start - 1].timestamp,
      relative[best.start - 1],
      detected[best.start].timestamp,
      relative[best.start],
      relativeThreshold,
    );
    final landing = _crossing(
      detected[best.end].timestamp,
      relative[best.end],
      detected[best.end + 1].timestamp,
      relative[best.end + 1],
      relativeThreshold,
    );

    final baselineAtTakeoff = localBaseline[best.start - 1];

    var peakLift = 0.0;
    for (var i = best.start; i <= best.end; i++) {
      final l = groundLevel - relative[i];
      if (l > peakLift) peakLift = l;
    }

    final rawSeconds =
        (landing - takeoff).inMicroseconds / Duration.microsecondsPerSecond;

    if (peakLift < lift * _minPeakToThresholdRatio) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.liftTooSmall,
        samples: sorted,
        detectedCount: detected.length,
        torsoPixels: torso,
        bodyAxis: axis,
        axisSampleCount: axisSampleCount,
        groundBaselineY: baseline,
        localGroundBaselines: alignedBaselines,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
        peakLiftPixels: peakLift,
        crossingTakeoff: takeoff,
        crossingLanding: landing,
        rawCrossingSeconds: rawSeconds,
      );
    }

    // Preferred: fit the parabola gravity forces the feet to follow across
    // every airborne sample, and solve for where it meets the ground. That
    // makes takeoff and landing *calculated* rather than *detected*, so no
    // sample has to sit near either end of the flight and the threshold's
    // position stops mattering at all. See core/ballistic_fit.dart for why
    // this beats hunting for the boundary frames.
    //
    // The threshold-crossing figure below stays as the fallback for a window
    // too short to fit (a parabola needs 4 points to leave any residual to
    // judge it by), and both are reported side by side in diagnostics.
    //
    // Fed the *relative* series, so "ground" is 0 — the same curve as before,
    // shifted by the local baseline. On a flat ground that shift is a constant
    // and the fit is arithmetically identical to the old one.
    final fit = BallisticFit.fit([
      for (var i = best.start; i <= best.end; i++)
        (
          seconds: seconds[i],
          y: relative[i],
        ),
    ]);
    // Only trust the fit when it is actually determined. On a real capture
    // the flight held just four samples 132 ms apart, the curvature was
    // barely constrained, and the fit came out 0.845 s against a hand-measured
    // 0.77 s — 34" for a 29" jump. Few points, or points that do not lie on a
    // parabola, mean the crossings are the better answer. The extraction pass
    // now spends a second, dense sampling pass inside the located jump
    // precisely so that this gate is normally satisfied.
    final fitUsable = fit != null &&
        fit.a > 0 &&
        fit.sampleCount >= _minFitSamples &&
        peakLift > 0 &&
        fit.rmsResidualPixels <= peakLift * _maxFitResidualFraction;
    // T = T_crossing / √(1 − L/H): exact for a parabola, and what the
    // crossing figure needs to undo the bias of a threshold sitting above
    // the ground.
    final crossingCorrected = rawSeconds / math.sqrt(1 - lift / peakLift);

    // The two readings are independent, and they fail differently. The
    // crossings are pinned to samples either side of the actual ground
    // contact, so their error is bounded by the sample step. The fit
    // *extrapolates* from the airborne samples to the ground, which is what
    // makes it better when it is well determined and unbounded when it is
    // not: on a small hop — half a dozen samples barely clear of the
    // threshold — one noisy landmark swings the curvature, and a seeded sweep
    // produced 0.58 s for a 0.35 s flight with a residual that looked fine.
    // So the fit is only believed where the crossings roughly agree with it.
    final fitAgrees = fitUsable &&
        rawSeconds > 0 &&
        ((fit.airborneSeconds(groundLevel) ?? double.infinity) -
                    crossingCorrected)
                .abs() <=
            crossingCorrected * _maxFitCrossingDisagreement;
    final fitted = fitAgrees ? fit.airborneSeconds(groundLevel) : null;
    final corrected =
        (fitted != null && FlightTime.isPlausible(fitted)) ? fitted : crossingCorrected;

    if (rawSeconds <= 0 || !FlightTime.isPlausible(corrected)) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.implausibleDuration,
        samples: sorted,
        detectedCount: detected.length,
        torsoPixels: torso,
        bodyAxis: axis,
        axisSampleCount: axisSampleCount,
        groundBaselineY: baseline,
        localGroundBaselines: alignedBaselines,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
        peakLiftPixels: peakLift,
        crossingTakeoff: takeoff,
        crossingLanding: landing,
        rawCrossingSeconds: rawSeconds,
        correctedSeconds: corrected,
      );
    }

    // The correction widens the window symmetrically about its midpoint:
    // flight is symmetric about the apex, so both crossings are inset by the
    // same amount and both are pushed back out by the same amount.
    final midUs = (takeoff.inMicroseconds + landing.inMicroseconds) ~/ 2;
    final halfUs =
        (corrected * Duration.microsecondsPerSecond / 2).round();
    var takeoffUs = midUs - halfUs;
    if (takeoffUs < 0) takeoffUs = 0;

    final result = JumpMeasurement(
      takeoff: Duration(microseconds: takeoffUs),
      landing: Duration(microseconds: takeoffUs + 2 * halfUs),
    );

    return PoseJumpDiagnostics(
      sampleCount: sorted.length,
      detectedCount: detected.length,
      torsoPixels: torso,
      bodyAxis: axis,
      axisSampleCount: axisSampleCount,
      groundBaselineY: baseline,
      localGroundBaselines: alignedBaselines,
      localBaselineAtTakeoff: baselineAtTakeoff,
      thresholdY: thresholdY,
      liftThresholdPixels: lift,
      peakLiftPixels: peakLift,
      crossingTakeoff: takeoff,
      crossingLanding: landing,
      rawCrossingSeconds: rawSeconds,
      correctedSeconds: corrected,
      fittedSeconds: fitted,
      fitResidualPixels: fit?.rmsResidualPixels,
      pixelsPerMetre:
          fit != null && fit.a > 0 ? fit.pixelsPerMetre : null,
      airborneWindowsSeen: windowsSeen,
      samples: sorted,
      rejection: PoseDetectionRejection.none,
      result: result,
    );
  }

  /// Instant between two samples (in that time order) where the interpolated
  /// foot-descent line crosses [thresholdY]. Falls back to the later sample if
  /// the two share a value, which would make the line horizontal.
  static Duration _crossing(
    Duration ta,
    double ya,
    Duration tb,
    double yb,
    double thresholdY,
  ) {
    final span = ya - yb;
    if (span == 0) return tb;
    final fraction = ((ya - thresholdY) / span).clamp(0.0, 1.0);
    final deltaUs = (tb - ta).inMicroseconds;
    return ta + Duration(microseconds: (deltaUs * fraction).round());
  }

  /// Ground level near each sample, in the same units as [descents].
  ///
  /// Two passes (see rule 1):
  ///
  /// 1. [_groundPercentile] of **every** sample in a rolling window. High
  ///    enough in the cluster that a flight filling most of the window cannot
  ///    drag it down, which is what makes it safe to run before anything is
  ///    known about where the flight is — but for the same reason it sits
  ///    toward the late, lower end of a drifting cluster rather than at the
  ///    sample's own time. Its only job is to say which samples are grounded.
  /// 2. The floor **bridged between the grounded samples either side**
  ///    ([_bridgedGround]).
  ///
  /// The pass-1 window is the nearest [_baselineWindowSamples] samples in
  /// time, widened until it also spans [_baselineMinHalfSpanSeconds] either
  /// side. Both halves of that rule were learnt the hard way. A span alone
  /// broke sparsely sampled clips: at a 130 ms step ±0.6 s held nine samples,
  /// four or five near the ends. A count alone broke densely sampled ones: at
  /// 20 ms, fifteen samples sit entirely inside a flight.
  static List<double> _localGroundBaselines(
    List<double> seconds,
    List<double> descents,
    double lift,
    double globalBaseline,
  ) {
    final coarse = _rollingPercentile(
      seconds,
      descents,
      _groundPercentile,
      List<double>.filled(descents.length, globalBaseline),
      minHalfSpanSeconds: _baselineMinHalfSpanSeconds,
    );
    // The percentile lags a floor that is moving; the envelope does not. The
    // lower of the two is the tighter bound on where the ground is.
    final envelope = groundEnvelope(seconds, descents);
    for (var i = 0; i < coarse.length; i++) {
      final e = envelope[i];
      if (e != null && e < coarse[i]) coarse[i] = e;
    }
    final grounded = <int>[
      for (var i = 0; i < descents.length; i++)
        if (coarse[i] - descents[i] <= lift) i,
    ];
    return _bridgedGround(seconds, descents, grounded, coarse);
  }

  /// Half-width of the window [_groundEnvelope] closes over. Twice this has to
  /// exceed the longest plausible flight ([FlightTime.maxAirborneSeconds]),
  /// or the flight itself would be read as floor.
  static const double _envelopeHalfSpanSeconds = 0.6;

  /// Where the floor is under an athlete who is **running toward or away from
  /// the camera**, null wherever there is not a full window of clip either
  /// side to judge it from.
  ///
  /// A run-up along the camera's line of sight slides the feet up or down the
  /// frame far faster than the rolling percentile can follow — on the clip
  /// pinned in `test/fixtures/run_up_away_capture.dart`, 160 px in under a
  /// second against a 45 px jump. The percentile sits at the *late* end of
  /// such a slide, so every stride of the run-up read as tens of pixels
  /// airborne, and the detector timed the run-up (a "flight" bounded by
  /// standing at one end and the real takeoff at the other) instead of the
  /// jump. It reported a number for it, which is worse than refusing.
  ///
  /// Feet cannot go *below* the floor, so the floor is the lower envelope of
  /// the foot trace — the upper envelope of descent. That is a morphological
  /// closing: a rolling maximum, then a rolling minimum of that, over the same
  /// window. Anything narrower than the window that dips toward the top of the
  /// frame — a flight, a running stride — is filled in; a slope is left
  /// exactly where it is, however steep. It reads a little low by the landmark
  /// jitter (it follows the noise's crest), which is why it is only allowed to
  /// *lower* the percentile's estimate, never replace it: on a floor that is
  /// not moving the percentile wins and nothing changes.
  ///
  /// Within a window's reach of either end of the series there may be no floor
  /// in view on that side — the clip can start or end mid-air — and an
  /// envelope built from one side would call that flight "ground". So there it
  /// declines, and the percentile stands alone as before. ([fullWindowOnly]
  /// false lifts that restriction, for a caller that only wants to know where
  /// to look — `JumpSamplingPlan.jumpCandidates` — and will verify what it
  /// finds.)
  static List<double?> groundEnvelope(
    List<double> seconds,
    List<double> descents, {
    bool fullWindowOnly = true,
  }) {
    final n = descents.length;
    if (n == 0) return const [];
    final first = seconds.first;
    final last = seconds.last;

    List<double> rolling(List<double> values, bool takeMax) {
      final out = <double>[];
      var from = 0;
      var to = 0;
      for (var i = 0; i < n; i++) {
        while (seconds[from] < seconds[i] - _envelopeHalfSpanSeconds) {
          from++;
        }
        while (to < n && seconds[to] <= seconds[i] + _envelopeHalfSpanSeconds) {
          to++;
        }
        var best = values[from];
        for (var j = from + 1; j < to; j++) {
          if (takeMax ? values[j] > best : values[j] < best) best = values[j];
        }
        out.add(best);
      }
      return out;
    }

    final closed = rolling(rolling(descents, true), false);
    return [
      for (var i = 0; i < n; i++)
        (!fullWindowOnly ||
                (seconds[i] - first >= _envelopeHalfSpanSeconds &&
                    last - seconds[i] >= _envelopeHalfSpanSeconds))
            ? closed[i]
            : null,
    ];
  }

  /// Grounded samples taken from each side of a sample when bridging the floor
  /// under it.
  static const int _bridgeSamplesPerSide = 7;

  /// Fewest grounded samples a side needs before the bridge leans on it.
  static const int _minBridgeSamples = 3;

  /// The floor under each sample: a straight line between the ground level
  /// just before it and the ground level just after it.
  ///
  /// Each side is the median of the nearest [_bridgeSamplesPerSide] grounded
  /// samples on that side (a sample that is itself grounded counts as
  /// "before"), placed at those samples' median time.
  ///
  /// This is what the ground actually does under a jump. An athlete who takes
  /// off moving toward the camera lands nearer to it, so the floor under the
  /// landing is further down the frame than the floor under the takeoff — on
  /// the walk-in capture by 44 px, half the height of the jump. During the
  /// flight there is no grounded sample to say where the floor is, and the
  /// previous rule (the median of the nearest grounded samples, whichever side
  /// they were on) made it a **step**: the takeoff's floor for the first half
  /// of the flight, the landing's for the second. A step in the middle of the
  /// arc is not a parabola, so the fit either failed its residual gate or,
  /// worse, passed it with the wrong flight time. Constant forward speed moves
  /// the floor linearly in time, and a parabola plus a line is still a
  /// parabola with the same roots against that line.
  ///
  /// It is also unbiased while standing: the two sides straddle the sample, so
  /// a steady drift cancels instead of lagging.
  ///
  /// With grounded samples on one side only — the ends of the clip — the floor
  /// is that side's median, not an extrapolation. A side holding fewer than
  /// [_minBridgeSamples] counts as absent: a median of one or two is whatever
  /// those samples happen to be, and on the device capture pinned in the tests
  /// one of them is a stray detection 460 px below the floor — drawing a line
  /// toward it put the landing frames "370 px airborne". Falls back to [fallback]
  /// when there are too few grounded samples to place a floor at all.
  static List<double> _bridgedGround(
    List<double> seconds,
    List<double> values,
    List<int> grounded,
    List<double> fallback,
  ) {
    if (grounded.length < _minBaselineSamples) return fallback;

    ({double t, double v}) side(int from, int to) => (
          t: _percentile([for (var k = from; k < to; k++) seconds[grounded[k]]], 0.5),
          v: _percentile([for (var k = from; k < to; k++) values[grounded[k]]], 0.5),
        );

    final out = <double>[];
    // Number of grounded samples at or before sample i; both lists are in
    // time order, so this only ever moves forward.
    var split = 0;
    for (var i = 0; i < values.length; i++) {
      while (split < grounded.length && grounded[split] <= i) {
        split++;
      }
      final beforeFrom = math.max(0, split - _bridgeSamplesPerSide);
      final afterTo = math.min(grounded.length, split + _bridgeSamplesPerSide);
      final hasBefore = split - beforeFrom >= _minBridgeSamples;
      final hasAfter = afterTo - split >= _minBridgeSamples;
      if (!hasBefore && !hasAfter) {
        // A couple of grounded samples either side and no more: pool them.
        out.add(side(beforeFrom, afterTo).v);
      } else if (!hasBefore) {
        out.add(side(split, afterTo).v);
      } else if (!hasAfter) {
        out.add(side(beforeFrom, split).v);
      } else {
        final before = side(beforeFrom, split);
        final after = side(split, afterTo);
        final span = after.t - before.t;
        final fraction =
            span <= 0 ? 0.0 : ((seconds[i] - before.t) / span).clamp(0.0, 1.0);
        out.add(before.v + (after.v - before.v) * fraction);
      }
    }
    return out;
  }

  /// [percentile] of the nearest [_baselineWindowSamples] values in time —
  /// more when [minHalfSpanSeconds] asks for a wider reach. Falls back per
  /// index to [fallback] only when there is genuinely too little to work with.
  static List<double> _rollingPercentile(
    List<double> seconds,
    List<double> values,
    double percentile,
    List<double> fallback, {
    double minHalfSpanSeconds = 0,
  }) {
    final usable = <int>[for (var j = 0; j < values.length; j++) j];

    final out = <double>[];
    for (var i = 0; i < values.length; i++) {
      if (usable.length < _minBaselineSamples) {
        out.add(fallback[i]);
        continue;
      }
      // Nearest by time, so the ends reach further to one side rather than
      // thinning out — no index gets a different *kind* of estimate.
      final byDistance = [...usable]..sort((a, b) =>
          (seconds[a] - seconds[i]).abs().compareTo(
              (seconds[b] - seconds[i]).abs()));
      var take = byDistance.length < _baselineWindowSamples
          ? byDistance.length
          : _baselineWindowSamples;
      // Densely sampled: keep going until the window also spans enough time
      // (see [_baselineMinHalfSpanSeconds]).
      while (take < byDistance.length &&
          (seconds[byDistance[take]] - seconds[i]).abs() <=
              minHalfSpanSeconds) {
        take++;
      }
      out.add(_percentile(
        [for (var k = 0; k < take; k++) values[byDistance[k]]],
        percentile,
      ));
    }
    return out;
  }

  /// Spreads a per-*detected*-sample series back over every sample, so the
  /// diagnostics line up frame by frame with [PoseJumpDiagnostics.samples].
  /// Null wherever the model found no athlete.
  static List<double?> _alignToSamples(
    List<PoseSample> all,
    List<PoseSample> detected,
    List<double> values,
  ) {
    final out = <double?>[];
    var next = 0;
    for (final s in all) {
      if (next < detected.length && identical(detected[next], s)) {
        out.add(values[next]);
        next++;
      } else {
        out.add(null);
      }
    }
    return out;
  }

  /// Fewest frames carrying a torso before an axis is derived from them at all.
  /// Below this the "robust average" would just be one frame's tilt.
  static const int _minAxisSamples = 3;

  /// Which way "up" is for the athlete in this series.
  ///
  /// Two passes, because the grounded frames cannot be identified until a
  /// baseline exists and the baseline cannot be placed until an axis exists:
  /// a provisional axis over every detected frame places a provisional
  /// baseline, and the axis is then re-derived over the frames that baseline
  /// calls grounded. The refinement is what keeps the in-flight torso tilt out
  /// of the axis; the provisional pass only has to be good enough to tell
  /// ground from air, which it is, because flight is a minority of any clip.
  ///
  /// Falls back to [BodyAxis.image] — the previous behaviour, exactly — when
  /// the series carries no foot *points*, or too few torsos to average. A
  /// series without foot points must never get a tilted axis: the two would be
  /// measured in different coordinate systems.
  ///
  /// Returns the axis *and* how many frames it was averaged over (0 for the
  /// image fallback, so the diagnostics can say "inferred" versus "assumed").
  static ({BodyAxis axis, int frameCount}) _resolveAxis(
    List<PoseSample> detected,
    double torso,
  ) {
    final fallback = (axis: BodyAxis.image, frameCount: 0);

    for (final s in detected) {
      if (s.foot == null) return fallback;
    }

    final provisional = _medianAxis(detected);
    if (provisional == null) return fallback;

    final baseline = _percentile(
      [for (final s in detected) s.footDescent(provisional.axis)!],
      _groundPercentile,
    );
    final threshold = baseline - torso * liftTorsoFraction;
    final grounded = [
      for (final s in detected)
        if (s.footDescent(provisional.axis)! >= threshold) s,
    ];

    return _medianAxis(grounded) ?? provisional;
  }

  /// Componentwise median of the per-frame torso directions, renormalised.
  ///
  /// A median rather than a mean so one frame whose shoulder or hip landmark
  /// snapped cannot swing the axis, and componentwise rather than an angular
  /// median so there is no ±180° wrap to handle. When every frame agrees — the
  /// synthetic case — it returns that exact direction.
  static ({BodyAxis axis, int frameCount})? _medianAxis(
    List<PoseSample> samples,
  ) {
    final xs = <double>[];
    final ys = <double>[];
    for (final s in samples) {
      final v = s.torsoUpVector;
      if (v == null) continue;
      final length = math.sqrt(v.x * v.x + v.y * v.y);
      if (!length.isFinite || length < 1e-9) continue;
      xs.add(v.x / length);
      ys.add(v.y / length);
    }
    if (xs.length < _minAxisSamples) return null;
    final axis = BodyAxis.fromUpVector(
      _percentile(xs, 0.5),
      _percentile(ys, 0.5),
    );
    if (axis == null) return null;
    return (axis: axis, frameCount: xs.length);
  }

  /// Linear-interpolation-free percentile: sorts a copy and picks the nearest
  /// rank. [p] is 0..1.
  static double _percentile(List<double> values, double p) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final index =
        ((sorted.length - 1) * p).round().clamp(0, sorted.length - 1);
    return sorted[index];
  }
}

class _Run {
  final int start;
  final int end;
  const _Run(this.start, this.end);
  int get length => end - start + 1;
}
