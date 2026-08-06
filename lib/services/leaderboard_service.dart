import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/models/leaderboard_athlete.dart';

/// Backend for the global leaderboard (Supabase).
///
/// Two rules shape this whole file:
///
/// 1. **No credentials, no problem.** The URL and anon key come from
///    `--dart-define` at build time. CI, `flutter test`, the web preview and
///    every plain `flutter run` have none, so [isConfigured] is false and
///    every method here becomes a no-op — the app starts and behaves exactly
///    as it does offline, with the Feed showing an honest unavailable board.
/// 2. **Nothing throws at the UI.** Every call is wrapped and timed out;
///    failure is reported as "no data" (null), never as an exception.
///
/// Numbers only: name, vertical, height. Videos and thumbnails stay on the
/// device — see `LeaderboardAthlete` for why.
class LeaderboardService {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Table name — must match `docs/supabase-setup.md`.
  static const String tableName = 'leaderboard_entries';

  static const Duration _initTimeout = Duration(seconds: 6);
  static const Duration _networkTimeout = Duration(seconds: 8);

  static const String _rowColumns =
      'athlete_id, display_name, vertical_inches, height_inches, recorded_at';

  bool _initialized = false;
  bool _initFailed = false;

  /// Whether this build was given both dart-defines.
  bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Whether the backend is actually usable right now.
  bool get isAvailable => isConfigured && _initialized && !_initFailed;

  /// The signed-in athlete's backend id, or null when nobody is signed in.
  /// Used only to highlight the athlete's own row on the board.
  String? get athleteId => _client?.auth.currentUser?.id;

  /// Boots Supabase. A no-op when unconfigured, and bounded by a timeout so a
  /// dead network can never hold up app startup. Any failure degrades to
  /// "unavailable" rather than a black screen.
  Future<void> initialize() async {
    if (!isConfigured || _initialized || _initFailed) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(_initTimeout);
      _initialized = true;
    } catch (_) {
      _initFailed = true;
    }
  }

  SupabaseClient? get _client {
    if (!isConfigured || !_initialized || _initFailed) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// The global board, best-first. Returns null when the board is
  /// unavailable (not configured, offline, or the request failed) — an empty
  /// list means the board is genuinely empty, and the UI says different
  /// things for those two cases.
  Future<List<LeaderboardAthlete>?> topAthletes({int limit = 50}) async {
    if (limit <= 0) return const [];
    final client = _client;
    if (client == null) return null;

    try {
      final rows = await _selectTop(client, limit).timeout(_networkTimeout);
      if (rows is! List) return null;
      final athletes = <LeaderboardAthlete>[];
      for (final row in rows) {
        if (row is! Map) continue;
        final parsed = LeaderboardAthlete.fromMap(
          Map<String, dynamic>.from(row),
        );
        // A malformed row is skipped, never faked and never fatal.
        if (parsed != null) athletes.add(parsed);
      }
      return athletes;
    } catch (_) {
      return null;
    }
  }

  /// Upserts THIS athlete's single row, and only when [verticalInches] beats
  /// what the server already holds for them (or their name changed). One row
  /// per athlete, never one per jump.
  ///
  /// Silent by design: callers fire this and move on. It never throws.
  Future<void> submitBest({
    required String displayName,
    required int verticalInches,
    required int heightInches,
  }) async {
    final client = _client;
    if (client == null) return;

    // No name, nothing published — consent is the gate.
    final name = LeaderboardAthlete.sanitizeDisplayName(displayName);
    if (name == null) return;

    if (verticalInches < LeaderboardAthlete.minVerticalInches ||
        verticalInches > LeaderboardAthlete.maxVerticalInches) {
      return;
    }
    final int height;
    if (heightInches < LeaderboardAthlete.minHeightInches) {
      height = LeaderboardAthlete.minHeightInches;
    } else if (heightInches > LeaderboardAthlete.maxHeightInches) {
      height = LeaderboardAthlete.maxHeightInches;
    } else {
      height = heightInches;
    }

    final id = await _ensureAthleteId(client);
    if (id == null) return;

    try {
      final existing = await _selectOwn(client, id).timeout(_networkTimeout);
      int? serverBest;
      String? serverName;
      if (existing is List && existing.isNotEmpty) {
        final row = existing.first;
        if (row is Map) {
          final rawBest = row['vertical_inches'];
          if (rawBest is num) serverBest = rawBest.round();
          final rawName = row['display_name'];
          if (rawName is String) serverName = rawName;
        }
      }

      final improves = serverBest == null || verticalInches > serverBest;
      final renames = serverName != null && serverName != name;
      if (!improves && !renames) return;

      final payload = <String, dynamic>{
        'athlete_id': id,
        'display_name': name,
        'vertical_inches': improves ? verticalInches : serverBest,
        'height_inches': height,
        // Only a genuine improvement resets the date; a rename leaves the
        // existing recorded_at alone (an omitted column keeps its value on an
        // upsert's update path).
        if (improves) 'recorded_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _upsert(client, payload).timeout(_networkTimeout);
    } catch (_) {
      // Swallowed on purpose: a failed submit must never surface in the UI.
    }
  }

  /// Anonymous sign-in — the athlete needs an identity to own a row, but not
  /// a signup flow. Returns null if sign-in is unavailable.
  Future<String?> _ensureAthleteId(SupabaseClient client) async {
    final existing = client.auth.currentUser?.id;
    if (existing != null) return existing;
    try {
      final response =
          await client.auth.signInAnonymously().timeout(_networkTimeout);
      return response.user?.id;
    } catch (_) {
      return null;
    }
  }

  // The three network calls are wrapped in plain async functions so the
  // returned object is unambiguously a Future (timeouts and error handling
  // then behave the same regardless of the query builder's own type).
  Future<dynamic> _selectTop(SupabaseClient client, int limit) async {
    return client
        .from(tableName)
        .select(_rowColumns)
        .order('vertical_inches', ascending: false)
        .order('recorded_at', ascending: true)
        .limit(limit);
  }

  Future<dynamic> _selectOwn(SupabaseClient client, String id) async {
    return client
        .from(tableName)
        .select('display_name, vertical_inches')
        .eq('athlete_id', id)
        .limit(1);
  }

  Future<void> _upsert(
    SupabaseClient client,
    Map<String, dynamic> payload,
  ) async {
    await client.from(tableName).upsert(payload);
  }
}
