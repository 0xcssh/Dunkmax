import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/jump_log_entry.dart';

/// Persists every logged jump measurement (from the Analyze tab) as its own
/// JSON string, feeding the Progress tab's vertical trend.
class JumpLogStore {
  static const _entriesKey = 'jump_log_entries_v1';

  final SharedPreferences _prefs;

  JumpLogStore(this._prefs);

  static Future<JumpLogStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return JumpLogStore(prefs);
  }

  List<JumpLogEntry> get entries {
    final raw = _prefs.getStringList(_entriesKey) ?? const [];
    return raw.map(JumpLogEntry.fromJson).whereType<JumpLogEntry>().toList();
  }

  Future<void> addEntry(JumpLogEntry entry) async {
    final updated = [...entries, entry];
    await _prefs.setStringList(
      _entriesKey,
      updated.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> reset() async => _prefs.remove(_entriesKey);
}
