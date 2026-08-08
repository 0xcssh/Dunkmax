import 'jump_form_scores.dart';
import 'jump_result.dart';
import 'jump_trend.dart';

/// One aspect of the jump singled out as the strongest or the weakest of the
/// aspects that were actually **measured** on this clip.
///
/// [measurement] is the raw quantity the score came from, carried straight
/// through from [FormScore.detail], so the sentence in [note] never stands on
/// its own — the number behind it is always rendered next to it.
class JumpAspectNote {
  /// "Bounce", "Power", "Control" or "Form".
  final String label;

  /// The 0–100 score, which is how this aspect won or lost the ranking.
  final int score;

  /// The observation the score came from, e.g. "0.18 s on the floor before
  /// takeoff".
  final String measurement;

  /// One sentence on why that measurement matters for a vertical.
  final String note;

  const JumpAspectNote({
    required this.label,
    required this.score,
    required this.measurement,
    required this.note,
  });
}

/// Written feedback for a single analyzed jump — grounded only in numbers we
/// actually measured.
///
/// Two sources feed it, and neither is ever extrapolated past what it
/// observed:
///
///  * the physics: measured vertical, gap to the dunk target, trend versus
///    past logged jumps ([headline], [focusNote]);
///  * the body: the form scores from `jump_form_scores.dart`, which come from
///    the landmarks tracked in *this* clip — ground contact time, hip drive,
///    left/right symmetry, torso lean, arm-swing size and timing.
///
/// From the form scores it names the best- and worst-scoring aspect
/// ([strength], [weakness]) and picks [tips] that address that weakness. The
/// rules that keep this honest:
///
///  1. Every claim traces to a measurement. There is no sentence here about
///     anything the pose pass did not measure (no "your penultimate step is
///     short" — nothing times the penultimate step).
///  2. **Scores that came back unavailable are never weaknesses.** A missing
///     Bounce score means there was no approach step to time, not that the
///     athlete is unspringy. Only measured scores are ranked.
///  3. Too little measured to rank — fewer than two measured scores, or a
///     dead tie between the best and the worst — and [strength] and [weakness]
///     are both null rather than reaching for something to say. The screen
///     then simply shows less.
///  4. No comparisons to other athletes: no percentiles, no "top N %". There
///     is no population to compare against, so any such line would be
///     fabricated.
///
/// [tips] are always well-established coaching advice written as guidance, not
/// as claims about what the video showed. When there is no ranked weakness
/// (manual marking, or a clip body tracking could not score) they fall back to
/// the general pool, which is exactly the feedback this screen gave before the
/// form scores existed.
class JumpFeedbackSummary {
  final String headline;
  final String focusNote;

  /// Best-scoring measured aspect, or null when too little was measured to
  /// rank one.
  final JumpAspectNote? strength;

  /// Worst-scoring measured aspect, or null under the same conditions.
  final JumpAspectNote? weakness;

  final List<String> tips;

  const JumpFeedbackSummary({
    required this.headline,
    required this.focusNote,
    required this.tips,
    this.strength,
    this.weakness,
  });

  /// True when the form scores supported a real ranking, so the breakdown has
  /// a strength and a weakness to show and the tips are targeted at that
  /// weakness rather than general.
  bool get hasRankedAspects => strength != null && weakness != null;
}

abstract class JumpFeedback {
  /// Used when no aspect could be ranked — the athlete marked the jump by
  /// hand, or body tracking scored too little of it. Deliberately general, and
  /// labelled as general on screen.
  static const _tipPool = [
    'Drive your arms up hard as your feet plant — arm drive is one of the '
        "biggest levers for a two-foot vertical, and it's free power you're "
        'not born with, you build it with reps.',
    'Keep your ground-contact time short on the plant. A quick transition '
        'from loading your hips to takeoff preserves more of your speed as '
        'lift instead of bleeding it into the ground.',
    'Depth jumps and box jumps train your body to convert landing force '
        'into the next jump faster — that reactive strength shows up '
        'directly in your vertical.',
    'Consistency beats intensity here: a few focused sessions a week, '
        'logged and repeated, moves your vertical more than one all-out '
        'session ever will.',
  ];

