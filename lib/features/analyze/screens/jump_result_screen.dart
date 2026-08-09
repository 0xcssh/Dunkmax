import 'package:flutter/material.dart';

import '../../../core/flight_time.dart';
import '../../../core/jump_auto_detector.dart';
import '../../../core/jump_feedback.dart';
import '../../../core/jump_form_scores.dart';
import '../../../core/jump_result.dart';
import '../../../core/jump_trend.dart';
import '../../../core/models/video_attempt_type.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
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
  final String ctaLabel;

  const JumpResultScreen({
    super.key,
    required this.result,
    required this.trend,
    required this.analysis,
    required this.method,
    required this.attemptType,
    required this.onAnalyzeAnother,
    this.ctaLabel = 'ANALYZE ANOTHER JUMP',
  });

  @override
  Widget build(BuildContext context) {
    final feedback = JumpFeedback.build(
      result,
      trend: trend,
      scores: analysis.scores,
    );
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            'YOUR JUMP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _VertCard(result: result),
          const SizedBox(height: 16),
          _BreakdownCard(feedback: feedback),
          const SizedBox(height: 16),
          _ScoresCard(scores: analysis.scores),
          if (analysis.hasAnyData) ...[
            const SizedBox(height: 16),
            _DiagnosticsCard(
              analysis: analysis,
              method: method,
              attemptType: attemptType,
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: ctaLabel,
            onPressed: onAnalyzeAnother,
          ),
        ],
      ),
    );
  }
}

/// Raw detection data for this clip, and — stated plainly, not implied —
/// which of the three methods produced the number above it: body tracking,
/// or the frame-motion fallback.
///
/// While detection is still being validated against real footage, showing
/// exactly what each pass saw (instead of only the final number) turns the
/// next bug report into something diagnosable instead of another guess. Both
/// passes are shown when both ran, so a pose pass that *declined* is as
/// visible as one that won. Collapsed by default so it doesn't clutter the
/// normal experience.
class _DiagnosticsCard extends StatefulWidget {
  final JumpAnalysis analysis;
  final JumpDetectionMethod method;
  final VideoAttemptType attemptType;
  const _DiagnosticsCard({
    required this.analysis,
    required this.method,
    required this.attemptType,
  });

