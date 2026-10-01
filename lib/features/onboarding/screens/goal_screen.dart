import 'package:flutter/material.dart';

import '../../../core/models/dunk_goal.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/option_list.dart';

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
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.goalTitle,
      subtitle: l10n.goalSubtitle,
      onBack: onBack,
      onContinue: selected.isEmpty ? null : onContinue,
      // The cards arrive one after another instead of as a single block.
      staggerBody: false,
      child: OptionList(
        cards: [
          for (final goal in DunkGoal.values)
            SelectableCard(
              leading: IconTile(
                icon: _icons[goal]!.$1,
                tint: _icons[goal]!.$2,
              ),
              // Translated here, keyed on the enum name: the core getters
              // are English-only (core/ has no Flutter, so no l10n).
              title: l10n.dunkGoalTitle(goal.name),
              subtitle: l10n.dunkGoalSubtitle(goal.name),
              selected: selected.contains(goal),
              onTap: () => onToggle(goal),
            ),
        ],
      ),
    );
  }
}
