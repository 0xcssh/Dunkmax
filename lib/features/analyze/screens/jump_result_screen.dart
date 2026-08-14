import 'package:flutter/material.dart';

import '../../../core/flight_time.dart';
import '../../../core/jump_auto_detector.dart';
import '../../../core/jump_feedback.dart';
import '../../../core/jump_form_scores.dart';
import '../../../core/jump_result.dart';
import '../../../core/jump_trend.dart';
import '../../../core/models/video_attempt_type.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import '../widgets/detection_details_card.dart';
import 'processing_screen.dart';

/// The Analyze payoff: the measured vertical plus where it puts the athlete
/// relative to their dunk goal. The four form scores (Bounce/Power/Control/
/// Form) come from `core/jump_form_scores.dart`, which reads the same tracked
/// landmarks that timed the jump — ground contact, hip drop and drive, left/
/// right symmetry, arm swing. Any one of them that could not be measured on
/// this clip renders as unavailable with the reason, never as a zero or a
/// filler number. Same rule for the written breakdown below: it's built
/// entirely from real measured numbers (see core/jump_feedback.dart) — the
/// vertical and the gap, plus the best- and worst-scoring *measured* form
/// aspects and coaching aimed at that weakness. No claims about form we can't
/// observe, and nothing ranked that wasn't measured.
class JumpResultScreen extends StatelessWidget {
  final JumpResult result;
  final JumpTrend? trend;
  final JumpAnalysis analysis;

  /// Which tier of the detection cascade produced [result].
  final JumpDetectionMethod method;
  final VideoAttemptType attemptType;
  final VoidCallback onAnalyzeAnother;

  /// Null means "analyze another jump" — the default can no longer live in the
  /// constructor, because it is a translation and needs a [BuildContext].
  final String? ctaLabel;

