import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
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

  group('CourtPosition numbering', () {
    test('is 1-based in list order', () {
      expect(CourtPosition.pointGuard.number, 1);
      expect(CourtPosition.center.number, 5);
    });
  });
}
