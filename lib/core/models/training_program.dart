import 'exercise.dart';

/// One training day within a program: an ordered list of exercises.
class ProgramDay {
  /// 1-based day number across the whole program.
  final int day;
  final List<Exercise> exercises;

  const ProgramDay({required this.day, required this.exercises});
}

/// A multi-week jump program (the "Reactive Power Program" and friends).
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

  /// The exercises to show for [day] (1-based). Falls back to the first
  /// sample day when a specific day isn't authored yet.
  ProgramDay dayFor(int day) {
    for (final d in sampleDays) {
      if (d.day == day) return d;
    }
    return sampleDays.first;
  }
}
