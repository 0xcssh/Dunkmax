import 'package:flutter/material.dart';

import '../../../core/models/exercise.dart';
import '../../../core/models/workout_session.dart';
import '../../../theme/app_theme.dart';
import '../../shared/widgets/primary_button.dart';

/// Logs actual reps/weight for a single exercise's sets. One instance of
/// this screen is shown per exercise in [SessionFlow]; [onLogged] advances
/// to the next exercise (or to the completion summary on the last one).
class LogExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final ValueChanged<LoggedExercise> onLogged;

  const LogExerciseScreen({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.onLogged,
  });

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  late final List<TextEditingController> _repsControllers;
  late final List<TextEditingController> _weightControllers;

  @override
  void initState() {
    super.initState();
    final prefillReps =
        RegExp(r'\d+').firstMatch(widget.exercise.repsLabel)?.group(0) ?? '';
    _repsControllers = List.generate(
      widget.exercise.sets,
      (_) => TextEditingController(text: prefillReps),
    );
    _weightControllers = List.generate(
      widget.exercise.sets,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final c in _repsControllers) {
      c.dispose();
    }
    for (final c in _weightControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final sets = <LoggedSet>[
      for (var i = 0; i < widget.exercise.sets; i++)
        LoggedSet(
          setNumber: i + 1,
          reps: int.tryParse(_repsControllers[i].text) ?? 0,
          weightLbs: double.tryParse(_weightControllers[i].text),
        ),
    ];
    widget.onLogged(LoggedExercise(
      exerciseId: widget.exercise.id,
      exerciseName: widget.exercise.name,
      sets: sets,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.exerciseIndex + 1 == widget.totalExercises;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXERCISE ${widget.exerciseIndex + 1}/${widget.totalExercises}',
              style: const TextStyle(
                color: DunkColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.exercise.name, style: DunkTheme.onboardingTitle),
            const SizedBox(height: 6),
            Text(widget.exercise.volumeLabel, style: DunkTheme.onboardingSubtitle),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: widget.exercise.sets,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _SetRow(
                  setNumber: i + 1,
                  repsController: _repsControllers[i],
                  weightController: _weightControllers[i],
                ),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: isLast ? 'FINISH SESSION' : 'NEXT EXERCISE',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final TextEditingController repsController;
  final TextEditingController weightController;

  const _SetRow({
    required this.setNumber,
    required this.repsController,
    required this.weightController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SET $setNumber',
            style: const TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: repsController,
                  hintText: 'reps',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: weightController,
                  hintText: 'lbs (optional)',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;

  const _NumberField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: DunkColors.textTertiary),
        filled: true,
        fillColor: DunkColors.surfaceRaised,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DunkColors.stroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DunkColors.stroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: DunkColors.primary),
        ),
      ),
    );
  }
}
