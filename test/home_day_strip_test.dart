import 'package:dunkmax/core/models/court_position.dart';
import 'package:dunkmax/core/models/dunk_goal.dart';
import 'package:dunkmax/core/models/experience_level.dart';
import 'package:dunkmax/core/models/onboarding_profile.dart';
import 'package:dunkmax/core/models/workout_session.dart';
import 'package:dunkmax/core/program_catalog.dart';
import 'package:dunkmax/core/training_schedule.dart';
import 'package:dunkmax/features/home/tabs/home_tab.dart';
import 'package:dunkmax/l10n/app_localizations.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:dunkmax/services/workout_session_store.dart';
import 'package:dunkmax/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home's 5-day strip must agree with the Train tab's week strip about which
/// days are rest days. On the device it drew Thursday 1 Oct — a scheduled
/// rest day on a 3-day (Mon/Wed/Fri) plan — as a red "missed" cross.
void main() {
  // 3 sessions a week land on Mon / Wed / Fri (TrainingSchedule).
  final threeDays = TrainingSchedule.trainingWeekdaysFor(3).toSet();
  final monday = DateTime(2026, 9, 28);
  final wednesday = DateTime(2026, 9, 30);
  final thursday = DateTime(2026, 10, 1);
  final friday = DateTime(2026, 10, 2);
  final saturday = DateTime(2026, 10, 3);

  HomeDayStatus statusOf(DateTime date, {DateTime? first}) => HomeDayStatus.of(
        date: date,
        today: friday,
        completedDays: {monday},
        firstLoggedDay: first ?? monday,
        trainingWeekdays: threeDays,
      );

  group('HomeDayStatus', () {
    test('a past scheduled rest day is a rest day, never missed', () {
      expect(threeDays, {1, 3, 5});
      expect(statusOf(thursday), HomeDayStatus.rest);
    });

    test('a past scheduled training day with nothing logged is missed', () {
      expect(statusOf(wednesday), HomeDayStatus.missed);
    });

    test('a training day before the first logged session is not missed', () {
      expect(statusOf(wednesday, first: thursday), HomeDayStatus.beforeStart);
      expect(
        HomeDayStatus.of(
          date: wednesday,
          today: friday,
          completedDays: const {},
          firstLoggedDay: null,
          trainingWeekdays: threeDays,
        ),
        HomeDayStatus.beforeStart,
      );
    });

    test('a logged day is completed, even on a rest day', () {
      expect(statusOf(monday), HomeDayStatus.completed);
      expect(
        HomeDayStatus.of(
          date: thursday,
          today: friday,
          completedDays: {thursday},
          firstLoggedDay: thursday,
          trainingWeekdays: threeDays,
        ),
        HomeDayStatus.completed,
      );
    });

    test('today and the days ahead are never missed', () {
      expect(statusOf(friday), HomeDayStatus.today);
      expect(statusOf(saturday), HomeDayStatus.rest);
      expect(statusOf(DateTime(2026, 10, 5)), HomeDayStatus.upcoming);
    });
  });

  testWidgets('the strip draws Thursday as rest and only Wednesday as missed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const profile = OnboardingProfile(
      goals: {DunkGoal.firstDunk},
      experience: ExperienceLevel.intermediate,
      position: CourtPosition.shootingGuard,
      daysPerWeek: 3,
    );
    final program = ProgramCatalog.recommend(profile);
    final sessions = await WorkoutSessionStore.load();
    await sessions.addSession(WorkoutSession(
      programId: program.id,
      sessionNumber: 1,
      completedAt: DateTime(2026, 9, 28, 18),
      exercises: const [
        LoggedExercise(
          exerciseId: 'depth_jumps',
          exerciseName: 'Depth Jumps',
          sets: [LoggedSet(setNumber: 1, reps: 6)],
        ),
      ],
    ));
    final jumps = await JumpLogStore.load();

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: DunkTheme.build(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HomeTab(
          profile: profile,
          program: program,
          sessionStore: sessions,
          jumpLogStore: jumps,
          onStartTraining: () {},
          onOpenSettings: () {},
          // Friday: the strip shows Wed 30 · Thu 1 · [Fri 2] · Sat 3 · Sun 4.
          now: () => DateTime(2026, 10, 2, 9),
        ),
      ),
    ));
    await tester.pump();

    expect(find.byKey(const ValueKey('home-day-missed')), findsOneWidget);
    // Thursday, Saturday and Sunday are all off on a Mon/Wed/Fri plan.
    expect(find.byKey(const ValueKey('home-day-rest')), findsNWidgets(3));
  });
}
