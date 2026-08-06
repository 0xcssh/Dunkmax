import 'package:dunkmax/app.dart';
import 'package:dunkmax/services/athlete_profile_store.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:dunkmax/services/leaderboard_service.dart';
import 'package:dunkmax/services/onboarding_store.dart';
import 'package:dunkmax/services/workout_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<DunkMaxApp> _buildApp() async {
  final store = await OnboardingStore.load();
  final sessionStore = await WorkoutSessionStore.load();
  final jumpLogStore = await JumpLogStore.load();
  final athleteProfileStore = await AthleteProfileStore.load();
  // No --dart-define credentials under test: the service is unconfigured and
  // every one of its methods is a no-op, so nothing here touches a network.
  final leaderboardService = LeaderboardService();
  await leaderboardService.initialize();

  return DunkMaxApp(
    store: store,
    sessionStore: sessionStore,
    jumpLogStore: jumpLogStore,
    athleteProfileStore: athleteProfileStore,
    leaderboardService: leaderboardService,
  );
}

void main() {
  testWidgets('fresh launch shows the welcome hook', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    expect(find.text("LET'S START"), findsOneWidget);
  });

  testWidgets('starting the quiz reveals the first question', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(await _buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("LET'S START"));
    await tester.pumpAndSettle();

    expect(find.textContaining('DUNK GOAL'), findsOneWidget);
    // Continue is gated until at least one goal is picked.
    expect(find.text('First Dunk Ever'), findsOneWidget);
  });

  test('the leaderboard service is inert without credentials', () async {
    final service = LeaderboardService();

    expect(service.isConfigured, isFalse);
    await service.initialize();
    expect(service.isAvailable, isFalse);
    expect(await service.topAthletes(), isNull);
    // Must not throw, must not hang.
    await service.submitBest(
      displayName: 'Marcus',
      verticalInches: 30,
      heightInches: 73,
    );
  });
}
