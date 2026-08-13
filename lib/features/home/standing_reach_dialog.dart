import 'package:flutter/material.dart';

import '../../core/standing_reach.dart';
import '../../core/vert_assessment.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Lets the athlete set or correct their standing reach after onboarding.
///
/// Returns the chosen reach in inches, or null if they backed out. The wheel
/// opens on their current measurement, or on the height-based estimate when
/// they never gave one — the same starting point the onboarding question uses.
Future<int?> showStandingReachDialog(
  BuildContext context, {
  required int heightInches,
  required int? currentReachInches,
}) {
  return showDialog<int>(
    context: context,
    builder: (_) => _StandingReachDialog(
      heightInches: heightInches,
      currentReachInches: currentReachInches,
    ),
  );
}

class _StandingReachDialog extends StatefulWidget {
  final int heightInches;
  final int? currentReachInches;

  const _StandingReachDialog({
    required this.heightInches,
    required this.currentReachInches,
  });

  @override
  State<_StandingReachDialog> createState() => _StandingReachDialogState();
}

class _StandingReachDialogState extends State<_StandingReachDialog> {
  late final int _estimate = StandingReach.clampInches(
      VertAssessment.standingReachInches(widget.heightInches));

  late int _reach =
      StandingReach.clampInches(widget.currentReachInches ?? _estimate);

  late final _ctrl = FixedExtentScrollController(
      initialItem: _reach - StandingReach.minInches);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: DunkColors.surface,
      title: Text(
        l10n.settingsStandingReach,
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.standingReachHowTo,
              style: const TextStyle(
                  color: DunkColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.standingReachValue(StandingReach.label(_reach), _reach),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListWheelScrollView.useDelegate(
                controller: _ctrl,
                itemExtent: 40,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) =>
                    setState(() => _reach = StandingReach.minInches + i),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount:
                      StandingReach.maxInches - StandingReach.minInches + 1,
                  builder: (context, i) {
                    final inches = StandingReach.minInches + i;
                    return Center(
                      child: Text(
                        l10n.standingReachValue(
                            StandingReach.label(inches), inches),
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (widget.currentReachInches == null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.standingReachEstimateNote(StandingReach.label(_estimate)),
                style: const TextStyle(
                  color: DunkColors.textTertiary,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.commonCancel,
            style: const TextStyle(color: DunkColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_reach),
          child: Text(
            l10n.commonSave,
            style: const TextStyle(
              color: DunkColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
