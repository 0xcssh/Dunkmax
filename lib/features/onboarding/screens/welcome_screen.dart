import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// The opening hook screen. Sells the promise, then hands off to the quiz.
class WelcomeScreen extends StatelessWidget {
  final VoidCallback onStart;

  const WelcomeScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.1,
            colors: [Color(0xFF241109), DunkColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                const _HeroEmblem(),
                const Spacer(flex: 2),
                const Text(
                  'TRAIN WITH A\nREAL PLAN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'A week-by-week jump program built around your\ngoals, your level and your schedule.',
                  textAlign: TextAlign.center,
                  style: DunkTheme.onboardingSubtitle,
                ),
                const Spacer(flex: 3),
                PrimaryButton(label: "LET'S START", onPressed: onStart),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroEmblem extends StatelessWidget {
  const _HeroEmblem();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: DunkColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: DunkColors.primary.withValues(alpha: 0.5),
              blurRadius: 60,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.sports_basketball, size: 84, color: Colors.white),
      ),
    );
  }
}
