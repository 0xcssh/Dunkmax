import 'package:flutter/material.dart';

import '../../../core/flight_time.dart';
import '../../../core/jump_auto_detector.dart';
import '../../../core/models/video_attempt_type.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../theme/app_theme.dart';
import '../screens/processing_screen.dart';

/// Raw detection data for this clip, and — stated plainly, not implied —
/// which of the three methods produced the number above it: body tracking,
/// or the frame-motion fallback.
///
/// While detection is still being validated against real footage, showing
/// exactly what each pass saw (instead of only the final number) turns the
/// next bug report into something diagnosable instead of another guess. Both
/// passes are shown when both ran, so a pose pass that *declined* is as
/// visible as one that won. Collapsed by default so it doesn't clutter the
/// normal experience.
class DetectionDetailsCard extends StatefulWidget {
  final JumpAnalysis analysis;
  final JumpDetectionMethod method;
  final VideoAttemptType attemptType;
  const DetectionDetailsCard({
    super.key,
    required this.analysis,
    required this.method,
    required this.attemptType,
  });

  @override
  State<DetectionDetailsCard> createState() => DetectionDetailsCardState();
}

class DetectionDetailsCardState extends State<DetectionDetailsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.analysis.motion;
    final p = widget.analysis.pose;
    return Container(
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bug_report_outlined,
                        color: DunkColors.textTertiary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DETECTION DETAILS',
                            style: TextStyle(
                              color: DunkColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Measured by ${widget.method.label.toLowerCase()}',
                            style: const TextStyle(
                              color: DunkColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: DunkColors.textTertiary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clip type: ${widget.attemptType.title}',
                    style: const TextStyle(
                      color: DunkColors.textTertiary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reported number from: ${widget.method.label}',
                    style: const TextStyle(
                      color: DunkColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PoseSection(
                    pose: p,
                    isReported: widget.method == JumpDetectionMethod.pose,
                  ),
                  if (d.sampleCount > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.method == JumpDetectionMethod.motion
                          ? 'FRAME MOTION (fallback — used)'
                          : 'FRAME MOTION (fallback)',
                      style: const TextStyle(
                        color: DunkColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _MotionSection(
                      d: d,
                      isReported:
                          widget.method == JumpDetectionMethod.motion,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The pose pass: what the body tracker saw. Shown whether it won or was
/// overruled by the fallback, because a pose pass that *declined* is exactly
/// the case that needs diagnosing from a real device.
class _PoseSection extends StatelessWidget {
  final PoseJumpDiagnostics pose;
  final bool isReported;

  const _PoseSection({required this.pose, required this.isReported});

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      color: DunkColors.textTertiary,
      fontSize: 11,
      fontFamily: 'monospace',
    );

    final lines = <String>[
      '${pose.sampleCount} frames · athlete found in ${pose.detectedCount} '
          '(${pose.missingCount} missed)',
    ];
    if (pose.detectedCount > 0) {
      // Which way the detector thought "up" was. Frames come out of the
      // extractor in whatever orientation the file stores them (an iPhone
      // portrait clip is stored landscape with a rotation flag), so a real
      // device report needs to say this rather than leave it to be guessed.
      lines.add(
        pose.bodyAxis.isImageVertical
            ? 'up axis: image vertical (assumed — no torso to measure)'
            : 'up axis: ${pose.bodyAxis.tiltDegrees.toStringAsFixed(1)}° from '
                'image up, from ${pose.axisSampleCount} grounded frames',
      );
      lines.add(
        'torso ${pose.torsoPixels.toStringAsFixed(1)}px · '
        'ground ${pose.groundBaselineY.toStringAsFixed(1)} · '
        'lift threshold ${pose.liftThresholdPixels.toStringAsFixed(1)}px',
      );
    }
    if (pose.peakLiftPixels > 0) {
      lines.add('peak foot lift ${pose.peakLiftPixels.toStringAsFixed(1)}px');
    }
    if (pose.crossingTakeoff != null && pose.crossingLanding != null) {
      lines.add(
        'window ${pose.crossingTakeoff!.inMilliseconds}–'
        '${pose.crossingLanding!.inMilliseconds}ms',
      );
    }
    if (pose.rawCrossingSeconds != null) {
      lines.add(
        'raw crossings ${pose.rawCrossingSeconds!.toStringAsFixed(3)}s',
      );
    }
    if (pose.correctedSeconds != null) {
      lines.add(
        'parabola-corrected ${pose.correctedSeconds!.toStringAsFixed(3)}s → '
        '${FlightTime.heightInches(pose.correctedSeconds!).toStringAsFixed(1)}"',
      );
    }
    lines.add('outcome: ${pose.rejection.label}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isReported ? 'BODY TRACKING (used)' : 'BODY TRACKING',
          style: TextStyle(
            color: isReported ? DunkColors.primary : DunkColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(line, style: mono),
          ),
        if (pose.samples.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text(
            'foot height down the up axis, per frame (— = no pose)',
            style: TextStyle(color: DunkColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            [
              for (final s in pose.samples)
                '${s.timestamp.inMilliseconds}:'
                    '${s.footDescent(pose.bodyAxis)?.round() ?? '—'}',
            ].join('  '),
            style: mono,
          ),
        ],
      ],
    );
  }
}

/// The legacy motion-energy pass, unchanged — only rendered when it actually
/// ran (i.e. body tracking declined).
class _MotionSection extends StatelessWidget {
  final JumpDetectionDiagnostics d;

  /// True only when this pass is the one that produced the headline number.
  final bool isReported;

  const _MotionSection({required this.d, required this.isReported});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${d.sampleCount} samples · energy '
          '${d.minEnergy.toStringAsFixed(3)}–${d.maxEnergy.toStringAsFixed(3)} · '
          'threshold ${d.threshold.toStringAsFixed(3)}',
          style: const TextStyle(
            color: DunkColors.textTertiary,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 10),
        if (d.candidates.isEmpty)
          const Text(
            'No plausible candidate windows found.',
            style: TextStyle(color: DunkColors.textTertiary, fontSize: 12),
          )
        else
          for (final c in d.candidates)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${c.chosen ? '→ ' : '  '}'
                '${c.airborneSeconds.toStringAsFixed(2)}s '
                '(${c.takeoff.inMilliseconds}–${c.landing.inMilliseconds}ms) · '
                'avg ${c.avgEnergy.toStringAsFixed(3)} · '
                'bounds ${c.boundingEnergy.toStringAsFixed(3)} · '
                'prom ${c.prominence.toStringAsFixed(3)}'
                '${c.chosen ? ' [CHOSEN]' : ''}',
                style: TextStyle(
                  color: c.chosen ? DunkColors.primary : DunkColors.textTertiary,
                  fontWeight: c.chosen ? FontWeight.w700 : FontWeight.w400,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        if (d.estimates.outerBoundSeconds != null) ...[
          const SizedBox(height: 12),
          const Text(
            'HOW THE WINDOW IS MEASURED',
            style: TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          _EstimateLine(
            label: 'outer bound',
            seconds: d.estimates.outerBoundSeconds,
            isReported: isReported,
          ),
          _EstimateLine(
            label: 'threshold cross',
            seconds: d.estimates.crossingSeconds,
          ),
          _EstimateLine(
            label: 'apex symmetry',
            seconds: d.estimates.apexSymmetrySeconds,
          ),
        ],
      ],
    );
  }
}

/// One candidate reading of the airborne window, shown as both the raw hang
/// time and the vertical it would produce — so the three can be compared
/// directly against a known reference measurement of the same clip.
class _EstimateLine extends StatelessWidget {
  final String label;
  final double? seconds;
  final bool isReported;

  const _EstimateLine({
    required this.label,
    required this.seconds,
    this.isReported = false,
  });

  @override
  Widget build(BuildContext context) {
    final value = seconds;
    final text = value == null
        ? '$label: —'
        : '$label: ${value.toStringAsFixed(3)}s → '
            '${FlightTime.heightInches(value).toStringAsFixed(1)}"'
            '${isReported ? '  [REPORTED]' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: isReported ? DunkColors.primary : DunkColors.textTertiary,
          fontWeight: isReported ? FontWeight.w700 : FontWeight.w400,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

/// The written read on the jump: the headline number, the trend note, then —
/// when body tracking measured enough to rank them — the best and worst
/// measured aspects and two tips aimed at that weakness.
///
/// The strength/weakness rows carry the same measurement string the matching
/// tile in FORM SCORES shows. That repetition is deliberate and framed
/// differently on each side: the tile is the number, this is the sentence that
/// says why it matters. When nothing could be ranked, the rows are simply
/// absent and the tips revert to the general ones — the card never fills the
/// space with a guess.
