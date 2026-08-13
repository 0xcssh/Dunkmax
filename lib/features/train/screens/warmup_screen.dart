import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// First step of [SessionFlow]: shows the day's focus + warm-up prescription
/// before diving into per-exercise logging.
class WarmupScreen extends StatelessWidget {
  final String focus;
  final String warmUp;

  /// "WEEK 2 · DAY 2 OF 3" — where this session sits in the program.
  final String weekLabel;

  /// True on a deload week, so the athlete knows the lighter prescription
  /// below is deliberate.
  final bool isDeload;

  final VoidCallback onStart;
  final VoidCallback onCancel;

  const WarmupScreen({
    super.key,
    required this.focus,
    required this.warmUp,
    required this.weekLabel,
    required this.isDeload,
    required this.onStart,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  l10n.warmUpHeader,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Text(
                    weekLabel,
                    style: const TextStyle(
                      color: DunkColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // The focus name comes from the untranslated program catalog.
                  Text(l10n.warmUpFocusDay(focus.toUpperCase()),
                      style: DunkTheme.onboardingTitle),
                  if (isDeload) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: DunkColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DunkColors.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_down,
                              size: 15, color: DunkColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.warmUpDeloadNote,
                              style: const TextStyle(
                                color: DunkColors.primary,
                                fontSize: 12,
                                height: 1.3,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DunkColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DunkColors.stroke),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: DunkColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.self_improvement,
                              color: DunkColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.warmUpCardLabel,
                                style: const TextStyle(
                                  color: DunkColors.textTertiary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                warmUp,
                                style: const TextStyle(
                                  color: DunkColors.textSecondary,
                                  fontSize: 15,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: l10n.warmUpCta, onPressed: onStart),
          ],
        ),
      ),
    );
  }
}
