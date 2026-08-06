import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// The last sell beat before the plan reveal.
///
/// This slot used to hold a social-proof screen with a placeholder star
/// rating and invented testimonials. A brand-new app has no reviews to show,
/// and shipping fabricated ones is both misleading and against App Store
/// Review guidelines — the same rule that keeps the Analyze form scores
/// honestly locked instead of faked (see CLAUDE.md). So rather than leave a
/// "replace before submission" landmine in the flow, this screen sells the
/// one thing that is genuinely true today: the method. Every claim below is
/// something the app actually does.
///
/// When real reviews exist, they belong here — added to this screen, not in
/// place of it.
class HowItWorksScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const HowItWorksScreen({
    super.key,
    required this.onContinue,
    required this.onBack,
  });

  static const _points = <(IconData, String, String)>[
    (
      Icons.straighten,
      'Measured, not guessed',
      'We time your hang from the video and derive the height from '
          'gravity itself. No camera calibration, no eyeballing.',
    ),
    (
      Icons.tune,
      'A plan built around you',
      'Your height, age, experience and training days decide the program '
          'you get — not a one-size-fits-all template.',
    ),
    (
      Icons.trending_up,
      'Progress you can check',
      'Every session and every analysed jump is logged, so the trend you '
          'see is your own history, not a motivational number.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: onBack,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.chevron_left,
                    color: Colors.white, size: 30),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Text(
                      'HOW YOUR VERT\nGETS MEASURED',
                      style: DunkTheme.onboardingTitle,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No wearables, no markers on the floor. Just physics '
                      'and your phone camera.',
                      style: DunkTheme.onboardingSubtitle,
                    ),
                    const SizedBox(height: 20),
                    const _PhysicsCard(),
                    const SizedBox(height: 12),
                    for (final (icon, title, body) in _points) ...[
                      _PointCard(icon: icon, title: title, body: body),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'START MY PLAN', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

/// The headline idea, stated plainly: hang time alone determines jump
/// height. Showing the actual relation is more persuasive than a star
/// rating we don't have — and it's true.
class _PhysicsCard extends StatelessWidget {
  const _PhysicsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, color: DunkColors.primary, size: 30),
          const SizedBox(height: 12),
          const Text(
            'HANG TIME',
            style: TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'decides your height',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: DunkColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'longer in the air  =  higher jump',
              style: TextStyle(
                color: DunkColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Two athletes with the same hang time jumped the same height. '
            'That is what we measure.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PointCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DunkColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: DunkColors.primary, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
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
