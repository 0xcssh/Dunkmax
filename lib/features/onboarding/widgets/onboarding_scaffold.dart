import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/layout_density.dart';
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

  /// Null means the generic "CONTINUE" label. It can't be defaulted in the
  /// constructor any more: the default is a translation, and translations
  /// need a [BuildContext].
  final String? ctaLabel;
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
    this.ctaLabel,
    this.onBack,
    this.staggerBody = true,
  });

  @override
  Widget build(BuildContext context) {
    // Every quiz step has to fit one page: header, headline, subtitle, the
    // body and the CTA. The headline keeps its authored line breaks and is
    // scaled down (never wrapped) when its longest line is wider than the
    // screen — a French line that wraps to a third row costs more height than
    // a slightly smaller headline. Shorter phones get the compact metrics.
    final density = LayoutDensity.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, density.pick(12, 10)),
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
              SizedBox(height: density.pick(18, 12)),
              StaggerItem(
                index: 0,
                child: OnboardingHeadline(text: title),
              ),
              SizedBox(height: density.pick(8, 6)),
              StaggerItem(
                index: 1,
                child: Text(
                  subtitle,
                  style: density.pick(
                    DunkTheme.onboardingSubtitle,
                    DunkTheme.onboardingSubtitleCompact,
                  ),
                ),
              ),
              SizedBox(height: density.pick(16, 12)),
              Expanded(
                child: staggerBody
                    ? StaggerItem(index: bodyStaggerIndex, child: child)
                    : child,
              ),
              SizedBox(height: density.pick(12, 10)),
              StaggerItem(
                index: _ctaStaggerIndex,
                child: PrimaryButton(
                  label: ctaLabel ?? AppLocalizations.of(context).commonContinue,
                  onPressed: onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The all-caps onboarding headline, shared by the quiz steps and the sell
/// screens so they shrink the same way on the same phones.
///
/// Authored line breaks are kept. If the longest line is still wider than the
/// available width the whole block scales down to fit, so a headline never
/// gains an unplanned extra row.
class OnboardingHeadline extends StatelessWidget {
  final String text;

  const OnboardingHeadline({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final density = LayoutDensity.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          softWrap: false,
          style: density.pick(
            DunkTheme.onboardingTitle,
            DunkTheme.onboardingTitleCompact,
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
