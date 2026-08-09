import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/athlete_profile_store.dart';
import 'services/jump_log_store.dart';
import 'services/leaderboard_service.dart';
import 'services/onboarding_store.dart';
import 'services/subscription_service.dart';
import 'services/workout_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final store = await OnboardingStore.load();
  final sessionStore = await WorkoutSessionStore.load();
  final jumpLogStore = await JumpLogStore.load();
  final athleteProfileStore = await AthleteProfileStore.load();
  // Global leaderboard. With no --dart-define credentials (CI, tests, web
  // preview, any plain `flutter run`) this returns immediately and the board
  // shows its unavailable state; a network or config failure is caught inside
  // and degrades the same way, so startup can never hang or crash on it.
  final leaderboardService = LeaderboardService();
  await leaderboardService.initialize();
  // In-app purchases. Same deal: with no --dart-define REVENUECAT_API_KEY this
  // returns immediately without ever configuring the SDK or touching StoreKit,
  // and the paywall says purchases are unavailable. Awaited so the phase
  // machine knows the entitlement before it picks a first screen — a
  // subscriber must not see the paywall flash on launch.
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();
  runApp(DunkMaxApp(
    store: store,
    sessionStore: sessionStore,
    jumpLogStore: jumpLogStore,
    athleteProfileStore: athleteProfileStore,
    leaderboardService: leaderboardService,
    subscriptionService: subscriptionService,
  ));
}
