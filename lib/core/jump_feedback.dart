import 'jump_result.dart';
import 'jump_trend.dart';

/// Written feedback for a single analyzed jump — grounded only in numbers
/// we actually measured (vertical, gap to dunk, trend vs. past jumps).
///
/// We have no pose-tracking data, so this deliberately does NOT claim to
/// have observed anything about the athlete's form in this specific clip
/// (no "your arm swing is late" style claims) — [tips] are general,
/// well-established vertical-jump coaching advice, not an assessment of
/// this jump. Faking a form observation we can't actually make would be
/// exactly the kind of fabricated data the locked Bounce/Power/Control/Form
/// cards on the result screen already refuse to show.
class JumpFeedbackSummary {
  final String headline;
  final String focusNote;
  final List<String> tips;

  const JumpFeedbackSummary({
    required this.headline,
    required this.focusNote,
    required this.tips,
  });
}

abstract class JumpFeedback {
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

  /// Deterministic (not random) so results are stable/testable — picks two
  /// distinct tips from the pool based on the measured gap.
  static JumpFeedbackSummary build(JumpResult result, {JumpTrend? trend}) {
    return JumpFeedbackSummary(
      headline: _headline(result),
      focusNote: _focusNote(result, trend),
      tips: _pickTips(result),
    );
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

  static List<String> _pickTips(JumpResult result) {
    final start = result.gapInches % _tipPool.length;
    final second = (start + 1) % _tipPool.length;
    return [_tipPool[start], _tipPool[second]];
  }
}
