import 'package:flutter/material.dart';

import '../../../core/models/commitment_level.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/option_list.dart';

class CommitmentScreen extends StatelessWidget {
  final CommitmentLevel? selected;
  final ValueChanged<CommitmentLevel> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const CommitmentScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  static const _icons = {
    CommitmentLevel.extremely: (Icons.local_fire_department, DunkColors.primary),
    CommitmentLevel.very: (Icons.bolt, DunkColors.primary),
    CommitmentLevel.needHelp: (Icons.favorite, Color(0xFFE05B5B)),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.commitmentTitle,
      subtitle: l10n.commitmentSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: OptionList(
        cards: [
          for (final level in CommitmentLevel.values)
            SelectableCard(
              leading: IconTile(
                icon: _icons[level]!.$1,
                tint: _icons[level]!.$2,
              ),
              // Translated here, keyed on the enum name: the core getters
              // are English-only (core/ has no Flutter, so no l10n).
              title: l10n.commitmentLevelTitle(level.name),
              subtitle: l10n.commitmentLevelSubtitle(level.name),
              selected: selected == level,
              onTap: () => onSelect(level),
            ),
        ],
      ),
    );
  }
}