  const JumpResultScreen({
    super.key,
    required this.result,
    required this.trend,
    required this.analysis,
    required this.method,
    required this.attemptType,
    required this.onAnalyzeAnother,
    this.ctaLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final feedback = JumpFeedback.build(
      result,
      trend: trend,
      scores: analysis.scores,
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.resultTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _VertCard(result: result),
          const SizedBox(height: 16),
          // Scores sit directly under the headline number on purpose: they are
          // the other measured output of the same pass, and a reader scanning
          // the screen should meet both before the prose that interprets them.
          _ScoresCard(scores: analysis.scores),
          const SizedBox(height: 16),
          _BreakdownCard(feedback: feedback),
          if (analysis.hasAnyData) ...[
            const SizedBox(height: 16),
            DetectionDetailsCard(
              analysis: analysis,
              method: method,
              attemptType: attemptType,
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: ctaLabel ?? l10n.resultCtaAnalyzeAnother,
            onPressed: onAnalyzeAnother,
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final JumpFeedbackSummary feedback;

  const _BreakdownCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: DunkColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.resultBreakdownTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback.headline,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DunkColors.accentGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DunkColors.accentGreen.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.show_chart, color: DunkColors.accentGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    feedback.focusNote,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (feedback.strength != null) ...[
            const SizedBox(height: 12),
            _AspectNote(
              caption: l10n.resultStrongest,
              icon: Icons.check_circle_outline,
              tone: DunkColors.accentGreen,
              aspect: feedback.strength!,
            ),
          ],
          if (feedback.weakness != null) ...[
            const SizedBox(height: 10),
            _AspectNote(
              caption: l10n.resultWeakest,
              icon: Icons.track_changes,
              tone: DunkColors.primary,
              aspect: feedback.weakness!,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            feedback.hasRankedAspects
                ? l10n.resultHowToWorkOnIt
                : l10n.resultGeneralTips,
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < feedback.tips.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == feedback.tips.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: DunkColors.surfaceRaised,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: DunkColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feedback.tips[i],
                      style: const TextStyle(
                        color: DunkColors.textSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One ranked aspect of the jump — the strongest or the one to work on —
/// rendered in the same tinted-panel language as the trend note above it: a
/// caption with the aspect name, the score as a pill, the sentence, and the
/// measurement it rests on.
class _AspectNote extends StatelessWidget {
  final String caption;
  final IconData icon;
  final Color tone;
  final JumpAspectNote aspect;

  const _AspectNote({
    required this.caption,
    required this.icon,
    required this.tone,
    required this.aspect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: tone, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  // The aspect name comes from the untranslated feedback core.
                  l10n.resultAspectCaption(
                      caption, aspect.label.toUpperCase()),
                  style: TextStyle(
                    color: tone,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.resultScoreOutOf(aspect.score),
                  style: TextStyle(
                    color: tone,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            aspect.note,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          if (aspect.measurement.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.resultMeasuredPrefix(aspect.measurement),
              style: const TextStyle(
                color: DunkColors.textTertiary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VertCard extends StatelessWidget {
  final JumpResult result;
  const _VertCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            l10n.resultEstVert,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.inches(result.verticalInches),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            result.clearsDunk
                ? l10n.resultClearsDunk(result.requiredVert)
                : l10n.resultGapToDunk(result.gapInches, result.requiredVert),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          // The measured vertical is real; the target it's compared against is
          // only as good as the standing reach behind it. Say which one this
          // is, quietly, and only while it's still an estimate.
          if (!result.assessment.reachIsMeasured) ...[
            const SizedBox(height: 8),
            Text(
              l10n.resultEstimatedReachNote(result.assessment.standingReach),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: result.progressToGoal.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bounce / Power / Control / Form, each read off the tracked landmarks of
/// this clip.
///
/// Every tile is either a measured number with the observation behind it, or
/// an explicit "not measured here" with the reason — there is no filler. The
/// whole card falls back to the unavailable state when body tracking never
/// located the jump (the number above then came from the athlete's own marks
/// or the motion fallback, and there are no landmarks to score).
///
/// Deliberately absent: any "top N % for your height" comparison. That needs
/// a real user base to compare against, and the app does not have one.
class _ScoresCard extends StatelessWidget {
  final JumpFormScores? scores;

  const _ScoresCard({required this.scores});

  /// Keyed on `FormScore.label`, which is authored in pure-Dart core and so
  /// is not translated. The display name comes from the ARB instead — see
  /// [_ScoreGrid._displayLabel].
  static const _icons = <String, IconData>{
    'Bounce': Icons.bolt,
    'Power': Icons.fitness_center,
    'Control': Icons.center_focus_strong,
    'Form': Icons.accessibility_new,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = scores;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s == null ? Icons.lock_outline : Icons.insights,
                color: s == null ? DunkColors.textTertiary : DunkColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.resultFormScoresTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s == null ? l10n.resultScoresUnavailable : l10n.resultScoresIntro,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (s?.takeoffType != null) ...[
            const SizedBox(height: 12),
            _TakeoffPill(type: s!.takeoffType!),
          ],
          const SizedBox(height: 14),
          _ScoreGrid(scores: s),
          const SizedBox(height: 12),
          Text(
            l10n.resultScoresDisclaimer,
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// The 2×2 grid. Rows are height-matched so a two-line reason on one tile
/// doesn't leave its neighbour looking clipped.
class _ScoreGrid extends StatelessWidget {
  final JumpFormScores? scores;

  const _ScoreGrid({required this.scores});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = <Widget>[
      for (final key in _ScoresCard._icons.keys)
        _ScoreTile(
          label: _displayLabel(l10n, key),
          icon: _ScoresCard._icons[key]!,
          score: _scoreFor(key),
        ),
    ];

    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tiles[row * 2]),
                const SizedBox(width: 12),
                Expanded(child: tiles[row * 2 + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  FormScore? _scoreFor(String label) {
    final s = scores;
    if (s == null) return null;
    return s.all.firstWhere((score) => score.label == label);
  }

  /// Maps the core's own (untranslated) score label onto its display name.
  static String _displayLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'Bounce':
        return l10n.scoreBounce;
      case 'Power':
        return l10n.scorePower;
      case 'Control':
        return l10n.scoreControl;
      case 'Form':
        return l10n.scoreForm;
      default:
        return key;
    }
  }
}

class _ScoreTile extends StatelessWidget {
  final String label;
  final IconData icon;

  /// Null when body tracking never ran on this clip at all; otherwise the
  /// score object, which may itself be unavailable with a reason.
  final FormScore? score;

  const _ScoreTile({
    required this.label,
    required this.icon,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = score?.value;
    final measured = value != null;
    // A reason the score object carries comes from untranslated core code.
    final reason = score?.unavailableReason ?? l10n.resultNoTrackingReason;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DunkColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: measured ? DunkColors.primary : DunkColors.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: measured ? Colors.white : DunkColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (value != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  l10n.resultScoreDenominator,
                  style: const TextStyle(
                    color: DunkColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 5,
                backgroundColor: DunkColors.stroke,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(DunkColors.primary),
              ),
            ),
            if (score?.detail != null) ...[
              const SizedBox(height: 8),
              Text(
                score!.detail!,
                style: const TextStyle(
                  color: DunkColors.textTertiary,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
            ],
          ] else ...[
            Text(
              l10n.resultNotMeasured,
              style: const TextStyle(
                color: DunkColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _capitalize(reason),
              style: const TextStyle(
                color: DunkColors.textTertiary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// One-foot vs two-foot, shown only when the two ankles left the ground
/// clearly together or clearly apart.
class _TakeoffPill extends StatelessWidget {
  final TakeoffType type;

  const _TakeoffPill({required this.type});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: DunkColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DunkColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_run, color: DunkColors.primary, size: 14),
            const SizedBox(width: 6),
            Text(
              type.label.toUpperCase(),
              style: const TextStyle(
                color: DunkColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
