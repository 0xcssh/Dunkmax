import 'package:dunkmax/core/models/dunk_hand.dart';
import 'package:dunkmax/core/models/hops_level.dart';
import 'package:dunkmax/core/vert_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VertAssessment — calibrated against the reference (6\'1", touch rim)', () {
    final a = VertAssessment(heightInches: 73, ageYears: 26, hops: HopsLevel.touchRim);

    test('standing reach is ~1.33x height', () {
      expect(a.standingReach, 97); // round(73 * 1.33)
    });

    test('dunk requires ~29"', () {
      expect(a.requiredVert, 29); // 126 - 97
    });

    test('touch-the-rim estimates ~23" today', () {
      expect(a.estimatedCurrentVert, 23); // 120 - 97
    });

    test('gap to dunk is ~6"', () {
      expect(a.gapInches, 6); // 29 - 23
      expect(a.canAlreadyDunk, isFalse);
    });
  });

  group('VertAssessment — relationships', () {
    test('taller athletes need less vertical to dunk', () {
      final short = VertAssessment(heightInches: 68, ageYears: 25, hops: HopsLevel.touchRim);
      final tall = VertAssessment(heightInches: 78, ageYears: 25, hops: HopsLevel.touchRim);
      expect(tall.requiredVert, lessThan(short.requiredVert));
    });

    test('higher hops level ⇒ higher current vert', () {
      VertAssessment mk(HopsLevel h) =>
          VertAssessment(heightInches: 73, ageYears: 25, hops: h);
      expect(mk(HopsLevel.belowRim).estimatedCurrentVert,
          lessThan(mk(HopsLevel.touchRim).estimatedCurrentVert));
      expect(mk(HopsLevel.touchRim).estimatedCurrentVert,
          lessThan(mk(HopsLevel.dunkConsistently).estimatedCurrentVert));
    });

    test('a consistent dunker already clears the requirement', () {
      final a = VertAssessment(heightInches: 73, ageYears: 25, hops: HopsLevel.dunkConsistently);
      expect(a.canAlreadyDunk, isTrue);
      expect(a.gapInches, 0);
    });
  });

  group('VertAssessment — projection', () {
    final a = VertAssessment(heightInches: 73, ageYears: 26, hops: HopsLevel.touchRim);

    test('week 0 equals today', () {
      expect(a.projectedVertAtWeek(0), a.estimatedCurrentVert);
    });

    test('projection is monotonic and gains taper (fastest early)', () {
      final w0 = a.projectedVertAtWeek(0);
      final w3 = a.projectedVertAtWeek(3);
      final w6 = a.projectedVertAtWeek(6);
      final w12 = a.projectedVertAtWeek(12);
      expect(w3, greaterThan(w0));
      expect(w6, greaterThanOrEqualTo(w3));
      expect(w12, greaterThanOrEqualTo(w6));
      // First 3 weeks deliver more than the following 3 (diminishing returns).
      expect(w3 - w0, greaterThanOrEqualTo(w6 - w3));
    });

    test('younger athletes carry more upside', () {
      final young = VertAssessment(heightInches: 73, ageYears: 17, hops: HopsLevel.touchRim);
      final older = VertAssessment(heightInches: 73, ageYears: 45, hops: HopsLevel.touchRim);
      expect(young.maxGainInches, greaterThan(older.maxGainInches));
    });
  });

  group('a measured standing reach beats the height estimate', () {
    // The height estimate is a population average and the app's whole
    // "inches to dunk" promise sits on top of it. On a real clip it claimed
    // the athlete was 2" from dunking while frame-by-frame measurement put
    // their fingertips ~20" below the rim at the apex.
    test('the athlete\'s own measurement is used when given', () {
      final measured = VertAssessment(
        heightInches: 73,
        ageYears: 22,
        hops: HopsLevel.touchRim,
        measuredStandingReach: 92,
      );

      expect(measured.reachIsMeasured, isTrue);
      expect(measured.standingReach, 92);
    });

    test('falls back to the estimate, and admits it, when not given', () {
      final estimated = VertAssessment(
        heightInches: 73,
        ageYears: 22,
        hops: HopsLevel.touchRim,
      );

      expect(estimated.reachIsMeasured, isFalse);
      expect(estimated.standingReach, VertAssessment.standingReachInches(73));
    });

    test('a shorter real reach raises the vert needed to dunk', () {
      const height = 73;
      final estimated = VertAssessment(
        heightInches: height,
        ageYears: 22,
        hops: HopsLevel.touchRim,
      );
      // Five inches less reach is five inches more jump to clear the rim.
      final shortArms = VertAssessment(
        heightInches: height,
        ageYears: 22,
        hops: HopsLevel.touchRim,
        measuredStandingReach: estimated.standingReach - 5,
      );

      expect(shortArms.requiredVert, estimated.requiredVert + 5);
      // The *gap* is unchanged, and that is correct: "touch the rim" is
      // defined relative to the rim, so a shorter reach means both a bigger
      // jump to dunk and a bigger jump to graze the rim. Shorter arms move
      // the whole scale, not the distance between those two points. What the
      // athlete's real reach changes is the absolute target they train
      // toward — and, once a real jump is measured against it, whether they
      // are actually near it.
      expect(shortArms.gapInches, estimated.gapInches);
      expect(shortArms.estimatedCurrentVert,
          estimated.estimatedCurrentVert + 5);
    });

    test('a zero or absent measurement is treated as unmeasured', () {
      final zero = VertAssessment(
        heightInches: 73,
        ageYears: 22,
        hops: HopsLevel.touchRim,
        measuredStandingReach: 0,
      );

      expect(zero.reachIsMeasured, isFalse);
      expect(zero.standingReach, VertAssessment.standingReachInches(73));
    });
  });

  group('the chosen finish sets how much room over the rim is needed', () {
    VertAssessment mk(DunkHand? hand) => VertAssessment(
          heightInches: 73,
          ageYears: 26,
          hops: HopsLevel.touchRim,
          dunkHand: hand,
        );

    test('an unanswered hand behaves exactly like a one-hand finish', () {
      final unanswered = mk(null);
      final oneHand = mk(DunkHand.right);

      expect(unanswered.reachTarget, oneHand.reachTarget);
      expect(unanswered.requiredVert, oneHand.requiredVert);
      expect(unanswered.gapInches, oneHand.gapInches);
      // And it is still the calibrated reference number.
      expect(unanswered.requiredVert, 29);
    });

    test('left and right are the same target — only the count of hands matters',
        () {
      expect(mk(DunkHand.left).requiredVert, mk(DunkHand.right).requiredVert);
    });

    test('a two-hand finish raises the required vert by exactly the extra '
        'clearance', () {
      final oneHand = mk(DunkHand.right);
      final twoHands = mk(DunkHand.both);

      expect(twoHands.requiredVert,
          oneHand.requiredVert + VertAssessment.twoHandExtraClearance);
      // Today's estimate is rim-relative, so it does not move — the gap is
      // what grows.
      expect(twoHands.estimatedCurrentVert, oneHand.estimatedCurrentVert);
      expect(twoHands.gapInches,
          oneHand.gapInches + VertAssessment.twoHandExtraClearance);
    });

    test('reachTarget is rim + clearance for each case', () {
      expect(mk(null).reachTarget, VertAssessment.dunkReachTarget); // 126
      expect(mk(DunkHand.left).reachTarget, VertAssessment.dunkReachTarget);
      expect(mk(DunkHand.right).reachTarget, VertAssessment.dunkReachTarget);
      expect(
        mk(DunkHand.both).reachTarget,
        VertAssessment.rimHeight +
            VertAssessment.dunkClearance +
            VertAssessment.twoHandExtraClearance,
      );
    });

    test('dunkClearanceFor is the one-hand figure unless both hands', () {
      expect(VertAssessment.dunkClearanceFor(null),
          VertAssessment.dunkClearance);
      expect(VertAssessment.dunkClearanceFor(DunkHand.left),
          VertAssessment.dunkClearance);
      expect(
        VertAssessment.dunkClearanceFor(DunkHand.both),
        VertAssessment.dunkClearance + VertAssessment.twoHandExtraClearance,
      );
    });
  });
}
