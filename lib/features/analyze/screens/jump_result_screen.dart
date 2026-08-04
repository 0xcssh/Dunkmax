import 'package:flutter/material.dart';

import '../../../core/jump_result.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// The Analyze payoff: the measured vertical plus where it puts the athlete
/// relative to their dunk goal. The four form scores (Bounce/Power/Control/
/// Form) need pose detection — not built yet (see CLAUDE.md) — so they're
/// shown locked rather than faked; no fabricated numbers.
class JumpResultScreen extends StatelessWidget {
  final JumpResult result;
  final VoidCallback onAnalyzeAnother;

  const JumpResultScreen({
    super.key,
    required this.result,
    required this.onAnalyzeAnother,
  });

  @override
  Widget build(BuildContext context) {
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
          const _ScoresCard(),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'ANALYZE ANOTHER JUMP',
            onPressed: onAnalyzeAnother,
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
