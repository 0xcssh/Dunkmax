import 'dart:math' as math;

import 'flight_time.dart';
import 'models/jump_measurement.dart';

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
  final double? footY;

  /// Shoulder-midpoint to hip-midpoint distance, in pixels: the athlete's own
  /// scale reference. Null when no pose was detected.
  ///
  /// The torso is used rather than a full head-to-ankle span because the legs
  /// tuck in mid-flight, which would make a leg-inclusive "body height" shrink
  /// exactly during the phase we are trying to measure. The torso is
  /// effectively rigid through a jump, so its pixel length tracks only the one
  /// thing we want it to track: how big the athlete is in this frame, i.e.
  /// how far they are from the camera.
  final double? torsoPixels;

  const PoseSample({
    required this.timestamp,
    this.footY,
    this.torsoPixels,
  });

  /// True when the pose model actually found the athlete in this frame.
  bool get isDetected => footY != null && torsoPixels != null;
}

/// Why [PoseJumpDetector] declined to report a measurement. Surfaced in the
/// diagnostics so a real-device report says what went wrong instead of just
/// "it fell back to the old detector".
enum PoseDetectionRejection {
  none('measured'),
  tooFewSamples('too few sampled frames'),
  tooManyMissing('athlete not found in enough frames'),
  noScaleReference('no usable body-scale reference'),
  noAirborneWindow('feet never left the ground baseline'),
  ambiguousWindows('more than one airborne window — ambiguous clip'),
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

  /// Ground level: the robust high percentile of [PoseSample.footY].
  final double groundBaselineY;

  /// The airborne threshold, in image coordinates (above the baseline, so
  /// numerically *smaller* than it).
  final double thresholdY;

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

  /// Every sample, sorted by time, exactly as the detector read them.
  final List<PoseSample> samples;

  final PoseDetectionRejection rejection;
  final JumpMeasurement? result;

  const PoseJumpDiagnostics({
    required this.sampleCount,
    required this.detectedCount,
    required this.torsoPixels,
    required this.groundBaselineY,
    required this.thresholdY,
    required this.liftThresholdPixels,
    required this.peakLiftPixels,
    required this.crossingTakeoff,
    required this.crossingLanding,
    required this.rawCrossingSeconds,
    required this.correctedSeconds,
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

  static PoseJumpDiagnostics _rejected(
    PoseDetectionRejection rejection, {
    required List<PoseSample> samples,
    required int detectedCount,
    double torsoPixels = 0,
    double groundBaselineY = 0,
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
      groundBaselineY: groundBaselineY,
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
/// 1. **Ground baseline.** While the athlete is on the ground, `footY` sits in
///    a tight cluster. The baseline is the [_groundPercentile] percentile of
///    the detected `footY` values — a high percentile because y grows
///    downward, so "on the ground" means "large y". A percentile, not the max:
///    one bad frame (a mis-fit landmark snapping to the bottom of the image)
///    destroys a max, and the whole measurement rides on this number.
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
/// fall back to the motion-energy detector — and then to manual marking — is
/// always better than reporting a fabricated number.
abstract class PoseJumpDetector {
  /// Fewest sampled frames worth reasoning about at all. Below this there is
  /// not enough of a ground cluster to place a baseline.
  static const int minSamples = 6;

  /// Most of the clip's frames that may have no pose before the time series is
  /// too holed-through to trust. Gaps are bridged (a missing frame does not
  /// end an airborne run), but a clip where the model loses the athlete a
  /// third of the time is a clip we should not be timing to the millisecond.
  static const double maxMissingFraction = 0.35;

  /// Percentile of `footY` taken as ground level. High, because y grows
  /// downward. 0.75 sits safely inside the ground cluster even when the
  /// athlete is airborne for a third of the sampled clip.
  static const double _groundPercentile = 0.75;

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

  /// If a second airborne window is at least this fraction of the winner's
  /// length, the clip has two comparable candidates and we refuse to guess
  /// which one the athlete meant.
  static const double _ambiguityRatio = 0.6;

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
    if (detected.length < minSamples ||
        (sorted.length - detected.length) / sorted.length > maxMissingFraction) {
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

    final baseline = _percentile(
      detected.map((s) => s.footY!).toList(),
      _groundPercentile,
    );
    final lift = torso * liftTorsoFraction;
    final thresholdY = baseline - lift;

    // Contiguous runs of detected samples whose feet are above the threshold.
    // Runs are built over the *detected* samples only, so an isolated frame
    // where the model lost the athlete does not chop a real flight in two.
    final runs = <_Run>[];
    int? start;
    for (var i = 0; i < detected.length; i++) {
      final airborne = detected[i].footY! < thresholdY;
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
        groundBaselineY: baseline,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
      );
    }

    usable.sort((a, b) => b.length.compareTo(a.length));
    final best = usable.first;
    if (usable.length > 1 && usable[1].length >= best.length * _ambiguityRatio) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.ambiguousWindows,
        samples: sorted,
        detectedCount: detected.length,
        torsoPixels: torso,
        groundBaselineY: baseline,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
      );
    }

    // Interpolated threshold crossings. On the takeoff side the ground sample
    // precedes the run; on the landing side it follows it.
    final takeoff = _crossing(
      detected[best.start - 1],
      detected[best.start],
      thresholdY,
    );
    final landing = _crossing(
      detected[best.end],
      detected[best.end + 1],
      thresholdY,
    );

    var peakLift = 0.0;
    for (var i = best.start; i <= best.end; i++) {
      final l = baseline - detected[i].footY!;
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
        groundBaselineY: baseline,
        thresholdY: thresholdY,
        liftThresholdPixels: lift,
        peakLiftPixels: peakLift,
        crossingTakeoff: takeoff,
        crossingLanding: landing,
        rawCrossingSeconds: rawSeconds,
      );
    }

    // T = T_crossing / √(1 − L/H). See the class doc: exact for a parabola.
    final corrected = rawSeconds / math.sqrt(1 - lift / peakLift);

    if (rawSeconds <= 0 || !FlightTime.isPlausible(corrected)) {
      return PoseJumpDiagnostics._rejected(
        PoseDetectionRejection.implausibleDuration,
        samples: sorted,
        detectedCount: detected.length,
        torsoPixels: torso,
        groundBaselineY: baseline,
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
      groundBaselineY: baseline,
      thresholdY: thresholdY,
      liftThresholdPixels: lift,
      peakLiftPixels: peakLift,
      crossingTakeoff: takeoff,
      crossingLanding: landing,
      rawCrossingSeconds: rawSeconds,
      correctedSeconds: corrected,
      samples: sorted,
      rejection: PoseDetectionRejection.none,
      result: result,
    );
  }

  /// Instant between [a] and [b] (in that time order) where the interpolated
  /// `footY` line crosses [thresholdY]. Falls back to the later sample if the
  /// two share a value, which would make the line horizontal.
  static Duration _crossing(PoseSample a, PoseSample b, double thresholdY) {
    final ya = a.footY!;
    final yb = b.footY!;
    final span = ya - yb;
    if (span == 0) return b.timestamp;
    final fraction = ((ya - thresholdY) / span).clamp(0.0, 1.0);
    final deltaUs = (b.timestamp - a.timestamp).inMicroseconds;
    return a.timestamp + Duration(microseconds: (deltaUs * fraction).round());
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
