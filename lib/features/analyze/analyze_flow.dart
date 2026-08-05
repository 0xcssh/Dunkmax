import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/jump_auto_detector.dart';
import '../../core/jump_result.dart';
import '../../core/jump_trend.dart';
import '../../core/models/jump_log_entry.dart';
import '../../core/models/jump_measurement.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/models/video_attempt_type.dart';
import '../../core/vert_assessment.dart';
import '../../services/jump_log_store.dart';
import 'screens/jump_result_screen.dart';
import 'screens/mark_jump_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/source_screen.dart';

enum _Step { source, mark, processing, result }

/// Drives the Analyze tab: pick/record a jump clip → mark takeoff/landing →
/// a brief "processing" beat → the result dashboard. The headline number
/// (EST. VERT) comes from the pure, tested flight-time core; the four
/// Bounce/Power/Control/Form scores need pose detection (not built yet — see
/// CLAUDE.md), so the result screen shows them locked rather than fabricated.
class AnalyzeFlow extends StatefulWidget {
  final OnboardingProfile profile;
  final JumpLogStore jumpLogStore;

  const AnalyzeFlow({
    super.key,
    required this.profile,
    required this.jumpLogStore,
  });

  @override
  State<AnalyzeFlow> createState() => _AnalyzeFlowState();
}

class _AnalyzeFlowState extends State<AnalyzeFlow> {
  _Step _step = _Step.source;
  File? _video;
  VideoAttemptType _attemptType = VideoAttemptType.jumpAttempt;
  JumpResult? _result;
  JumpTrend? _trend;
  JumpDetectionDiagnostics _diagnostics = JumpDetectionDiagnostics.empty;

  void _onVideoSelected(File video, VideoAttemptType attemptType) {
    setState(() {
      _video = video;
      _attemptType = attemptType;
      _step = _Step.processing;
    });
  }

  void _onDetected(JumpDetectionDiagnostics diagnostics) {
    setState(() => _diagnostics = diagnostics);
    final measurement = diagnostics.result;
    if (measurement == null) {
      // Auto-detection couldn't find a clear jump — fall back to manual
      // marking rather than dead-ending the user.
      setState(() => _step = _Step.mark);
      return;
    }
    _finishWithMeasurement(measurement);
  }

  void _onMarked(JumpMeasurement measurement) =>
      _finishWithMeasurement(measurement);

  Future<void> _finishWithMeasurement(JumpMeasurement measurement) async {
    final assessment = VertAssessment(
      heightInches: widget.profile.heightInches,
      ageYears: widget.profile.ageYears,
      hops: widget.profile.hopsLevel,
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
      _step = _Step.result;
    });
  }

  void _reset() => setState(() {
        _video = null;
        _attemptType = VideoAttemptType.jumpAttempt;
        _result = null;
        _trend = null;
        _diagnostics = JumpDetectionDiagnostics.empty;
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
        return SourceScreen(onVideoSelected: _onVideoSelected);
      case _Step.processing:
        return ProcessingScreen(video: _video!, onDetected: _onDetected);
      case _Step.mark:
        return MarkJumpScreen(
          video: _video!,
          onMarked: _onMarked,
          onCancel: _reset,
          isFallback: true,
        );
      case _Step.result:
        return JumpResultScreen(
          result: _result!,
          trend: _trend,
          diagnostics: _diagnostics,
          attemptType: _attemptType,
          onAnalyzeAnother: _reset,
        );
    }
  }
}
