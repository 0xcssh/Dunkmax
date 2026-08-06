import 'package:flutter/material.dart';

import '../../../core/flight_time.dart';
import '../../../core/jump_auto_detector.dart';
import '../../../core/jump_feedback.dart';
import '../../../core/jump_result.dart';
import '../../../core/jump_trend.dart';
import '../../../core/models/video_attempt_type.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'processing_screen.dart';

/// The Analyze payoff: the measured vertical plus where it puts the athlete
/// relative to their dunk goal. The four form scores (Bounce/Power/Control/
/// Form) need a second pose pass over joint angles, arm swing and symmetry —
/// pose tracking now times the jump, but nothing scores the *form* yet (see
/// CLAUDE.md) — so they're shown locked rather than faked. Same rule for the
/// written breakdown below: it's built entirely from real measured numbers
/// (see core/jump_feedback.dart) — no claims about form we can't observe.
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
    final feedback = JumpFeedback.build(result, trend: trend);
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
          const _ScoresCard(),
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
/// the frame-motion fallback, or the athlete's own manual marks.
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
          const SizedBox(height: 14),
          const Text(
            'GENERAL TIPS TO CLOSE THE GAP',
            style: TextStyle(
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

class _ScoresCard extends StatelessWidget {
  const _ScoresCard();

  static const _scores = [
    ('Bounce', Icons.bolt),
    ('Power', Icons.fitness_center),
    ('Control', Icons.center_focus_strong),
    ('Form', Icons.accessibility_new),
  ];

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
              Icon(Icons.lock_outline, color: DunkColors.textTertiary, size: 16),
              SizedBox(width: 6),
              Text(
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
          const Text(
            'Unlocks with pose analysis — coming soon.',
            style: TextStyle(color: DunkColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (label, icon) in _scores)
                SizedBox(
                  width: 130,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DunkColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: DunkColors.textTertiary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: DunkColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
