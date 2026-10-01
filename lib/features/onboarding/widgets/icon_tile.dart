import 'package:flutter/material.dart';

import '../../shared/layout_density.dart';

/// Side of the rounded-square badge on an option card. 44 pt keeps a card
/// at ~68 pt, which is what lets five of them share a screen with the
/// headline and the CTA; short phones drop to 40.
double _tileSize(BuildContext context) =>
    LayoutDensity.of(context).pick(44, 40);

/// The small rounded-square icon badge used on onboarding option cards.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const IconTile({super.key, required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    final size = _tileSize(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: tint, size: size * 0.5),
    );
  }
}

/// A numbered badge variant (used on the "what position" screen).
class NumberTile extends StatelessWidget {
  final int number;
  final Color tint;

  const NumberTile({super.key, required this.number, required this.tint});

  @override
  Widget build(BuildContext context) {
    final size = _tileSize(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: tint,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
