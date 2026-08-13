import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';

class DaysPerWeekScreen extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const DaysPerWeekScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  // Value paired with the label shown ("5+" maps to 5).
  static const _options = [(2, '2'), (3, '3'), (4, '4'), (5, '5+')];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.daysTitle,
      subtitle: l10n.daysSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MotivationBanner(),
          const SizedBox(height: 24),
          Row(
            children: [
              for (final (value, label) in _options) ...[
                Expanded(
                  child: _DayChip(
                    label: label,
                    selected: selected == value,
                    onTap: () => onSelect(value),
                  ),
                ),
                if (value != 5) const SizedBox(width: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MotivationBanner extends StatelessWidget {
  const _MotivationBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DunkColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
              Icons.local_fire_department, color: DunkColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            // "Athletes who train 4+ days see results 2x faster" used to sit
            // here. There is no study behind that number and no user base to
            // draw it from — it was invented to make a nudge sound
            // authoritative, which is the same rule the fake ratings and
            // testimonials were removed under. What replaces it is true of
            // any training programme and claims no measurement.
            child: Text(
              AppLocalizations.of(context).daysBanner,
              style: const TextStyle(
                color: DunkColors.primaryBright,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 0.82,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: DunkColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? DunkColors.primary : DunkColors.stroke,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: selected ? DunkColors.primary : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).daysChipUnit,
                  style: const TextStyle(
                      color: DunkColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 6),
                if (selected)
                  const Icon(Icons.check_circle, color: DunkColors.primary, size: 22)
                else
                  const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
