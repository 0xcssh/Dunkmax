import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/vert_assessment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

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

  String _heightLabel(AppLocalizations l10n) => l10n.heightValueCompact(
        profile.heightInches ~/ 12,
        profile.heightInches % 12,
      );

  /// The goal titles themselves come from `core/models/dunk_goal.dart`, which
  /// is pure Dart and stays untranslated for now — only the "no goal picked"
  /// fallback is localised here.
  String _primaryGoal(AppLocalizations l10n) =>
      profile.goals.isEmpty ? l10n.gapDefaultGoal : profile.goals.first.title;

  @override
  Widget build(BuildContext context) {
    final a = _a;
    final l10n = AppLocalizations.of(context);
    final heightLabel = _heightLabel(l10n);
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
                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Text(
                        a.reachIsMeasured
                            ? l10n.gapBasedOnReach
                            : l10n.gapBasedOnHeight,
                        style: const TextStyle(
                            color: DunkColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(l10n.gapTitle, style: DunkTheme.onboardingTitle),
                    const SizedBox(height: 12),
                    Text(
                      l10n.gapIntro(
                        heightLabel,
                        a.estimatedCurrentVert,
                        a.requiredVert,
                      ),
                      style: DunkTheme.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    _GapMeter(assessment: a),
                    if (profile.dunkHand?.isTwoHanded ?? false) ...[
                      const SizedBox(height: 12),
                      const _TwoHandNote(),
                    ],
                    if (!a.reachIsMeasured) ...[
                      const SizedBox(height: 12),
                      _EstimatedReachNote(assessment: a),
                    ],
                    const SizedBox(height: 20),
                    _SummaryGrid(rows: [
                      (l10n.gapRowHeight, heightLabel),
                      (
                        l10n.gapRowStandingReach,
                        a.reachIsMeasured
                            ? l10n.inches(a.standingReach)
                            : l10n.gapReachEstimatedSuffix(a.standingReach)
                      ),
                      (l10n.gapRowEstToday, l10n.inches(a.estimatedCurrentVert)),
                      (l10n.gapRowDunkTarget, l10n.inches(a.requiredVert)),
                      (l10n.gapRowWeight, l10n.gapWeightValue(profile.weightLbs)),
                      // The hops labels come from core/models/hops_level.dart,
                      // which is pure Dart and stays English for now.
                      (l10n.gapRowHops, profile.hopsLevel.title),
                      (l10n.gapRowPrimaryGoal, _primaryGoal(l10n)),
                      (
                        l10n.gapRowTrainingDays,
                        l10n.gapTrainingDaysValue(profile.daysPerWeek)
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: l10n.gapCta, onPressed: onContinue),
            ],
          ),
        ),
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.back_hand, color: DunkColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)
                .gapTwoHandNote(VertAssessment.twoHandExtraClearance),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.straighten, color: DunkColors.textTertiary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            AppLocalizations.of(context)
                .gapEstimatedReachNote(assessment.standingReach),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Big(
              value: l10n.inchesApprox(assessment.estimatedCurrentVert),
              label: l10n.gapMeterToday,
              color: Colors.white),
          const Icon(Icons.arrow_forward, color: DunkColors.textTertiary),
          _Big(
              value: l10n.inchesGap(assessment.gapInches),
              label: l10n.gapMeterGap,
              color: DunkColors.primary),
          const Icon(Icons.arrow_forward, color: DunkColors.textTertiary),
          _Big(
              value: l10n.inchesApprox(assessment.requiredVert),
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
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: DunkColors.textSecondary, letterSpacing: 0.5)),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final List<(String, String)> rows;
  const _SummaryGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (k, v) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(k, style: const TextStyle(color: DunkColors.textSecondary, fontSize: 15)),
                Text(v,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}
