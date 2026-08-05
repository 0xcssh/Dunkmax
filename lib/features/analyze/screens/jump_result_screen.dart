import 'package:flutter/material.dart';

import '../../../core/jump_auto_detector.dart';
import '../../../core/jump_feedback.dart';
import '../../../core/jump_result.dart';
import '../../../core/jump_trend.dart';
import '../../../core/models/video_attempt_type.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// The Analyze payoff: the measured vertical plus where it puts the athlete
/// relative to their dunk goal. The four form scores (Bounce/Power/Control/
/// Form) need pose detection — not built yet (see CLAUDE.md) — so they're
/// shown locked rather than faked; no fabricated numbers. Same rule for the
/// written breakdown below: it's built entirely from real measured numbers
/// (see core/jump_feedback.dart) — no claims about form we can't observe.
class JumpResultScreen extends StatelessWidget {
  final JumpResult result;
  final JumpTrend? trend;
  final JumpDetectionDiagnostics diagnostics;
  final VideoAttemptType attemptType;
  final VoidCallback onAnalyzeAnother;
  final String ctaLabel;

  const JumpResultScreen({
    super.key,
    required this.result,
    required this.trend,
    required this.diagnostics,
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
          if (diagnostics.sampleCount > 0) ...[
            const SizedBox(height: 16),
            _DiagnosticsCard(diagnostics: diagnostics, attemptType: attemptType),
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

/// Raw detection data for this clip — while the auto-detector is still
/// being tuned against real footage, showing exactly what it saw (instead
/// of only the final number) turns the next bug report into something
/// diagnosable instead of another guess. Collapsed by default so it doesn't
/// clutter the normal experience.
class _DiagnosticsCard extends StatefulWidget {
  final JumpDetectionDiagnostics diagnostics;
  final VideoAttemptType attemptType;
  const _DiagnosticsCard({required this.diagnostics, required this.attemptType});

  @override
  State<_DiagnosticsCard> createState() => _DiagnosticsCardState();
}

class _DiagnosticsCardState extends State<_DiagnosticsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.diagnostics;
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
                    const Expanded(
                      child: Text(
                        'DETECTION DETAILS',
                        style: TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
                ],
              ),
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
