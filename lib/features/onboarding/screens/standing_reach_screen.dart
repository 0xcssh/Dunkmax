import 'package:flutter/material.dart';

import '../../../core/standing_reach.dart';
import '../../../core/vert_assessment.dart';
import '../../../theme/app_theme.dart';
import '../widgets/onboarding_scaffold.dart';

/// Standing reach: fingertip height with one arm overhead, flat-footed.
///
/// The single number every "X inches to dunk" claim in the app rests on. Until
/// the athlete measures it, it is estimated from their height — a population
/// average that can be several inches out — so this screen asks for the real
/// one, teaches the measurement in a line, and opens the wheel on the estimate
/// so there is always a sensible starting point.
///
/// Deliberately skippable: an athlete who has not measured it should not be
/// blocked, and guessing here would be worse than the estimate. Skipping is a
/// visible option, not a hidden one.
class StandingReachScreen extends StatefulWidget {
  /// Used for the starting estimate and the "measured from your height" copy.
  final int heightInches;

  /// The athlete's current measurement, if they already gave one.
  final int? standingReachInches;

  final ValueChanged<int> onChanged;

  /// Move on without a measurement — the app keeps using the estimate.
  final VoidCallback onSkip;

  final VoidCallback onContinue;
  final VoidCallback onBack;
  final int step;
  final int totalSteps;

  const StandingReachScreen({
    super.key,
    required this.heightInches,
    required this.standingReachInches,
    required this.onChanged,
    required this.onSkip,
    required this.onContinue,
    required this.onBack,
    required this.step,
    required this.totalSteps,
  });

  @override
  State<StandingReachScreen> createState() => _StandingReachScreenState();
}

class _StandingReachScreenState extends State<StandingReachScreen> {
  late final int _estimate = StandingReach.clampInches(
      VertAssessment.standingReachInches(widget.heightInches));

  late int _reach =
      StandingReach.clampInches(widget.standingReachInches ?? _estimate);

  late final _ctrl =
      FixedExtentScrollController(initialItem: _reach - StandingReach.minInches);

  @override
  void initState() {
    super.initState();
    // Emit the starting value up front: continuing without touching the wheel
    // is still an answer, and the parent must not be left holding null.
    widget.onChanged(_reach);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      step: widget.step,
      totalSteps: widget.totalSteps,
      title: 'YOUR STANDING REACH',
      subtitle:
          'Stand flat against a wall, reach one arm as high as it goes, mark '
          'your fingertips, then measure from the floor.',
      onBack: widget.onBack,
      onContinue: widget.onContinue,
      ctaLabel: 'USE THIS REACH',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ValueBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(StandingReach.label(_reach), style: _bigStyle),
                const SizedBox(height: 2),
                Text(
                  '$_reach in',
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'FINGERTIPS, FLAT-FOOTED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DunkColors.textSecondary,
              letterSpacing: 2,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: _Wheel(
              controller: _ctrl,
              count: StandingReach.maxInches - StandingReach.minInches + 1,
              label: (i) {
                final inches = StandingReach.minInches + i;
                return '${StandingReach.label(inches)}  ·  $inches in';
              },
              onSelected: (i) => setState(() {
                _reach = StandingReach.minInches + i;
                widget.onChanged(_reach);
              }),
            ),
          ),
          const SizedBox(height: 14),
          _EstimateNote(estimate: _estimate),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text(
                "I HAVEN'T MEASURED IT YET",
                style: TextStyle(
                  color: DunkColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _bigStyle =
    TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white);

/// Says out loud that the pre-filled number is only a starting point, so a
/// tapped-through CONTINUE never looks like a measurement it isn't.
class _EstimateNote extends StatelessWidget {
  final int estimate;
  const _EstimateNote({required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.straighten, color: DunkColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'We started you at ${StandingReach.label(estimate)}, the average '
              'reach for your height. Arms vary by several inches, and this is '
              'the number your dunk target is built on — your real one makes it '
              'exact.',
              style: const TextStyle(
                color: DunkColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final Widget child;
  const _ValueBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
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
        itemExtent: 42,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, i) => Center(
            child: Text(
              label(i),
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
