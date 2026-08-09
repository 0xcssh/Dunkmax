import 'models/training_program.dart';

/// Turns "how many sessions have I completed" + a [TrainingProgram] into
/// "what exactly do I train today" — week number, day-of-week placement,
/// rest days, deload weeks and the progressed exercise prescription.
///
/// Pure Dart, no Flutter imports, so every rule below is unit-testable and
/// the UI stays a thin renderer of what this returns.
///
/// ## The three rules, stated plainly
///
/// **1. Rest days.** A week is 7 calendar days. The program's
/// `sessionsPerWeek` training days are spread as evenly as the week allows
/// (weekday `1 + (i * 7) ~/ n` for the i-th session), the remaining days are
/// rest. 3/week lands on Mon/Wed/Fri, 2/week on Mon/Thu — never a block of
/// back-to-back days followed by a long empty tail. The spacing between
/// consecutive training days is always `7 ~/ n` or `(7 ~/ n) + 1` days.
///
/// **2. Progressive overload.** Plain linear progression on **sets**: each
/// build week adds one set to every exercise of the authored day, so week 3's
/// Power Day is the authored day plus two sets per exercise. Each completed
/// 4-week block also raises the block's opening volume by one set, so the
/// program keeps climbing rather than resetting. Everything is capped:
/// at most [maxAddedSets] sets above the authored base, and never more than
/// [maxSetsPerExercise] sets in total.
///
/// Reps are deliberately **not** progressed. The catalog's rep labels are
/// free-form ("8 reps/leg", "20m", "30 sec") — incrementing them would mean
/// guessing at units, and inventing a percentage scheme would be a
/// pseudo-scientific claim this app has no basis for. Sets are unambiguous.
///
/// **3. Deload.** Every 4th week (4, 8, 12 …) is a deload: volume drops to
/// one set *below* that block's opening volume — always clearly lighter than
/// the week before it. Exception: the program's **final** week is never a
/// deload. A program should end on its peak week (that's when the athlete
/// re-tests their vertical), not taper into nothing, so a final week that
/// would land on the deload slot is promoted to a build week instead.
class TrainingSchedule {
  final TrainingProgram program;

  const TrainingSchedule(this.program);

  /// Calendar days in a training week.
  static const int daysInWeek = 7;

  /// Deload cadence: the last week of every block of this size is lighter.
  static const int deloadEveryWeeks = 4;

  /// Hard cap on how far above the authored base volume progression goes.
  static const int maxAddedSets = 3;

  /// Absolute per-exercise ceiling, so a heavy authored day (6 sets) can't
  /// progress into an unrealistic amount of work.
  static const int maxSetsPerExercise = 8;

  /// Training days per week, clamped to a real week.
  int get sessionsPerWeek => program.sessionsPerWeek.clamp(0, daysInWeek);

  /// Weeks in the program, at least one.
  int get weeks => program.weeks < 1 ? 1 : program.weeks;

  /// Weekdays (1 = Monday … 7 = Sunday, matching [DateTime.monday]) that are
  /// training days for a program running [sessionsPerWeek] sessions a week.
  static List<int> trainingWeekdaysFor(int sessionsPerWeek) {
    final n = sessionsPerWeek.clamp(0, daysInWeek);
    return [for (var i = 0; i < n; i++) 1 + (i * daysInWeek) ~/ n];
  }

  /// This program's training weekdays.
  List<int> get trainingWeekdays => trainingWeekdaysFor(program.sessionsPerWeek);

  /// 1-based week containing the [sessionNumber]-th session of the program.
  int weekOfSession(int sessionNumber) {
    final s = sessionNumber < 1 ? 1 : sessionNumber;
    if (sessionsPerWeek < 1) return 1;
    return ((s - 1) ~/ sessionsPerWeek) + 1;
  }

  /// 1-based position of the [sessionNumber]-th session inside its week
  /// (1 … [sessionsPerWeek]).
  int dayInWeekOfSession(int sessionNumber) {
    final s = sessionNumber < 1 ? 1 : sessionNumber;
    if (sessionsPerWeek < 1) return 1;
    return ((s - 1) % sessionsPerWeek) + 1;
  }

  /// Global 1-based session number for a (week, dayInWeek) pair.
  int sessionNumberAt({required int week, required int dayInWeek}) {
    final w = week < 1 ? 1 : week;
    final d = dayInWeek < 1 ? 1 : dayInWeek;
    return (w - 1) * sessionsPerWeek + d;
  }

