import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/media_path.dart';

/// Turns the media path a JumpLogEntry stored into a file that exists today.
///
/// The Analyze flow copies each clip and thumbnail into the application
/// documents directory and stores only the **file name**. On iOS the documents
/// directory sits inside a container whose UUID changes on reinstall (and can
/// change across updates), so an absolute path captured at record time is not
/// a durable identifier — the file name is. Resolution therefore happens at
/// read time, against the current directory.
///
/// Entries written before that change hold absolute paths. They are handled
/// too: an absolute path is tried as-is first (still correct while the
/// container has not moved), and only if the file is gone do we fall back to
/// its basename resolved against the current documents directory — which is
/// exactly the case where the container moved and the file is still there
/// under a new prefix. When neither exists the answer is `null`, and every
/// call site paints its honest empty state rather than a broken affordance.
///
/// The lookup is async, so the directory is cached once at startup by
/// [initialize] and every read after that is synchronous — the callers are
/// `build` methods. Uninitialized (a widget test, a failed lookup) degrades to
/// "absolute paths only", never to a crash.
class MediaFileResolver {
  MediaFileResolver._();

  /// One shared instance: the documents directory is a process-wide fact, and
  /// resolution happens deep inside widget trees that have no store to thread
  /// it through.
  static final MediaFileResolver instance = MediaFileResolver._();

  String? _documentsPath;

  /// The current documents directory, or null if it was never looked up.
  String? get documentsPath => _documentsPath;

  bool get isInitialized => _documentsPath != null;

  /// Caches the documents directory. Safe to call more than once; a failure is
  /// swallowed (and leaves the resolver uninitialized so a later call retries)
  /// because a missing directory must degrade the jump thumbnails, not the
  /// launch.
  Future<void> initialize() async {
    if (_documentsPath != null) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      _documentsPath = dir.path;
    } catch (_) {
      // Left uninitialized on purpose — see the doc comment.
    }
  }

  /// The existing file [stored] refers to, or null when there is none.
  ///
  /// [stored] is whatever the entry persisted: a bare file name (current) or a
  /// legacy absolute path.
  File? resolve(String? stored) {
    if (stored == null) return null;
    final trimmed = stored.trim();
    if (trimmed.isEmpty) return null;

    if (MediaPath.isAbsolute(trimmed)) {
      final asStored = File(trimmed);
      if (_exists(asStored)) return asStored;
      // Fall through: the container most likely moved, so try the name.
    }

    final documents = _documentsPath;
    if (documents == null) return null;
    final name = MediaPath.basename(trimmed);
    if (name.isEmpty) return null;
    final candidate = File(MediaPath.join(documents, name));
    return _exists(candidate) ? candidate : null;
  }

  /// True when [stored] still points at a file on this device.
  bool exists(String? stored) => resolve(stored) != null;

  /// What to persist for a file just written into the documents directory:
  /// its name, never its absolute path.
  static String? storageNameFor(String? writtenPath) {
    if (writtenPath == null) return null;
    final name = MediaPath.basename(writtenPath);
    return name.isEmpty ? null : name;
  }

  static bool _exists(File file) {
    try {
      return file.existsSync();
    } on FileSystemException {
      return false;
    }
  }
}
