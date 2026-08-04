import 'dart:convert';

/// One vertical-jump test result, as measured by the Analyze flow — the
/// persisted unit of jump history that Progress's trend is computed from.
class JumpLogEntry {
  final int verticalInches;
  final DateTime recordedAt;
  const JumpLogEntry({required this.verticalInches, required this.recordedAt});

  Map<String, dynamic> toMap() => {
        'verticalInches': verticalInches,
        'recordedAt': recordedAt.toIso8601String(),
      };

  String toJson() => jsonEncode(toMap());

  static JumpLogEntry? fromMap(Map<String, dynamic> map) {
    final verticalInches = map['verticalInches'];
    final recordedAtRaw = map['recordedAt'];
    if (verticalInches is! int || recordedAtRaw is! String) return null;
    final recordedAt = DateTime.tryParse(recordedAtRaw);
    if (recordedAt == null) return null;
    return JumpLogEntry(verticalInches: verticalInches, recordedAt: recordedAt);
  }

  static JumpLogEntry? fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      return fromMap(decoded);
    } on FormatException {
      return null;
    }
  }
}
