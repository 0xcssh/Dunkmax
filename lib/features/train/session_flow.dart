import 'package:flutter/material.dart';

import '../../core/models/training_program.dart';
import '../../core/models/workout_session.dart';
import '../../core/training_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../services/analytics.dart';
import '../../services/workout_session_store.dart';
import '../../theme/app_theme.dart';
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

  void _startExercises() {
    Analytics.track(
        AnalyticsEvent.sessionStarted, {'focus': _day.focus, 'week': _week});
    setState(() => _step = _Step.exercise);
  }

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

  /// True from the first tap on SAVE & FINISH. Without it a double tap saved
  /// the session twice and popped two routes.
  bool _saving = false;

  bool _confirmingDiscard = false;

  Future<void> _saveAndFinish() async {
    if (_saving) return;
    _saving = true;
    try {
      await widget.sessionStore.addSession(WorkoutSession(
        programId: widget.program.id,
        sessionNumber: widget.sessionNumber,
        completedAt: DateTime.now(),
        exercises: _logged,
      ));
      Analytics.track(AnalyticsEvent.sessionCompleted,
          {'focus': _day.focus, 'week': _week, 'exercises': _logged.length});
    } catch (_) {
      // Let the athlete try again rather than leaving the button dead.
      _saving = false;
      rethrow;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  /// Leaving is free during the warm-up — nothing has been logged yet. Past
  /// it, a stray back gesture would silently throw the whole session away, so
  /// every exit (system back, the log screen's close icon) asks first.
  bool get _canLeaveFreely => _step == _Step.warmup;

  Future<void> _confirmDiscard() async {
    if (_saving || _confirmingDiscard) return;
    _confirmingDiscard = true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DunkColors.surface,
        title: Text(l10n.sessionDiscardTitle,
            style: const TextStyle(color: Colors.white)),
        content: Text(
          l10n.sessionDiscardBody,
          style: const TextStyle(color: DunkColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.sessionDiscardKeep,
                style: const TextStyle(color: DunkColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.sessionDiscardConfirm,
                style: const TextStyle(color: DunkColors.primary)),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (discard != true || !mounted || _saving) return;
    Analytics.track(AnalyticsEvent.sessionDiscarded,
        {'focus': _day.focus, 'week': _week, 'logged': _logged.length});
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    // `canPop: false` also switches off the iOS back-swipe for this route,
    // which is why the log screen carries its own close icon.
    return PopScope(
      canPop: _canLeaveFreely,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: _buildStep(context),
    );
  }

  Widget _buildStep(BuildContext context) {
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
            onClose: _confirmDiscard,
          ),
        _Step.complete => SessionCompleteScreen(
            loggedExercises: _logged,
            onFinish: _saveAndFinish,
          ),
      },
    );
  }
}
