import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/jump_auto_detector.dart';
import '../../../theme/app_theme.dart';
import '../motion_extraction.dart';

/// Runs motion-energy analysis on the recorded clip to auto-detect the
/// jump's takeoff/landing — see core/jump_auto_detector.dart for the
/// algorithm. Calls [onDetected] with the measurement (null if no clear
/// jump was found — the caller falls back to manual marking) AND the full
/// [JumpDetectionDiagnostics], so the result screen can show exactly what
/// the detector saw on this real clip instead of tuning being another blind
/// guess from a bug report.
///
/// This used to run a second, denser pass restricted to a small window
/// around the coarse result to refine the exact timestamps — reverted: that
/// refine pass re-derived its own relative energy threshold from just that
/// narrow window, which turned out to be an unreliable, non-representative
/// sample (confirmed by a real clip going from a ~20" reading to a bogus
/// ~50" reading after the refine step was added). A single full-clip pass
/// is coarser but far more predictable. The UI below reflects the real
/// stages of that single pass as they complete — it is not a decorative
/// animation.
class ProcessingScreen extends StatefulWidget {
  final File video;
  final void Function(JumpDetectionDiagnostics diagnostics) onDetected;

  const ProcessingScreen({
    super.key,
    required this.video,
    required this.onDetected,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

enum _Phase { extracting, locating, estimating }

class _ProcessingScreenState extends State<ProcessingScreen> {
  _Phase _phase = _Phase.extracting;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    JumpDetectionDiagnostics diagnostics = JumpDetectionDiagnostics.empty;
    try {
      if (mounted) setState(() => _phase = _Phase.extracting);
      final samples = await extractMotionSamples(widget.video);

      if (mounted) setState(() => _phase = _Phase.locating);
      diagnostics = JumpAutoDetector.detectWithDiagnostics(samples);

      if (mounted) setState(() => _phase = _Phase.estimating);
    } catch (_) {
      diagnostics = JumpDetectionDiagnostics.empty;
    }
    if (!mounted) return;
    widget.onDetected(diagnostics);
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
