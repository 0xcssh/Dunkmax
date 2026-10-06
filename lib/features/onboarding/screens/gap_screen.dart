import 'package:flutter/material.dart';

import '../../../core/models/dunk_goal.dart';
import '../../../core/models/onboarding_profile.dart';
import '../../../core/vert_assessment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/layout_density.dart';
import '../../shared/unit_scope.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/sell_scaffold.dart';

/// "Here's the gap" — turns the vitals into the inches-to-dunk story.
class GapScreen extends StatelessWidget {
  final OnboardingProfile profile;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const GapScreen({
    super.key,
    required this.profile,
    required this.onContinue,
    required this.onBack,
  });

  VertAssessment get _a => VertAssessment(
        heightInches: profile.heightInches,
        ageYears: profile.ageYears,
        hops: profile.hopsLevel,
        measuredStandingReach: profile.standingReachInches,
        dunkHand: profile.dunkHand,
      );

  String _heightLabel(AppLocalizations l10n, UnitSystem units) {
    final h = units.height(profile.heightInches);
    return l10n.heightValueCompact(units.name, h.feet, h.inches, h.cm);
  }

  /// Every goal the athlete picked, in the catalogue's order. The quiz is a
  /// multi-select, so showing only the first tap as a "primary goal" invented
  /// a ranking the athlete never made. Titles are translated via the enum
  /// name (the core getters are English-only).
  String _goals(AppLocalizations l10n) {
    if (profile.goals.isEmpty) return l10n.gapDefaultGoal;
    final picked = [
      for (final goal in DunkGoal.values)
        if (profile.goals.contains(goal)) l10n.dunkGoalTitle(goal.name),
    ];
    return picked.join(l10n.gapGoalsSeparator);
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final unit = units.name;
    final heightLabel = _heightLabel(l10n, units);
    final density = LayoutDensity.of(context);
    return SellScaffold(
      onBack: onBack,
      ctaLabel: a.canAlreadyDunk ? l10n.gapCtaCanDunk : l10n.gapCta,
      onContinue: onContinue,
      children: [
        Text(a.reachIsMeasured ? l10n.gapBasedOnReach : l10n.gapBasedOnHeight,
            style: const TextStyle(
                color: DunkColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 13)),
        const SizedBox(height: 6),
        // An athlete already estimated to clear the dunk has no gap: the
        // headline, the meter's middle figure and the CTA all say so rather
        // than selling a "-0" shortfall.
        OnboardingHeadline(
          text: a.canAlreadyDunk ? l10n.gapTitleCanDunk : l10n.gapTitle,
        ),
        SizedBox(height: density.pick(8, 6)),
        Text(
          a.canAlreadyDunk
              ? l10n.gapIntroCanDunk(
                  unit,
                  heightLabel,
                  units.lengthValue(a.estimatedCurrentVert),
                  units.lengthValue(a.requiredVert),
                )
              : l10n.gapIntro(
                  unit,
                  heightLabel,
                  units.lengthValue(a.estimatedCurrentVert),
                  units.lengthValue(a.requiredVert),
                ),
          style: density.pick(
            DunkTheme.onboardingSubtitle,
            DunkTheme.onboardingSubtitleCompact,
          ),
        ),
        SizedBox(height: density.pick(16, 12)),
        _GapMeter(assessment: a),
        if (profile.dunkHand?.isTwoHanded ?? false) ...[
          const SizedBox(height: 10),
          const _TwoHandNote(),
        ],
        if (!a.reachIsMeasured) ...[
          const SizedBox(height: 10),
          _EstimatedReachNote(assessment: a),
        ],
        SizedBox(height: density.pick(14, 8)),
        // The summary card takes the height left above the CTA; its rows
        // spread out to fill it.
        Expanded(
          child: _SummaryGrid(rows: [
            (l10n.gapRowHeight, heightLabel),
            (
              l10n.gapRowStandingReach,
              a.reachIsMeasured
                  ? l10n.length(unit, units.lengthValue(a.standingReach))
                  : l10n.gapReachEstimatedSuffix(
                      unit, units.lengthValue(a.standingReach))
            ),
            (
              l10n.gapRowEstToday,
              l10n.length(unit, units.lengthValue(a.estimatedCurrentVert))
            ),
            (
              l10n.gapRowDunkTarget,
              l10n.length(unit, units.lengthValue(a.requiredVert))
            ),
            (
              l10n.gapRowWeight,
              l10n.gapWeightValue(unit, units.weight(profile.weightLbs).value)
            ),
            (l10n.gapRowHops, l10n.hopsLevelTitle(profile.hopsLevel.name)),
            (l10n.gapRowGoals, _goals(l10n)),
            (
              l10n.gapRowTrainingDays,
              l10n.gapTrainingDaysValue(profile.daysPerWeek)
            ),
          ]),
        ),
      ],
    );
  }
}

