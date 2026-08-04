import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// A tappable option row (onboarding lists). Shows a leading icon tile, a
/// title + optional subtitle, and a trailing check when [selected].
class SelectableCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const SelectableCard({
    super.key,
    required this.leading,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? DunkColors.primary : DunkColors.stroke,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: DunkTheme.cardTitle),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: DunkTheme.cardSubtitle),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Check(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool selected;
  const _Check({required this.selected});

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return const SizedBox(width: 26, height: 26);
    }
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: DunkColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, size: 17, color: Colors.black),
    );
  }
}
