import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/jump_auto_detector.dart';
import '../../../core/models/jump_measurement.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../theme/app_theme.dart';
import '../motion_extraction.dart';
import '../pose_extraction.dart';

/// Which of the three ways of finding takeoff/landing produced the number the
/// athlete is being shown. Surfaced on the result screen so the reading is
/// never presented as more (or less) authoritative than it is.
enum JumpDetectionMethod {
  pose('Body tracking'),
  motion('Frame motion'),
  manual('Your own marks');

  final String label;
  const JumpDetectionMethod(this.label);
}

/// Everything the processing pass produced: the pose pass always, the
/// motion-energy pass only when the pose pass declined to answer.
class JumpAnalysis {
  final PoseJumpDiagnostics pose;
  final JumpDetectionDiagnostics motion;

  const JumpAnalysis({required this.pose, required this.motion});

  static const empty = JumpAnalysis(
    pose: PoseJumpDiagnostics.empty,
    motion: JumpDetectionDiagnostics.empty,
  );

  /// Pose first, motion energy second, null when neither could answer (the
  /// caller then falls back to manual marking).
  JumpMeasurement? get measurement => pose.result ?? motion.result;

  JumpDetectionMethod? get method {
    if (pose.result != null) return JumpDetectionMethod.pose;
    if (motion.result != null) return JumpDetectionMethod.motion;
    return null;
  }

  bool get hasAnyData => pose.sampleCount > 0 || motion.sampleCount > 0;
}

/// Finds the jump's takeoff/landing in the recorded clip, then hands the whole
/// [JumpAnalysis] to [onDetected] so the result screen can say exactly what
/// was measured and how.
///
/// The pipeline is pose first, motion energy second:
///
/// 1. **Pose tracking** (`pose_extraction.dart` → `core/pose_jump_detector.dart`)
///    follows the athlete's feet and times the crossings of a ground baseline.
///    This is the primary method because whole-frame motion energy was
///    *measured* to fail on a real clip: it is a ratio of moving area to total
///    area, so it is scale-invariant, and an athlete occupying a small part of
///    the frame registered 0.013 against UI transitions at 0.30. Sampling at
///    96 px instead of 32 px moved that 0.012 → 0.012. See CLAUDE.md.
/// 2. **Motion energy** (`core/jump_auto_detector.dart`) runs only when the
///    pose pass could not run at all — no frames decoded, the model
///    unavailable. It is *not* used when pose ran and declined: that decline
///    is a considered refusal by the better method, and overriding it with
///    the weaker one is how a jump measured at 28-29" got reported as 8".
/// 3. Otherwise the caller falls back to **manual marking**, which always
///    works and is honest about who made the call.
///
/// The checklist below tracks the real stages of that pass as they complete —
/// it is not a decorative animation, and when the fallback engages it says so
/// rather than quietly pretending the first method worked.
class ProcessingScreen extends StatefulWidget {
  final File video;
  final void Function(JumpAnalysis analysis) onDetected;

  const ProcessingScreen({
    super.key,
    required this.video,
    required this.onDetected,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

enum _Phase { tracking, locating, estimating }

class _ProcessingScreenState extends State<ProcessingScreen> {
  _Phase _phase = _Phase.tracking;

  /// Set only when the pose pass declined and the motion-energy fallback is
  /// actually running, so the athlete is never told something untrue about
  /// what the app is doing.
  String? _fallbackNote;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    var analysis = JumpAnalysis.empty;
    try {
      if (mounted) setState(() => _phase = _Phase.tracking);
      final poseSamples = await extractPoseSamples(widget.video);

      if (mounted) setState(() => _phase = _Phase.locating);
      final pose = PoseJumpDetector.detectWithDiagnostics(poseSamples);

      // A pose pass that *declined* is a considered refusal, not a failure:
      // it looked at the athlete and found the clip unmeasurable (no clear
      // window, two comparable jumps, lost mid-flight). Handing that to
      // frame motion overrides a good judgement with a bad one — on the clip
      // that motivated this, pose correctly declined and frame motion
      // confidently answered 8" for a jump measured at 28-29". So motion
      // energy is now only a safety net for a pose pass that could not run
      // at all (no frames decoded, the plugin unavailable); when pose ran and
      // said no, the athlete marks the jump by hand instead.
      var motion = JumpDetectionDiagnostics.empty;
      if (pose.result == null && poseSamples.isEmpty) {
        if (mounted) {
          setState(() => _fallbackNote =
              "Body tracking couldn't run on this clip — trying frame "
              'motion instead.');
        }
        final motionSamples = await extractMotionSamples(widget.video);
        motion = JumpAutoDetector.detectWithDiagnostics(motionSamples);
      } else if (pose.result == null && mounted) {
        setState(() => _fallbackNote =
            "Body tracking couldn't measure this clip "
            '(${pose.rejection.label}) — mark the jump yourself.');
      }

      analysis = JumpAnalysis(pose: pose, motion: motion);
      if (mounted) setState(() => _phase = _Phase.estimating);
    } catch (_) {
      analysis = JumpAnalysis.empty;
    }
    if (!mounted) return;
    widget.onDetected(analysis);
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
                    _StepRow(
                      label: 'Tracking your body through the clip',
                      stepPhase: _Phase.tracking,
                      currentPhase: _phase,
                    ),
                    _StepRow(
                      label: 'Finding your takeoff and landing',
                      stepPhase: _Phase.locating,
                      currentPhase: _phase,
                    ),
                    _StepRow(
                      label: 'Estimating your vertical',
                      stepPhase: _Phase.estimating,
                      currentPhase: _phase,
                      isLast: true,
                    ),
                  ],
                ),
              ),
              if (_fallbackNote != null) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: DunkColors.textTertiary, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fallbackNote!,
                        style: const TextStyle(
                          color: DunkColors.textTertiary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
