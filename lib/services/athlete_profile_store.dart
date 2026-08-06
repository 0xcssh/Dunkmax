import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/leaderboard_athlete.dart';

/// Persists the athlete's public display name — the only thing about them
/// that ever reaches the global leaderboard.
///
/// Defaults to empty on purpose: nothing is published until the athlete
/// deliberately picks a name, so no auto-generated pseudonym can appear on a
/// public board without consent.
class AthleteProfileStore {
  static const _displayNameKey = 'athlete_display_name_v1';

  final SharedPreferences _prefs;

  AthleteProfileStore(this._prefs);

  static Future<AthleteProfileStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AthleteProfileStore(prefs);
  }

  /// The stored name, already sanitised; empty string when unset.
  String get displayName {
    final raw = _prefs.getString(_displayNameKey);
    if (raw == null) return '';
    return LeaderboardAthlete.sanitizeDisplayName(raw) ?? '';
  }

  bool get hasDisplayName => displayName.isNotEmpty;

  /// Stores [name] after sanitising it. A name that sanitises to nothing
  /// clears the stored value instead of persisting junk.
  Future<void> setDisplayName(String name) async {
    final sanitized = LeaderboardAthlete.sanitizeDisplayName(name);
    if (sanitized == null) {
      await _prefs.remove(_displayNameKey);
      return;
    }
    await _prefs.setString(_displayNameKey, sanitized);
  }

  Future<void> reset() async => _prefs.remove(_displayNameKey);
}
