import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../shared/unit_scope.dart';
import '../widgets/onboarding_scaffold.dart';

/// Height picker. Imperial regions get two wheels (feet + inches), metric
/// regions one centimetre wheel; either way the value reported upward is
/// total inches, the unit everything downstream stores and computes in.
class HeightScreen extends StatefulWidget {
  final int heightInches;
  final ValueChanged<int> onChanged;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const HeightScreen({
    super.key,
    required this.heightInches,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  static const _minFeet = UnitInputRanges.minHeightFeet;
  static const _maxFeet = UnitInputRanges.maxHeightFeet;
  static const _minCm = UnitInputRanges.minHeightCm;
  static const _maxCm = UnitInputRanges.maxHeightCm;

  /// The shortest the body is ever laid out: the value box and its caption
  /// plus roughly two wheel rows. A layout figure, not a measurement.
  static const double _minBodyHeight = 250;

  // Imperial state.
  late int _feet = (widget.heightInches ~/ 12).clamp(_minFeet, _maxFeet);
  late int _inches = widget.heightInches % 12;

  // Metric state: the same stored height, in whole centimetres.
  late int _cm =
      UnitConversions.inchesToCm(widget.heightInches).clamp(_minCm, _maxCm);

  late final _ftCtrl =
      FixedExtentScrollController(initialItem: _feet - _minFeet);
  late final _inCtrl = FixedExtentScrollController(initialItem: _inches);
  late final _cmCtrl = FixedExtentScrollController(initialItem: _cm - _minCm);

  @override
  void dispose() {
    _ftCtrl.dispose();
    _inCtrl.dispose();
    _cmCtrl.dispose();
    super.dispose();
  }

  void _emitImperial() => widget.onChanged(_feet * 12 + _inches);

  void _emitMetric() => widget.onChanged(UnitConversions.cmToInches(_cm));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final units = UnitScope.of(context);
    return OnboardingScaffold(
      step: widget.step,
      totalSteps: widget.totalSteps,
      title: l10n.heightTitle,
      subtitle: l10n.heightSubtitle,
      onBack: widget.onBack,
      onContinue: widget.onContinue,
      // Laid out in the space the scaffold gives the body, never in less than
      // [_minBodyHeight]: below that the body scrolls instead of shrinking
      // further. With room to spare nothing here differs from a plain Column.
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(constraints.maxHeight, _minBodyHeight),
            ),
            child: _buildBody(l10n, units),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, UnitSystem units) {
    final unit = units.name;
    final value = units.isMetric
        ? l10n.heightValue(unit, 0, 0, _cm)
        : l10n.heightValue(unit, _feet, _inches, 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ValueBox(child: Text(value, style: _bigStyle)),
        const SizedBox(height: 8),
        Text(l10n.heightUnitLabel(unit),
            style: const TextStyle(
                color: DunkColors.textSecondary,
                letterSpacing: 2,
                fontSize: 13)),
        const SizedBox(height: 18),
        // The wheel takes every pixel the body has left, so a tall phone
        // shows a taller picker instead of an empty band above Continue; on
        // a short screen (320x568) it gives up height instead of painting
        // over the button.
        Expanded(
          child: SizedBox(
            child: units.isMetric
                ? _Wheel(
                    controller: _cmCtrl,
                    count: _maxCm - _minCm + 1,
                    label: (i) => l10n.heightCmOption(_minCm + i),
                    onSelected: (i) => setState(() {
                      _cm = _minCm + i;
                      _emitMetric();
                    }),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _Wheel(
                          controller: _ftCtrl,
                          count: _maxFeet - _minFeet + 1,
                          label: (i) => l10n.heightFeetOption(_minFeet + i),
                          onSelected: (i) => setState(() {
                            _feet = _minFeet + i;
                            _emitImperial();
                          }),
                        ),
                      ),
                      Expanded(
                        child: _Wheel(
                          controller: _inCtrl,
                          count: 12,
                          label: (i) => l10n.heightInchesOption(i),
                          onSelected: (i) => setState(() {
                            _inches = i;
                            _emitImperial();
                          }),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

const _bigStyle =
    TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white);

class _ValueBox extends StatelessWidget {
  final Widget child;
  const _ValueBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.7)),
      ),
      child: child,
    );
  }
}

class _Wheel extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int count;
  final String Function(int) label;
  final ValueChanged<int> onSelected;

  const _Wheel({
    required this.controller,
    required this.count,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent
        ],
        stops: [0.0, 0.3, 0.7, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.dstIn,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 44,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, i) => Center(
            child: Text(
              label(i),
              style: const TextStyle(fontSize: 22, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
