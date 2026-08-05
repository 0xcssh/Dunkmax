/// A single plyometric / strength drill inside a program day.
class Exercise {
  final String id;
  final String name;
  final int sets;
  final String repsLabel;

  /// Optional demo-clip URL, played before/while logging this exercise.
  /// Null for every exercise in the catalog today — no real clips are
  /// authored yet, so the UI shows an honest "coming soon" state rather
  /// than a broken or fabricated video.
  final String? videoUrl;

  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.repsLabel,
    this.videoUrl,
  });

  /// e.g. "5 sets × 6-8 reps"
  String get volumeLabel => '$sets sets × $repsLabel';
}
