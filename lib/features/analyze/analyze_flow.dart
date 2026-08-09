import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/jump_result.dart';
import '../../core/jump_trend.dart';
import '../../core/models/jump_log_entry.dart';
import '../../core/models/jump_measurement.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/models/video_attempt_type.dart';
import '../../core/trim_range.dart';
import '../../core/vert_assessment.dart';
import '../../services/jump_log_store.dart';
import 'screens/jump_result_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/source_screen.dart';
import 'screens/trim_screen.dart';
import 'screens/unmeasured_screen.dart';

enum _Step { source, trim, processing, unmeasured, result }

/// Drives the Analyze tab: pick/record a jump clip → trim it to the one jump →
/// find takeoff/landing → the result dashboard. The headline number (EST.
/// VERT) comes from the pure, tested flight-time core.
///
/// The trim step is load-bearing, not decoration: both frame samplers spend a
/// fixed budget across whatever range they are handed, so the [TrimRange]
/// chosen there is passed all the way into [ProcessingScreen] and buys
/// temporal resolution inside the flight. Nothing is re-encoded — the original
/// file is still what is saved to the jump log.
///
/// Finding the airborne window is a three-tier cascade (see
/// [ProcessingScreen]): pose tracking first, whole-frame motion energy as a
/// fallback. When neither can answer there is no number: the athlete is
/// told what the detector saw and how to fix the clip. Every tier reports
/// which one it was, so the result screen never presents a fallback reading as
/// if it came from body tracking.
///
/// The four Bounce/Power/Control/Form scores are computed in the same pass,
/// from the same landmark series (`core/jump_form_scores.dart`), and travel to
/// the result screen inside [JumpAnalysis] alongside the diagnostics. Any of
/// them the clip could not support is carried as unavailable-with-a-reason
/// rather than filled in.
class AnalyzeFlow extends StatefulWidget {
  final OnboardingProfile profile;
  final JumpLogStore jumpLogStore;

  /// When set, this is the pre-paywall "try it free" run: the source screen
  /// offers a skip link (straight to the paywall) and the result screen's
  /// primary action continues to the paywall instead of resetting to
  /// analyze another jump. Both null in the normal Analyze-tab usage.
  final VoidCallback? onSkip;
  final VoidCallback? onFirstResult;

  const AnalyzeFlow({
    super.key,
    required this.profile,
    required this.jumpLogStore,
    this.onSkip,
    this.onFirstResult,
  });

  @override
  State<AnalyzeFlow> createState() => _AnalyzeFlowState();
}

class _AnalyzeFlowState extends State<AnalyzeFlow> {
  _Step _step = _Step.source;
  File? _video;
  TrimRange? _trim;
  VideoAttemptType _attemptType = VideoAttemptType.jumpAttempt;
  JumpResult? _result;
  JumpTrend? _trend;
  JumpAnalysis _analysis = JumpAnalysis.empty;
  JumpDetectionMethod _method = JumpDetectionMethod.pose;

  void _onVideoSelected(File video, VideoAttemptType attemptType) {
    setState(() {
      _video = video;
      _trim = null;
      _attemptType = attemptType;
      _step = _Step.trim;
    });
  }

  void _onTrimmed(TrimRange range) {
    setState(() {
      _trim = range;
      _step = _Step.processing;
    });
  }

  void _onDetected(JumpAnalysis analysis) {
    setState(() => _analysis = analysis);
    final measurement = analysis.measurement;
    if (measurement == null) {
      // No measurement. The athlete used to be handed the clip and asked to
      // tap the takeoff and landing frames; that is a fiddly job offered at
      // the moment the app failed at its headline feature, and identifying
      // those two frames by eye is the dominant error source even for trained
      // users at 240 fps. They get the reason and the fix instead.
      setState(() => _step = _Step.unmeasured);
      return;
    }
    _finishWithMeasurement(measurement, analysis.method!);
  }

  Future<void> _finishWithMeasurement(
    JumpMeasurement measurement,
    JumpDetectionMethod method,
  ) async {
    final assessment = VertAssessment(
      heightInches: widget.profile.heightInches,
      ageYears: widget.profile.ageYears,
      hops: widget.profile.hopsLevel,
      measuredStandingReach: widget.profile.standingReachInches,
      dunkHand: widget.profile.dunkHand,
    );
    final result = JumpResult(measurement: measurement, assessment: assessment);
    if (measurement.isValid) {
      String? videoPath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        final ext = _video!.path.contains('.') ? _video!.path.split('.').last : 'mov';
        final path = '${dir.path}/jump_video_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final saved = await _video!.copy(path);
        videoPath = saved.path;
      } catch (_) {
        videoPath = null;
      }
      String? thumbnailPath;
      try {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/jump_${DateTime.now().millisecondsSinceEpoch}.jpg';
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: _video!.path,
          thumbnailPath: path,
          imageFormat: ImageFormat.JPEG,
          timeMs: measurement.takeoff.inMilliseconds,
          quality: 70,
        );
      } catch (_) {
        thumbnailPath = null;
      }
      await widget.jumpLogStore.addEntry(
        JumpLogEntry(
          verticalInches: result.verticalInches,
          recordedAt: DateTime.now(),
          thumbnailPath: thumbnailPath,
          videoPath: videoPath,
          attemptType: _attemptType,
        ),
      );
    }
    final trend = JumpTrendCalculator.compute(widget.jumpLogStore.entries);
    if (!mounted) return;
    setState(() {
      _result = result;
      _trend = trend;
      _method = method;
      _step = _Step.result;
    });
  }

  void _reset() => setState(() {
        _video = null;
        _trim = null;
        _attemptType = VideoAttemptType.jumpAttempt;
        _result = null;
        _trend = null;
        _analysis = JumpAnalysis.empty;
        _method = JumpDetectionMethod.pose;
        _step = _Step.source;
      });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.source:
        return SourceScreen(onVideoSelected: _onVideoSelected, onSkip: widget.onSkip);
      case _Step.trim:
        return TrimScreen(
          video: _video!,
          onConfirmed: _onTrimmed,
          onCancel: _reset,
        );
      case _Step.processing:
        return ProcessingScreen(
          video: _video!,
          rangeStart: _trim!.start,
          rangeEnd: _trim!.end,
          onDetected: _onDetected,
        );
      case _Step.unmeasured:
        return UnmeasuredScreen(
          rejection: _analysis.pose.rejection,
          onRetrim: () => setState(() => _step = _Step.trim),
          onNewClip: _reset,
        );
      case _Step.result:
        return JumpResultScreen(
          result: _result!,
          trend: _trend,
          analysis: _analysis,
          method: _method,
          attemptType: _attemptType,
          onAnalyzeAnother: widget.onFirstResult ?? _reset,
          ctaLabel: widget.onFirstResult != null ? 'CONTINUE' : 'ANALYZE ANOTHER JUMP',
        );
    }
  }
}
