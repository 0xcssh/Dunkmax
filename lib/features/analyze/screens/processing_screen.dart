import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/jump_analysis_pipeline.dart';
import '../../../core/jump_form_scores.dart';
import '../../../core/models/jump_measurement.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../pose_extraction.dart';

/// Everything the processing pass produced.
class JumpAnalysis {
  /// What body tracking saw and decided — the measurement when there is one,
  /// the reason when there is not.
  final PoseJumpDiagnostics pose;

  /// The four form scores, from the same landmark series that timed the jump.
  /// Null when no airborne window was found — there is then no jump to score,
  /// and the result screen says so rather than inventing one.
  final JumpFormScores? scores;

  /// What went wrong when the clip could not be read at all, verbatim, for
  /// the developer-facing details card. Null on a clip that was analysed,
  /// whether or not it could be measured.
  final String? error;

  const JumpAnalysis({required this.pose, this.scores, this.error});

  static const empty = JumpAnalysis(pose: PoseJumpDiagnostics.empty);

  /// Null when the clip could not be measured (the caller then shows why,
  /// rather than asking the athlete to mark it).
  JumpMeasurement? get measurement => pose.result;

  bool get hasAnyData => pose.sampleCount > 0 || error != null;
}

/// Finds the jump's takeoff/landing in the recorded clip, then hands the whole
/// [JumpAnalysis] to [onDetected] so the result screen can say exactly what
/// was measured and how.
///
/// There is one method: body tracking. `core/jump_analysis_pipeline.dart`
/// decides which frames to look at, `pose_extraction.dart` turns them into
/// landmarks, `core/pose_jump_detector.dart` times the flight. A whole-frame
/// motion-energy detector used to sit behind it as a fallback; it was
/// *measured* to be blind to an athlete who fills a small part of the frame
/// (see CLAUDE.md) and reported 8" for a 28" jump, so it is gone rather than
/// kept as a second, worse opinion. When tracking cannot measure the clip
/// there is no number: the caller shows what the detector declined on and how
/// to fix the clip.
///
/// The checklist and the bar track the real work — frames decoded against the
/// plan's frame budget — not a decorative animation.
class ProcessingScreen extends StatefulWidget {
  final File video;
  final void Function(JumpAnalysis analysis) onDetected;

  /// The slice of the clip the athlete trimmed to, on the original clip's
  /// timeline — and so are the takeoff and landing that come back. The
  /// pipeline looks here first and only reaches past it, up to
  /// [clipDuration], when the trim itself cannot be measured.
  final Duration rangeStart;
  final Duration rangeEnd;
  final Duration clipDuration;

  const ProcessingScreen({
    super.key,
    required this.video,
    required this.onDetected,
    required this.rangeStart,
    required this.rangeEnd,
    required this.clipDuration,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

enum _Phase { tracking, locating, estimating }

class _ProcessingScreenState extends State<ProcessingScreen> {
  _Phase _phase = _Phase.tracking;

  /// Frames decoded so far against the plan's budget for this range.
  int _framesDone = 0;
  late final int _frameBudget =
      JumpSamplingPlan.frameBudget(widget.rangeStart, widget.rangeEnd);

  @override
  void initState() {
    super.initState();
    _run();
  }

  /// Share of the work done. Held just short of full until the result is in:
  /// a second, wider attempt (see [JumpAnalysisPipeline.run]) can spend more
  /// frames than the first one's budget.
  double get _progress {
    if (_phase == _Phase.estimating) return 1;
    if (_frameBudget <= 0) return 0;
    final fraction = _framesDone / _frameBudget;
    return fraction > 0.95 ? 0.95 : fraction;
  }

  Future<void> _run() async {
    final extractor = PoseFrameExtractor(
      widget.video,
      onFrame: () {
        if (mounted) setState(() => _framesDone++);
      },
    );
    JumpAnalysis analysis;
    try {
      final pose = await JumpAnalysisPipeline.run(
        rangeStart: widget.rangeStart,
        rangeEnd: widget.rangeEnd,
        clipDuration: widget.clipDuration,
        sample: extractor.sample,
        onStage: (stage) {
          if (!mounted) return;
          setState(() {
            _phase = stage == JumpAnalysisStage.scanning
                ? _Phase.tracking
                : _Phase.locating;
          });
        },
      );
      if (mounted) setState(() => _phase = _Phase.estimating);

      // The form scores read the *same* landmark series, so they cost no
      // extra decoding or inference — only arithmetic.
      final lastError = extractor.lastError;
      analysis = JumpAnalysis(
        pose: pose,
        scores: JumpFormScoring.fromDiagnostics(pose),
        error: pose.rejection == PoseDetectionRejection.unreadable
            ? 'decoded 0 of ${extractor.requested} frames'
                '${lastError == null ? '' : ' · $lastError'}'
            : null,
      );
    } catch (error) {
      // The plugin failed outright. That is not a clip that is too short or
      // an athlete who was out of shot, and it must not be reported as one.
      analysis = JumpAnalysis(
        pose: PoseJumpDiagnostics.unreadable,
        error: '$error',
      );
    } finally {
      await extractor.close();
    }
    if (!mounted) return;
    widget.onDetected(analysis);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: l10n.processingHeadline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: 0.5,
                      ),
                    ),
                    TextSpan(
                      text: l10n.processingHeadlineAccent,
                      style: const TextStyle(
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
                  Text(
                    l10n.processingBadge,
                    style: const TextStyle(
                      color: DunkColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 6,
                  backgroundColor: DunkColors.surfaceRaised,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(DunkColors.primary),
                ),
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
                      label: l10n.processingStepTracking,
                      stepPhase: _Phase.tracking,
                      currentPhase: _phase,
                    ),
                    _StepRow(
                      label: l10n.processingStepLocating,
                      stepPhase: _Phase.locating,
                      currentPhase: _phase,
                    ),
                    _StepRow(
                      label: l10n.processingStepEstimating,
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
