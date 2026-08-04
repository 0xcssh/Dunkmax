import 'exercise.dart';

/// One training day within a program: an ordered list of exercises.
class ProgramDay {
  /// 1-based day number across the whole program.
  final int day;

  /// Short label for the day's training emphasis (e.g. "Power", "Strength",
  /// "Speed").
  final String focus;

  /// One-line warm-up prescription shown before the day's exercises.
  final String warmUp;

  final List<Exercise> exercises;

  const ProgramDay({
    required this.day,
    required this.focus,
    required this.warmUp,
    required this.exercises,
  });
}

/// A multi-week jump program (the "Reactive Power Program" and friends).
///
/// [sampleDays] is a genuine rotation — e.g. a 3-day A/B/C split — that
/// repeats every N sessions for the life of the program, not a single
/// fallback day.
///
/// [totalSessions] is the denominator for progress: weeks × sessions/week,
/// computed once at construction so the UI never re-derives it.
class TrainingProgram {
  final String id;
  final String name;
  final int weeks;
  final int sessionsPerWeek;
  final List<ProgramDay> sampleDays;

  const TrainingProgram({
    required this.id,
    required this.name,
    required this.weeks,
    required this.sessionsPerWeek,
    required this.sampleDays,
  });

  int get totalSessions => weeks * sessionsPerWeek;

  /// "8 WEEKS • Day 1" style label. [currentDay] is 1-based.
  String durationLabel({int currentDay = 1}) =>
      '$weeks WEEKS • Day $currentDay';

  /// The day to show for the [sessionNumber]-th session (1-based), rotating
  /// through [sampleDays] via modulo so the split repeats indefinitely.
  ProgramDay dayFor(int sessionNumber) {
    if (sampleDays.isEmpty) {
      throw StateError('TrainingProgram "$id" has no authored days');
    }
    final index = (sessionNumber - 1) % sampleDays.length;
    return sampleDays[index];
  }
}
