import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// A brief "crunching the numbers" beat between marking the jump and seeing
/// the result — the math itself is instant, but a flash cut feels cheap.
class ProcessingScreen extends StatefulWidget {
  final Future<void> Function() onDone;

  const ProcessingScreen({super.key, required this.onDone});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              'Measuring hang time…',
              style: DunkTheme.onboardingSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}
