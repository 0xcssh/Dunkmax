import 'package:flutter/material.dart';

import '../../../core/exercise_library.dart';
import '../../../core/models/exercise.dart';
import '../../../core/models/training_program.dart';
import '../../../core/models/workout_session.dart';
import '../../../core/program_progress.dart';
import '../../../core/training_schedule.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/workout_session_store.dart';
import '../../../theme/app_theme.dart';
import '../../train/session_flow.dart';

/// The TRAIN tab: enrolled program header, the current week at a glance,
/// today's (progressed) exercises and a live progress card.
///
/// Everything on screen — week number, day-of-week placement, rest days,
/// deload flag, set counts — comes from the pure [TrainingSchedule] and
/// [ProgramProgress] models; this widget only renders them.
class TrainTab extends StatefulWidget {
  final TrainingProgram program;
  final WorkoutSessionStore sessionStore;

  const TrainTab({super.key, required this.program, required this.sessionStore});

  @override
  State<TrainTab> createState() => _TrainTabState();
}

class _TrainTabState extends State<TrainTab> {
  TrainingSchedule get _schedule => TrainingSchedule(widget.program);

  List<WorkoutSession> get _programSessions => widget.sessionStore.sessions
      .where((s) => s.programId == widget.program.id)
      .toList();

  /// Whether a session for this program was already logged today. The
  /// schedule lays out rest days; only the app knows the calendar, so this
  /// is the one calendar fact it feeds back in.
  bool _trainedToday(List<WorkoutSession> sessions) {
    final now = DateTime.now();
    return sessions.any((s) =>
        s.completedAt.year == now.year &&
        s.completedAt.month == now.month &&
        s.completedAt.day == now.day);
  }

  Future<void> _startSession(TodayPlan plan) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SessionFlow(
          program: widget.program,
          sessionNumber: plan.sessionNumber,
          sessionStore: widget.sessionStore,
        ),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final program = widget.program;
    final schedule = _schedule;
    final sessions = _programSessions;
    final completed = sessions.length;
    final progress = ProgramProgress(
      totalSessions: program.totalSessions,
      completedSessions: completed,
    );
    final plan = schedule.today(
      completedSessions: completed,
      restToday: _trainedToday(sessions),
    );
    final week = schedule.weekAt(plan.week, completedSessions: completed);

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
              Text(
                AppLocalizations.of(context).trainTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _EnrolledCard(program: program, plan: plan),
          const SizedBox(height: 16),
          _WeekStrip(week: week, todayWeekday: plan.weekday),
          const SizedBox(height: 16),
          if (plan.isRestDay)
            _RestDayCard(nextFocus: plan.day.focus)
          else
            _TodaysExercises(
              focus: plan.day.focus,
              warmUp: plan.day.warmUp,
              exercises: plan.day.exercises,
              isDeload: plan.isDeloadWeek,
            ),
          const SizedBox(height: 16),
          _ProgressCard(progress: progress),
          const SizedBox(height: 20),
          _CompleteButton(
            done: progress.isComplete,
            isRestDay: plan.isRestDay,
            onTap: progress.isComplete ? null : () => _startSession(plan),
          ),
        ],
      ),
    );
  }
}

class _EnrolledCard extends StatelessWidget {
  final TrainingProgram program;
  final TodayPlan plan;

