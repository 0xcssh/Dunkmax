import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';

/// Weight picker: a slider in pounds (75–300), matching the reference.
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
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: 'YOUR WEIGHT',
      subtitle: 'Saved to your athlete profile.',
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
                  Text('$weightLbs',
                      style: const TextStyle(
                          fontSize: 54, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  const Text('LBS',
                      style: TextStyle(
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
                min: 75,
                max: 300,
                value: weightLbs.clamp(75, 300).toDouble(),
                onChanged: (v) => onChanged(v.round()),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('75', style: TextStyle(color: DunkColors.textTertiary, fontSize: 13)),
                Text('300', style: TextStyle(color: DunkColors.textTertiary, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
