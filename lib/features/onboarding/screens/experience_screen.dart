import 'package:flutter/material.dart';

import '../../../core/models/experience_level.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

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
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: ExperienceLevel.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final level = ExperienceLevel.values[i];
          final (icon, tint) = _icons[level]!;
          return StaggerItem(
            index: OnboardingScaffold.bodyStaggerIndex + i,
            child: SelectableCard(
              leading: IconTile(icon: icon, tint: tint),
              title: level.title,
              subtitle: level.subtitle,
              selected: selected == level,
              onTap: () => onSelect(level),
            ),
          );
        },
      ),
    );
  }
}
