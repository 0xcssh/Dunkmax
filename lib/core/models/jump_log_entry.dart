import 'dart:convert';

/// One vertical-jump test result, as measured by the Analyze flow — the
/// persisted unit of jump history that Progress's trend is computed from.
class JumpLogEntry {
  final int verticalInches;
  final DateTime recordedAt;
  // Local file path to a still frame captured near takeoff; null if
  // generation failed or this entry predates the thumbnail feature.
  final String? thumbnailPath;
  // Local file path to the persisted source clip (a copy made at analysis
  // time, since the original image_picker temp file isn't guaranteed to
  // survive); null if the copy failed or this entry predates the
  // video-persistence feature.
  final String? videoPath;

  const JumpLogEntry({
    required this.verticalInches,
    required this.recordedAt,
    this.thumbnailPath,
    this.videoPath,
  });

  Map<String, dynamic> toMap() => {
        'verticalInches': verticalInches,
        'recordedAt': recordedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
        'videoPath': videoPath,
      };

  String toJson() => jsonEncode(toMap());

  static JumpLogEntry? fromMap(Map<String, dynamic> map) {
    final verticalInches = map['verticalInches'];
    final recordedAtRaw = map['recordedAt'];
    if (verticalInches is! int || recordedAtRaw is! String) return null;
    final recordedAt = DateTime.tryParse(recordedAtRaw);
    if (recordedAt == null) return null;
    final rawThumb = map['thumbnailPath'];
    final rawVideo = map['videoPath'];
    return JumpLogEntry(
      verticalInches: verticalInches,
      recordedAt: recordedAt,
      thumbnailPath: rawThumb is String ? rawThumb : null,
      videoPath: rawVideo is String ? rawVideo : null,
    );
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
