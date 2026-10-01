import 'package:flutter/material.dart';

import '../../../core/models/court_position.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/option_list.dart';

class PositionScreen extends StatelessWidget {
  final CourtPosition? selected;
  final ValueChanged<CourtPosition> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const PositionScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.positionTitle,
      // Position is stored and shown back, but nothing in the program catalog
      // reads it — so no "we'll tailor exercises to your position" here.
      subtitle: l10n.savedToAthleteProfile,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: OptionList(
        cards: [
          for (final position in CourtPosition.values)
            SelectableCard(
              leading:
                  NumberTile(number: position.number, tint: DunkColors.primary),
              // Translated here, keyed on the enum name (core is English-only).
              title: l10n.courtPositionLabel(position.name),
              selected: selected == position,
              onTap: () => onSelect(position),
            ),
        ],
      ),
    );
  }
}
