import 'package:flutter/material.dart';

import '../../../core/flight_time.dart';
import '../../../core/models/video_attempt_type.dart';
import '../../../core/pose_jump_detector.dart';
import '../../../theme/app_theme.dart';
import '../screens/processing_screen.dart';

/// Raw detection data for this clip: what body tracking saw, frame by frame,
/// and what it decided.
///
/// While detection is still being validated against real footage, showing
/// exactly what the pass saw (instead of only the final number) turns the
/// next bug report into something diagnosable instead of another guess — and
/// a pass that *declined* needs that more than one that measured. Collapsed by
/// default so it doesn't clutter the normal experience.
class DetectionDetailsCard extends StatefulWidget {
  final JumpAnalysis analysis;
  final VideoAttemptType attemptType;
  const DetectionDetailsCard({
    super.key,
    required this.analysis,
    required this.attemptType,
  });

  @override
  State<DetectionDetailsCard> createState() => DetectionDetailsCardState();
}

class DetectionDetailsCardState extends State<DetectionDetailsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.analysis.pose;
    final error = widget.analysis.error;
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
                    const Expanded(
                      child: Text(
                        'DETECTION DETAILS',
                        style: TextStyle(
                          color: DunkColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
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
                  if (error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'error: $error',
                      style: const TextStyle(
                        color: DunkColors.primary,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _PoseSection(pose: p, isReported: p.result != null),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// What the body tracker saw. Shown whether or not it measured the jump,
/// because a pass that *declined* is exactly the case that needs diagnosing
/// from a real device.
class _PoseSection extends StatelessWidget {
  final PoseJumpDiagnostics pose;
  final bool isReported;

  const _PoseSection({required this.pose, required this.isReported});

  /// `ms:lift` for every frame, lift being how far the foot sat above the
  /// *local* ground baseline — the quantity the airborne threshold is applied
  /// to. `—` where there was no pose, hence no baseline.
  static String _liftSeries(PoseJumpDiagnostics pose) {
    final parts = <String>[];
    for (var i = 0; i < pose.samples.length; i++) {
      final sample = pose.samples[i];
      final ms = sample.timestamp.inMilliseconds;
      final base = pose.localGroundBaselines[i];
      final foot = sample.footDescent(pose.bodyAxis);
      parts.add(base == null || foot == null
          ? '$ms:—'
          : '$ms:${(base - foot).round()}');
    }
    return parts.join('  ');
  }

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
        'ground ${pose.groundBaselineY.toStringAsFixed(1)} (clip-wide) · '
        'lift threshold ${pose.liftThresholdPixels.toStringAsFixed(1)}px',
      );
      // The timing is measured against a *rolling* ground level, because an
      // athlete walking toward the camera drifts down the frame by more than
      // the jump lifts them. When that spread is large and the clip-wide
      // number sits away from both ends of it, this line is the whole story.
      final local = [
        for (final b in pose.localGroundBaselines)
          if (b != null) b,
      ];
      if (local.isNotEmpty) {
        final low = local.reduce((a, b) => a < b ? a : b);
        final high = local.reduce((a, b) => a > b ? a : b);
        final atTakeoff = pose.localBaselineAtTakeoff;
        final takeoffNote = atTakeoff == null
            ? ''
            : ' · at takeoff ${atTakeoff.toStringAsFixed(1)}';
        lines.add(
          'local ground ${low.toStringAsFixed(1)}–${high.toStringAsFixed(1)} '
          '(drift ${(high - low).toStringAsFixed(1)}px)$takeoffNote',
        );
      }
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
    if (pose.fittedSeconds != null) {
      lines.add(
        'parabola fit ${pose.fittedSeconds!.toStringAsFixed(3)}s · '
        'residual ${pose.fitResidualPixels?.toStringAsFixed(1) ?? '—'}px',
      );
    }
    if (pose.samples.length > 1) {
      final spanMs = pose.samples.last.timestamp.inMilliseconds -
          pose.samples.first.timestamp.inMilliseconds;
      lines.add(
        'series ${pose.samples.first.timestamp.inMilliseconds}–'
        '${pose.samples.last.timestamp.inMilliseconds}ms · step '
        '${(spanMs / (pose.samples.length - 1)).toStringAsFixed(0)}ms',
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
        // The same frames as lift *above the local ground*, which is what the
        // run detection actually thresholds. Reading the two rows together
        // shows whether a frame was called airborne because the foot rose or
        // because the floor under it moved.
        if (pose.localGroundBaselines.length == pose.samples.length &&
            pose.localGroundBaselines.any((b) => b != null)) ...[
          const SizedBox(height: 4),
          const Text(
            'lift above the local ground baseline, per frame',
            style: TextStyle(color: DunkColors.textTertiary, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(_liftSeries(pose), style: mono),
        ],
      ],
    );
  }
}
