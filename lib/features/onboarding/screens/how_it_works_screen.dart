import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/layout_density.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/sell_scaffold.dart';

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

  /// Every line here has to be something the app does today.
  ///
  /// This list previously claimed the programme was built from "your height,
  /// age, experience and training days". Height and age never reached the
  /// programming — they drive the dunk target and the projection curve, which
  /// is a different thing — so the sell screen was promising a
  /// personalisation that did not exist. Check any claim added here against
  /// `core/program_catalog.dart` and `core/pose_jump_detector.dart` before it
  /// ships.
  List<(IconData, String, String)> _points(AppLocalizations l10n) => [
        (
          Icons.accessibility_new,
          l10n.howItWorksPoint1Title,
          l10n.howItWorksPoint1Body,
        ),
        (
          Icons.straighten,
          l10n.howItWorksPoint2Title,
          l10n.howItWorksPoint2Body,
        ),
        (
          Icons.tune,
          l10n.howItWorksPoint3Title,
          l10n.howItWorksPoint3Body,
        ),
        (
          Icons.trending_up,
          l10n.howItWorksPoint4Title,
          l10n.howItWorksPoint4Body,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final density = LayoutDensity.of(context);
    final gap = density.pick(8.0, 6.0);
    // This is the densest screen in the flow — five blocks of prose — so
    // every gap here is a notch under the other sell screens'.
    return SellScaffold(
      onBack: onBack,
      ctaLabel: l10n.howItWorksCta,
      onContinue: onContinue,
      children: [
        OnboardingHeadline(text: l10n.howItWorksTitle),
        const SizedBox(height: 4),
        Text(
          l10n.howItWorksSubtitle,
          style: density.pick(
            DunkTheme.onboardingSubtitle,
            DunkTheme.onboardingSubtitleCompact,
          ),
        ),
        SizedBox(height: density.pick(10, 8)),
        const _PhysicsCard(),
        SizedBox(height: gap),
        _PointsCard(points: _points(l10n)),
      ],
    );
  }
}

/// The four claims as one card of rows with hairline dividers, rather than
/// four bordered cards: same words, same icons, and the ~80 pt of card
/// chrome that would otherwise push the CTA below the fold goes to the
/// text instead.
class _PointsCard extends StatelessWidget {
  final List<(IconData, String, String)> points;

  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final compact = LayoutDensity.of(context).isCompact;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        children: [
          for (var i = 0; i < points.length; i++) ...[
            if (i > 0) const Divider(color: DunkColors.stroke, height: 1),
            _PointRow(
              icon: points[i].$1,
              title: points[i].$2,
              body: points[i].$3,
            ),
          ],
        ],
      ),
    );
  }
}

/// The headline idea, stated plainly: hang time alone determines jump
/// height. Showing the actual relation is more persuasive than a star
/// rating we don't have — and it's true.
///
/// Laid out as a row (icon beside the claim) rather than a centred stack:
/// this screen carries five cards of prose and has to fit one page, so the
/// hero card spends its height on words, not on vertical centring.
class _PhysicsCard extends StatelessWidget {
  const _PhysicsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DunkColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.timer_outlined,
                    color: DunkColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.hangTimeLabel,
                      style: const TextStyle(
                        color: DunkColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.hangTimeDecides,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: DunkColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.hangTimeFormula,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DunkColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.hangTimeNote,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _PointRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _PointRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final compact = LayoutDensity.of(context).isCompact;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 5 : 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DunkColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DunkColors.primary, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 12,
                    height: 1.25,
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
