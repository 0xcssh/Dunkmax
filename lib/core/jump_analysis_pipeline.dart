import 'pose_jump_detector.dart';

/// Turns a list of clip timestamps into one [PoseSample] each.
///
/// The real one decodes frames and runs the pose model
/// (`features/analyze/pose_extraction.dart`); tests pass a synthetic athlete.
/// A frame the model found nobody in must still come back, as a sample with
/// null measurements — an *empty* list means nothing could be read at all.
typedef PoseFrameSampler = Future<List<PoseSample>> Function(
  List<Duration> timestamps,
);

/// Where the pipeline is, for the processing screen's checklist.
enum JumpAnalysisStage { scanning, measuring }

/// Which frames of the clip get looked at.
///
/// ## Why this exists
///
/// The sampler used to spend a fixed *number* of frames across whatever range
/// it was handed, so the time between samples was a function of clip length:
/// 30 ms on a one-second trim, 130 ms on an eight-second one. Every constant
/// in the detector was then implicitly tuned to one of those regimes and broke
/// in the other — a rolling ground window wide enough at 130 ms held nothing
/// but flight at 20 ms, and one sized for 30 ms held four samples at 130 ms.
/// Each fix for a long clip broke short ones and the reverse.
///
/// So the clip's length no longer reaches the measurement. Whatever is filmed,
/// the number comes from the **same series**: one sample every
/// [measureStepMs], covering the jump with about a second of ground before it
/// and half a second after. A clip short enough is sampled like that outright;
/// a longer one gets a sparse scan first, whose only job is to say *where* the
/// jump is.
abstract class JumpSamplingPlan {
  /// Step of the series the measurement is taken from — one frame of a 30 fps
  /// clip. Finer would ask the decoder for frames that do not exist.
  static const int measureStepMs = 33;

  /// A range up to this many measurement steps long is simply sampled whole.
  static const int singlePassMaxFrames = 100;

  /// Step of the locating scan. A jump big enough to time is airborne for
  /// 0.3 s or more, so 150 ms always lands at least one sample well inside it
  /// and usually two.
  static const int scanStepMs = 150;

  /// Frames the scan may cost before its step starts to stretch (~15 s of
  /// clip).
  static const int scanMaxFrames = 100;

  /// The scan step never stretches past this, however long the clip: a gap
  /// wider than a flight could step clean over the jump, and no later pass
  /// can find what the scan never saw. Past ~24 s the scan simply costs more
  /// frames — a long clip takes longer, it does not get a worse answer.
  static const int scanMaxStepMs = 240;

  /// How much clip the measured series keeps before and after the instant
  /// the scan pointed at. The longest plausible flight is just under a
  /// second, so wherever in it that instant fell there is still ground on
  /// both sides — and more before than after, because the form scores read
  /// the approach and the countermovement out of the lead-in.
  static const int leadInMs = 1400;
  static const int leadOutMs = 1100;

  /// Two high scan samples closer together than this are the same candidate
  /// (see [jumpCandidates]).
  static const int candidateSpacingMs = 1000;

  /// Most places in the clip the dense pass will be pointed at.
  static const int maxCandidates = 4;

  /// How far past the athlete's trim the pipeline reaches on its second
  /// attempt (see [JumpAnalysisPipeline.run]).
  static const int widenMs = 1000;

  static bool isSinglePass(Duration start, Duration end) =>
      (end - start).inMilliseconds <= singlePassMaxFrames * measureStepMs;

  /// Evenly spaced instants in `[from, to)`, [stepMs] apart.
  static List<Duration> uniform(Duration from, Duration to, int stepMs) {
    final fromMs = from.inMilliseconds;
    final toMs = to.inMilliseconds;
    return [
      for (var t = fromMs; t < toMs; t += stepMs) Duration(milliseconds: t),
    ];
  }

