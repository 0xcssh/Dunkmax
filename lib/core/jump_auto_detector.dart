import 'flight_time.dart';
import 'models/jump_measurement.dart';
import 'models/motion_sample.dart';

/// One rejected-or-considered low-motion window, kept around purely for
/// diagnostics (see [JumpDetectionDiagnostics]) — lets the result screen
/// show exactly what the detector saw on a real clip instead of us having
/// to guess blind from a bug report.
class CandidateWindow {
  final Duration takeoff;
  final Duration landing;
  final double avgEnergy;
  final double boundingEnergy;
  final double prominence;
  final bool chosen;

  const CandidateWindow({
    required this.takeoff,
    required this.landing,
    required this.avgEnergy,
    required this.boundingEnergy,
    required this.prominence,
    required this.chosen,
  });

  double get airborneSeconds =>
      (landing - takeoff).inMicroseconds / Duration.microsecondsPerSecond;
}

/// Everything [JumpAutoDetector.detectWithDiagnostics] saw and decided,
/// for a real clip — surfaced on the result screen so tuning the detector
/// can be grounded in real signal shape instead of another blind guess.
class JumpDetectionDiagnostics {
  final int sampleCount;
  final double minEnergy;
  final double maxEnergy;
  final double threshold;
  final List<CandidateWindow> candidates;
  final JumpMeasurement? result;

  /// Alternative airborne-time estimates for the chosen window, computed but
  /// deliberately NOT used for the reported vertical (see
  /// [JumpAutoDetector.detectWithDiagnostics]).
  ///
  /// The reported number has been consistently lower than a reference app on
  /// the same clip, and the cause is which instants we call "takeoff" and
  /// "landing" — a question of where the flight phase really starts and ends
  /// in the motion-energy signal, not of the physics (`h = g·t²/8` is exact).
  /// Three defensible answers exist and they disagree by enough to move the
  /// result by several inches, so rather than guess a fourth time, all three
  /// are surfaced side by side on a real clip. Once a real measurement with a
  /// known reference value is in hand, the right one can be promoted to
  /// [result] with evidence instead of intuition.
  final JumpEstimates estimates;

  const JumpDetectionDiagnostics({
    required this.sampleCount,
    required this.minEnergy,
    required this.maxEnergy,
    required this.threshold,
    required this.candidates,
    required this.result,
    this.estimates = JumpEstimates.none,
  });

  static const empty = JumpDetectionDiagnostics(
    sampleCount: 0,
    minEnergy: 0,
    maxEnergy: 0,
    threshold: 0,
    candidates: [],
    result: null,
  );
}

/// The three ways of reading takeoff/landing out of the motion-energy signal,
/// all in seconds of airborne time. Null when no window was found.
///
/// Physically, frame-to-frame motion energy during flight tracks the body's
/// vertical speed: maximal at takeoff, ~zero at the apex, maximal again at
/// landing. So the signal traces a V, and how wide you call that V decides
/// the answer:
///
/// - [outerBoundSeconds] — the sample just outside the quiet run on each
///   side. An upper bound: it includes up to one whole sample step of ground
///   phase at each end. This is what currently feeds the reported number.
/// - [crossingSeconds] — the interpolated instant the energy actually crosses
///   the threshold, between samples. Removes the sample-step quantisation
///   (which at ~100 ms per sample is worth several inches on its own) but is
///   only as good as the threshold level itself.
/// - [apexSymmetrySeconds] — twice the time from the apex (the V's minimum)
///   to the landing impact. Uses the fact that flight is symmetric about the
///   apex, so it needs only the landing side — the sharpest, least ambiguous
///   event in the whole signal — and never has to decide where the takeoff
///   drive ends and flight begins.
class JumpEstimates {
  final double? outerBoundSeconds;
  final double? crossingSeconds;
  final double? apexSymmetrySeconds;

  const JumpEstimates({
    this.outerBoundSeconds,
    this.crossingSeconds,
    this.apexSymmetrySeconds,
  });

  static const none = JumpEstimates();
}

