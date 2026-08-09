import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/dunk_hand.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingProfile serialisation', () {
    const profile = OnboardingProfile(
      goals: {DunkGoal.firstDunk, DunkGoal.maxVertical},
      experience: ExperienceLevel.intermediate,
      position: CourtPosition.smallForward,
      daysPerWeek: 4,
    );

    test('round-trips through JSON without loss', () {
      final restored = OnboardingProfile.fromJson(profile.toJson());
      expect(restored, isNotNull);
      expect(restored!.goals, profile.goals);
      expect(restored.experience, ExperienceLevel.intermediate);
      expect(restored.position, CourtPosition.smallForward);
      expect(restored.daysPerWeek, 4);
    });

    test('garbage JSON returns null instead of throwing', () {
      expect(OnboardingProfile.fromJson('not json'), isNull);
      expect(OnboardingProfile.fromJson('{"goals":[]}'), isNull);
    });

    test('unknown enum keys are dropped, not fatal', () {
      final restored = OnboardingProfile.fromJson(
        '{"goals":["firstDunk","bogusGoal"],"experience":"beginner",'
        '"position":"center","daysPerWeek":2}',
      );
      expect(restored, isNotNull);
      expect(restored!.goals, {DunkGoal.firstDunk});
    });
  });

  group('OnboardingProfile.dunkHand', () {
    const base = OnboardingProfile(
      goals: {DunkGoal.firstDunk},
      experience: ExperienceLevel.beginner,
      position: CourtPosition.center,
      daysPerWeek: 3,
    );

    test('defaults to null — the question is answerable, not assumed', () {
      expect(base.dunkHand, isNull);
      expect(base.toMap().containsKey('dunkHand'), isFalse);
    });

    test('round-trips through JSON for every hand', () {
      for (final hand in DunkHand.values) {
        final restored =
            OnboardingProfile.fromJson(base.copyWith(dunkHand: hand).toJson());
        expect(restored, isNotNull);
        expect(restored!.dunkHand, hand);
      }
    });

    test('a profile saved before the field existed still decodes, with null',
        () {
      final legacy = base.toMap()..remove('dunkHand');
      final restored = OnboardingProfile.fromMap(legacy);

      expect(restored, isNotNull);
      expect(restored!.dunkHand, isNull);
      // Nothing else was disturbed by the new field.
      expect(restored.goals, base.goals);
      expect(restored.daysPerWeek, base.daysPerWeek);
    });

    test('an unrecognised stored hand degrades to null, not a crash', () {
      final restored = OnboardingProfile.fromJson(
        '{"goals":["firstDunk"],"experience":"beginner",'
        '"position":"center","daysPerWeek":3,"dunkHand":"tail"}',
      );

      expect(restored, isNotNull);
      expect(restored!.dunkHand, isNull);
    });

    test('copyWith keeps an existing hand when none is passed', () {
      final withHand = base.copyWith(dunkHand: DunkHand.both);
      expect(withHand.copyWith(daysPerWeek: 5).dunkHand, DunkHand.both);
    });
  });

  group('CourtPosition numbering', () {
    test('is 1-based in list order', () {
      expect(CourtPosition.pointGuard.number, 1);
      expect(CourtPosition.center.number, 5);
    });
  });
}
