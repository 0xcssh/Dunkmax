import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';
import 'staggered_entrance.dart';

/// Shared chrome for every quiz step: a segmented progress bar + back button
/// up top, a title/subtitle block, the step's body, and a pinned Continue CTA.
///
/// The blocks arrive in a short stagger (see [StaggerItem]) when the step is
/// entered. The header is deliberately left out of it: the progress bar is
/// continuous chrome, so re-animating it every step would fight the sense that
/// it is one bar filling up.
class OnboardingScaffold extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final String ctaLabel;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  /// Whether the body should arrive as one block. Screens whose body is a list
  /// of option cards pass false and stagger the cards individually, from
  /// [bodyStaggerIndex] upwards.
  final bool staggerBody;

  /// Where the body sits in the stagger order — also the first index a screen
  /// staggering its own cards should use.
  static const int bodyStaggerIndex = 2;

  /// The CTA is pinned late and at a fixed index so it always lands last,
  /// whatever the body does.
  static const int _ctaStaggerIndex = 7;

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
    this.staggerBody = true,
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
              StaggerItem(
                index: 0,
                child: Text(title, style: DunkTheme.onboardingTitle),
              ),
              const SizedBox(height: 12),
              StaggerItem(
                index: 1,
                child: Text(subtitle, style: DunkTheme.onboardingSubtitle),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: staggerBody
                    ? StaggerItem(index: bodyStaggerIndex, child: child)
                    : child,
              ),
              const SizedBox(height: 12),
              StaggerItem(
                index: _ctaStaggerIndex,
                child: PrimaryButton(label: ctaLabel, onPressed: onContinue),
              ),
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
