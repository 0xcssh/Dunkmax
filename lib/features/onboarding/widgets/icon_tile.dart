import 'package:flutter/material.dart';

/// The small rounded-square icon badge used on onboarding option cards.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color tint;

  const IconTile({super.key, required this.icon, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: tint, size: 24),
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
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: tint,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
