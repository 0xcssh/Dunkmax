import 'package:flutter/material.dart';

import '../../../core/models/exercise.dart';
import '../../../core/models/training_program.dart';
import '../../../core/program_progress.dart';
import '../../../theme/app_theme.dart';

/// The TRAIN tab: enrolled program header, today's exercises, and a live
/// progress card. Completing a session increments progress through the pure
/// [ProgramProgress] model so the numbers on screen come straight from core.
class TrainTab extends StatefulWidget {
  final TrainingProgram program;

  const TrainTab({super.key, required this.program});

  @override
  State<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends State<TrainTab> {
  int _completed = 0;

  int get _currentDay =>
      (_completed + 1).clamp(1, widget.program.totalSessions);

  void _completeSession() {
    setState(() {
      if (_completed < widget.program.totalSessions) _completed++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final progress = ProgramProgress(
      totalSessions: program.totalSessions,
      completedSessions: _completed,
    );
    final today = program.dayFor(_currentDay);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: DunkColors.primary,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'TRAIN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _EnrolledCard(program: program, currentDay: _currentDay),
          const SizedBox(height: 16),
          _TodaysExercises(exercises: today.exercises),
          const SizedBox(height: 16),
          _ProgressCard(progress: progress),
          const SizedBox(height: 20),
          _CompleteButton(
            done: progress.isComplete,
            onTap: progress.isComplete ? null : _completeSession,
          ),
        ],
      ),
    );
  }
}

class _EnrolledCard extends StatelessWidget {
  final TrainingProgram program;
  final int currentDay;

  const _EnrolledCard({required this.program, required this.currentDay});

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
          const Text(
            'ENROLLED PROGRAM',
            style: TextStyle(
              color: DunkColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            program.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            program.durationLabel(currentDay: currentDay),
            style: const TextStyle(color: DunkColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TodaysExercises extends StatelessWidget {
  final List<Exercise> exercises;

  const _TodaysExercises({required this.exercises});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S EXERCISES",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DunkColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${exercises.length} exercises',
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < exercises.length; i++) ...[
            if (i > 0) const Divider(color: DunkColors.stroke, height: 20),
            _ExerciseRow(exercise: exercises[i]),
          ],
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DunkColors.surfaceRaised,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.directions_run, color: DunkColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                exercise.volumeLabel,
                style: const TextStyle(
                  color: DunkColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgramProgress progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: DunkColors.primary, size: 18),
              SizedBox(width: 8),
              Text(
                'PROGRAM PROGRESS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(
                value: '${progress.completedSessions}',
                label: 'COMPLETED',
                color: DunkColors.primary,
              ),
              _Stat(
                value: '${progress.remaining}',
                label: 'REMAINING',
                color: Colors.white,
              ),
              _Stat(
                value: '${progress.percentComplete}%',
                label: 'COMPLETE',
                color: DunkColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.fraction,
              minHeight: 8,
              backgroundColor: DunkColors.surfaceRaised,
              valueColor: const AlwaysStoppedAnimation(DunkColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: DunkColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CompleteButton extends StatelessWidget {
  final bool done;
  final VoidCallback? onTap;

  const _CompleteButton({required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: done ? null : DunkColors.primaryGradient,
            color: done ? DunkColors.surface : null,
            borderRadius: BorderRadius.circular(16),
            border: done ? Border.all(color: DunkColors.stroke) : null,
          ),
          child: Text(
            done ? 'PROGRAM COMPLETE' : "COMPLETE TODAY'S SESSION",
            style: TextStyle(
              color: done ? DunkColors.textSecondary : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