/// Finds the airborne window in a jump clip from a motion-energy time
/// series, without any pose/frame-pixel dependencies (that glue lives in
/// features/analyze/motion_extraction.dart — this is the pure, testable
/// decision logic).
///
/// Heuristic: the body moves smoothly (low motion) while airborne, framed
/// by higher motion before (the jump drive) and after (landing impact).
/// Finds contiguous low-motion runs bounded by higher motion on both sides,
/// filtered to a physically plausible airborne duration, and picks the one
/// with the highest *prominence* — how much more violent the bounding
/// motion is than the window itself.
///
/// Prominence, not "lowest average energy", is the ranking signal on
/// purpose: a person standing perfectly still before or after the jump is
/// often even quieter than a body smoothly translating through the air, so
/// picking the single stillest moment in the clip tends to land on
/// pre-jump stillness instead of the actual flight phase. Requiring a
/// dramatic contrast with the bounding motion (the explosive takeoff drive
/// and the landing impact) targets the jump specifically, not just any
/// quiet moment. Returns null if no clear window is found.
abstract class JumpAutoDetector {
  /// Auto-detection-only floor, stricter than [FlightTime.minAirborneSeconds]
  /// (which also gates manual marking, where a real athlete's genuinely weak
  /// jump should still be accepted). A sub-4" "jump" is far more likely to be
  /// a mis-detected stillness window than a real attempt, so auto-detection
  /// discards candidates below this before ranking.
  static const double _minAutoDetectSeconds = 0.28;

  /// Least motion, as a fraction of the clip's peak, that a window must
  /// average to be considered a flight phase at all. Deliberately tiny: this
  /// is a frozen-frame guard, not an accuracy knob. A real airborne body
  /// registers well above it; a paused player or a static screen sits at
  /// essentially zero.
  static const double _minMotionFraction = 0.01;

  static JumpMeasurement? detect(List<MotionSample> samples) =>
      detectWithDiagnostics(samples).result;

  /// Same detection logic as [detect], but also returns every plausible
  /// candidate window it considered (not just the winner) plus the energy
  /// stats it based its threshold on.
  static JumpDetectionDiagnostics detectWithDiagnostics(
    List<MotionSample> samples,
  ) {
    if (samples.length < 3) return JumpDetectionDiagnostics.empty;

    final sorted = [...samples]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final energies = sorted.map((s) => s.energy).toList()..sort();
    final maxEnergy = energies.last;
    final minEnergy = energies.first;
    if (maxEnergy <= 0) {
      return JumpDetectionDiagnostics(
        sampleCount: sorted.length,
        minEnergy: minEnergy,
        maxEnergy: maxEnergy,
        threshold: 0,
        candidates: const [],
        result: null,
      );
    }

    // Threshold: whichever is more permissive of the 35th percentile or a
    // flat fraction of the peak, so a clip with mostly-low motion (little
    // camera shake) still finds a real quiet window instead of thresholding
    // everything as "low".
    final percentileIndex =
        (energies.length * 0.35).floor().clamp(0, energies.length - 1).toInt();
    final percentileThreshold = energies[percentileIndex];
    final fractionThreshold = maxEnergy * 0.25;
    final threshold = percentileThreshold > fractionThreshold
        ? percentileThreshold
        : fractionThreshold;

    // Find maximal contiguous runs of sorted[i].energy <= threshold.
    final runs = <_Run>[];
    int? runStart;
    for (var i = 0; i < sorted.length; i++) {
      final isLow = sorted[i].energy <= threshold;
      if (isLow && runStart == null) {
        runStart = i;
      } else if (!isLow && runStart != null) {
        runs.add(_Run(runStart, i - 1));
        runStart = null;
      }
    }
    if (runStart != null) runs.add(_Run(runStart, sorted.length - 1));

    // Filter to a plausible airborne duration, using the sample just before
    // the run (or the run's own first sample, if the run starts at index 0)
    // as takeoff, and the sample just after the run (or the run's own last
    // sample, if it runs to the end) as landing.
    final diagCandidates = <CandidateWindow>[];
    _Run? best;
    _Run? bestRun;
    double? bestProminence;
    for (final run in runs) {
      // A jump has a takeoff drive before it and a landing impact after it.
      // A quiet run that reaches either end of the clip has neither, so we
      // never actually observed the event we'd be timing — it's the clip
      // starting or ending on a still image, not a body in the air. Taking
      // those was a real bug: on a clip that ended with several motionless
      // seconds, the tail scored the highest prominence of anything in the
      // signal and got reported as a jump.
      if (run.start == 0 || run.end == sorted.length - 1) continue;

      final takeoffIndex = run.start - 1;
      final landingIndex = run.end + 1;
      final takeoff = sorted[takeoffIndex].timestamp;
      final landing = sorted[landingIndex].timestamp;
      if (landing <= takeoff) continue;
      final airborneSeconds =
          (landing - takeoff).inMicroseconds / Duration.microsecondsPerSecond;
      if (!FlightTime.isPlausible(airborneSeconds)) continue;
      if (airborneSeconds < _minAutoDetectSeconds) continue;

      final runEnergies =
          sorted.sublist(run.start, run.end + 1).map((s) => s.energy);
      final avgEnergy = runEnergies.reduce((a, b) => a + b) / runEnergies.length;

      // A body travelling through the air still moves pixels. A window with
      // essentially no motion at all is a frozen picture — a paused clip, a
      // static frame, duplicate decoded frames — not a flight phase.
      if (avgEnergy < maxEnergy * _minMotionFraction) continue;

      final boundingEnergy =
          (sorted[takeoffIndex].energy + sorted[landingIndex].energy) / 2;
      final prominence = boundingEnergy - avgEnergy;

      diagCandidates.add(CandidateWindow(
        takeoff: takeoff,
        landing: landing,
        avgEnergy: avgEnergy,
        boundingEnergy: boundingEnergy,
        prominence: prominence,
        chosen: false,
      ));

      if (best == null || prominence > bestProminence!) {
        best = _Run(takeoffIndex, landingIndex);
        bestRun = run;
        bestProminence = prominence;
      }
    }

    JumpMeasurement? result;
    var finalCandidates = diagCandidates;
    var estimates = JumpEstimates.none;
    if (best != null) {
      final takeoff = sorted[best.start].timestamp;
      final landing = sorted[best.end].timestamp;
      result = JumpMeasurement(takeoff: takeoff, landing: landing);
      estimates = _estimate(sorted, best, bestRun!, threshold);
      finalCandidates = [
        for (final c in diagCandidates)
          c.takeoff == takeoff && c.landing == landing
              ? CandidateWindow(
                  takeoff: c.takeoff,
                  landing: c.landing,
                  avgEnergy: c.avgEnergy,
                  boundingEnergy: c.boundingEnergy,
                  prominence: c.prominence,
                  chosen: true,
                )
              : c,
      ];
    }

    return JumpDetectionDiagnostics(
      sampleCount: sorted.length,
      minEnergy: minEnergy,
      maxEnergy: maxEnergy,
      threshold: threshold,
      candidates: finalCandidates,
      result: result,
      estimates: estimates,
    );
  }

