/// A single plyometric / strength drill inside a program day.
class Exercise {
  final String id;
  final String name;
  final int sets;
  final String repsLabel;

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.repsLabel,
  });

  /// e.g. "5 sets × 6-8 reps"
  String get volumeLabel => '$sets sets × $repsLabel';
}
