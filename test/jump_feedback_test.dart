import 'dart:math' show sqrt;

import 'package:dunkmax/core/jump_feedback.dart';
import 'package:dunkmax/core/models/hops_level.dart';
import 'package:dunkmax/core/models/jump_measurement.dart';
import 'package:dunkmax/core/jump_result.dart';
import 'package:dunkmax/core/jump_trend.dart';
import 'package:dunkmax/core/vert_assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 6'1" (73") athlete: requiredVert == 29" (see vert_assessment_test.dart).
  VertAssessment assessment() => VertAssessment(
        heightInches: 73,
        ageYears: 26,
        hops: HopsLevel.touchRim,
      );

  JumpResult resultWithVert(int inches) {
    // airborne seconds s.t. FlightTime.heightInches(t) ≈ inches, derived via
    // a takeoff/landing pair — simplest is to pick a plausible duration and
    // accept whatever vertical it yields, then assert against that.
    // Instead: build measurement directly from a duration known to produce
    // a vertical clearly below/above the 29" requirement.
    final landingMs = inches <= 23 ? 550 : 900; // short vs. clears-dunk jump
    return JumpResult(
      measurement: JumpMeasurement(
        takeoff: Duration.zero,
        landing: Duration(milliseconds: landingMs),
      ),
      assessment: assessment(),
    );
  }

  group('JumpFeedback.build — headline', () {
    test('short jump mentions the real gap and requirement, not a fabricated claim', () {
      final result = resultWithVert(20);
      final summary = JumpFeedback.build(result);

      expect(summary.headline, contains('${result.verticalInches}"'));
      expect(summary.headline, contains('${result.gapInches}"'));
      expect(summary.headline, contains('${result.requiredVert}"'));
      expect(result.clearsDunk, isFalse);
    });

    test('a jump that clears the dunk requirement gets the clears-it copy', () {
      final result = resultWithVert(30);
      expect(result.clearsDunk, isTrue);

      final summary = JumpFeedback.build(result);
      expect(summary.headline, contains('clears'));
      expect(summary.headline, contains('${result.verticalInches}"'));
    });
  });

  group('JumpFeedback.build — focusNote (first jump, no trend yet)', () {
    // touchRim/73"/26yo -> assessment.estimatedCurrentVert == 23" (see
    // vert_assessment_test.dart's calibration case).
    JumpResult resultWithMeasuredVert(int targetInches) {
      // Solve landing duration t s.t. FlightTime.heightInches(t) ~= target
      // (h = g*t^2/8 => t = sqrt(h*8/g)), then trust the actual rounded
      // result rather than the target.
      final tSeconds = sqrt(targetInches * 8 / 386.09);
      final ms = (tSeconds * 1000).round();
      return JumpResult(
        measurement: JumpMeasurement(
          takeoff: Duration.zero,
          landing: Duration(milliseconds: ms),
        ),
        assessment: assessment(),
      );
    }

    test('measured close to onboarding estimate reads as good self-awareness, not a fabricated trend', () {
      final result = resultWithMeasuredVert(23); // ~= estimatedCurrentVert
      expect((result.verticalInches - result.assessment.estimatedCurrentVert).abs(),
          lessThanOrEqualTo(2));

      final summary = JumpFeedback.build(result, trend: null);
      expect(summary.focusNote, contains('lines up closely'));
    });

    test('measured well above onboarding estimate is named honestly, not hidden', () {
      final result = resultWithMeasuredVert(35); // well above estimatedCurrentVert (23")
      expect(result.verticalInches, greaterThan(result.assessment.estimatedCurrentVert + 2));

      final summary = JumpFeedback.build(result, trend: null);
      expect(summary.focusNote, contains('above your onboarding estimate'));
      expect(summary.focusNote, contains('${result.verticalInches}"'));
      expect(summary.focusNote, contains('${result.assessment.estimatedCurrentVert}"'));
    });

    test('measured well below onboarding estimate is named honestly, not spun positive', () {
      final result = resultWithMeasuredVert(10); // well below estimatedCurrentVert (23")
      expect(result.verticalInches, lessThan(result.assessment.estimatedCurrentVert - 2));

      final summary = JumpFeedback.build(result, trend: null);
      expect(summary.focusNote, contains('below your onboarding estimate'));
    });
  });

  group('JumpFeedback.build — focusNote (trend from prior jumps)', () {
    final result = resultWithVert(20);

    test('positive delta trend is stated honestly as improvement', () {
      final trend = JumpTrend(
        latestVerticalInches: 20,
        latestRecordedAt: DateTime(2026, 1, 1),
        deltaFromFirstInches: 4,
      );
      final summary = JumpFeedback.build(result, trend: trend);
      expect(summary.focusNote, contains('up'));
      expect(summary.focusNote, contains('4"'));
    });

    test('negative delta trend is stated honestly, not spun positive', () {
      final trend = JumpTrend(
        latestVerticalInches: 20,
        latestRecordedAt: DateTime(2026, 1, 1),
        deltaFromFirstInches: -3,
      );
      final summary = JumpFeedback.build(result, trend: trend);
      expect(summary.focusNote, contains('below'));
      expect(summary.focusNote, contains('3"'));
      expect(summary.focusNote, isNot(contains('-3')));
    });

    test('zero delta trend is stated as flat, not fabricated as progress', () {
      final trend = JumpTrend(
        latestVerticalInches: 20,
        latestRecordedAt: DateTime(2026, 1, 1),
        deltaFromFirstInches: 0,
      );
      final summary = JumpFeedback.build(result, trend: trend);
      expect(summary.focusNote, contains('Same as your first'));
    });
  });

  group('JumpFeedback.build — tips', () {
    test('always returns exactly two non-empty, distinct general tips', () {
      final summary = JumpFeedback.build(resultWithVert(20));
      expect(summary.tips, hasLength(2));
      expect(summary.tips[0], isNotEmpty);
      expect(summary.tips[1], isNotEmpty);
      expect(summary.tips[0], isNot(equals(summary.tips[1])));
    });

    test('tip selection is deterministic for the same input', () {
      final a = JumpFeedback.build(resultWithVert(20));
      final b = JumpFeedback.build(resultWithVert(20));
      expect(a.tips, b.tips);
    });
  });
}
