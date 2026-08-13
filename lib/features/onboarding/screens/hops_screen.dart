import 'package:flutter/material.dart';

import '../../../core/models/hops_level.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/staggered_entrance.dart';

class HopsScreen extends StatelessWidget {
  final HopsLevel? selected;
  final ValueChanged<HopsLevel> onSelect;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const HopsScreen({
    super.key,
    required this.selected,
    required this.onSelect,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  static const _icons = {
    HopsLevel.dunkConsistently: (Icons.emoji_events, DunkColors.primary),
    HopsLevel.dunkOnGoodDay: (Icons.local_fire_department, Color(0xFFC97B34)),
    HopsLevel.grabRim: (Icons.back_hand, Color(0xFFE05B5B)),
    HopsLevel.touchRim: (Icons.vertical_align_top, DunkColors.accentPurple),
    HopsLevel.belowRim: (Icons.arrow_circle_up, DunkColors.accentGreen),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: step,
      totalSteps: totalSteps,
      title: l10n.hopsTitle,
      subtitle: l10n.hopsSubtitle,
      onBack: onBack,
      onContinue: selected == null ? null : onContinue,
      staggerBody: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The vertical "ladder" rail from the reference screen.
          StaggerItem(
            index: OnboardingScaffold.bodyStaggerIndex,
            child: Container(
              width: 3,
              margin: const EdgeInsets.only(right: 14, top: 6, bottom: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DunkColors.stroke,
                    DunkColors.primary,
                    DunkColors.stroke,
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: HopsLevel.values.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final level = HopsLevel.values[i];
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
          ),
        ],
      ),
    );
  }
}
