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

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    JumpMeasurement? result;
    try {
      final samples = await extractMotionSamples(widget.video);
      result = JumpAutoDetector.detect(samples);
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    widget.onDetected(result);
  }

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                color: DunkColors.primary,
                strokeWidth: 4,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'ANALYZING YOUR JUMP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Finding your takeoff and landing…',
              style: DunkTheme.onboardingSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}