  /// Whether [week] is a deload week. The final week of the program never is
  /// (see the class doc).
  bool isDeloadWeek(int week) {
    final w = week < 1 ? 1 : week;
    if (w >= weeks) return false;
    return w % deloadEveryWeeks == 0;
  }

  /// Sets added to (or, on a deload, removed from) the authored base for
  /// [week]. Clamped to [-1, maxAddedSets].
  int addedSetsForWeek(int week) {
    final w = week < 1 ? 1 : week;
    final blockIndex = (w - 1) ~/ deloadEveryWeeks;
    final positionInBlock = (w - 1) % deloadEveryWeeks;
    final int added;
    if (isDeloadWeek(w)) {
      // One set below this block's opening volume.
      added = blockIndex - 1;
    } else {
      // A final week promoted out of the deload slot trains at the block's
      // last build level (its peak).
      final buildPosition = positionInBlock == deloadEveryWeeks - 1
          ? deloadEveryWeeks - 2
          : positionInBlock;
      added = blockIndex + buildPosition;
    }
    return added.clamp(-1, maxAddedSets);
  }

  /// Progressed set count for an exercise authored with [baseSets] in [week].
  int setsFor({required int baseSets, required int week}) {
    final base = baseSets < 1 ? 1 : baseSets;
    return (base + addedSetsForWeek(week)).clamp(1, maxSetsPerExercise);
  }

  /// The authored day for a session, with every exercise's set count
  /// progressed for the week that session falls in.
  ///
  /// Throws a [StateError] if the program has no authored days — a training
  /// day is never empty.
  ProgramDay prescriptionForSession(int sessionNumber) {
    final base = program.dayFor(sessionNumber);
    return _progress(base, weekOfSession(sessionNumber));
  }

  /// The progressed prescription for a (week, dayInWeek) pair.
  ProgramDay prescriptionFor({required int week, required int dayInWeek}) =>
      prescriptionForSession(
        sessionNumberAt(week: week, dayInWeek: dayInWeek),
      );

  ProgramDay _progress(ProgramDay base, int week) {
    if (base.exercises.isEmpty) {
      throw StateError(
        'ProgramDay "${base.focus}" of program "${program.id}" has no exercises',
      );
    }
    return ProgramDay(
      day: base.day,
      focus: base.focus,
      warmUp: base.warmUp,
      exercises: [
        for (final exercise in base.exercises)
          // copyWith, not a fresh Exercise: progression only touches the set
          // count, and everything else (equipment, a home substitution the
          // catalog applied, media) has to survive the rewrite untouched.
          exercise.copyWith(
            sets: setsFor(baseSets: exercise.sets, week: week),
          ),
      ],
    );
  }

  /// The full 7-day layout of [week], training days and rest days alike.
  ///
  /// [completedSessions] (sessions already logged for this program) marks the
  /// days that are behind the athlete, so the UI can render the week strip.
  TrainingWeek weekAt(int week, {int completedSessions = 0}) {
    final w = week.clamp(1, weeks);
    final deload = isDeloadWeek(w);
    final weekdays = trainingWeekdays;
    final days = <ScheduledDay>[];

    for (var weekday = 1; weekday <= daysInWeek; weekday++) {
      final index = weekdays.indexOf(weekday);
      if (index < 0) {
        days.add(ScheduledDay.rest(week: w, weekday: weekday, isDeload: deload));
        continue;
      }
      final dayInWeek = index + 1;
      final sessionNumber = sessionNumberAt(week: w, dayInWeek: dayInWeek);
      days.add(ScheduledDay.training(
        week: w,
        weekday: weekday,
        isDeload: deload,
        dayInWeek: dayInWeek,
        sessionNumber: sessionNumber,
        day: prescriptionForSession(sessionNumber),
        isCompleted: sessionNumber <= completedSessions,
      ));
    }

    return TrainingWeek(weekNumber: w, isDeload: deload, days: days);
  }

