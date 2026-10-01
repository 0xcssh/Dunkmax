import 'package:flutter/material.dart';

import '../../shared/layout_density.dart';
import '../../shared/widgets/fit_or_scroll.dart';
import 'onboarding_scaffold.dart';
import 'staggered_entrance.dart';

/// The body of a card-list quiz step: the option cards stacked with a
/// density-aware gap, each arriving in the step's stagger.
///
/// Laid out as a column rather than a `ListView` so that, on the phones the
/// app targets, the cards take exactly the room between the subtitle and the
/// CTA and nothing scrolls. If a longer locale or a shorter phone pushes them
/// past that room the column scrolls instead of clipping — see
/// [FitOrScrollColumn].
class OptionList extends StatelessWidget {
  final List<Widget> cards;

  const OptionList({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    final gap = LayoutDensity.of(context).pick(10.0, 8.0);
    return FitOrScrollColumn(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) SizedBox(height: gap),
          StaggerItem(
            index: OnboardingScaffold.bodyStaggerIndex + i,
            child: cards[i],
          ),
        ],
      ],
    );
  }
}
