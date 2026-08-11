/// What a drill needs before an athlete can perform it at all.
///
/// Deliberately coarse: the question the app has to answer is "can this be
/// done in a living room?", not "which brand of box". Anything other than
/// [Equipment.none] is unavailable to a home-only athlete and gets swapped
/// for a substitute (see `ExerciseLibrary.homeSubstituteId`).
enum Equipment {
  /// Bodyweight, or nothing beyond a floor and a wall.
  none,

  /// A plyo box, bench, step or equivalent raised surface to drop from or
  /// jump onto.
  box,

  /// A bench, chair or other stable surface used as a support (rear foot
  /// elevated, ankles anchored).
  bench,

  /// External load — barbell, dumbbells, weighted vest.
  weights;

  /// Short all-caps label for badges, e.g. "NO EQUIPMENT", "PLYO BOX".
  String get label {
    switch (this) {
      case Equipment.none:
        return 'NO EQUIPMENT';
      case Equipment.box:
        return 'PLYO BOX';
      case Equipment.bench:
        return 'BENCH';
      case Equipment.weights:
        return 'WEIGHTS';
    }
  }

  /// True for everything a home-only athlete may not have.
  bool get isRequired => this != Equipment.none;
}

/// A single plyometric / strength drill inside a program day.
class Exercise {
  final String id;
  final String name;
  final int sets;
  final String repsLabel;

  /// What the athlete needs to perform this drill. Required and explicit at
  /// every authoring site: an exercise that silently defaulted to "no
  /// equipment" would be prescribed to a home-only athlete who cannot do it.
  final Equipment equipment;

  /// When this exercise replaced another one (a home substitution), the id of
  /// the exercise it stands in for. Null when it is the authored drill.
  final String? substitutedForId;


  const Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.repsLabel,
    required this.equipment,
    this.substitutedForId,
  });

  /// True when this exercise was swapped in for an equipment-requiring one.
  bool get isSubstitution => substitutedForId != null;

  /// e.g. "5 sets × 6-8 reps"
  String get volumeLabel => '$sets sets × $repsLabel';

  Exercise copyWith({
    String? id,
    String? name,
    int? sets,
    String? repsLabel,
    Equipment? equipment,
    String? substitutedForId,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      repsLabel: repsLabel ?? this.repsLabel,
      equipment: equipment ?? this.equipment,
      substitutedForId: substitutedForId ?? this.substitutedForId,
    );
  }
}
