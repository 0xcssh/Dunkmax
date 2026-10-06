import 'package:flutter/material.dart';

import '../../shared/layout_density.dart';
import '../../shared/widgets/fit_or_scroll.dart';
import '../../shared/widgets/selectable_card.dart';
import 'onboarding_scaffold.dart';
import 'staggered_entrance.dart';

/// The body of a card-list quiz step: the option cards stacked over the
/// height between the subtitle and the CTA, each arriving in the step's
/// stagger.
///
/// The cards **share that height** rather than sitting at their natural size
/// at the top: on a tall phone each card grows (up to [maxCardHeight]) and
/// the gaps open a little, so a three-option step fills the screen as fully
/// as a five-option one. On a short phone the share drops below a card's
/// natural height and the cards simply keep that natural height; if even
/// that does not fit, the list scrolls instead of clipping (see
/// [FitOrScrollColumn]).
///
/// The share reaches each card through [OptionCardHeight], which
/// `SelectableCard` (as a minimum height) and the icon tiles (as a size)
/// read — so no screen has to pass it along.
class OptionList extends StatelessWidget {
  final List<Widget> cards;

  const OptionList({super.key, required this.cards});

  /// A card never grows past this: beyond it a card stops reading as an
  /// option row and starts reading as an empty panel.
  static const double maxCardHeight = 136;

  /// How far the gaps may open once the cards are at [maxCardHeight].
  static const double _maxExtraGap = 24;

  @override
  Widget build(BuildContext context) {
    final density = LayoutDensity.of(context);
    final baseGap = density.pick(12.0, 8.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = cards.length;
        var cardHeight = 0.0;
        var gap = baseGap;
        // Only a regular-height phone grows the cards: on a compact one the
        // share is close to a card's natural height, and a card whose
        // French subtitle wraps would push the list into a scroll.
        if (!density.isCompact && constraints.hasBoundedHeight && n > 0) {
          final share = (constraints.maxHeight - (n - 1) * baseGap) / n;
          // A few pixels per card stay in hand, so one card whose text wraps
          // past the share does not push the list into a scroll.
          cardHeight = (share - 4).clamp(0.0, maxCardHeight);
          if (n > 1) {
            final spare =
                constraints.maxHeight - n * cardHeight - (n - 1) * baseGap;
            gap += (spare / (n - 1)).clamp(0.0, _maxExtraGap);
          }
        }
        return OptionCardHeight(
          height: cardHeight,
          child: FitOrScrollColumn(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) SizedBox(height: gap),
                StaggerItem(
                  index: OnboardingScaffold.bodyStaggerIndex + i,
                  child: cards[i],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
