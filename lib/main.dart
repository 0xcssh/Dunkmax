import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/jump_log_store.dart';
import 'services/onboarding_store.dart';
import 'services/workout_session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  final store = await OnboardingStore.load();
  final sessionStore = await WorkoutSessionStore.load();
  final jumpLogStore = await JumpLogStore.load();
  runApp(DunkMaxApp(
    store: store,
    sessionStore: sessionStore,
    jumpLogStore: jumpLogStore,
  ));
}
