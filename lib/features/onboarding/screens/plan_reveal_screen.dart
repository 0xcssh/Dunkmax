import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/program_catalog.dart';
import '../../../core/training_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/layout_density.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/sell_scaffold.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final program = ProgramCatalog.recommend(profile);
    // Week 1 exactly as the Train tab will lay it out: the program's own day
    // focuses (Power / Strength / Speed …) on the weekdays TrainingSchedule
    // places them (3/wk = Mon/Wed/Fri). This used to be a hand-rolled
    // FOUNDATION/BASIC/CORE strip on an every-other-day pattern, which
    // promised days the program does not contain on days it does not use.
    final week = TrainingSchedule(program).weekAt(1).days;

    final density = LayoutDensity.of(context);
    return SellScaffold(
      onBack: onBack,
      ctaLabel: l10n.commonContinue,
      onContinue: onContinue,
      children: [
        OnboardingHeadline(text: l10n.planRevealTitle),
        SizedBox(height: density.pick(8, 6)),
        // Goals are collected but never reach the programming — only
        // experience, training days and location do. Naming them here would
        // be a claim the catalog does not honour.
        Text(
          l10n.planRevealSubtitle,
          style: density.pick(
            DunkTheme.onboardingSubtitle,
            DunkTheme.onboardingSubtitleCompact,
          ),
        ),
        SizedBox(height: density.pick(16, 12)),
        Container(
          padding: const EdgeInsets.all(16),
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
              const SizedBox(height: 8),
              // Scaled down as one unit only when the three badges are wider
              // than the card (longer French labels on a narrow phone);
              // untouched otherwise.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Badge(l10n.planBadgeDays(profile.daysPerWeek)),
                    const SizedBox(width: 8),
                    _Badge(l10n
                        .trainingLocationTitle(profile.trainingLocation.name)
                        .toUpperCase()),
                    const SizedBox(width: 8),
                    _Badge(l10n.planBadgeWeeks(program.weeks)),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: density.pick(16, 12)),
        Text(l10n.planThisWeek,
            style: const TextStyle(
                color: DunkColors.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 12)),
        const SizedBox(height: 8),
        for (var i = 0; i < week.length; i++) ...[
          _DayRow(day: week[i]),
          if (i < week.length - 1)
            Divider(color: DunkColors.stroke, height: density.pick(10, 8)),
        ],
      ],
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
  final ScheduledDay day;
  const _DayRow({required this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final training = day.isTraining;
    // Same seven labels the Train tab's strip uses (the core
    // `ScheduledDay.weekdayLabel` is English-only).
    final weekdays = l10n.weekdayLabels.split(',');
    final weekday = weekdays[(day.weekday - 1).clamp(0, weekdays.length - 1)];
    final label = training
        ? l10n.programDayFocus(day.day!.focus)
        : l10n.planDayRest;
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(weekday,
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