  const _EnrolledCard({required this.program, required this.plan});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Built here rather than read off `plan.positionLabel`: that getter lives
    // in pure-Dart core, which has no access to translations.
    final position = l10n.trainPositionLabel(
      plan.week,
      plan.dayInWeek,
      plan.sessionsPerWeek,
    );
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
            children: [
              Expanded(
                child: Text(
                  l10n.trainEnrolledProgram,
                  style: const TextStyle(
                    color: DunkColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (plan.isDeloadWeek) const _DeloadPill(),
            ],
          ),
          const SizedBox(height: 6),
          // Program names come from the untranslated program catalog.
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
            l10n.trainProgramMeta(position, plan.totalWeeks),
            style: const TextStyle(color: DunkColors.textSecondary, fontSize: 13),
          ),
          if (plan.isDeloadWeek) ...[
            const SizedBox(height: 10),
            Text(
              l10n.trainDeloadExplainer,
              style: const TextStyle(
                color: DunkColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeloadPill extends StatelessWidget {
  const _DeloadPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: DunkColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DunkColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.trending_down, size: 13, color: DunkColors.primary),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).trainDeloadPill,
            style: const TextStyle(
              color: DunkColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// The week at a glance: seven chips, training days highlighted, rest days
/// explicitly labelled so the athlete can see the structure — and the
/// spacing between sessions — without opening anything.
class _WeekStrip extends StatelessWidget {
  final TrainingWeek week;
  final int todayWeekday;

  const _WeekStrip({required this.week, required this.todayWeekday});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .trainWeekNumber(week.weekNumber),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).trainWeekSummary(
                    week.trainingDays.length,
                    week.restDays.length,
                  ),
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final day in week.days)
                Expanded(
                  child: _DayChip(
                    day: day,
                    isToday: day.weekday == todayWeekday,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  final ScheduledDay day;
  final bool isToday;

  const _DayChip({required this.day, required this.isToday});

  @override
  Widget build(BuildContext context) {
    // Seven comma-separated short weekday names, Monday first — the core
    // `ScheduledDay.weekdayLabel` is English-only and can't be translated
    // there, so the index is used against the catalogue instead.
    final labels = AppLocalizations.of(context).weekdayLabels.split(',');
    final labelIndex = (day.weekday - 1).clamp(0, labels.length - 1);
    final Color background;
    final Color border;
    final Widget mark;

    if (day.isRest) {
      background = Colors.transparent;
      border = DunkColors.stroke;
      mark = const Icon(Icons.nightlight_round,
          size: 15, color: DunkColors.textTertiary);
    } else if (day.isCompleted) {
      background = DunkColors.primary;
      border = DunkColors.primary;
      mark = const Icon(Icons.check, size: 16, color: Colors.white);
    } else {
      background = DunkColors.surfaceRaised;
      border = isToday ? DunkColors.primary : DunkColors.stroke;
      mark = Icon(
        Icons.fitness_center,
        size: 15,
        color: isToday ? DunkColors.primary : DunkColors.textSecondary,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Text(
            labels[labelIndex],
            style: TextStyle(
              color: isToday && day.isTraining
                  ? DunkColors.primary
                  : DunkColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: border,
                width: isToday && day.isTraining ? 1.6 : 1,
              ),
            ),
            child: mark,
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the exercise list once a session has been logged today:
/// an explicit, deliberate rest state rather than a second session pretending
/// to be due.
class _RestDayCard extends StatelessWidget {
  final String nextFocus;

  const _RestDayCard({required this.nextFocus});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DunkColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DunkColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DunkColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.nightlight_round,
                    color: DunkColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainRestDayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.trainRestDaySubtitle,
                      style: const TextStyle(
                        color: DunkColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l10n.trainRestDayBody,
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.event_available,
                  size: 15, color: DunkColors.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.trainUpNext(nextFocus.toUpperCase()),
                  style: const TextStyle(
                    color: DunkColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodaysExercises extends StatelessWidget {
  final String focus;
  final String warmUp;
  final List<Exercise> exercises;
  final bool isDeload;

  const _TodaysExercises({
    required this.focus,
    required this.warmUp,
    required this.exercises,
    required this.isDeload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.trainTodaysExercises,
                style: const TextStyle(
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
                  l10n.trainExerciseCount(exercises.length),
                  style: const TextStyle(
                    color: DunkColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Both the focus and the warm-up text come from the untranslated
          // program catalog.
          Text(
            l10n.trainFocusAndWarmUp(focus.toUpperCase(), warmUp),
            style: const TextStyle(
              color: DunkColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (isDeload) ...[
            const SizedBox(height: 6),
            Text(
              l10n.trainDeloadVolumeNote,
              style: const TextStyle(color: DunkColors.primary, fontSize: 12),
            ),
          ],
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

/// The drill's own start-position frame, rather than a generic running figure
/// repeated down the list.
///
/// Falls back to the icon when a drill has no photo — one does: no entry in
/// the dataset is actually a wall sit, and illustrating one exercise with a
/// picture of another would be worse than an icon.
class _ExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseThumbnail({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final frames = ExerciseLibrary.guideForExercise(exercise)?.demoFrames;
    final radius = BorderRadius.circular(10);

    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DunkColors.surfaceRaised,
        borderRadius: radius,
      ),
      child: frames == null || frames.isEmpty
          ? const Icon(Icons.directions_run,
              color: DunkColors.primary, size: 22)
          : Image.asset(
              frames.first,
              fit: BoxFit.cover,
              // A missing asset must not break the session list.
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_run,
                color: DunkColors.primary,
                size: 22,
              ),
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
        _ExerciseThumbnail(exercise: exercise),
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
    final l10n = AppLocalizations.of(context);
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
          Row(
            children: [
              const Icon(Icons.show_chart, color: DunkColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.trainProgramProgress,
                style: const TextStyle(
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
                label: l10n.progressCompleted,
                color: DunkColors.primary,
              ),
              _Stat(
                value: '${progress.remaining}',
                label: l10n.progressRemaining,
                color: Colors.white,
              ),
              _Stat(
                value: l10n.progressPercent(progress.percentComplete),
                label: l10n.progressCompleteLabel,
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
  final bool isRestDay;
  final VoidCallback? onTap;

  const _CompleteButton({
    required this.done,
    required this.isRestDay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // On a rest day the next session stays reachable — the app recommends
    // recovery, it doesn't lock the athlete out.
    final l10n = AppLocalizations.of(context);
    final muted = done || isRestDay;
    final String label;
    if (done) {
      label = l10n.trainCtaProgramComplete;
    } else if (isRestDay) {
      label = l10n.trainCtaTrainAnyway;
    } else {
      label = l10n.trainCtaStartSession;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: muted ? null : DunkColors.primaryGradient,
            color: muted ? DunkColors.surface : null,
            borderRadius: BorderRadius.circular(16),
            border: muted
                ? Border.all(
                    color: isRestDay && !done
                        ? DunkColors.primary.withValues(alpha: 0.5)
                        : DunkColors.stroke,
                  )
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: done
                  ? DunkColors.textSecondary
                  : (isRestDay ? DunkColors.primary : Colors.white),
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