  /// Why the best-scoring aspect matters. Keyed by [FormScore.label].
  static const _strengthNotes = <String, String>{
    'Bounce': 'Your strongest measured piece is how briefly you stayed on the '
        'floor. A short contact means you are reusing the energy of the plant '
        'instead of rebuilding it from a dead stop.',
    'Power': 'Your strongest measured piece is the drive itself — your hips '
        'came up out of the dip quickly, and that speed is what actually '
        'generates the lift.',
    'Control': 'Your strongest measured piece is how square you stayed. Level '
        'hips, matched feet and an upright torso keep the force going straight '
        'up instead of leaking sideways.',
    'Form': 'Your strongest measured piece is the arm swing. A big swing that '
        'finishes as the feet leave the floor adds height you get for free.',
  };

  /// Why the worst-scoring aspect is the one to work on. Same keys.
  static const _weaknessNotes = <String, String>{
    'Bounce': 'The weakest measured piece is your time on the floor before '
        'takeoff. A long contact bleeds the speed you built up into the ground '
        'instead of turning it into lift.',
    'Power': 'The weakest measured piece is the drive out of your dip. However '
        'well the rest is set up, the jump can only be as high as the speed '
        'your hips leave the floor with.',
    'Control': 'The weakest measured piece is how square you stayed through '
        'the jump. Force that goes sideways, or into rotation, is force that '
        'is not going up.',
    'Form': 'The weakest measured piece is the arm swing. The arms are the '
        'cheapest inches in a vertical, and a swing that is small or mistimed '
        'leaves them on the table.',
  };

  /// Two pieces of established coaching advice per aspect, addressing the two
  /// things that aspect actually measures: contact time for Bounce, force and
  /// then rate of force for Power, single-leg balance and trunk stiffness for
  /// Control, swing size and swing timing for Form.
  static const _weaknessTips = <String, List<String>>{
    'Bounce': [
      'Reactive strength is what shortens a slow plant: pogo hops, ankle '
          'bounces and low-box depth jumps, every rep cued to spend as little '
          'time on the floor as possible. Stop the set the moment your '
          'contacts start to feel heavy — this quality does not survive '
          'fatigue.',
      'On your last two steps think "stiff ankle, hit and go" instead of '
          'sinking into the floor. Short approach jumps and sprint '
          'accelerations at full intent train that same fast plant.',
    ],
    'Power': [
      'Raw force sets the ceiling on how hard you can drive out of the dip. '
          'Squats, trap-bar deadlifts and hip thrusts in the 3–5 rep range, '
          'loaded a little heavier week to week, are what raise it.',
      'Then train how fast you apply that force: light jump squats, kettlebell '
          'swings, and every countermovement jump performed with the intent to '
          'move as fast as you can rather than just as high.',
    ],
    'Control': [
      'Single-leg work is the standard fix for a side-to-side difference: '
          'Bulgarian split squats, single-leg RDLs and step-ups, the same sets '
          'and reps on both legs and the weaker side first.',
      'Add anti-rotation trunk work — Pallof presses, suitcase carries, side '
          'planks — so your torso stays stacked over your hips while your legs '
          'do the work.',
    ],
    'Form': [
      'Use the whole range of the swing: let your arms drop below your hips as '
          'you dip, and finish with them fully overhead. Drill the swing on its '
          'own first, then attached to a countermovement jump, until the full '
          'range feels normal.',
      'Time the arms to the plant — they should be driving upward while your '
          'feet are still down and finishing as you leave the floor. Slow, '
          'deliberate reps of the swing paired with a countermovement jump are '
          'what build that timing.',
    ],
  };

  /// Builds the written breakdown.
  ///
  /// [scores] is optional: a jump measured by manual marking has no tracked
  /// body to score, and then this returns exactly the feedback it always did.
  /// Deterministic (never random), so the same jump always reads the same.
  static JumpFeedbackSummary build(
    JumpResult result, {
    JumpTrend? trend,
    JumpFormScores? scores,
  }) {
    final ranked = _rank(scores);
    return JumpFeedbackSummary(
      headline: _headline(result),
      focusNote: _focusNote(result, trend),
      strength: ranked == null
          ? null
          : _aspect(
              ranked.best,
              notes: _strengthNotes,
              fallback: 'The best-scoring of the aspects we could measure on '
                  'this clip.',
            ),
      weakness: ranked == null
          ? null
          : _aspect(
              ranked.worst,
              notes: _weaknessNotes,
              fallback: 'The weakest-scoring of the aspects we could measure '
                  'on this clip.',
            ),
      tips: ranked == null ? _generalTips(result) : _tipsFor(ranked.worst),
    );
  }

