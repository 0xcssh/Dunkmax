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
}
