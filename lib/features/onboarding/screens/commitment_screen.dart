import 'package:flutter/material.dart';

import '../../../core/models/commitment_level.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

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
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: CommitmentLevel.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final level = CommitmentLevel.values[i];
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
