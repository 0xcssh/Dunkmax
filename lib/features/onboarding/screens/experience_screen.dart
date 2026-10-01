import 'package:flutter/material.dart';

import '../../../core/models/experience_level.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/option_list.dart';

class ExperienceScreen extends StatelessWidget {
  final ExperienceLevel? selected;
  final ValueChanged<ExperienceLevel> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const ExperienceScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  static const _icons = {
    ExperienceLevel.beginner: (Icons.star, DunkColors.primary),
    ExperienceLevel.intermediate: (Icons.fitness_center, DunkColors.primary),
    ExperienceLevel.advanced: (Icons.psychology, DunkColors.accentGreen),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.experienceTitle,
      subtitle: l10n.experienceSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: OptionList(
        cards: [
          for (final level in ExperienceLevel.values)
            SelectableCard(
              leading: IconTile(
                icon: _icons[level]!.$1,
                tint: _icons[level]!.$2,
              ),
              // Translated here, keyed on the enum name: the core getters
              // are English-only (core/ has no Flutter, so no l10n).
              title: l10n.experienceLevelTitle(level.name),
              subtitle: l10n.experienceLevelSubtitle(level.name),
              selected: selected == level,
              onTap: () => onSelect(level),
            ),
        ],
      ),
    );
  }
}
