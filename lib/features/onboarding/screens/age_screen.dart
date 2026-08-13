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
      child: Column(
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
          SizedBox(
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
                        style: const TextStyle(fontSize: 22, color: Colors.white)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
