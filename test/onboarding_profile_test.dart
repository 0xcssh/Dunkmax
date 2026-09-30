import 'package:dunkmax/core/models/commitment_level.dart';
import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/dunk_hand.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/hops_level.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:dunkmax/core/models/training_location.dart';
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

    // A stored profile is decoded during startup, so a field of the wrong
    // type must never throw: that would crash every launch.
    test('a wrong-typed required field decodes to null, not a TypeError', () {
      const corrupt = [
        '{"goals":["firstDunk"],"experience":7,"position":"center",'
            '"daysPerWeek":3}',
        '{"goals":["firstDunk"],"experience":"beginner","position":["center"],'
            '"daysPerWeek":3}',
        '{"goals":["firstDunk"],"experience":"beginner","position":"center",'
            '"daysPerWeek":"3"}',
        '[1,2,3]',
        '"beginner"',
      ];
      for (final source in corrupt) {
        expect(OnboardingProfile.fromJson(source), isNull, reason: source);
      }
    });

    test('a wrong-typed optional field falls back to its default', () {
      final restored = OnboardingProfile.fromJson(
        '{"goals":"firstDunk","experience":"beginner","position":"center",'
        '"daysPerWeek":3,"trainingLocation":4,"hopsLevel":{"a":1},'
        '"heightInches":"73","commitment":false,"standingReachInches":"97",'
        '"dunkHand":2}',
      );
      expect(restored, isNotNull);
      expect(restored!.goals, isEmpty);
      expect(restored.trainingLocation, TrainingLocation.both);
      expect(restored.hopsLevel, HopsLevel.touchRim);
      expect(restored.heightInches, 70);
      expect(restored.commitment, CommitmentLevel.very);
      expect(restored.standingReachInches, isNull);
      expect(restored.dunkHand, isNull);
    });

    test('a non-string entry inside goals is skipped, not fatal', () {
      final restored = OnboardingProfile.fromJson(
        '{"goals":["firstDunk",3,null],"experience":"beginner",'
        '"position":"center","daysPerWeek":2}',
      );
      expect(restored, isNotNull);
      expect(restored!.goals, {DunkGoal.firstDunk});
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
