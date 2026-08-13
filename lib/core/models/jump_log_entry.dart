import 'dart:convert';

import 'video_attempt_type.dart';

/// One vertical-jump test result, as measured by the Analyze flow — the
/// persisted unit of jump history that Progress's trend is computed from.
class JumpLogEntry {
  final int verticalInches;
  final DateTime recordedAt;
  // File NAME of a still frame captured near takeoff, inside the application
  // documents directory; null if generation failed or this entry predates the
  // thumbnail feature.
  //
  // A name, not a path, deliberately: on iOS the documents directory sits in a
  // container whose UUID changes on reinstall and can change across updates,
  // so an absolute path captured at record time goes stale and the entry
  // silently loses its media. Entries written before this change still hold
  // absolute paths — both forms are read through
  // `services/media_file_resolver.dart`, which tries an absolute path as-is
  // and falls back to its basename under the current documents directory.
  // Nothing here interprets the value; it is stored and returned verbatim so
  // the model stays pure and old entries round-trip untouched.
  final String? thumbnailPath;
  // File NAME of the persisted source clip (a copy made at analysis time,
  // since the original image_picker temp file isn't guaranteed to survive);
  // null if the copy failed or this entry predates the video-persistence
  // feature. Same name-not-path rule and same legacy handling as
  // [thumbnailPath].
  final String? videoPath;
  // What the athlete said the clip was (dunk vs. bare jump attempt) —
  // collected for future detector tuning, not yet used to change behavior.
  // Null for entries that predate this feature.
  final VideoAttemptType? attemptType;

  const JumpLogEntry({
    required this.verticalInches,
    required this.recordedAt,
    this.thumbnailPath,
    this.videoPath,
    this.attemptType,
  });

  Map<String, dynamic> toMap() => {
        'verticalInches': verticalInches,
        'recordedAt': recordedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
        'videoPath': videoPath,
        'attemptType': attemptType?.storageKey,
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
    final rawAttemptType = map['attemptType'];
    return JumpLogEntry(
      verticalInches: verticalInches,
      recordedAt: recordedAt,
      thumbnailPath: rawThumb is String ? rawThumb : null,
      videoPath: rawVideo is String ? rawVideo : null,
      attemptType: rawAttemptType is String
          ? VideoAttemptType.fromStorageKey(rawAttemptType)
          : null,
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
