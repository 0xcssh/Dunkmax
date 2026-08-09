import 'models/exercise.dart';

/// The coaching content behind a drill: what it trains, how to do it, what
/// usually goes wrong, and what to do instead when the equipment isn't there.
///
/// Every claim here is a description of the movement itself. Nothing in this
/// file promises a number of inches, a percentage or a timeframe — the app
/// measures the athlete's vertical, it does not predict what a drill will do
/// to it.
class ExerciseGuide {
  /// Matches the id used in `ProgramCatalog`'s authored days.
  final String id;

  /// Display name, kept in sync with the authored exercise.
  final String name;

  /// One line: what it trains and why that matters for jumping.
  final String summary;

  /// Ordered execution steps, from set-up to finish.
  final List<String> steps;

  /// Two or three mistakes that show up most often on this drill.
  final List<String> commonMistakes;

  /// Primary muscles or the physical quality trained.
  final List<String> trains;

  final Equipment equipment;

  /// The closest drill that trains the same quality with no equipment.
  /// Non-null for every guide whose [equipment] is not [Equipment.none];
  /// null for drills that need nothing (they are their own home version).
  final String? homeSubstituteId;

  /// Optional real demo media. Both null for every drill today: no clips or
  /// photos have been filmed, and the app does not ship stand-ins that look
  /// like demonstrations. The written [steps] are the content.
  final String? demoVideoUrl;
  final String? demoImageAsset;

  const ExerciseGuide({
    required this.id,
    required this.name,
    required this.summary,
    required this.steps,
    required this.commonMistakes,
    required this.trains,
    required this.equipment,
    this.homeSubstituteId,
    this.demoVideoUrl,
    this.demoImageAsset,
  });

  bool get hasDemoMedia => demoVideoUrl != null || demoImageAsset != null;
}

