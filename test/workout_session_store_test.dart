import 'package:dunkmax/core/models/workout_session.dart';
import 'package:dunkmax/services/workout_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  WorkoutSession session(int sessionNumber) => WorkoutSession(
        programId: 'foundation',
        sessionNumber: sessionNumber,
        completedAt: DateTime(2026, 1, sessionNumber),
        exercises: const [],
      );

  test('fresh store has no sessions', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await WorkoutSessionStore.load();

    expect(store.sessions, isEmpty);
  });

  test('added session survives a simulated app restart', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await WorkoutSessionStore.load();

    await store.addSession(session(1));

    final restarted = await WorkoutSessionStore.load();
    expect(restarted.sessions, hasLength(1));
    expect(restarted.sessions.first.programId, 'foundation');
    expect(restarted.sessions.first.sessionNumber, 1);
  });

  test('multiple sessions accumulate in order', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await WorkoutSessionStore.load();

    await store.addSession(session(1));
    await store.addSession(session(2));
    await store.addSession(session(3));

    expect(store.sessions.map((s) => s.sessionNumber).toList(), [1, 2, 3]);
  });

  test('reset clears the list back to empty', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await WorkoutSessionStore.load();

    await store.addSession(session(1));
    expect(store.sessions, isNotEmpty);

    await store.reset();
    expect(store.sessions, isEmpty);
  });
}
