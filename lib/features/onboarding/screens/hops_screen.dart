import 'package:flutter/material.dart';

import '../../../core/models/hops_level.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/selectable_card.dart';
import '../widgets/icon_tile.dart';
import '../widgets/onboarding_scaffold.dart';
import '../widgets/option_list.dart';
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
              margin: const EdgeInsets.only(right: 12, top: 6, bottom: 6),
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
            child: OptionList(
              cards: [
                for (final level in HopsLevel.values)
                  SelectableCard(
                    leading: IconTile(
                      icon: _icons[level]!.$1,
                      tint: _icons[level]!.$2,
                    ),
                    // Translated here, keyed on the enum name: the core
                    // getters are English-only (core/ has no Flutter).
                    title: l10n.hopsLevelTitle(level.name),
                    subtitle: l10n.hopsLevelSubtitle(level.name),
                    selected: selected == level,
                    onTap: () => onSelect(level),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
