import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/jump_auto_detector.dart';
import '../../../core/models/jump_measurement.dart';
import '../../../theme/app_theme.dart';
import '../motion_extraction.dart';

/// Runs motion-energy analysis on the recorded clip to auto-detect the
/// jump's takeoff/landing — see core/jump_auto_detector.dart for the
/// algorithm. Calls [onDetected] with the result, or null if no clear jump
/// was found (the caller falls back to manual marking).
///
/// Two real passes are run: a coarse full-clip pass to find an approximate
/// jump window, then a dense pass restricted to just that window (padded by
/// 250ms either side) to pin down takeoff/landing far more precisely. The UI
/// below reflects these real stages as they complete — it is not a
/// decorative animation.
class ProcessingScreen extends StatefulWidget {
  final File video;
  final ValueChanged<JumpMeasurement?> onDetected;

  const ProcessingScreen({
    super.key,
    required this.video,
    required this.onDetected,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

enum _Phase { extracting, locating, refining, estimating }

class _ProcessingScreenState extends State<ProcessingScreen> {
  _Phase _phase = _Phase.extracting;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    JumpMeasurement? result;
    try {
      if (mounted) setState(() => _phase = _Phase.extracting);
      final coarse = await extractMotionSamples(widget.video);

      if (mounted) setState(() => _phase = _Phase.locating);
      final coarseResult = JumpAutoDetector.detect(coarse);

      if (coarseResult != null) {
        if (mounted) setState(() => _phase = _Phase.refining);
        var start = coarseResult.takeoff - const Duration(milliseconds: 250);
        if (start < Duration.zero) start = Duration.zero;
        final end = coarseResult.landing + const Duration(milliseconds: 250);
        final refined = await extractMotionSamples(
          widget.video,
          rangeStart: start,
          rangeEnd: end,
          sampleCount: 60,
        );

        if (mounted) setState(() => _phase = _Phase.estimating);
        result = JumpAutoDetector.detect(refined) ?? coarseResult;
      } else {
        result = null;
      }
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    widget.onDetected(result);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _PulsingIcon(),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'ANALYZING',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: ' YOUR JUMP',
                      style: TextStyle(
                        color: DunkColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: DunkColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI PROCESSING',
                    style: TextStyle(
                      color: DunkColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: (_phase.index + 1) / _Phase.values.length,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                builder: (context, value, _) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: DunkColors.surfaceRaised,
                      valueColor: const AlwaysStoppedAnimation<Color>(DunkColors.primary),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: DunkColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DunkColors.stroke),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepRow(label: 'Extracting frames', stepPhase: _Phase.extracting, currentPhase: _phase),
                    _StepRow(label: 'Locating your jump', stepPhase: _Phase.locating, currentPhase: _phase),
                    _StepRow(label: 'Refining takeoff & landing', stepPhase: _Phase.refining, currentPhase: _phase),
                    _StepRow(
                      label: 'Estimating your vertical',
                      stepPhase: _Phase.estimating,
                      currentPhase: _phase,
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String label;
  final _Phase stepPhase;
  final _Phase currentPhase;
  final bool isLast;

  const _StepRow({
    required this.label,
    required this.stepPhase,
    required this.currentPhase,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = currentPhase.index > stepPhase.index;
    final isCurrent = currentPhase.index == stepPhase.index;

    Widget statusIcon;
    Color textColor;
    FontWeight fontWeight;

    if (isDone) {
      statusIcon = Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: DunkColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 14),
      );
      textColor = Colors.white;
      fontWeight = FontWeight.w600;
    } else if (isCurrent) {
      statusIcon = const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DunkColors.primary,
          ),
        ),
      );
      textColor = DunkColors.primary;
      fontWeight = FontWeight.w700;
    } else {
      statusIcon = Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: DunkColors.stroke, width: 1.5),
        ),
      );
      textColor = DunkColors.textTertiary;
      fontWeight = FontWeight.w500;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: DunkColors.stroke, width: 1)),
            ),
      child: Row(
        children: [
          statusIcon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: fontWeight,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A softly "breathing" basketball icon in a tinted circle — purely a
/// low-cost looping scale animation, decorative only (unlike the checklist
/// below, which reflects real pipeline progress).
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: DunkColors.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.sports_basketball, color: DunkColors.primary, size: 40),
      ),
    );
  }
}