/// Shown only to an athlete who picked a two-hand finish: their target is
/// several inches higher than a one-hand one, and a number that moves by four
/// inches because of an answer they gave two screens ago has to say why.
class _TwoHandNote extends StatelessWidget {
  const _TwoHandNote();

  @override
  Widget build(BuildContext context) {
    final units = UnitScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.back_hand, color: DunkColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).gapTwoHandNote(
              units.name,
              units.lengthValue(VertAssessment.twoHandExtraClearance),
            ),
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

/// Quiet caveat, shown only while the reach is still an estimate: the dunk
/// target above is height-derived, not measured. Stated plainly rather than
/// dressed up as a warning — the number is a reasonable starting point, it
/// just isn't theirs yet.
class _EstimatedReachNote extends StatelessWidget {
  final VertAssessment assessment;
  const _EstimatedReachNote({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final units = UnitScope.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.straighten, color: DunkColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context).gapEstimatedReachNote(
              units.name,
              units.lengthValue(assessment.standingReach),
            ),
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _GapMeter extends StatelessWidget {
  final VertAssessment assessment;
  const _GapMeter({required this.assessment});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final unit = units.name;
    // The middle figure is the gap — or, once there is none, the length to
    // spare. A margin of exactly zero reads as a plain 0" gap, not "+0".
    final margin = assessment.marginInches;
    final showMargin = assessment.canAlreadyDunk && margin > 0;
    final String middleValue;
    if (showMargin) {
      middleValue = l10n.lengthMargin(unit, units.lengthValue(margin));
    } else if (assessment.canAlreadyDunk) {
      middleValue = l10n.length(unit, 0);
    } else {
      middleValue =
          l10n.lengthGap(unit, units.lengthValue(assessment.gapInches));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Big(
              value: l10n.lengthApprox(
                  unit, units.lengthValue(assessment.estimatedCurrentVert)),
              label: l10n.gapMeterToday,
              color: Colors.white),
          const Icon(Icons.arrow_forward, color: DunkColors.textTertiary),
          _Big(
              value: middleValue,
              label: showMargin ? l10n.gapMeterMargin : l10n.gapMeterGap,
              color: DunkColors.primary),
          const Icon(Icons.arrow_forward, color: DunkColors.textTertiary),
          _Big(
              value: l10n.lengthApprox(
                  unit, units.lengthValue(assessment.requiredVert)),
              label: l10n.gapMeterDunk,
              color: DunkColors.accentGreen),
        ],
      ),
    );
  }
}

class _Big extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _Big({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    // Flexible + scale-down: three of these share one row, and a long caption
    // (the French for "today") or a two-digit figure on a 375pt screen must
    // shrink to fit rather than overflow. At full size nothing changes.
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: DunkColors.textSecondary,
                    letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<(String, String)> rows;
  const _SummaryGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    // A card the page sizes: eight rows of 14 pt text, spread evenly over
    // whatever height it is given, packed at a slim gap when it is given
    // only their natural height.
    final density = LayoutDensity.of(context);
    final rowGap = density.pick(5.0, 3.5);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: density.pick(8.0, 4.0),
      ),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final (k, v) in rows)
            Padding(
              padding: EdgeInsets.symmetric(vertical: rowGap),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(k,
                      style: const TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 14,
                          height: 1.3)),
                  const SizedBox(width: 12),
                  // Flexible so a long value (a hops label, a goal title) wraps
                  // under itself instead of overflowing the row.
                  Flexible(
                    child: Text(v,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.3,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