  /// What the athlete should see right now, given how many sessions of this
  /// program are already persisted.
  ///
  /// [restToday] is the caller's answer to "has this athlete already trained
  /// today?" — the schedule places rest days in the week, but only the app
  /// knows the calendar. When true the returned plan is flagged as a rest
  /// day; the next session is still resolved so the UI can offer it anyway.
  TodayPlan today({required int completedSessions, bool restToday = false}) {
    final done = completedSessions < 0 ? 0 : completedSessions;
    final total = program.totalSessions;
    final isComplete = total > 0 && done >= total;
    final sessionNumber = total > 0 ? (done + 1).clamp(1, total) : done + 1;
    final week = weekOfSession(sessionNumber);
    final dayInWeek = dayInWeekOfSession(sessionNumber);

    return TodayPlan(
      week: week,
      totalWeeks: weeks,
      dayInWeek: dayInWeek,
      sessionsPerWeek: sessionsPerWeek,
      sessionNumber: sessionNumber,
      weekday: _weekdayFor(dayInWeek),
      isDeloadWeek: isDeloadWeek(week),
      isRestDay: restToday && !isComplete,
      isProgramComplete: isComplete,
      day: prescriptionForSession(sessionNumber),
    );
  }

  int _weekdayFor(int dayInWeek) {
    final weekdays = trainingWeekdays;
    if (weekdays.isEmpty) return 1;
    final index = (dayInWeek - 1).clamp(0, weekdays.length - 1);
    return weekdays[index];
  }
}

/// One calendar day of a scheduled week — either a training day carrying a
/// fully progressed [ProgramDay], or a rest day.
class ScheduledDay {
  /// 1-based week within the program.
  final int week;

  /// 1 = Monday … 7 = Sunday (matches [DateTime.weekday]).
  final int weekday;

  final bool isRest;

  /// True when this day sits in a deload week (rest days included, so the
  /// UI can tint the whole strip).
  final bool isDeload;

  /// 1-based position among the week's training days. Null on a rest day.
  final int? dayInWeek;

  /// Global 1-based session number. Null on a rest day.
  final int? sessionNumber;

  /// The progressed prescription. Null on a rest day.
  final ProgramDay? day;

  /// Whether this session is already logged.
  final bool isCompleted;

  const ScheduledDay.rest({
    required this.week,
    required this.weekday,
    required this.isDeload,
  })  : isRest = true,
        dayInWeek = null,
        sessionNumber = null,
        day = null,
        isCompleted = false;

  const ScheduledDay.training({
    required this.week,
    required this.weekday,
    required this.isDeload,
    required int this.dayInWeek,
    required int this.sessionNumber,
    required ProgramDay this.day,
    required this.isCompleted,
  }) : isRest = false;

  bool get isTraining => !isRest;

  /// "MON", "TUE" … for the week strip.
  String get weekdayLabel => const [
        'MON',
        'TUE',
        'WED',
        'THU',
        'FRI',
        'SAT',
        'SUN',
      ][(weekday - 1).clamp(0, 6)];
}

/// A program week: seven [ScheduledDay]s, some training, some rest.
class TrainingWeek {
  final int weekNumber;
  final bool isDeload;
  final List<ScheduledDay> days;

  const TrainingWeek({
    required this.weekNumber,
    required this.isDeload,
    required this.days,
  });

  List<ScheduledDay> get trainingDays =>
      days.where((d) => d.isTraining).toList();

  List<ScheduledDay> get restDays => days.where((d) => d.isRest).toList();
}

/// The resolved "what am I doing today" view handed to the TRAIN tab.
class TodayPlan {
  final int week;
  final int totalWeeks;

  /// 1-based position among the week's training days.
  final int dayInWeek;
  final int sessionsPerWeek;

  /// Global 1-based session number this plan describes.
  final int sessionNumber;

  /// Weekday (1 = Monday … 7 = Sunday) this session is scheduled on.
  final int weekday;

  final bool isDeloadWeek;

  /// True when the athlete has already trained today — the scheduled
  /// recovery state, not a missing session.
  final bool isRestDay;

  final bool isProgramComplete;

  /// The progressed prescription for [sessionNumber].
  final ProgramDay day;

  const TodayPlan({
    required this.week,
    required this.totalWeeks,
    required this.dayInWeek,
    required this.sessionsPerWeek,
    required this.sessionNumber,
    required this.weekday,
    required this.isDeloadWeek,
    required this.isRestDay,
    required this.isProgramComplete,
    required this.day,
  });

  /// "WEEK 2 · DAY 2 OF 3"
  String get positionLabel => 'WEEK $week · DAY $dayInWeek OF $sessionsPerWeek';
}