/// Authored coaching content for every drill the catalog can prescribe,
/// plus the bodyweight substitutes it swaps in for a home-only athlete.
///
/// Pure Dart, no Flutter imports. `test/exercise_library_test.dart` pins the
/// invariants that keep this file and `program_catalog.dart` from drifting:
/// every prescribed id is present here, every equipment-requiring drill names
/// a substitute, and every substitute needs no equipment.
abstract class ExerciseLibrary {
  static const Map<String, ExerciseGuide> guides = {
    // ---------------------------------------------------------------- power
    'depth_jumps': ExerciseGuide(
      id: 'depth_jumps',
      name: 'Depth Jumps',
      summary:
          'Trains reactive strength — how fast you turn a landing back into '
          'a jump, which is the quality a one-step dunk approach lives on.',
      steps: [
        'Stand on the edge of a box, toes at the edge, arms free.',
        'Step off — do not jump off. Let gravity drop you.',
        'Land on the balls of both feet with stiff ankles and hips.',
        'Rebound straight up as fast as you can, reaching overhead.',
        'Land softly, reset, and take a full breath before the next rep.',
      ],
      commonMistakes: [
        'Jumping off the box instead of stepping off, which changes the drop '
            'height and the landing force.',
        'Sinking into a deep squat on landing — the ground contact should be '
            'short, not comfortable.',
        'Using a box so tall the rebound is slow and heavy; height is not the '
            'point, speed off the floor is.',
      ],
      trains: ['Reactive strength', 'Calves and Achilles', 'Quads', 'Glutes'],
      equipment: Equipment.box,
      homeSubstituteId: 'tuck_jumps',
    ),
    'box_jumps': ExerciseGuide(
      id: 'box_jumps',
      name: 'Box Jumps',
      summary:
          'Trains concentric jumping power with a soft landing, so you can '
          'practise full-effort take-offs without the landing impact.',
      steps: [
        'Stand a short step back from the box, feet about hip width.',
        'Dip into a quarter squat and swing both arms back.',
        'Drive through the floor and swing the arms up, jumping onto the box.',
        'Land quietly in a quarter squat with both feet fully on the surface.',
        'Step — do not jump — back down, and reset.',
      ],
      commonMistakes: [
        'Chasing box height by tucking the knees high instead of actually '
            'jumping higher.',
        'Jumping back down, which stacks landing impact rep after rep.',
        'Landing with the heels hanging off the edge of the box.',
      ],
      trains: ['Explosive hip and knee extension', 'Quads', 'Glutes'],
      equipment: Equipment.box,
      homeSubstituteId: 'squat_jumps',
    ),
    'weighted_box_jumps': ExerciseGuide(
      id: 'weighted_box_jumps',
      name: 'Weighted Box Jumps',
      summary:
          'A box jump against external load, shifting the drill towards force '
          'production rather than pure speed.',
      steps: [
        'Wear a light vest or hold light dumbbells at your sides.',
        'Set up a short step back from a box lower than your usual height.',
        'Dip into a quarter squat, then drive up onto the box.',
        'Land in a quarter squat with both feet flat on the surface.',
        'Step down under control and reset fully between reps.',
      ],
      commonMistakes: [
        'Keeping your normal box height once loaded — the box has to come '
            'down when the load goes up.',
        'Letting the load round the back on the dip.',
        'Rushing reps; loaded jumps need full recovery to stay fast.',
      ],
      trains: ['Maximal jumping force', 'Quads', 'Glutes', 'Hamstrings'],
      equipment: Equipment.weights,
      homeSubstituteId: 'squat_jumps',
    ),
    'squat_jumps': ExerciseGuide(
      id: 'squat_jumps',
      name: 'Squat Jumps',
      summary:
          'The plain, full-intent vertical jump — the movement the whole '
          'program is training, rehearsed under control.',
      steps: [
        'Stand with feet about hip to shoulder width.',
        'Dip to roughly a quarter squat, swinging both arms back.',
        'Jump straight up as high as you can, arms swinging overhead.',
        'Land on the balls of the feet, absorbing through ankles, knees, hips.',
        'Reset to a full stand before the next rep.',
      ],
      commonMistakes: [
        'Dipping too deep, which turns a fast jump into a slow squat.',
        'Leaving the arms out of it — the arm swing is part of the jump.',
        'Landing stiff-legged instead of absorbing through the whole leg.',
      ],
      trains: ['Jump power', 'Quads', 'Glutes', 'Calves'],
      equipment: Equipment.none,
    ),
    'weighted_squat_jumps': ExerciseGuide(
      id: 'weighted_squat_jumps',
      name: 'Weighted Squat Jumps',
      summary:
          'Squat jumps against light external load, biasing the jump towards '
          'strength while keeping the movement fast.',
      steps: [
        'Hold light dumbbells at your sides or wear a weighted vest.',
        'Stand with feet about hip to shoulder width, chest tall.',
        'Dip to a quarter squat and jump as high as the load allows.',
        'Land softly on both feet, absorbing through the whole leg.',
        'Stand fully, reset your breath, then repeat.',
      ],
      commonMistakes: [
        'Loading heavy enough that the jump slows down — if it looks like a '
            'squat, the load is wrong.',
        'Letting the shoulders round forward under the dumbbells.',
        'Grinding out long sets; quality drops fast on loaded jumps.',
      ],
      trains: ['Force production', 'Quads', 'Glutes', 'Trunk'],
      equipment: Equipment.weights,
      homeSubstituteId: 'squat_jumps',
    ),
    'tuck_jumps': ExerciseGuide(
      id: 'tuck_jumps',
      name: 'Tuck Jumps',
      summary:
          'Repeated fast jumps with a knee tuck, trained for short ground '
          'contacts — the bodyweight way to work reactive strength.',
      steps: [
        'Stand tall, feet about hip width, arms ready at your sides.',
        'Dip shallow and jump, pulling both knees towards your chest.',
        'Drop the feet back under you before landing.',
        'Land on the balls of both feet and rebound immediately.',
        'Keep the contacts short — quality over the number of reps.',
      ],
      commonMistakes: [
        'Tucking the knees but barely leaving the floor.',
        'Pausing between reps, which removes the reactive part of the drill.',
        'Landing heels-first with locked knees.',
      ],
      trains: ['Reactive strength', 'Calves', 'Quads', 'Hip flexors'],
      equipment: Equipment.none,
    ),
    'broad_jumps': ExerciseGuide(
      id: 'broad_jumps',
      name: 'Broad Jumps',
      summary:
          'A maximal horizontal jump, training the hip extension power that a '
          'running dunk approach converts into height.',
      steps: [
        'Stand behind a line, feet about hip width.',
        'Swing the arms back and hinge at the hips into a quarter squat.',
        'Jump forward as far as you can, driving the arms forward and up.',
        'Land on both feet with bent knees, chest over the toes.',
        'Walk back to the line and reset before the next rep.',
      ],
      commonMistakes: [
        'Jumping up rather than out — the drill is distance, not height.',
        'Landing with straight legs instead of absorbing the landing.',
        'Chaining reps back to back; each one should be from a dead stop.',
      ],
      trains: ['Horizontal power', 'Glutes', 'Hamstrings', 'Quads'],
      equipment: Equipment.none,
    ),
    // ------------------------------------------------------------- strength
    'bulgarian_split_squat_jumps': ExerciseGuide(
      id: 'bulgarian_split_squat_jumps',
      name: 'Bulgarian Split Squat Jumps',
      summary:
          'A single-leg jump with the rear foot elevated, exposing and '
          'training the weaker leg that a one-foot take-off depends on.',
      steps: [
        'Place the top of your rear foot on a bench behind you.',
        'Set the front foot far enough forward that the knee stays over the '
            'mid-foot at the bottom.',
        'Lower until the front thigh is around parallel, chest tall.',
        'Jump straight up off the front leg.',
        'Land on the same front foot, absorb, and go straight into the next '
            'rep. Finish all reps, then switch legs.',
      ],
      commonMistakes: [
        'Standing too close to the bench, which pushes the front knee far past '
            'the toes.',
        'Leaning the torso forward to make the rep easier.',
        'Pushing off the rear foot instead of loading the front leg.',
      ],
      trains: ['Single-leg power', 'Quads', 'Glutes', 'Balance'],
      equipment: Equipment.bench,
      homeSubstituteId: 'split_squat_jumps',
    ),
    'split_squat_jumps': ExerciseGuide(
      id: 'split_squat_jumps',
      name: 'Split Squat Jumps',
      summary:
          'A jumping lunge from the floor — the same single-leg power demand '
          'as the Bulgarian version, with nothing to set up.',
      steps: [
        'Step into a lunge: front foot flat, rear knee under or just behind '
            'the hip, both knees bent.',
        'Dip slightly, then jump straight up out of the lunge.',
        'Switch the legs in the air and land in the mirrored lunge.',
        'Absorb the landing with both legs bending together.',
        'Keep alternating, counting one rep per leg.',
      ],
      commonMistakes: [
        'Landing with a straight front leg, which sends the impact to the '
            'knee instead of the muscles.',
        'Letting the torso pitch forward over the front thigh.',
        'Taking a stance so short the rear knee slams down.',
      ],
      trains: ['Single-leg power', 'Quads', 'Glutes', 'Balance'],
      equipment: Equipment.none,
    ),
    'box_step_ups': ExerciseGuide(
      id: 'box_step_ups',
      name: 'Box Step-Ups',
      summary:
          'Slow, controlled single-leg strength — the base a single-leg jump '
          'is built on, without the impact of jumping.',
      steps: [
        'Face a box or step at about knee height.',
        'Place one whole foot on the surface, heel included.',
        'Drive through that heel to stand tall on top of the box.',
        'Keep the trailing leg passive — it is not there to push.',
        'Lower under control back to the floor. Finish the reps, then switch.',
      ],
      commonMistakes: [
        'Pushing off the back foot to launch up, so the working leg does '
            'little.',
        'Letting the knee collapse inward on the way up.',
        'Dropping back down instead of lowering under control.',
      ],
      trains: ['Single-leg strength', 'Quads', 'Glutes'],
      equipment: Equipment.box,
      homeSubstituteId: 'reverse_lunges',
    ),
    'reverse_lunges': ExerciseGuide(
      id: 'reverse_lunges',
      name: 'Reverse Lunges',
      summary:
          'Single-leg strength from the floor, loading the front leg the same '
          'way a step-up does with nothing to stand on.',
      steps: [
        'Stand tall, feet hip width, hands on the hips or in front of you.',
        'Step one foot straight back and lower until both knees are around '
            'ninety degrees.',
        'Keep the weight in the front heel and the chest upright.',
        'Drive through the front heel back to standing.',
        'Alternate legs, counting one rep per leg.',
      ],
      commonMistakes: [
        'Stepping back too short, which drives the front knee far past the '
            'toes.',
        'Letting the front knee travel inward.',
        'Leaning the chest forward to reach the floor faster.',
      ],
      trains: ['Single-leg strength', 'Quads', 'Glutes', 'Balance'],
      equipment: Equipment.none,
    ),
    'nordic_hamstring_curls': ExerciseGuide(
      id: 'nordic_hamstring_curls',
      name: 'Nordic Hamstring Curls',
      summary:
          'A hard eccentric hamstring drill — the hamstrings decelerate the '
          'leg on every take-off and landing, and this is where they get '
          'strong at doing it.',
      steps: [
        'Kneel on a pad with your ankles anchored under a bench or held by a '
            'partner.',
        'Squeeze the glutes so hips, torso and head form one straight line.',
        'Lower yourself towards the floor as slowly as you can control.',
        'Catch yourself with the hands when you can no longer hold the line.',
        'Push back just enough to restart, and use the hamstrings the rest of '
            'the way up.',
      ],
      commonMistakes: [
        'Breaking at the hips, which turns the drill into a knee-hover.',
        'Free-falling and calling it a rep — the whole point is the slow part.',
        'Doing high volume; this drill leaves people sore for days.',
      ],
      trains: ['Eccentric hamstring strength', 'Hamstrings', 'Glutes'],
      equipment: Equipment.bench,
      homeSubstituteId: 'single_leg_glute_bridges',
    ),
    'single_leg_glute_bridges': ExerciseGuide(
      id: 'single_leg_glute_bridges',
      name: 'Single-Leg Glute Bridges',
      summary:
          'Hamstring and glute work on one leg from the floor — the '
          'no-equipment way to strengthen the back of the jumping leg.',
      steps: [
        'Lie on your back, one foot flat on the floor with the knee bent.',
        'Lift the other leg so the thigh is roughly vertical.',
        'Drive through the planted heel and lift the hips until the body is '
            'in a straight line from knee to shoulder.',
        'Pause at the top with the glute squeezed.',
        'Lower under control. Finish the reps, then switch legs.',
      ],
      commonMistakes: [
        'Arching the lower back instead of extending the hip.',
        'Pushing through the toes, which shifts the work to the quad.',
        'Bouncing off the floor between reps.',
      ],
      trains: ['Hip extension strength', 'Glutes', 'Hamstrings'],
      equipment: Equipment.none,
    ),
    'wall_sits': ExerciseGuide(
      id: 'wall_sits',
      name: 'Wall Sits',
      summary:
          'An isometric hold that builds quad endurance, so late-game legs '
          'still have a jump left in them.',
      steps: [
        'Stand with your back flat against a wall, feet a step forward.',
        'Slide down until the thighs are around parallel to the floor.',
        'Keep the knees over the ankles and the whole back on the wall.',
        'Hold, breathing normally, arms off the thighs.',
        'Stand up under control when the time is done.',
      ],
      commonMistakes: [
        'Sitting too high, above parallel, which removes most of the work.',
        'Resting the hands on the thighs to take load off the legs.',
        'Holding your breath for the whole set.',
      ],
      trains: ['Quad endurance', 'Quads', 'Glutes'],
      equipment: Equipment.none,
    ),
    'calf_raises': ExerciseGuide(
      id: 'calf_raises',
      name: 'Calf Raises',
      summary:
          'Direct calf and Achilles work — the last joint to leave the floor '
          'on a jump, and the one that has to be stiff to transmit force.',
      steps: [
        'Stand tall with feet hip width, weight over the balls of the feet.',
        'Rise as high onto the toes as you can.',
        'Pause briefly at the top without rolling out to the little toes.',
        'Lower slowly until the heels are back on the floor.',
        'Keep the knees straight but not locked throughout.',
      ],
      commonMistakes: [
        'Bouncing the reps and using the tendon instead of the muscle.',
        'Cutting the range short at the top.',
        'Letting the ankles roll outward as the set gets hard.',
      ],
      trains: ['Ankle stiffness', 'Calves', 'Achilles tendon'],
      equipment: Equipment.none,
    ),
    // ---------------------------------------------------------------- speed
    'single_leg_hops': ExerciseGuide(
      id: 'single_leg_hops',
      name: 'Single Leg Hops',
      summary:
          'Repeated hops on one leg, training the stiffness and balance a '
          'one-foot take-off needs.',
      steps: [
        'Stand on one leg, the other knee bent and held behind you.',
        'Hop in place or slightly forward, landing on the same foot.',
        'Keep the ground contacts short and the ankle stiff.',
        'Keep the hips level — do not let the free side drop.',
        'Finish the reps, then switch legs and match them.',
      ],
      commonMistakes: [
        'Long, heavy contacts that sink into the heel.',
        'Letting the knee cave inward on each landing.',
        'Doing more reps on the strong leg than the weak one.',
      ],
      trains: ['Single-leg stiffness', 'Calves', 'Quads', 'Hip stability'],
      equipment: Equipment.none,
    ),
    'pogo_hops': ExerciseGuide(
      id: 'pogo_hops',
      name: 'Pogo Hops',
      summary:
          'Small, fast, stiff-ankle hops — the cheapest way to train the '
          'bounce that makes a jump feel springy.',
      steps: [
        'Stand tall with feet hip width and the knees almost straight.',
        'Hop on the spot using mostly the ankles.',
        'Stay on the balls of the feet; the heels barely kiss the floor.',
        'Aim for the shortest possible time on the ground.',
        'Keep the trunk quiet — no folding at the hips.',
      ],
      commonMistakes: [
        'Bending the knees deeply, which turns it into a squat jump.',
        'Chasing height instead of speed off the floor.',
        'Landing flat-footed once the set gets tiring.',
      ],
      trains: ['Ankle stiffness', 'Calves', 'Achilles tendon'],
      equipment: Equipment.none,
    ),
    'bounds': ExerciseGuide(
      id: 'bounds',
      name: 'Bounding',
      summary:
          'Exaggerated running strides for distance, training the powerful '
          'single-leg push that a dunk approach turns into height.',
      steps: [
        'Start with a few easy jogging steps to build momentum.',
        'Push off one leg and cover as much ground as you can per stride.',
        'Drive the opposite knee up and forward, arms swinging in opposition.',
        'Land on the mid-foot and go straight into the next bound.',
        'Cover the prescribed distance, then walk back to recover.',
      ],
      commonMistakes: [
        'Reaching with the front foot, which brakes instead of propelling.',
        'Running fast instead of bounding far — the strides should be long '
            'and floaty.',
        'Letting the trunk collapse forward as fatigue arrives.',
      ],
      trains: ['Single-leg power', 'Glutes', 'Hamstrings', 'Calves'],
      equipment: Equipment.none,
    ),
    'alternating_bounds': ExerciseGuide(
      id: 'alternating_bounds',
      name: 'Alternating Bounds',
      summary:
          'Bounding that switches legs every contact, training both legs to '
          'produce and absorb force at speed.',
      steps: [
        'Jog a few steps into the drill.',
        'Bound off one leg, land on the other, and immediately bound again.',
        'Drive the free knee up hard on every contact.',
        'Keep the arms swinging in opposition to the legs.',
        'Cover the prescribed distance, then walk back to recover.',
      ],
      commonMistakes: [
        'Turning it into a sprint with short, choppy steps.',
        'Uneven strides that hide a weaker leg.',
        'Landing heel-first, which kills the rebound.',
      ],
      trains: ['Alternating leg power', 'Glutes', 'Hamstrings', 'Calves'],
      equipment: Equipment.none,
    ),
    'lateral_bounds': ExerciseGuide(
      id: 'lateral_bounds',
      name: 'Lateral Bounds',
      summary:
          'Side-to-side jumps that train the hip stability keeping the knee '
          'tracking properly when you take off from a moving approach.',
      steps: [
        'Stand on one leg with a soft knee.',
        'Push sideways off that leg and land on the opposite foot.',
        'Stick the landing for a beat — balanced, knee over the mid-foot.',
        'Push straight back the other way.',
        'Keep the chest facing forward the whole time.',
      ],
      commonMistakes: [
        'Letting the landing knee collapse towards the midline.',
        'Rushing the rebound before the landing is balanced.',
        'Rotating the torso to cover more distance.',
      ],
      trains: ['Lateral power', 'Glute medius', 'Quads', 'Hip stability'],
      equipment: Equipment.none,
    ),
  };

