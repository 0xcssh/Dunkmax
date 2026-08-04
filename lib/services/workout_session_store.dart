import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/workout_session.dart';

/// Persists every completed [WorkoutSession] as its own JSON string in a
/// shared_preferences string list — one corrupt entry (e.g. from a future
/// format change) can't take the rest of the history down with it.
class WorkoutSessionStore {
  static const _sessionsKey = 'workout_sessions_v1';

  final SharedPreferences _prefs;

  WorkoutSessionStore(this._prefs);

  static Future<WorkoutSessionStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return WorkoutSessionStore(prefs);
  }

  /// All completed sessions across every program, in the order they were
  /// added.
  List<WorkoutSession> get sessions {
    final raw = _prefs.getStringList(_sessionsKey) ?? const [];
    return raw.map(WorkoutSession.fromJson).whereType<WorkoutSession>().toList();
  }

  Future<void> addSession(WorkoutSession session) async {
    final updated = [...sessions, session];
    await _prefs.setStringList(
      _sessionsKey,
      updated.map((s) => s.toJson()).toList(),
    );
  }

  Future<void> reset() async => _prefs.remove(_sessionsKey);
}