  @override
  State<_DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends State<_DiagnosticsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.analysis.motion;
    final p = widget.analysis.pose;
    return Container(
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_outlined,
                        color: DunkColors.textTertiary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DETECTION DETAILS',
                            style: TextStyle(
                              color: DunkColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Measured by ${widget.method.label.toLowerCase()}',
                            style: const TextStyle(
                              color: DunkColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: DunkColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clip type: ${widget.attemptType.title}',
                    style: const TextStyle(
                      color: DunkColors.textTertiary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reported number from: ${widget.method.label}',
                    style: const TextStyle(
                      color: DunkColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PoseSection(
                    pose: p,
                    isReported: widget.method == JumpDetectionMethod.pose,
                  ),
                  if (d.sampleCount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.method == JumpDetectionMethod.motion
                          ? 'FRAME MOTION (fallback — used)'
                          : 'FRAME MOTION (fallback)',
                      style: const TextStyle(
                        color: DunkColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MotionSection(
                      d: d,
                      isReported:
                          widget.method == JumpDetectionMethod.motion,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The pose pass: what the body tracker saw. Shown whether it won or was
/// overruled by the fallback, because a pose pass that *declined* is exactly
/// the case that needs diagnosing from a real device.
class _PoseSection extends StatelessWidget {
  final PoseJumpDiagnostics pose;
  final bool isReported;

  const _PoseSection({required this.pose, required this.isReported});

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      color: DunkColors.textTertiary,
      fontSize: 11,
      fontFamily: 'monospace',
    );

    final lines = <String>[
      '${pose.sampleCount} frames · athlete found in ${pose.detectedCount} '
          '(${pose.missingCount} missed)',
    ];
    if (pose.detectedCount > 0) {
      lines.add(
        'torso ${pose.torsoPixels.toStringAsFixed(1)}px · '
        'ground y ${pose.groundBaselineY.toStringAsFixed(1)} · '
        'lift threshold ${pose.liftThresholdPixels.toStringAsFixed(1)}px',
      );
    }
    if (pose.peakLiftPixels > 0) {
      lines.add('peak foot lift ${pose.peakLiftPixels.toStringAsFixed(1)}px');
    }
    if (pose.crossingTakeoff != null && pose.crossingLanding != null) {
      lines.add(
        'window ${pose.crossingTakeoff!.inMilliseconds}–'
        '${pose.crossingLanding!.inMilliseconds}ms',
      );
    }
    if (pose.rawCrossingSeconds != null) {
      lines.add(
        'raw crossings ${pose.rawCrossingSeconds!.toStringAsFixed(3)}s',
      );
    }
    if (pose.correctedSeconds != null) {
      lines.add(
        'parabola-corrected ${pose.correctedSeconds!.toStringAsFixed(3)}s → '
        '${FlightTime.heightInches(pose.correctedSeconds!).toStringAsFixed(1)}"',
      );
    }
    lines.add('outcome: ${pose.rejection.label}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isReported ? 'BODY TRACKING (used)' : 'BODY TRACKING',
          style: TextStyle(
            color: isReported ? DunkColors.primary : DunkColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: mono),
          ),
        if (pose.samples.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text(
            'foot y per frame (— = no pose)',
            style: TextStyle(color: DunkColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            [
              for (final s in pose.samples)
                '${s.timestamp.inMilliseconds}:'
                    '${s.footY == null ? '—' : s.footY!.round()}',
            ].join('  '),
            style: mono,
          ),
        ],
      ],
    );
  }
}

/// The legacy motion-energy pass, unchanged — only rendered when it actually
/// ran (i.e. body tracking declined).
class _MotionSection extends StatelessWidget {
  final JumpDetectionDiagnostics d;

  /// True only when this pass is the one that produced the headline number.
  final bool isReported;

  const _MotionSection({required this.d, required this.isReported});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${d.sampleCount} samples · energy '
          '${d.minEnergy.toStringAsFixed(3)}–${d.maxEnergy.toStringAsFixed(3)} · '
          'threshold ${d.threshold.toStringAsFixed(3)}',
          style: const TextStyle(
            color: DunkColors.textTertiary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 10),
        if (d.candidates.isEmpty)
          const Text(
            'No plausible candidate windows found.',
            style: TextStyle(color: DunkColors.textTertiary, fontSize: 12),
          )
        else
          for (final c in d.candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${c.chosen ? '→ ' : '  '}'
                '${c.airborneSeconds.toStringAsFixed(2)}s '
                '(${c.takeoff.inMilliseconds}–${c.landing.inMilliseconds}ms) · '
                'avg ${c.avgEnergy.toStringAsFixed(3)} · '
                'bounds ${c.boundingEnergy.toStringAsFixed(3)} · '
                'prom ${c.prominence.toStringAsFixed(3)}'
                '${c.chosen ? ' [CHOSEN]' : ''}',
                style: TextStyle(
                  color: c.chosen ? DunkColors.primary : DunkColors.textTertiary,
                  fontWeight: c.chosen ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        if (d.estimates.outerBoundSeconds != null) ...[
          const SizedBox(height: 12),
          const Text(
            'HOW THE WINDOW IS MEASURED',
            style: TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _EstimateLine(
            label: 'outer bound',
            seconds: d.estimates.outerBoundSeconds,
            isReported: isReported,
          ),
          _EstimateLine(
            label: 'threshold cross',
            seconds: d.estimates.crossingSeconds,
          ),
          _EstimateLine(
            label: 'apex symmetry',
            seconds: d.estimates.apexSymmetrySeconds,
          ),
        ],
      ],
    );
  }
}

/// One candidate reading of the airborne window, shown as both the raw hang
/// time and the vertical it would produce — so the three can be compared
/// directly against a known reference measurement of the same clip.
class _EstimateLine extends StatelessWidget {
  final String label;
  final double? seconds;
  final bool isReported;

  const _EstimateLine({
    required this.label,
    required this.seconds,
    this.isReported = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = seconds;
    final text = value == null
        ? '$label: —'
        : '$label: ${value.toStringAsFixed(3)}s → '
            '${FlightTime.heightInches(value).toStringAsFixed(1)}"'
            '${isReported ? '  [REPORTED]' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: isReported ? DunkColors.primary : DunkColors.textTertiary,
          fontWeight: isReported ? FontWeight.w700 : FontWeight.w400,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// The written read on the jump: the headline number, the trend note, then —
/// when body tracking measured enough to rank them — the best and worst
/// measured aspects and two tips aimed at that weakness.
///
/// The strength/weakness rows carry the same measurement string the matching
/// tile in FORM SCORES shows. That repetition is deliberate and framed
/// differently on each side: the tile is the number, this is the sentence that
/// says why it matters. When nothing could be ranked, the rows are simply
/// absent and the tips revert to the general ones — the card never fills the
/// space with a guess.
class _BreakdownCard extends StatelessWidget {
  final JumpFeedbackSummary feedback;

  const _BreakdownCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.bolt, color: DunkColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'JUMP BREAKDOWN',
                style: TextStyle(
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
              caption: 'STRONGEST',
              icon: Icons.check_circle_outline,
              tone: DunkColors.accentGreen,
              aspect: feedback.strength!,
            ),
          ],
          if (feedback.weakness != null) ...[
            const SizedBox(height: 10),
            _AspectNote(
              caption: 'WEAKEST',
              icon: Icons.track_changes,
              tone: DunkColors.primary,
              aspect: feedback.weakness!,
            ),
          ],
          const SizedBox(height: 14),
          Text(
            feedback.hasRankedAspects
                ? 'HOW TO WORK ON IT'
                : 'GENERAL TIPS TO CLOSE THE GAP',
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
                  '$caption · ${aspect.label.toUpperCase()}',
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
                  '${aspect.score}/100',
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
              'Measured: ${aspect.measurement}',
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'EST. VERT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.verticalInches}"',
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
                ? 'That clears your ${result.requiredVert}" dunk target'
                : '${result.gapInches}" to go to your ${result.requiredVert}" dunk target',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          // The measured vertical is real; the target it's compared against is
          // only as good as the standing reach behind it. Say which one this
          // is, quietly, and only while it's still an estimate.
          if (!result.assessment.reachIsMeasured) ...[
            const SizedBox(height: 8),
            Text(
              'Target assumes an estimated ${result.assessment.standingReach}" '
              'standing reach. Set your real reach in Settings for an exact one.',
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

  static const _icons = <String, IconData>{
    'Bounce': Icons.bolt,
    'Power': Icons.fitness_center,
    'Control': Icons.center_focus_strong,
    'Form': Icons.accessibility_new,
  };

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'FORM SCORES',
                style: TextStyle(
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
            s == null
                ? 'Scoring your form needs body tracking, and it could not '
                    'follow you through this clip.'
                : 'Scored from your body in this clip — nothing is filled in '
                    'where it could not be measured.',
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
          const Text(
            'Scores rate your technique against coaching guidelines, not '
            'against other athletes.',
            style: TextStyle(
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
    final tiles = <Widget>[
      for (final label in _ScoresCard._icons.keys)
        _ScoreTile(
          label: label,
          icon: _ScoresCard._icons[label]!,
          score: _scoreFor(label),
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
    final value = score?.value;
    final measured = value != null;
    final reason = score?.unavailableReason ?? 'body tracking did not run';

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
                const Text(
                  '/100',
                  style: TextStyle(
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
            const Text(
              'Not measured',
              style: TextStyle(
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