  /// Every id the library knows about.
  static Iterable<String> get ids => guides.keys;

  /// The guide for [id], or null when nothing is authored for it.
  static ExerciseGuide? guideFor(String id) => guides[id];

  /// The guide for [exercise], or null when nothing is authored for it.
  static ExerciseGuide? guideForExercise(Exercise exercise) =>
      guides[exercise.id];

  /// The no-equipment stand-in for [id], or null when [id] needs nothing (it
  /// is already the home version) or has no authored substitute.
  static ExerciseGuide? homeSubstituteFor(String id) {
    final substituteId = guides[id]?.homeSubstituteId;
    if (substituteId == null) return null;
    return guides[substituteId];
  }

  /// [exercise] as a home-only athlete can actually train it.
  ///
  /// Returns the exercise untouched when it needs no equipment (or when no
  /// usable substitute is authored — never silently drop a drill). Otherwise
  /// returns the substitute, carrying the prescribed sets and reps across and
  /// recording which drill it replaced so the UI can say so.
  static Exercise homeVariantOf(Exercise exercise) {
    if (!exercise.equipment.isRequired) return exercise;
    final substitute = homeSubstituteFor(exercise.id);
    if (substitute == null || substitute.equipment.isRequired) return exercise;
    return Exercise(
      id: substitute.id,
      name: substitute.name,
      sets: exercise.sets,
      repsLabel: exercise.repsLabel,
      equipment: substitute.equipment,
      substitutedForId: exercise.id,
    );
  }
}
