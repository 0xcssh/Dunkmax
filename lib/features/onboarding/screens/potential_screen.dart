import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/program_catalog.dart';
import '../../../core/vert_assessment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/layout_density.dart';
import '../../shared/unit_scope.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/sell_scaffold.dart';

/// "Your jump potential" — projected vert curve over the recommended program.
///
/// The window is the program's real length (8 weeks for Foundation and
/// Reactive Power, 10 for Elite Vertical), read off the same catalog the
/// plan-reveal screen uses, so the two can never disagree. The curve itself
/// is age-only (`VertAssessment.projectedVertAtWeek`): it does not know the
/// athlete's schedule or experience, and the subtitle says so.
class PotentialScreen extends StatelessWidget {
  final OnboardingProfile profile;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const PotentialScreen({
    super.key,
    required this.profile,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final a = VertAssessment(
      heightInches: profile.heightInches,
      ageYears: profile.ageYears,
      hops: profile.hopsLevel,
      measuredStandingReach: profile.standingReachInches,
      dunkHand: profile.dunkHand,
    );
    final programWeeks = ProgramCatalog.recommend(profile).weeks;
    // Four bars: three early checkpoints and the program's final week, so the
    // last bar is the same figure as the headline below it.
    final weeks = [1, 3, 5, programWeeks];
    final values = [for (final w in weeks) a.projectedVertAtWeek(w)];
    final maxV = values.last + 1;
    final minV = a.estimatedCurrentVert - 2;

    final density = LayoutDensity.of(context);
    return SellScaffold(
      onBack: onBack,
      ctaLabel: l10n.potentialCta,
      onContinue: onContinue,
      children: [
        OnboardingHeadline(text: l10n.potentialTitle),
        SizedBox(height: density.pick(8, 6)),
        Text(
          l10n.potentialSubtitle,
          style: density.pick(
            DunkTheme.onboardingSubtitle,
            DunkTheme.onboardingSubtitleCompact,
          ),
        ),
        SizedBox(height: density.pick(16, 12)),
        Container(
          height: density.pick(210, 176),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DunkColors.stroke),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < weeks.length; i++)
                Expanded(
                  child: _Bar(
                    value: values[i],
                    minV: minV,
                    maxV: maxV,
                    weekLabel: l10n.potentialWeekLabel(weeks[i]),
                    highlight: i == weeks.length - 1,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: density.pick(14, 10)),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: DunkColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.potentialWindowLabel(programWeeks),
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(l10n.lengthApprox(units.name, units.lengthValue(values.last)),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.1,
                      fontWeight: FontWeight.w900)),
              Text(
                  l10n.potentialFromToday(
                      units.name, units.lengthValue(a.estimatedCurrentVert)),
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final int value;
  final int minV;
  final int maxV;
  final String weekLabel;
  final bool highlight;

  const _Bar({
    required this.value,
    required this.minV,
    required this.maxV,
    required this.weekLabel,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final frac = ((value - minV) / (maxV - minV)).clamp(0.05, 1.0);
    final units = UnitScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
              AppLocalizations.of(context)
                  .length(units.name, units.lengthValue(value)),
              style: TextStyle(
                  color: highlight ? DunkColors.primary : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 6),
          // The bar fills whatever height the chart card leaves it, so the
          // card's height — not the bar's — is what the screen budgets.
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: frac,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: highlight
                        ? DunkColors.primaryGradient
                        : const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF3A3A40), Color(0xFF26262A)]),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(weekLabel,
              style: const TextStyle(color: DunkColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
