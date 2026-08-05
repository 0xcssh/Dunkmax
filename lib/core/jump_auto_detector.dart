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

  const JumpDetectionDiagnostics({
    required this.sampleCount,
    required this.minEnergy,
    required this.maxEnergy,
    required this.threshold,
    required this.candidates,
    required this.result,
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
    double? bestProminence;
    for (final run in runs) {
      final takeoffIndex = run.start > 0 ? run.start - 1 : run.start;
      final landingIndex =
          run.end < sorted.length - 1 ? run.end + 1 : run.end;
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
        bestProminence = prominence;
      }
    }

    JumpMeasurement? result;
    var finalCandidates = diagCandidates;
    if (best != null) {
      final takeoff = sorted[best.start].timestamp;
      final landing = sorted[best.end].timestamp;
      result = JumpMeasurement(takeoff: takeoff, landing: landing);
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
    );
  }
}

class _Run {
  final int start;
  final int end;
  const _Run(this.start, this.end);
}