  /// Computes the three competing readings of the chosen window described on
  /// [JumpEstimates]. Pure arithmetic over the already-selected window — it
  /// never changes which window was picked, only how that window is measured.
  static JumpEstimates _estimate(
    List<MotionSample> sorted,
    _Run bounds,
    _Run run,
    double threshold,
  ) {
    double seconds(Duration a, Duration b) =>
        (b - a).inMicroseconds / Duration.microsecondsPerSecond;

    final outerTakeoff = sorted[bounds.start].timestamp;
    final outerLanding = sorted[bounds.end].timestamp;

    // Interpolated threshold crossings. On the takeoff side the high sample
    // precedes the quiet run; on the landing side it follows it.
    final crossTakeoff = run.start > 0
        ? _crossing(sorted[run.start - 1], sorted[run.start], threshold)
        : outerTakeoff;
    final crossLanding = run.end < sorted.length - 1
        ? _crossing(sorted[run.end + 1], sorted[run.end], threshold)
        : outerLanding;

    // Apex = quietest instant of the flight, i.e. the bottom of the V.
    var apexIndex = run.start;
    for (var i = run.start; i <= run.end; i++) {
      if (sorted[i].energy < sorted[apexIndex].energy) apexIndex = i;
    }
    final apex = sorted[apexIndex].timestamp;

    final apexToLanding = seconds(apex, crossLanding);

    return JumpEstimates(
      outerBoundSeconds: seconds(outerTakeoff, outerLanding),
      crossingSeconds: seconds(crossTakeoff, crossLanding),
      apexSymmetrySeconds: apexToLanding > 0 ? apexToLanding * 2 : null,
    );
  }

  /// Instant between [high] (energy above [threshold]) and [low] (energy at
  /// or below it) where the signal crosses the threshold, by linear
  /// interpolation. Either sample may be the earlier one in time.
  static Duration _crossing(
    MotionSample high,
    MotionSample low,
    double threshold,
  ) {
    final span = high.energy - low.energy;
    if (span <= 0) return high.timestamp;
    final fraction = ((high.energy - threshold) / span).clamp(0.0, 1.0);
    final deltaUs = (low.timestamp - high.timestamp).inMicroseconds;
    return high.timestamp + Duration(microseconds: (deltaUs * fraction).round());
  }
}

class _Run {
  final int start;
  final int end;
  const _Run(this.start, this.end);
}
