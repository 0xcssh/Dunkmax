/// Pure string helpers for the media paths persisted alongside a jump.
///
/// Why this exists: the app copies each analyzed clip (and its thumbnail) into
/// the application documents directory. On iOS that directory lives inside a
/// container whose UUID is **not stable** — it changes on reinstall and can
/// change across updates — so an absolute path captured at record time goes
/// stale and the entry silently loses its video. What survives is the *file
/// name*, resolved against whatever the documents directory is right now.
///
/// Splitting a path and recognising an absolute one is pure logic, so it lives
/// here and is unit-tested. Looking the directory up is async and needs
/// Flutter, so that half lives in `services/media_file_resolver.dart`
/// (CLAUDE.md: `core/` has zero Flutter imports).
///
/// Both separators are handled on every platform: iOS/Android write POSIX
/// paths, but a desktop or test run can produce Windows ones, and a path
/// stored on one is only ever read as text here.
class MediaPath {
  const MediaPath._();

  /// True when [path] names a location from the filesystem root rather than
  /// relative to something — a POSIX `/…`, a Windows UNC `\\…`, or a drive
  /// root `C:\…` / `C:/…`. A bare file name is never absolute, which is
  /// exactly the distinction the resolver needs.
  static bool isAbsolute(String path) {
    if (path.isEmpty) return false;
    if (_isSeparator(path[0])) return true;
    // Drive letter: at least "C:" plus a separator.
    return path.length >= 3 &&
        _isLetter(path[0]) &&
        path[1] == ':' &&
        _isSeparator(path[2]);
  }

  /// The last segment of [path] — the file name, with any directory part and
  /// any trailing separators removed. Returns an empty string when [path] has
  /// no name part at all (`''`, `'/'`).
  static String basename(String path) {
    var end = path.length;
    while (end > 0 && _isSeparator(path[end - 1])) {
      end--;
    }
    if (end == 0) return '';
    var start = end;
    while (start > 0 && !_isSeparator(path[start - 1])) {
      start--;
    }
    return path.substring(start, end);
  }

  /// Joins a directory and a file name with a single separator, keeping the
  /// separator style [directory] already uses so a Windows path stays a
  /// Windows path.
  static String join(String directory, String name) {
    if (directory.isEmpty) return name;
    if (name.isEmpty) return directory;
    var end = directory.length;
    while (end > 0 && _isSeparator(directory[end - 1])) {
      end--;
    }
    final separator =
        directory.contains('\\') && !directory.contains('/') ? '\\' : '/';
    return '${directory.substring(0, end)}$separator$name';
  }

  static bool _isSeparator(String char) => char == '/' || char == '\\';

  static bool _isLetter(String char) {
    final code = char.codeUnitAt(0);
    return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
  }
}
