import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/models/training_program.dart';
import '../../../theme/app_theme.dart';

/// Landing tab: a quick welcome and a shortcut into today's training.
class HomeTab extends StatelessWidget {
  final OnboardingProfile profile;
  final TrainingProgram program;
  final VoidCallback onStartTraining;

  const HomeTab({
    super.key,
    required this.profile,
    required this.program,
    required this.onStartTraining,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const Text(
            "LET'S GET UP",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You're on the ${program.name}. Time to put in work.",
            style: DunkTheme.onboardingSubtitle,
          ),
          const SizedBox(height: 24),
          _TodayCard(program: program, onStartTraining: onStartTraining),
          const SizedBox(height: 16),
          _FocusCard(profile: profile),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final TrainingProgram program;
  final VoidCallback onStartTraining;

  const _TodayCard({required this.program, required this.onStartTraining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: DunkColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S SESSION",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            program.dayFor(1).exercises.map((e) => e.name).join(' · '),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onStartTraining,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                child: const Text(
                  'START TRAINING',
                  style: TextStyle(
                    color: DunkColors.primaryDeep,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final OnboardingProfile profile;

  const _FocusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final goals = profile.goals.map((g) => g.title).join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR FOCUS',
            style: TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            goals.isEmpty ? 'Max Vertical' : goals,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${profile.position.label} · ${profile.daysPerWeek} days/week',
            style: const TextStyle(color: DunkColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
