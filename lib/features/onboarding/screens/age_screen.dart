import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';

/// Age picker: a single wheel of years.
class AgeScreen extends StatefulWidget {
  final int ageYears;
  final ValueChanged<int> onChanged;
  final VoidCallback? onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const AgeScreen({
    super.key,
    required this.ageYears,
    required this.onChanged,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  static const _minAge = 14;
  static const _maxAge = 70;

  /// The shortest the body is ever laid out: the value box and its caption
  /// plus roughly two wheel rows. A layout figure, not a measurement.
  static const double _minBodyHeight = 250;
  late int _age = widget.ageYears.clamp(_minAge, _maxAge);
  late final _ctrl = FixedExtentScrollController(initialItem: _age - _minAge);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      step: widget.step,
      totalSteps: widget.totalSteps,
      title: l10n.ageTitle,
      subtitle: l10n.savedToAthleteProfile,
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
            child: _buildBody(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DunkColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DunkColors.primary.withValues(alpha: 0.7)),
          ),
          child: Text('$_age',
              style: const TextStyle(
                  fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
        const SizedBox(height: 8),
        Text(l10n.ageUnitLabel,
            style: const TextStyle(
                color: DunkColors.textSecondary, letterSpacing: 2, fontSize: 13)),
        const SizedBox(height: 18),
        // Flexible, so on a very short screen (320x568) the wheel gives up
        // height instead of painting over the Continue button. With room to
        // spare it is exactly 160 tall, as before.
        Flexible(
          child: SizedBox(
            height: 160,
            child: ShaderMask(
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
                controller: _ctrl,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => setState(() {
                  _age = _minAge + i;
                  widget.onChanged(_age);
                }),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _maxAge - _minAge + 1,
                  builder: (context, i) => Center(
                    child: Text(l10n.ageOption(_minAge + i),
                        style: const TextStyle(
                            fontSize: 22, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
