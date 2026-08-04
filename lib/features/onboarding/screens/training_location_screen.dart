import 'package:flutter/material.dart';

import '../../../core/models/training_location.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';

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
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: 'WHERE WILL YOU\nBE TRAINING?',
      subtitle: "We'll recommend programs that fit your setup.",
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: TrainingLocation.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final loc = TrainingLocation.values[i];
          final (icon, tint) = _icons[loc]!;
          return SelectableCard(
            leading: IconTile(icon: icon, tint: tint),
            title: loc.title,
            subtitle: loc.subtitle,
            selected: selected == loc,
            onTap: () => onSelect(loc),
          );
        },
      ),
    );
  }
}
