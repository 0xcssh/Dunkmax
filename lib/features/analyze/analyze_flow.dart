import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/jump_result.dart';
import '../../core/models/jump_measurement.dart';
import '../../core/models/onboarding_profile.dart';
import '../../core/vert_assessment.dart';
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

  const AnalyzeFlow({super.key, required this.profile});

  @override
  State<AnalyzeFlow> createState() => _AnalyzeFlowState();
}

class _AnalyzeFlowState extends State<AnalyzeFlow> {
  _Step _step = _Step.source;
  File? _video;
  JumpResult? _result;

  void _onVideoSelected(File video) {
    setState(() {
      _video = video;
      _step = _Step.mark;
    });
  }

  void _onMarked(JumpMeasurement measurement) {
    final assessment = VertAssessment(
      heightInches: widget.profile.heightInches,
      ageYears: widget.profile.ageYears,
      hops: widget.profile.hopsLevel,
    );
    setState(() {
      _result = JumpResult(measurement: measurement, assessment: assessment);
      _step = _Step.processing;
    });
  }

  void _onProcessed() => setState(() => _step = _Step.result);

  void _reset() => setState(() {
        _video = null;
        _result = null;
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
      case _Step.mark:
        return MarkJumpScreen(
          video: _video!,
          onMarked: _onMarked,
          onCancel: _reset,
        );
      case _Step.processing:
        return ProcessingScreen(onDone: _onProcessed);
      case _Step.result:
        return JumpResultScreen(result: _result!, onAnalyzeAnother: _reset);
    }
  }
}
