/// Progress through a program's sessions. Pure value type — the "PROGRAM
/// PROGRESS" card reads [completed]/[remaining]/[percentComplete] directly.
class ProgramProgress {
  final int totalSessions;
  final int completedSessions;

  const ProgramProgress({
    required this.totalSessions,
    required this.completedSessions,
  })  : assert(totalSessions >= 0),
        assert(completedSessions >= 0);

  /// Never negative even if completed somehow exceeds total (defensive).
  int get remaining {
    final left = totalSessions - completedSessions;
    return left < 0 ? 0 : left;
  }

  /// Fraction in [0, 1]. Zero-total programs report 0 rather than dividing.
  double get fraction {
    if (totalSessions <= 0) return 0;
    final f = completedSessions / totalSessions;
    if (f < 0) return 0;
    if (f > 1) return 1;
    return f;
  }

  /// Whole-percent value shown as "N% COMPLETE".
  int get percentComplete => (fraction * 100).round();

  bool get isComplete => totalSessions > 0 && completedSessions >= totalSessions;
}
