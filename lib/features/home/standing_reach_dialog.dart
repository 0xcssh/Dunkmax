import 'package:flutter/material.dart';

import '../../core/standing_reach.dart';
import '../../core/vert_assessment.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../shared/unit_scope.dart';

/// Lets the athlete set or correct their standing reach after onboarding.
///
/// Returns the chosen reach in inches, or null if they backed out. The wheel
/// opens on their current measurement, or on the height-based estimate when
/// they never gave one — the same starting point the onboarding question uses.
/// In a metric region the wheel runs in centimetres and the pick is converted
/// to inches on the way out; what is stored never changes unit.
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

  /// The wheel's own unit system, fixed when the dialog opens: the wheel's
  /// range and controller are built once, so a scope change mid-dialog (which
  /// never happens in practice) must not re-base them.
  late final UnitSystem _units = UnitScope.of(context);

  /// The wheel's first entry, in the wheel's unit.
  int get _min => _units.isMetric ? StandingReach.minCm : StandingReach.minInches;

  int get _max => _units.isMetric ? StandingReach.maxCm : StandingReach.maxInches;

  /// Metric: the wheel position in centimetres (stored separately so that
  /// scrolling one centimetre never snaps back through the inch rounding).
  late int _cm = StandingReach.clampCm(UnitConversions.inchesToCm(_reach));

  late final FixedExtentScrollController _ctrl = FixedExtentScrollController(
    initialItem: (_units.isMetric ? _cm : _reach) - _min,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// One reading, in the wheel's unit: `8'1"  ·  97 in` or `246 cm`.
  String _label(AppLocalizations l10n, int wheelValue) {
    if (_units.isMetric) {
      return l10n.standingReachValue(_units.name, '', wheelValue);
    }
    return l10n.standingReachValue(
        _units.name, StandingReach.label(wheelValue), wheelValue);
  }

  void _onSelected(int index) {
    setState(() {
      if (_units.isMetric) {
        _cm = _min + index;
        _reach = StandingReach.clampInches(UnitConversions.cmToInches(_cm));
      } else {
        _reach = _min + index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final estimateLabel = _units.isMetric
        ? l10n.length(_units.name, UnitConversions.inchesToCm(_estimate))
        : StandingReach.label(_estimate);
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
              _label(l10n, _units.isMetric ? _cm : _reach),
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
                onSelectedItemChanged: _onSelected,
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _max - _min + 1,
                  builder: (context, i) => Center(
                    child: Text(
                      _label(l10n, _min + i),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.currentReachInches == null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.standingReachEstimateNote(estimateLabel),
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
          // Always inches: the dialog's contract, whatever the wheel showed.
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
