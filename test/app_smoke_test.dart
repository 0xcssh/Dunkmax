import 'package:dunkmax/app.dart';
import 'package:dunkmax/services/athlete_profile_store.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:dunkmax/services/leaderboard_service.dart';
import 'package:dunkmax/core/subscription_offer.dart';
import 'package:dunkmax/services/onboarding_store.dart';
import 'package:dunkmax/services/subscription_service.dart';
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
  // Likewise unconfigured: no RevenueCat key under test, so the SDK is never
  // configured and StoreKit is never touched.
  final subscriptionService = SubscriptionService();
  await subscriptionService.initialize();

  return DunkMaxApp(
    store: store,
    sessionStore: sessionStore,
    jumpLogStore: jumpLogStore,
    athleteProfileStore: athleteProfileStore,
    leaderboardService: leaderboardService,
    subscriptionService: subscriptionService,
  );
}

/// Onboarding's painted court backdrop animates continuously, so the tree
/// never goes idle and `pumpAndSettle` would run to its timeout. Pump a fixed
/// stretch instead — comfortably longer than the flow's own arrival stagger
/// (620 ms) and its step transition (320 ms).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('fresh launch shows the intro carousel', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(await _buildApp());
    await _settle(tester);

    expect(find.textContaining('SEE YOUR REAL'), findsOneWidget);
    expect(find.text("LET'S START"), findsOneWidget);
  });

  testWidgets('starting the quiz reveals the first question', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(await _buildApp());
    await _settle(tester);

    await tester.tap(find.text("LET'S START"));
    await _settle(tester);

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

  test('the subscription service is inert without an API key', () async {
    final service = SubscriptionService();

    expect(service.isConfigured, isFalse);
    // Must not throw, must not hang, must never call Purchases.configure.
    await service.initialize();
    expect(service.isAvailable, isFalse);
    expect(await service.fetchOffer(), isNull);
    expect(await service.purchaseById('\$rc_annual'),
        PurchaseOutcome.unavailable);
    expect(await service.restore(), isFalse);
    await service.refreshEntitlement();
    expect(service.isSubscribed.value, isFalse);

    // Nobody is entitled without a key, so a non-release build gets the
    // explicit dev/CI escape hatch instead of being locked out entirely.
    // kReleaseMode is false under `flutter test`.
    expect(service.allowsUnconfiguredAccess, isTrue);
    expect(service.hasAccess, isTrue);
  });
}
