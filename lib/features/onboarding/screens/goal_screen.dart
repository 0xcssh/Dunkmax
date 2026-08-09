import 'package:flutter/material.dart';

import '../../../core/models/dunk_goal.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

class GoalScreen extends StatelessWidget {
  final Set<DunkGoal> selected;
  final ValueChanged<DunkGoal> onToggle;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const GoalScreen({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  static const _icons = {
    DunkGoal.firstDunk: (Icons.track_changes, DunkColors.primary),
    DunkGoal.dunkInGames: (Icons.sports_basketball, Color(0xFFC97B34)),
    DunkGoal.windmillsAnd360s: (Icons.air, Color(0xFFE05B5B)),
    DunkGoal.alleyOopFinishing: (Icons.south, DunkColors.accentPurple),
    DunkGoal.maxVertical: (Icons.local_fire_department, DunkColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: "WHAT'S YOUR\nDUNK GOAL?",
      subtitle: "Select every goal that fires you up — we'll build the path.",
      onBack: onBack,
      onContinue: selected.isEmpty ? null : onContinue,
      // The cards arrive one after another instead of as a single block.
      staggerBody: false,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: DunkGoal.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final goal = DunkGoal.values[i];
          final (icon, tint) = _icons[goal]!;
          return StaggerItem(
            index: OnboardingScaffold.bodyStaggerIndex + i,
            child: SelectableCard(
              leading: IconTile(icon: icon, tint: tint),
              title: goal.title,
              subtitle: goal.subtitle,
              selected: selected.contains(goal),
              onTap: () => onToggle(goal),
            ),
          );
        },
      ),
    );
  }
}
