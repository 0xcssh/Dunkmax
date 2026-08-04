import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';

/// Height picker: two wheels (feet + inches). Reports total inches upward.
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
  static const _minFeet = 4;
  late int _feet = (widget.heightInches ~/ 12).clamp(_minFeet, 7);
  late int _inches = widget.heightInches % 12;

  late final _ftCtrl = FixedExtentScrollController(initialItem: _feet - _minFeet);
  late final _inCtrl = FixedExtentScrollController(initialItem: _inches);

  @override
  void dispose() {
    _ftCtrl.dispose();
    _inCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_feet * 12 + _inches);

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: widget.step,
      totalSteps: widget.totalSteps,
      title: 'YOUR HEIGHT',
      subtitle:
          'We use this to personalize your jump analysis and vert estimates.',
      onBack: widget.onBack,
      onContinue: widget.onContinue,
      child: Column(
        children: [
          _ValueBox(child: Text('$_feet\' $_inches"', style: _bigStyle)),
          const SizedBox(height: 8),
          const Text('FEET & INCHES',
              style: TextStyle(
                  color: DunkColors.textSecondary, letterSpacing: 2, fontSize: 13)),
          const SizedBox(height: 18),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: _Wheel(
                    controller: _ftCtrl,
                    count: 7 - _minFeet + 1,
                    label: (i) => '${_minFeet + i} ft',
                    onSelected: (i) => setState(() {
                      _feet = _minFeet + i;
                      _emit();
                    }),
                  ),
                ),
                Expanded(
                  child: _Wheel(
                    controller: _inCtrl,
                    count: 12,
                    label: (i) => '$i in',
                    onSelected: (i) => setState(() {
                      _inches = i;
                      _emit();
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _bigStyle = TextStyle(fontSize: 52, fontWeight: FontWeight.w800, color: Colors.white);

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
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
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
