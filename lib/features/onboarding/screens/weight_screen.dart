import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/unit_scope.dart';
import '../widgets/onboarding_scaffold.dart';

/// Weight picker: a slider in pounds (75–300) in imperial regions, in
/// kilograms (35–150) in metric ones. The value reported upward is always
/// pounds, the unit the profile stores.
class WeightScreen extends StatelessWidget {
  final int weightLbs;
  final ValueChanged<int> onChanged;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const WeightScreen({
    super.key,
    required this.weightLbs,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    final min = units.isMetric
        ? UnitInputRanges.minWeightKg
        : UnitInputRanges.minWeightLbs;
    final max = units.isMetric
        ? UnitInputRanges.maxWeightKg
        : UnitInputRanges.maxWeightLbs;
    final shown = units.weight(weightLbs).value.clamp(min, max);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.weightTitle,
      subtitle: l10n.savedToAthleteProfile,
      onBack: onBack,
      onContinue: onContinue,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: DunkColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DunkColors.primary.withValues(alpha: 0.7)),
              ),
              child: Column(
                children: [
                  Text('$shown',
                      style: const TextStyle(
                          fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(l10n.weightUnitLabel(units.name),
                      style: const TextStyle(
                          color: DunkColors.textSecondary, letterSpacing: 2, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: DunkColors.primary,
                inactiveTrackColor: DunkColors.stroke,
                thumbColor: Colors.white,
                overlayColor: DunkColors.primary.withValues(alpha: 0.2),
                trackHeight: 6,
              ),
              child: Slider(
                min: min.toDouble(),
                max: max.toDouble(),
                value: shown.toDouble(),
                // Stored in pounds whatever the slider shows.
                onChanged: (v) => onChanged(units.lbsFromWeight(v.round())),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$min',
                    style: const TextStyle(
                        color: DunkColors.textTertiary, fontSize: 13)),
                Text('$max',
                    style: const TextStyle(
                        color: DunkColors.textTertiary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