  /// First pass over `[start, end)`: the measurement series itself when the
  /// range is short, otherwise the sparse locating scan.
  static List<Duration> firstPass(Duration start, Duration end) {
    if (end <= start) return const [];
    if (isSinglePass(start, end)) return uniform(start, end, measureStepMs);
    final spanMs = (end - start).inMilliseconds;
    var stepMs = scanStepMs;
    if (spanMs > scanStepMs * scanMaxFrames) {
      stepMs = (spanMs / scanMaxFrames).ceil();
      if (stepMs > scanMaxStepMs) stepMs = scanMaxStepMs;
    }
    return uniform(start, end, stepMs);
  }

  /// The stretch of clip to measure around [instant], clamped to
  /// `[start, end]`.
  static ({Duration from, Duration to}) measureWindow(
    Duration instant,
    Duration start,
    Duration end,
  ) {
    var from = instant - const Duration(milliseconds: leadInMs);
    var to = instant + const Duration(milliseconds: leadOutMs);
    if (from < start) from = start;
    if (to > end) to = end;
    return (from: from, to: to);
  }

  /// Where in the clip the jump might be, best guess first.
  ///
  /// The scan's own verdict is not enough to go on. It is sparse, and the
  /// detector's ground estimate needs fifteen samples — seconds of clip at
  /// this step — so its floor can be well off under an athlete who is
  /// travelling, and a perfectly good jump reads as no airborne window (or a
  /// window in the wrong place). It can also land a single sample in a short
  /// hop, which is not a window at all.
  ///
  /// Neither matters for *finding* the jump. The candidates are the samples
  /// whose feet stand furthest above the floor's envelope
  /// ([PoseJumpDetector.groundEnvelope]): the lower envelope of the foot
  /// trace, which fills in anything as brief as a flight and leaves a slope
  /// exactly where it is. That last part is the point. Comparing each sample
  /// with the median of its neighbours was tried first, and a run-up toward
  /// the camera beat the jump at its own game: the frames at the top of the
  /// slope stand 80 px "above" a neighbourhood full of later, lower ones.
  ///
  /// Anything clear of the airborne threshold is worth a dense look, highest
  /// first — "analyse my jump" means the best one in the clip. The scan's own
  /// window, when it has one somewhere else, goes last. The dense pass, not
  /// this, decides whether any of them is a jump.
  static List<Duration> jumpCandidates(PoseJumpDiagnostics scan) {
    final candidates = <Duration>[];
    bool isFarFromAll(Duration t, int milliseconds) => candidates
        .every((c) => (c - t).inMilliseconds.abs() > milliseconds);

    final detected = [
      for (final s in scan.samples)
        if (s.isDetected) s,
    ];
    if (detected.length >= PoseJumpDetector.minSamples) {
      final axis = scan.bodyAxis;
      final threshold = _median([for (final s in detected) s.torsoPixels!]) *
          PoseJumpDetector.liftTorsoFraction;
      final feet = [for (final s in detected) s.footDescent(axis)!];
      final floor = PoseJumpDetector.groundEnvelope(
        [
          for (final s in detected)
            s.timestamp.inMicroseconds / Duration.microsecondsPerSecond,
        ],
        feet,
        fullWindowOnly: false,
      );

      final peaks = <({Duration at, double lift})>[];
      for (var i = 0; i < detected.length; i++) {
        final lift = floor[i]! - feet[i];
        if (lift > threshold) {
          peaks.add((at: detected[i].timestamp, lift: lift));
        }
      }
      peaks.sort((a, b) => b.lift.compareTo(a.lift));
      for (final peak in peaks) {
        if (candidates.length >= maxCandidates - 1) break;
        // Neighbouring samples of one flight are one candidate.
        if (isFarFromAll(peak.at, candidateSpacingMs)) {
          candidates.add(peak.at);
        }
      }
    }

    final located = scan.result;
    if (located != null) {
      final apex = located.takeoff + located.airborne ~/ 2;
      if (isFarFromAll(apex, 500)) candidates.add(apex);
    }
    return candidates;
  }

