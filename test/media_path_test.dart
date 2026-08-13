import 'package:dunkmax/core/media_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isAbsolute', () {
    test('a bare file name is relative', () {
      expect(MediaPath.isAbsolute('jump_video_1723.mov'), isFalse);
      expect(MediaPath.isAbsolute('jump_1723.jpg'), isFalse);
    });

    test('an iOS container path is absolute', () {
      expect(
        MediaPath.isAbsolute(
          '/var/mobile/Containers/Data/Application/AAAA-BBBB/Documents/j.mov',
        ),
        isTrue,
      );
    });

    test('windows drive and UNC roots are absolute', () {
      expect(MediaPath.isAbsolute(r'C:\Users\a\jump.mov'), isTrue);
      expect(MediaPath.isAbsolute('C:/Users/a/jump.mov'), isTrue);
      expect(MediaPath.isAbsolute(r'\\server\share\jump.mov'), isTrue);
    });

    test('a relative directory path is not absolute', () {
      expect(MediaPath.isAbsolute('Documents/jump.mov'), isFalse);
      expect(MediaPath.isAbsolute(r'Documents\jump.mov'), isFalse);
    });

    test('a drive letter with no separator is not treated as a root', () {
      expect(MediaPath.isAbsolute('C:jump.mov'), isFalse);
    });

    test('empty is not absolute', () {
      expect(MediaPath.isAbsolute(''), isFalse);
    });
  });

  group('basename', () {
    test('strips a POSIX directory', () {
      expect(
        MediaPath.basename('/var/mobile/Containers/Data/jump_video_17.mov'),
        'jump_video_17.mov',
      );
    });

    test('strips a Windows directory', () {
      expect(MediaPath.basename(r'C:\Users\a\jump_17.jpg'), 'jump_17.jpg');
    });

    test('a bare name is returned unchanged', () {
      expect(MediaPath.basename('jump_video_17.mov'), 'jump_video_17.mov');
    });

    test('trailing separators are ignored', () {
      expect(MediaPath.basename('/a/b/'), 'b');
      expect(MediaPath.basename(r'C:\a\b\\'), 'b');
    });

    test('a path with no name part yields empty', () {
      expect(MediaPath.basename(''), '');
      expect(MediaPath.basename('/'), '');
      expect(MediaPath.basename('///'), '');
    });

    test('is idempotent — a basename of a basename is the same', () {
      const stored = '/Documents/jump_video_1723.mov';
      expect(
        MediaPath.basename(MediaPath.basename(stored)),
        MediaPath.basename(stored),
      );
    });
  });

  group('join', () {
    test('inserts exactly one separator', () {
      expect(MediaPath.join('/var/Documents', 'j.mov'), '/var/Documents/j.mov');
      expect(MediaPath.join('/var/Documents/', 'j.mov'), '/var/Documents/j.mov');
      expect(
        MediaPath.join('/var/Documents///', 'j.mov'),
        '/var/Documents/j.mov',
      );
    });

    test('keeps a Windows directory using backslashes', () {
      expect(MediaPath.join(r'C:\Users\a', 'j.mov'), r'C:\Users\a\j.mov');
      expect(MediaPath.join(r'C:\Users\a\', 'j.mov'), r'C:\Users\a\j.mov');
    });

    test('a mixed-separator directory falls back to a forward slash', () {
      expect(MediaPath.join(r'C:/Users\a', 'j.mov'), r'C:/Users\a/j.mov');
    });

    test('degrades rather than inventing a separator', () {
      expect(MediaPath.join('', 'j.mov'), 'j.mov');
      expect(MediaPath.join('/var/Documents', ''), '/var/Documents');
    });

    test('round-trips a name through a directory', () {
      const dir = '/var/mobile/Containers/Data/Application/NEW/Documents';
      const name = 'jump_video_1723.mov';
      final joined = MediaPath.join(dir, name);
      expect(MediaPath.isAbsolute(joined), isTrue);
      expect(MediaPath.basename(joined), name);
    });
  });
}
