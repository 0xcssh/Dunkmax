import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// First step of [SessionFlow]: shows the day's focus + warm-up prescription
/// before diving into per-exercise logging.
class WarmupScreen extends StatelessWidget {
  final String focus;
  final String warmUp;
  final VoidCallback onStart;
  final VoidCallback onCancel;

  const WarmupScreen({
    super.key,
    required this.focus,
    required this.warmUp,
    required this.onStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                const Text(
                  'WARM UP',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text(
                    focus.toUpperCase(),
                    style: const TextStyle(
                      color: DunkColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${focus.toUpperCase()} DAY', style: DunkTheme.onboardingTitle),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DunkColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DunkColors.stroke),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: DunkColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.self_improvement,
                              color: DunkColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WARM-UP',
                                style: TextStyle(
                                  color: DunkColors.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                warmUp,
                                style: const TextStyle(
                                  color: DunkColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'START EXERCISES', onPressed: onStart),
          ],
        ),
      ),
    );
  }
}
