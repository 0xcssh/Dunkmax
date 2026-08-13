import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/vert_assessment.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// "Your jump potential" — projected vert curve over the first 8-week block.
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
    final a = VertAssessment(
      heightInches: profile.heightInches,
      ageYears: profile.ageYears,
      hops: profile.hopsLevel,
      measuredStandingReach: profile.standingReachInches,
      dunkHand: profile.dunkHand,
    );
    const weeks = [1, 3, 5, 8];
    final values = [for (final w in weeks) a.projectedVertAtWeek(w)];
    final maxV = values.last + 1;
    final minV = a.estimatedCurrentVert - 2;

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
                    Text(l10n.potentialTitle,
                        style: DunkTheme.onboardingTitle),
                    const SizedBox(height: 12),
                    Text(l10n.potentialSubtitle,
                        style: DunkTheme.onboardingSubtitle),
                    const SizedBox(height: 24),
                    Container(
                      height: 230,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: DunkColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.potentialWindowLabel,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Text(l10n.inchesApprox(a.projectedVert8Week),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900)),
                          Text(l10n.potentialFromToday(a.estimatedCurrentVert),
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: l10n.potentialCta, onPressed: onContinue),
            ],
          ),
        ),
      ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(AppLocalizations.of(context).inches(value),
              style: TextStyle(
                  color: highlight ? DunkColors.primary : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          const SizedBox(height: 6),
          FractionallySizedBox(
            widthFactor: 1,
            child: Container(
              height: 120 * frac,
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
          const SizedBox(height: 8),
          Text(weekLabel,
              style: const TextStyle(color: DunkColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
