import 'dart:math' as math;

import 'models/dunk_hand.dart';
import 'models/hops_level.dart';

/// Pure vertical-jump math: turns the athlete's vitals + self-reported hops
/// into a standing reach, the vert required to dunk, today's estimated vert,
/// the gap between them, and a projected-progress curve.
///
/// Calibrated against the reference app: a 6'1" (73") athlete who can "touch
/// the rim" gets standing reach 97", dunk target 29", est. today 23", gap 6".
/// No Flutter imports — fully unit-tested.
class VertAssessment {
  /// Standard 10-foot rim, in inches.
  static const int rimHeight = 120;

  /// Extra reach above the rim needed to finish a **one-hand** dunk: the ball
  /// and one hand have to clear the ring.
  static const int dunkClearance = 6;

  /// A two-hand finish needs both forearms over the ring, not one hand, so it
  /// asks for more height from the same athlete. Four inches is a coaching
  /// figure rather than a measured one — it is documented as such here so it
  /// is never mistaken for something derived.
  static const int twoHandExtraClearance = 4;

  /// Clearance above the rim for [hand]. Unknown hand falls back to the
  /// one-hand figure, which is the friendlier of the two: it is better to
  /// under-state a target than to invent inches an athlete does not need.
  static int dunkClearanceFor(DunkHand? hand) =>
      (hand?.isTwoHanded ?? false)
          ? dunkClearance + twoHandExtraClearance
          : dunkClearance;

  /// Rim + one-hand clearance. Kept for the default case and pinned by tests.
  static const int dunkReachTarget = rimHeight + dunkClearance; // 126

  /// Standing reach ≈ 1.33 × height (fingertips overhead, flat-footed).
  ///
  /// A population average, and the weakest link in everything below: arm
  /// length varies by several inches between people of the same height, and
  /// every "X inches to dunk" claim is this number plus a measurement. On a
  /// real clip the athlete's fingertips were about 20 inches below the rim at
  /// the apex of a jump this estimate said should have cleared it — so when
  /// the athlete's actual reach is known, it must win.
  static int standingReachInches(int heightInches) =>
      (heightInches * 1.33).round();

  final int heightInches;
  final int ageYears;
  final HopsLevel hops;

  /// The athlete's real standing reach, if they have measured it (fingertips
  /// overhead, flat-footed, against a wall). Null means fall back to the
  /// height estimate — and say so wherever the result is shown.
  final int? measuredStandingReach;

  /// How the athlete intends to finish. Null keeps the one-hand target.
  final DunkHand? dunkHand;

  VertAssessment({
    required this.heightInches,
    required this.ageYears,
    required this.hops,
    this.measuredStandingReach,
    this.dunkHand,
  });

  /// The reach height this athlete's chosen finish actually requires.
  int get reachTarget => rimHeight + dunkClearanceFor(dunkHand);

  /// True when [standingReach] is the athlete's own measurement rather than
  /// an estimate derived from their height.
  bool get reachIsMeasured =>
      measuredStandingReach != null && measuredStandingReach! > 0;

  int get standingReach =>
      reachIsMeasured ? measuredStandingReach! : standingReachInches(heightInches);

  /// Inches of vertical leap needed to get a hand over the rim to dunk.
  int get requiredVert => math.max(0, reachTarget - standingReach);

  /// Estimated current vertical from the self-reported hops level, expressed
  /// relative to the rim (touching the rim ⇒ reach == rim height).
  int get estimatedCurrentVert {
    final touchRimVert = rimHeight - standingReach; // graze the rim
    int v;
    switch (hops) {
      case HopsLevel.belowRim:
        v = touchRimVert - 4;
        break;
      case HopsLevel.touchRim:
        v = touchRimVert;
        break;
      case HopsLevel.grabRim:
        v = touchRimVert + 3;
        break;
      case HopsLevel.dunkOnGoodDay:
        v = requiredVert - 1;
        break;
      case HopsLevel.dunkConsistently:
        v = requiredVert + 2;
        break;
    }
    return math.max(0, v);
  }

  /// Inches still missing to dunk (0 if they already clear it).
  int get gapInches => math.max(0, requiredVert - estimatedCurrentVert);

  bool get canAlreadyDunk => estimatedCurrentVert >= requiredVert;

  /// Rough ceiling of vertical gain over a full 12-week block, biased by age
  /// (younger athletes carry more upside). Heuristic, tunable from feedback.
  int get maxGainInches {
    if (ageYears <= 18) return 8;
    if (ageYears <= 25) return 7;
    if (ageYears <= 32) return 6;
    if (ageYears <= 40) return 5;
    return 4;
  }

  /// Projected vertical after [week] weeks of training: a diminishing-returns
  /// curve (fastest gains early) added onto today's estimate.
  int projectedVertAtWeek(int week) {
    if (week <= 0) return estimatedCurrentVert;
    const tau = 5.0; // weeks; controls how fast gains taper off
    final gained = maxGainInches * (1 - math.exp(-week / tau));
    return estimatedCurrentVert + gained.round();
  }

  /// The headline projection the onboarding "potential" screen shows.
  int get projectedVert8Week => projectedVertAtWeek(8);
}
