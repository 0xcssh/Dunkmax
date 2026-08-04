import 'package:flutter/material.dart';

import '../../core/models/training_program.dart';
import '../../core/models/workout_session.dart';
import '../../services/workout_session_store.dart';
import 'screens/log_exercise_screen.dart';
import 'screens/session_complete_screen.dart';
import 'screens/warmup_screen.dart';

enum _Step { warmup, exercise, complete }

/// Drives one training session: warm-up → per-exercise set logging (one
/// screen per exercise) → a summary, then persists a [WorkoutSession] and
/// pops back to the TRAIN tab.
class SessionFlow extends StatefulWidget {
  final TrainingProgram program;
  final ProgramDay day;
  final int sessionNumber;
  final WorkoutSessionStore sessionStore;

  const SessionFlow({
    super.key,
    required this.program,
    required this.day,
    required this.sessionNumber,
    required this.sessionStore,
  });

  @override
  State<SessionFlow> createState() => _SessionFlowState();
}

class _SessionFlowState extends State<SessionFlow> {
  _Step _step = _Step.warmup;
  int _exerciseIndex = 0;
  final List<LoggedExercise> _logged = [];

  void _startExercises() => setState(() => _step = _Step.exercise);

  void _onExerciseLogged(LoggedExercise logged) {
    setState(() {
      _logged.add(logged);
      if (_exerciseIndex + 1 < widget.day.exercises.length) {
        _exerciseIndex++;
      } else {
        _step = _Step.complete;
      }
    });
  }

  Future<void> _saveAndFinish() async {
    await widget.sessionStore.addSession(WorkoutSession(
      programId: widget.program.id,
      sessionNumber: widget.sessionNumber,
      completedAt: DateTime.now(),
      exercises: _logged,
    ));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (_step) {
        _Step.warmup => WarmupScreen(
            focus: widget.day.focus,
            warmUp: widget.day.warmUp,
            onStart: _startExercises,
            onCancel: () => Navigator.of(context).pop(false),
          ),
        _Step.exercise => LogExerciseScreen(
            exercise: widget.day.exercises[_exerciseIndex],
            exerciseIndex: _exerciseIndex,
            totalExercises: widget.day.exercises.length,
            onLogged: _onExerciseLogged,
          ),
        _Step.complete => SessionCompleteScreen(
            loggedExercises: _logged,
            onFinish: _saveAndFinish,
          ),
      },
    );
  }
}
