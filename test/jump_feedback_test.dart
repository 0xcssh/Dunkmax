import 'dart:math' show sqrt;

import 'package:dunkmax/core/jump_feedback.dart';
import 'package:dunkmax/core/jump_form_scores.dart';
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

  group('JumpFeedback.build — strength/weakness from the form scores', () {
    JumpFormScores scores({
      FormScore? bounce,
      FormScore? power,
      FormScore? control,
      FormScore? form,
    }) =>
        JumpFormScores(
          bounce: bounce ??
              const FormScore.unavailable('Bounce', 'no approach step'),
          power:
              power ?? const FormScore.unavailable('Power', 'hips not tracked'),
          control: control ??
              const FormScore.unavailable('Control', 'body not tracked'),
          form: form ??
              const FormScore.unavailable('Form', 'arms not visible'),
        );

    test('no scores at all (manual marking) still produces the general feedback',
        () {
      final summary = JumpFeedback.build(resultWithVert(20));

      expect(summary.strength, isNull);
      expect(summary.weakness, isNull);
      expect(summary.hasRankedAspects, isFalse);
      expect(summary.tips, hasLength(2));
      expect(summary.tips[0], isNot(equals(summary.tips[1])));
    });

    test('names the best and worst measured aspect, with the measurement behind each',
        () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: scores(
          bounce: FormScore.measured('Bounce', 84, '0.18 s on the floor'),
          power: FormScore.measured('Power', 61, 'driving up at 3.1x torso/s'),
          control: FormScore.measured('Control', 30, 'hips 0.12x torso off level'),
          form: FormScore.measured('Form', 55, 'arm swing 1.10x torso'),
        ),
      );

      expect(summary.strength!.label, 'Bounce');
      expect(summary.strength!.score, 84);
      expect(summary.strength!.measurement, '0.18 s on the floor');
      expect(summary.strength!.note, isNotEmpty);

      expect(summary.weakness!.label, 'Control');
      expect(summary.weakness!.score, 30);
      expect(summary.weakness!.measurement, 'hips 0.12x torso off level');
      expect(summary.hasRankedAspects, isTrue);
    });

    test('an unavailable score is never ranked as the weakness', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: scores(
          // Bounce/Form unavailable: no approach step to time, arms out of
          // frame. Neither is evidence of a weakness.
          power: FormScore.measured('Power', 72, 'driving up at 3.9x torso/s'),
          control: FormScore.measured('Control', 40, 'torso 14 deg off vertical'),
        ),
      );

      expect(summary.strength!.label, 'Power');
      expect(summary.weakness!.label, 'Control');
      expect(summary.weakness!.label, isNot('Bounce'));
      expect(summary.weakness!.label, isNot('Form'));
    });

    test('one measured score is not a ranking — nothing is named', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: scores(
          power: FormScore.measured('Power', 72, 'driving up at 3.9x torso/s'),
        ),
      );

      expect(summary.strength, isNull);
      expect(summary.weakness, isNull);
      expect(summary.tips, hasLength(2));
    });

    test('no measured score at all names nothing', () {
      final summary = JumpFeedback.build(resultWithVert(20), scores: scores());

      expect(summary.strength, isNull);
      expect(summary.weakness, isNull);
    });

    test('a dead tie is not spun into a strength and a weakness', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: scores(
          power: FormScore.measured('Power', 60, 'driving up at 3.0x torso/s'),
          control: FormScore.measured('Control', 60, 'hips level'),
        ),
      );

      expect(summary.strength, isNull);
      expect(summary.weakness, isNull);
    });

    test('the trend note is unchanged by the form scores', () {
      final trend = JumpTrend(
        latestVerticalInches: 20,
        latestRecordedAt: DateTime(2026, 1, 1),
        deltaFromFirstInches: 4,
      );
      final withScores = JumpFeedback.build(
        resultWithVert(20),
        trend: trend,
        scores: scores(
          power: FormScore.measured('Power', 72, 'driving up at 3.9x torso/s'),
          control: FormScore.measured('Control', 40, 'torso 14 deg off vertical'),
        ),
      );
      final withoutScores = JumpFeedback.build(resultWithVert(20), trend: trend);

      expect(withScores.focusNote, withoutScores.focusNote);
      expect(withScores.headline, withoutScores.headline);
    });
  });

  group('JumpFeedback.build — tips target the measured weakness', () {
    JumpFormScores twoScores(String weakLabel, String weakDetail) {
      FormScore pick(String label, String detail) => label == weakLabel
          ? FormScore.measured(label, 25, detail)
          : FormScore.measured(label, 80, detail);

      return JumpFormScores(
        bounce: pick('Bounce', '0.38 s on the floor before takeoff'),
        power: pick('Power', 'driving up at 2.0x torso/s off the plant'),
        control: pick('Control', 'hips 0.14x torso off level'),
        form: pick('Form', weakLabel == 'Form' ? weakDetail : 'arm swing 1.6x torso'),
      );
    }

    test('a slow ground contact gets reactive-strength work', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores('Bounce', ''),
      );

      expect(summary.weakness!.label, 'Bounce');
      expect(summary.tips, hasLength(2));
      expect(summary.tips.join(' ').toLowerCase(), contains('depth jumps'));
    });

    test('a slow drive gets strength and rate-of-force work', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores('Power', ''),
      );

      expect(summary.weakness!.label, 'Power');
      expect(summary.tips.join(' ').toLowerCase(), contains('squat'));
    });

    test('poor symmetry gets single-leg work', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores('Control', ''),
      );

      expect(summary.weakness!.label, 'Control');
      expect(summary.tips.join(' ').toLowerCase(), contains('single-leg'));
    });

    test('a late arm swing leads with the arm-timing tip', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores(
          'Form',
          'arm swing 1.20x torso, peaking 0.09 s after takeoff',
        ),
      );

      expect(summary.weakness!.label, 'Form');
      expect(summary.tips.first.toLowerCase(), contains('time the arms'));
    });

    test('a small arm swing leads with the swing-range tip', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores(
          'Form',
          'arm swing 0.60x torso, peaking 0.04 s before takeoff',
        ),
      );

      expect(summary.weakness!.label, 'Form');
      expect(summary.tips.first.toLowerCase(), contains('whole range'));
    });

    test('targeted tips stay two, distinct and deterministic', () {
      final a = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores('Control', ''),
      );
      final b = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores('Control', ''),
      );

      expect(a.tips, hasLength(2));
      expect(a.tips[0], isNot(equals(a.tips[1])));
      expect(a.tips, b.tips);
    });

    test('nothing compares the athlete to other athletes', () {
      final summary = JumpFeedback.build(
        resultWithVert(20),
        scores: twoScores('Control', ''),
      );
      final all = [
        summary.headline,
        summary.focusNote,
        summary.strength!.note,
        summary.weakness!.note,
        ...summary.tips,
      ].join(' ').toLowerCase();

      expect(all, isNot(contains('%')));
      expect(all, isNot(contains('percentile')));
      expect(all, isNot(contains('other athletes')));
      expect(all, isNot(contains('average athlete')));
    });
  });
}
