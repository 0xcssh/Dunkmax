import 'package:flutter/material.dart';

import '../../../core/models/training_program.dart';
import '../../../theme/app_theme.dart';

/// A brief "assembling your program" beat between the quiz and the app.
/// Purely cosmetic — it just delays, then calls [onDone].
class BuildingPlanScreen extends StatefulWidget {
  final TrainingProgram program;
  final VoidCallback onDone;

  const BuildingPlanScreen({
    super.key,
    required this.program,
    required this.onDone,
  });

  @override
  State<BuildingPlanScreen> createState() => _BuildingPlanScreenState();
}

class _BuildingPlanScreenState extends State<BuildingPlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: DunkColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'BUILDING YOUR PLAN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Matching you to the ${widget.program.name}',
                textAlign: TextAlign.center,
                style: DunkTheme.onboardingSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
