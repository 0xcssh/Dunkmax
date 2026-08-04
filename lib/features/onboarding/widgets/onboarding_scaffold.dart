import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Shared chrome for every quiz step: a segmented progress bar + back button
/// up top, a title/subtitle block, the step's body, and a pinned Continue CTA.
class OnboardingScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final String ctaLabel;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onContinue,
    this.ctaLabel = 'CONTINUE',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BackButton(onBack: onBack),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProgressBar(step: step, totalSteps: totalSteps),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(title, style: DunkTheme.onboardingTitle),
              const SizedBox(height: 12),
              Text(subtitle, style: DunkTheme.onboardingSubtitle),
              const SizedBox(height: 28),
              Expanded(child: child),
              const SizedBox(height: 12),
              PrimaryButton(label: ctaLabel, onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback? onBack;
  const _BackButton({this.onBack});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  const _ProgressBar({required this.step, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fraction = (step / totalSteps).clamp(0.0, 1.0);
        return Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: DunkColors.surfaceRaised,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 8,
              width: constraints.maxWidth * fraction,
              decoration: BoxDecoration(
                gradient: DunkColors.primaryGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      },
    );
  }
}
