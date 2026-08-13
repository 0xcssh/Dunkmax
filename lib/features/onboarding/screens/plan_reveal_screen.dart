import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/program_catalog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// "Here's your plan" — reveals the recommended program + this week's layout,
/// right before the paywall gate.
class PlanRevealScreen extends StatelessWidget {
  final OnboardingProfile profile;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const PlanRevealScreen({
    super.key,
    required this.profile,
    required this.onContinue,
    required this.onBack,
  });

  // A simple representative week derived from the training frequency.
  List<(String, bool)> _week(AppLocalizations l10n) {
    final labels = [
      l10n.planDayFoundation,
      l10n.planDayBasic,
      l10n.planDayCore,
      l10n.planDayPower,
      l10n.planDayReactive,
    ];
    final days = <(String, bool)>[];
    var trained = 0;
    for (var d = 0; d < 7 && days.length < 7; d++) {
      final trainToday = trained < profile.daysPerWeek &&
          (d % 2 == 0 || (7 - d) <= (profile.daysPerWeek - trained));
      if (trainToday && trained < labels.length) {
        days.add((labels[trained], true));
        trained++;
      } else {
        days.add((l10n.planDayRest, false));
      }
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final program = ProgramCatalog.recommend(profile);
    final week = _week(l10n);

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
                    Text(l10n.planRevealTitle,
                        style: DunkTheme.onboardingTitle),
                    const SizedBox(height: 10),
                    // Goals are collected but never reach the programming —
                    // only experience, training days and location do. Naming
                    // them here would be a claim the catalog does not honour.
                    Text(
                      l10n.planRevealSubtitle,
                      style: DunkTheme.onboardingSubtitle,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: DunkColors.primaryGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(program.name.toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _Badge(l10n.planBadgeDays(profile.daysPerWeek)),
                              const SizedBox(width: 8),
                              // Location titles live in the untranslated
                              // core/models/training_location.dart.
                              _Badge(profile.trainingLocation.title.toUpperCase()),
                              const SizedBox(width: 8),
                              _Badge(l10n.planBadgeWeeks(program.weeks)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.planThisWeek,
                        style: const TextStyle(
                            color: DunkColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 12)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < week.length; i++) ...[
                      _DayRow(day: i + 1, label: week[i].$1, training: week[i].$2),
                      if (i < week.length - 1)
                        const Divider(color: DunkColors.stroke, height: 14),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: l10n.commonContinue, onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

class _DayRow extends StatelessWidget {
  final int day;
  final String label;
  final bool training;
  const _DayRow({required this.day, required this.label, required this.training});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(AppLocalizations.of(context).planDayLabel(day),
              style: const TextStyle(
                  color: DunkColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Icon(training ? Icons.bolt : Icons.bedtime_outlined,
            size: 18, color: training ? DunkColors.primary : DunkColors.textTertiary),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: training ? Colors.white : DunkColors.textSecondary,
                fontSize: 15,
                fontWeight: training ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}
