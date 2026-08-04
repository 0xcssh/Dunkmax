import 'dart:convert';

/// One logged set within an exercise — actual reps/weight performed, as
/// opposed to the [Exercise] model's prescription (target reps/sets).
class LoggedSet {
  final int setNumber; // 1-based
  final int reps;
  final double? weightLbs; // null = bodyweight / not entered
  const LoggedSet({required this.setNumber, required this.reps, this.weightLbs});

  Map<String, dynamic> toMap() => {
        'setNumber': setNumber,
        'reps': reps,
        'weightLbs': weightLbs,
      };

  static LoggedSet? fromMap(Map<String, dynamic> map) {
    final setNumber = map['setNumber'];
    final reps = map['reps'];
    if (setNumber is! int || reps is! int) return null;
    final rawWeight = map['weightLbs'];
    return LoggedSet(
      setNumber: setNumber,
      reps: reps,
      weightLbs: rawWeight is num ? rawWeight.toDouble() : null,
    );
  }
}

/// All sets logged for a single exercise within a session.
class LoggedExercise {
  final String exerciseId;
  final String exerciseName;
  final List<LoggedSet> sets;
  const LoggedExercise({required this.exerciseId, required this.exerciseName, required this.sets});

  int get totalReps => sets.fold(0, (sum, s) => sum + s.reps);

  Map<String, dynamic> toMap() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toMap()).toList(),
      };

  static LoggedExercise? fromMap(Map<String, dynamic> map) {
    final id = map['exerciseId'];
    final name = map['exerciseName'];
    if (id is! String || name is! String) return null;
    final rawSets = map['sets'];
    final sets = <LoggedSet>[];
    if (rawSets is List) {
      for (final s in rawSets) {
        if (s is Map<String, dynamic>) {
          final parsed = LoggedSet.fromMap(s);
          if (parsed != null) sets.add(parsed);
        }
      }
    }
    return LoggedExercise(exerciseId: id, exerciseName: name, sets: sets);
  }
}

/// One completed training session — the persisted unit of TRAIN history.
///
/// Distinct from the prescriptive `ProgramDay`/`Exercise` models: this is
/// what the athlete actually did (reps/weight entered while logging), tied
/// back to the program + slot it was performed against so progress can be
/// derived per-program later.
class WorkoutSession {
  final String programId; // matches TrainingProgram.id
  final int sessionNumber; // 1-based, position within the program
  final DateTime completedAt;
  final List<LoggedExercise> exercises;

  const WorkoutSession({
    required this.programId,
    required this.sessionNumber,
    required this.completedAt,
    required this.exercises,
  });

  Map<String, dynamic> toMap() => {
        'programId': programId,
        'sessionNumber': sessionNumber,
        'completedAt': completedAt.toIso8601String(),
        'exercises': exercises.map((e) => e.toMap()).toList(),
      };

  String toJson() => jsonEncode(toMap());

  static WorkoutSession? fromMap(Map<String, dynamic> map) {
    final programId = map['programId'];
    final sessionNumber = map['sessionNumber'];
    final completedAtRaw = map['completedAt'];
    if (programId is! String || sessionNumber is! int || completedAtRaw is! String) {
      return null;
    }
    final completedAt = DateTime.tryParse(completedAtRaw);
    if (completedAt == null) return null;
    final rawExercises = map['exercises'];
    final exercises = <LoggedExercise>[];
    if (rawExercises is List) {
      for (final e in rawExercises) {
        if (e is Map<String, dynamic>) {
          final parsed = LoggedExercise.fromMap(e);
          if (parsed != null) exercises.add(parsed);
        }
      }
    }
    return WorkoutSession(
      programId: programId,
      sessionNumber: sessionNumber,
      completedAt: completedAt,
      exercises: exercises,
    );
  }

  static WorkoutSession? fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}
