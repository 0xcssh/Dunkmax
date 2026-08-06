/// One athlete's row on the GLOBAL leaderboard: a name, their best measured
/// vertical, their height, and when that best was set.
///
/// Deliberately numbers-only — no video, no thumbnail, no free-form text
/// beyond the display name. Ranking on numbers alone keeps the app out of
/// user-generated-content territory (App Store Guideline 1.2), so clips and
/// thumbnails never leave the device.
///
/// This shape is what comes back off the network, so [fromMap] is defensive:
/// it accepts the snake_case column names the backend uses, tolerates numbers
/// arriving as ints, doubles or strings, and returns `null` for anything it
/// cannot trust. One bad row is skipped; it never sinks the whole board.
class LeaderboardAthlete {
  /// Opaque backend id of the row's owner (the anonymous auth user). Null for
  /// rows built locally, or when the backend did not return the column.
  final String? athleteId;

  final String displayName;
  final int verticalInches;
  final int heightInches;

  /// When this personal best was set (UTC as stored server-side).
  final DateTime recordedAt;

  const LeaderboardAthlete({
    this.athleteId,
    required this.displayName,
    required this.verticalInches,
    required this.heightInches,
    required this.recordedAt,
  });

  /// Display names are short so the board stays readable and so no one can
  /// smuggle a paragraph onto a public list.
  static const int maxDisplayNameLength = 20;

  // Plausibility bounds. A row outside them is corrupt or hostile, not an
  // athlete, and is dropped rather than shown.
  static const int minVerticalInches = 1;
  static const int maxVerticalInches = 60;
  static const int minHeightInches = 36;
  static const int maxHeightInches = 96;

  /// Column names match the Postgres table (see `docs/supabase-setup.md`).
  Map<String, dynamic> toMap() => {
        if (athleteId != null) 'athlete_id': athleteId,
        'display_name': displayName,
        'vertical_inches': verticalInches,
        'height_inches': heightInches,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };

  /// Parses one board row. Returns null when the row is missing a field,
  /// carries an unusable type, or falls outside the plausibility bounds.
  static LeaderboardAthlete? fromMap(Map<String, dynamic> map) {
    final rawName = map['display_name'];
    if (rawName is! String) return null;
    final displayName = sanitizeDisplayName(rawName);
    if (displayName == null) return null;

    final verticalInches = _asInt(map['vertical_inches']);
    if (verticalInches == null ||
        verticalInches < minVerticalInches ||
        verticalInches > maxVerticalInches) {
      return null;
    }

    final heightInches = _asInt(map['height_inches']);
    if (heightInches == null ||
        heightInches < minHeightInches ||
        heightInches > maxHeightInches) {
      return null;
    }

    final rawRecordedAt = map['recorded_at'];
    if (rawRecordedAt is! String) return null;
    final recordedAt = DateTime.tryParse(rawRecordedAt);
    if (recordedAt == null) return null;

    final rawId = map['athlete_id'];

    return LeaderboardAthlete(
      athleteId: rawId is String && rawId.isNotEmpty ? rawId : null,
      displayName: displayName,
      verticalInches: verticalInches,
      heightInches: heightInches,
      recordedAt: recordedAt,
    );
  }

  /// Trims, collapses whitespace, strips control characters and caps the
  /// length. Returns null when nothing usable is left — the caller then knows
  /// not to publish anything.
  static String? sanitizeDisplayName(String raw) {
    final buffer = StringBuffer();
    for (final rune in raw.runes) {
      // Control characters become spaces; they have no business on a board.
      buffer.writeCharCode(rune < 0x20 || rune == 0x7f ? 0x20 : rune);
    }
    final cleaned =
        buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.length <= maxDisplayNameLength) return cleaned;
    final truncated = cleaned.substring(0, maxDisplayNameLength).trim();
    return truncated.isEmpty ? null : truncated;
  }

  /// 68 -> `5'8"`. Negative input is treated as zero rather than throwing.
  static String formatHeight(int inches) {
    final safe = inches < 0 ? 0 : inches;
    return "${safe ~/ 12}'${safe % 12}\"";
  }

  String get formattedHeight => formatHeight(heightInches);

  /// `43" vert` — the orange half of a board row's stat line.
  String get formattedVertical => '$verticalInches" vert';

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) {
      if (value.isNaN || value.isInfinite) return null;
      return value.round();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final asDouble = double.tryParse(value.trim());
      if (asDouble == null || asDouble.isNaN || asDouble.isInfinite) {
        return null;
      }
      return asDouble.round();
    }
    return null;
  }
}
