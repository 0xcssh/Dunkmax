import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:dunkmax/core/program_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

OnboardingProfile _profile({
  required ExperienceLevel experience,
  int daysPerWeek = 3,
}) {
  return OnboardingProfile(
    goals: {DunkGoal.firstDunk},
    experience: experience,
    position: CourtPosition.pointGuard,
    daysPerWeek: daysPerWeek,
  );
}

void main() {
  group('ProgramCatalog.recommend', () {
    test('beginner gets the Foundation Builder', () {
      final program =
          ProgramCatalog.recommend(_profile(experience: ExperienceLevel.beginner));
      expect(program.id, 'foundation');
      expect(program.name, 'Foundation Builder');
    });

    test('intermediate gets the Reactive Power Program', () {
      final program = ProgramCatalog.recommend(
          _profile(experience: ExperienceLevel.intermediate));
      expect(program.id, 'reactive_power');
    });

    test('advanced gets a longer, higher-volume system', () {
      final beginner =
          ProgramCatalog.recommend(_profile(experience: ExperienceLevel.beginner));
      final advanced =
          ProgramCatalog.recommend(_profile(experience: ExperienceLevel.advanced));
      expect(advanced.weeks, greaterThan(beginner.weeks));
    });

    test('training frequency drives total session count', () {
      final twice = ProgramCatalog.recommend(
          _profile(experience: ExperienceLevel.intermediate, daysPerWeek: 2));
      final fivePlus = ProgramCatalog.recommend(
          _profile(experience: ExperienceLevel.intermediate, daysPerWeek: 5));
      expect(fivePlus.totalSessions, greaterThan(twice.totalSessions));
    });

    test('daysPerWeek is clamped into a sane range', () {
      final absurd = ProgramCatalog.recommend(
          _profile(experience: ExperienceLevel.intermediate, daysPerWeek: 99));
      expect(absurd.sessionsPerWeek, lessThanOrEqualTo(7));
    });

    test('recommended program exposes at least one authored day', () {
      final program = ProgramCatalog.recommend(
          _profile(experience: ExperienceLevel.intermediate));
      expect(program.sampleDays, isNotEmpty);
      expect(program.dayFor(1).exercises, isNotEmpty);
    });

    test('every recommended program has a full 3-day rotation', () {
      for (final experience in ExperienceLevel.values) {
        final program =
            ProgramCatalog.recommend(_profile(experience: experience));
        expect(program.sampleDays.length, 3,
            reason: '${program.id} should have 3 authored days');
        for (final day in program.sampleDays) {
          expect(day.exercises, isNotEmpty,
              reason: '${program.id} day ${day.day} has no exercises');
        }
      }
    });
  });
}
