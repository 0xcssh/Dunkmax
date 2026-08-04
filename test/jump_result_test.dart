import 'package:dunkmax/core/jump_result.dart';
import 'package:dunkmax/core/models/hops_level.dart';
import 'package:dunkmax/core/models/jump_measurement.dart';
import 'package:dunkmax/core/vert_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 6'1" (73") athlete: requiredVert == 29 (see vert_assessment_test.dart).
  VertAssessment assessment() => VertAssessment(
        heightInches: 73,
        ageYears: 26,
        hops: HopsLevel.touchRim,
      );

  group('JumpResult', () {
    test('a jump short of the requirement leaves a gap', () {
      final result = JumpResult(
        measurement: JumpMeasurement(
          takeoff: Duration.zero,
          landing: const Duration(milliseconds: 600), // ~23"
        ),
        assessment: assessment(),
      );
      expect(result.requiredVert, 29);
      expect(result.verticalInches, lessThan(29));
      expect(result.gapInches, greaterThan(0));
      expect(result.clearsDunk, isFalse);
      expect(result.progressToGoal, lessThan(1));
    });

    test('a jump that clears the requirement has zero gap', () {
      final result = JumpResult(
        measurement: JumpMeasurement(
          takeoff: Duration.zero,
          landing: const Duration(milliseconds: 850), // well over 29"
        ),
        assessment: assessment(),
      );
      expect(result.verticalInches, greaterThanOrEqualTo(result.requiredVert));
      expect(result.gapInches, 0);
      expect(result.clearsDunk, isTrue);
      expect(result.progressToGoal, greaterThanOrEqualTo(1));
    });

    test('an invalid measurement reports zero vertical, not a crash', () {
      final result = JumpResult(
        measurement: JumpMeasurement(
          takeoff: const Duration(seconds: 1),
          landing: const Duration(seconds: 1), // same instant, invalid
        ),
        assessment: assessment(),
      );
      expect(result.verticalInches, 0);
      expect(result.gapInches, result.requiredVert);
    });
  });
}