  static double _median(List<double> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  /// Upper bound on the frames one attempt over `[start, end)` will decode,
  /// for the progress bar.
  static int frameBudget(Duration start, Duration end) {
    final first = firstPass(start, end).length;
    if (isSinglePass(start, end)) return first;
    return first + ((leadInMs + leadOutMs) / measureStepMs).ceil();
  }
}

/// The one way a clip becomes a measurement.
///
/// 1. Look across the athlete's trim ([JumpSamplingPlan.firstPass]).
/// 2. If that was only a scan, sample densely around where it points
///    ([JumpSamplingPlan.jumpCandidates]) and measure *that* series on its
///    own — it carries its own ground on both sides, so nothing about the
///    rest of the clip can leak into the number.
/// 3. If the trim itself could not be measured and there is more clip either
///    side of it, try once more a second wider. A trim cut too close to the
///    takeoff or the landing is the most common way to lose a good jump, and
///    the frames that fix it are already in the file.
///
/// There is no second method behind this one. When body tracking cannot
/// measure the clip the athlete is told why; see [PoseDetectionRejection].
abstract class JumpAnalysisPipeline {
  static Future<PoseJumpDiagnostics> run({
    required Duration rangeStart,
    required Duration rangeEnd,
    required Duration clipDuration,
    required PoseFrameSampler sample,
    void Function(JumpAnalysisStage stage)? onStage,
  }) async {
    final attempt = await _analyze(rangeStart, rangeEnd, sample, onStage);
    if (attempt.result != null) return attempt;
    // Nothing could be read at all: more of the same clip will not help.
    if (attempt.rejection == PoseDetectionRejection.unreadable) return attempt;

    const widen = Duration(milliseconds: JumpSamplingPlan.widenMs);
    var start = rangeStart - widen;
    if (start < Duration.zero) start = Duration.zero;
    var end = rangeEnd + widen;
    if (end > clipDuration) end = clipDuration;
    if (start >= rangeStart && end <= rangeEnd) return attempt;

    final wider = await _analyze(start, end, sample, onStage);
    // The athlete's own range is the one to explain when neither worked.
    return wider.result != null ? wider : attempt;
  }

  static Future<PoseJumpDiagnostics> _analyze(
    Duration start,
    Duration end,
    PoseFrameSampler sample,
    void Function(JumpAnalysisStage stage)? onStage,
  ) async {
    final firstTimes = JumpSamplingPlan.firstPass(start, end);
    if (firstTimes.isEmpty) return PoseJumpDiagnostics.empty;

    onStage?.call(JumpAnalysisStage.scanning);
    final firstSamples = await sample(firstTimes);
    if (firstSamples.isEmpty) return PoseJumpDiagnostics.unreadable;
    final first = PoseJumpDetector.detectWithDiagnostics(firstSamples);
    if (JumpSamplingPlan.isSinglePass(start, end)) return first;

    // Point the dense pass at each place the jump might be until one of
    // them measures.
    PoseJumpDiagnostics? closest;
    for (final instant in JumpSamplingPlan.jumpCandidates(first)) {
      final window = JumpSamplingPlan.measureWindow(instant, start, end);
      onStage?.call(JumpAnalysisStage.measuring);
      final samples = await sample(
        JumpSamplingPlan.uniform(
          window.from,
          window.to,
          JumpSamplingPlan.measureStepMs,
        ),
      );
      if (samples.isEmpty) continue;
      final dense = PoseJumpDetector.detectWithDiagnostics(samples);
      if (dense.result != null) return dense;
      closest ??= dense;
    }
    // Nothing measured. A window the scan itself reported is deliberately
    // *not* used as the answer: at a step this sparse its crossings are
    // interpolated across gaps as long as the landing itself, and a number
    // that coarse is a guess with a decimal point. The dense look at the best
    // candidate also says more about why than the scan does.
    if (closest != null) return closest;
    if (first.result == null) return first;
    return PoseJumpDiagnostics.unreadable;
  }
}
