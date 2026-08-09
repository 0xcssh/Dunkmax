import 'package:flutter/material.dart';

import '../../../core/models/court_position.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

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
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: 'WHAT POSITION DO\nYOU PLAY?',
      subtitle: "We'll tailor exercises to your position.",
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: CourtPosition.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final position = CourtPosition.values[i];
          return StaggerItem(
            index: OnboardingScaffold.bodyStaggerIndex + i,
            child: SelectableCard(
              leading:
                  NumberTile(number: position.number, tint: DunkColors.primary),
              title: position.label,
              selected: selected == position,
              onTap: () => onSelect(position),
            ),
          );
        },
      ),
    );
  }
}
