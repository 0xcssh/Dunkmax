import 'package:flutter/material.dart';

import '../../../core/models/onboarding_profile.dart';
import '../../../core/vert_assessment.dart';
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
      );

  String get _heightLabel =>
      "${profile.heightInches ~/ 12}'${profile.heightInches % 12}\"";

  String get _primaryGoal =>
      profile.goals.isEmpty ? 'Your First Dunk' : profile.goals.first.title;

  @override
  Widget build(BuildContext context) {
    final a = _a;
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
                    const Text('BASED ON YOUR HEIGHT + HOPS',
                        style: TextStyle(
                            color: DunkColors.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                            fontSize: 13)),
                    const SizedBox(height: 8),
                    const Text("HERE'S THE GAP.", style: DunkTheme.onboardingTitle),
                    const SizedBox(height: 12),
                    Text(
                      "You're $_heightLabel. About ${a.estimatedCurrentVert}\" today. "
                      "Dunking usually takes ~${a.requiredVert}\".",
                      style: DunkTheme.onboardingSubtitle,
                    ),
                    const SizedBox(height: 24),
                    _GapMeter(assessment: a),
                    const SizedBox(height: 20),
                    _SummaryGrid(rows: [
                      ('Height', _heightLabel),
                      ('Est. today', '${a.estimatedCurrentVert}"'),
                      ('Dunk target', '${a.requiredVert}"'),
                      ('Weight', '${profile.weightLbs} lbs'),
                      ('Hops', profile.hopsLevel.title),
                      ('Primary goal', _primaryGoal),
                      ('Training days', '${profile.daysPerWeek}/week'),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'CLOSE THE GAP', onPressed: onContinue),
            ],
          ),
        ),
      ),
    );
  }
}

class _GapMeter extends StatelessWidget {
  final VertAssessment assessment;
  const _GapMeter({required this.assessment});

  @override
  Widget build(BuildContext context) {
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
          _Big(value: '~${assessment.estimatedCurrentVert}"', label: 'TODAY', color: Colors.white),
          const Icon(Icons.arrow_forward, color: DunkColors.textTertiary),
          _Big(value: '-${assessment.gapInches}"', label: 'EST. GAP', color: DunkColors.primary),
          const Icon(Icons.arrow_forward, color: DunkColors.textTertiary),
          _Big(value: '~${assessment.requiredVert}"', label: 'DUNK', color: DunkColors.accentGreen),
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
