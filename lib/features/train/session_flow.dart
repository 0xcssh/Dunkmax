import 'package:flutter/material.dart';

import '../../core/models/training_program.dart';
import '../../core/models/workout_session.dart';
import '../../core/training_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../services/workout_session_store.dart';
import 'screens/log_exercise_screen.dart';
import 'screens/session_complete_screen.dart';
import 'screens/warmup_screen.dart';

enum _Step { warmup, exercise, complete }

/// Drives one training session: warm-up → per-exercise set logging (one
/// screen per exercise) → a summary, then persists a [WorkoutSession] and
/// pops back to the TRAIN tab.
///
/// The day trained is resolved here, from [TrainingSchedule], so the session
/// always runs the **progressed** prescription for the week [sessionNumber]
/// falls in (week 3's Power Day carries more sets than week 1's) rather than
/// the raw authored base — no caller can accidentally pass the wrong one.
class SessionFlow extends StatefulWidget {
  final TrainingProgram program;
  final int sessionNumber;
  final WorkoutSessionStore sessionStore;

  const SessionFlow({
    super.key,
    required this.program,
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

  late final TrainingSchedule _schedule = TrainingSchedule(widget.program);

  /// Resolved once so the prescription can't shift mid-session.
  late final ProgramDay _day =
      _schedule.prescriptionForSession(widget.sessionNumber);

  int get _week => _schedule.weekOfSession(widget.sessionNumber);

  void _startExercises() => setState(() => _step = _Step.exercise);

  void _onExerciseLogged(LoggedExercise logged) {
    setState(() {
      _logged.add(logged);
      if (_exerciseIndex + 1 < _day.exercises.length) {
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
            focus: _day.focus,
            warmUp: _day.warmUp,
            weekLabel: AppLocalizations.of(context).trainPositionLabel(
              _week,
              _schedule.dayInWeekOfSession(widget.sessionNumber),
              _schedule.sessionsPerWeek,
            ),
            isDeload: _schedule.isDeloadWeek(_week),
            onStart: _startExercises,
            onCancel: () => Navigator.of(context).pop(false),
          ),
        _Step.exercise => LogExerciseScreen(
            // Keyed by index so Flutter creates a fresh State per exercise
            // instead of reusing the previous exercise's — without this, the
            // set-validation flags (and text controllers) from exercise N
            // carried over to exercise N+1, showing every set as already
            // "DONE" the moment the new exercise loaded.
            key: ValueKey(_exerciseIndex),
            exercise: _day.exercises[_exerciseIndex],
            exerciseIndex: _exerciseIndex,
            totalExercises: _day.exercises.length,
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
