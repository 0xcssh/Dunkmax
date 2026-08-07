import 'package:flutter/material.dart';

import '../../core/standing_reach.dart';
import '../../core/vert_assessment.dart';
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
    return AlertDialog(
      backgroundColor: DunkColors.surface,
      title: const Text(
        'Standing reach',
        style: TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stand flat against a wall, reach one arm as high as it goes, '
              'mark your fingertips, then measure from the floor. Your dunk '
              'target is built on this number.',
              style: TextStyle(color: DunkColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(
              '${StandingReach.label(_reach)}  ·  $_reach in',
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
                        '${StandingReach.label(inches)}  ·  $inches in',
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
                'Currently estimated at ${StandingReach.label(_estimate)} from '
                'your height.',
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
          child: const Text(
            'Cancel',
            style: TextStyle(color: DunkColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_reach),
          child: const Text(
            'Save',
            style: TextStyle(
              color: DunkColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
