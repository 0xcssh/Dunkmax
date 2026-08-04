import 'package:dunkmax/app.dart';
import 'package:dunkmax/services/jump_log_store.dart';
import 'package:dunkmax/services/onboarding_store.dart';
import 'package:dunkmax/services/workout_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('fresh launch shows the welcome hook', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await OnboardingStore.load();
    final sessionStore = await WorkoutSessionStore.load();
    final jumpLogStore = await JumpLogStore.load();

    await tester.pumpWidget(DunkMaxApp(
      store: store,
      sessionStore: sessionStore,
      jumpLogStore: jumpLogStore,
    ));
    await tester.pumpAndSettle();

    expect(find.text("LET'S START"), findsOneWidget);
  });

  testWidgets('starting the quiz reveals the first question', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await OnboardingStore.load();
    final sessionStore = await WorkoutSessionStore.load();
    final jumpLogStore = await JumpLogStore.load();

    await tester.pumpWidget(DunkMaxApp(
      store: store,
      sessionStore: sessionStore,
      jumpLogStore: jumpLogStore,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text("LET'S START"));
    await tester.pumpAndSettle();

    expect(find.textContaining('DUNK GOAL'), findsOneWidget);
    // Continue is gated until at least one goal is picked.
    expect(find.text('First Dunk Ever'), findsOneWidget);
  });
}
