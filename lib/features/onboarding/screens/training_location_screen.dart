import 'package:flutter/material.dart';

import '../../../core/models/training_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/option_list.dart';

class TrainingLocationScreen extends StatelessWidget {
  final TrainingLocation? selected;
  final ValueChanged<TrainingLocation> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const TrainingLocationScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  static const _icons = {
    TrainingLocation.home: (Icons.home_rounded, DunkColors.accentGreen),
    TrainingLocation.gym: (Icons.apartment_rounded, DunkColors.primary),
    TrainingLocation.both: (Icons.sync_rounded, DunkColors.primary),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.locationTitle,
      subtitle: l10n.locationSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: OptionList(
        cards: [
          for (final loc in TrainingLocation.values)
            SelectableCard(
              leading: IconTile(icon: _icons[loc]!.$1, tint: _icons[loc]!.$2),
              // Translated here, keyed on the enum name: the core getters
              // are English-only (core/ has no Flutter, so no l10n).
              title: l10n.trainingLocationTitle(loc.name),
              subtitle: l10n.trainingLocationSubtitle(loc.name),
              selected: selected == loc,
              onTap: () => onSelect(loc),
            ),
        ],
      ),
    );
  }
}