  /// The best- and worst-scoring **measured** aspects, or null when there is
  /// no honest ranking to make.
  ///
  /// Unavailable scores are filtered out first (rule 2): a metric whose inputs
  /// were not found says nothing about the athlete. Two measured scores are
  /// the minimum — one score ranked against nothing is not a ranking — and a
  /// dead tie is treated the same way, because calling one of two identical
  /// numbers the strength and the other the weakness would be inventing a
  /// difference that was not measured.
  ///
  /// Ties for best (or worst) among three or more resolve to the first in
  /// [JumpFormScores.all] order, so the result is deterministic.
  static ({FormScore best, FormScore worst})? _rank(JumpFormScores? scores) {
    if (scores == null) return null;
    final measured = scores.all.where((s) => s.isAvailable).toList();
    if (measured.length < 2) return null;

    var best = measured.first;
    var worst = measured.first;
    for (final score in measured.skip(1)) {
      if (score.value! > best.value!) best = score;
      if (score.value! < worst.value!) worst = score;
    }
    if (best.value == worst.value) return null;
    return (best: best, worst: worst);
  }

  static JumpAspectNote _aspect(
    FormScore score, {
    required Map<String, String> notes,
    required String fallback,
  }) {
    return JumpAspectNote(
      label: score.label,
      score: score.value!,
      measurement: score.detail ?? '',
      note: notes[score.label] ?? fallback,
    );
  }

  /// Coaching for the aspect that actually scored worst.
  ///
  /// For Form the two tips address the two halves of the metric — how big the
  /// swing was, and when it peaked — so the more relevant one leads. Which one
  /// that is comes from the detail line the score already carries; it is only
  /// an ordering preference, and an unrecognised detail simply keeps the
  /// default order.
  static List<String> _tipsFor(FormScore worst) {
    final tips = _weaknessTips[worst.label];
    if (tips == null || tips.length < 2) return _tipPool.take(2).toList();
    if (worst.label == 'Form' &&
        (worst.detail?.contains('after takeoff') ?? false)) {
      return [tips[1], tips[0]];
    }
    return [tips[0], tips[1]];
  }

  static String _headline(JumpResult result) {
    if (result.clearsDunk) {
      return "You hit ${result.verticalInches}\" — that clears the "
          '${result.requiredVert}" you need at your height. Keep stacking '
          'sessions to make it repeatable, not a one-off.';
    }
    return "You hit ${result.verticalInches}\" this jump, "
        '${result.gapInches}" short of the ${result.requiredVert}" you need '
        'at your height.';
  }

  static String _focusNote(JumpResult result, JumpTrend? trend) {
    if (trend == null) {
      // First-ever logged jump: this is the first time real data exists,
      // and it will often disagree with the self-reported hops-level guess
      // from onboarding (assessment.estimatedCurrentVert) — sometimes by a
      // lot, since a self-report is a coarse category, not a measurement.
      // Naming that difference explicitly beats leaving the athlete to
      // wonder why the gap they saw at onboarding doesn't match this one.
      final selfReported = result.assessment.estimatedCurrentVert;
      final measured = result.verticalInches;
      final delta = measured - selfReported;
      if (delta.abs() <= 2) {
        return 'Your measured jump lines up closely with your onboarding '
            'estimate — good self-awareness. Log a few more to start '
            'tracking your trend.';
      }
      if (delta > 0) {
        return 'Your measured jump ($measured") came in $delta" above your '
            'onboarding estimate ($selfReported") — that estimate was a '
            'guess from a self-reported category, not a measurement. This '
            'real number is what we track from here.';
      }
      return 'Your measured jump ($measured") came in ${delta.abs()}" below '
          'your onboarding estimate ($selfReported") — self-reports run '
          'optimistic more often than not. This real number is what we '
          'track from here.';
    }
    final delta = trend.deltaFromFirstInches;
    if (delta > 0) {
      return "You're up $delta\" since your first logged test — the trend "
          'is real, keep logging to see it hold.';
    }
    if (delta < 0) {
      return "You're ${delta.abs()}\" below your first logged test. That "
          "happens — fatigue, footing, warm-up all move this number day to "
          'day. Keep logging; one jump is a data point, not a verdict.';
    }
    return "Same as your first logged test so far — log a few more to see "
        'a real trend form.';
  }

  /// Deterministic (not random) so results are stable/testable — picks two
  /// distinct tips from the general pool based on the measured gap.
  static List<String> _generalTips(JumpResult result) {
    final start = result.gapInches % _tipPool.length;
    final second = (start + 1) % _tipPool.length;
    return [_tipPool[start], _tipPool[second]];
  }
}
