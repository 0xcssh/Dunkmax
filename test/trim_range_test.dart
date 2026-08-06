import 'package:dunkmax/core/trim_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const clip = Duration(seconds: 10);

  group('TrimRange.full', () {
    test('opens on the whole clip', () {
      final range = TrimRange.full(clip);
      expect(range.start, Duration.zero);
      expect(range.end, clip);
      expect(range.span, clip);
      expect(range.isFullClip, isTrue);
    });

    test('a negative clip length collapses to zero rather than throwing', () {
      final range = TrimRange.full(const Duration(seconds: -3));
      expect(range.clipDuration, Duration.zero);
      expect(range.start, Duration.zero);
      expect(range.end, Duration.zero);
    });
  });

  group('handle clamping', () {
    test('the start handle cannot pass the minimum span before the end', () {
      final range = TrimRange.full(clip)
          .movingEndTo(const Duration(seconds: 4))
          .movingStartTo(const Duration(seconds: 9));
      expect(range.end, const Duration(seconds: 4));
      expect(range.start, const Duration(seconds: 4) - TrimRange.minimumSpan);
      expect(range.span, TrimRange.minimumSpan);
    });

    test('the end handle cannot pass the minimum span after the start', () {
      final range = TrimRange.full(clip)
          .movingStartTo(const Duration(seconds: 6))
          .movingEndTo(Duration.zero);
      expect(range.start, const Duration(seconds: 6));
      expect(range.end, const Duration(seconds: 6) + TrimRange.minimumSpan);
      expect(range.span, TrimRange.minimumSpan);
    });

    test('handles clamp to the clip bounds', () {
      final range = TrimRange.full(clip)
          .movingStartTo(const Duration(seconds: -5))
          .movingEndTo(const Duration(seconds: 40));
      expect(range.start, Duration.zero);
      expect(range.end, clip);
    });

    test('an ordinary trim keeps both marks exactly where they were put', () {
      final range = TrimRange.of(
        clipDuration: clip,
        start: const Duration(milliseconds: 1200),
        end: const Duration(milliseconds: 3400),
      );
      expect(range.start, const Duration(milliseconds: 1200));
      expect(range.end, const Duration(milliseconds: 3400));
      expect(range.isFullClip, isFalse);
    });

    test('a clip shorter than the minimum span pins both handles', () {
      const tiny = Duration(milliseconds: 400);
      final range = TrimRange.full(tiny)
          .movingStartTo(const Duration(milliseconds: 300))
          .movingEndTo(const Duration(milliseconds: 100));
      expect(range.start, Duration.zero);
      expect(range.end, tiny);
    });

    test('crossed marks are pushed apart, never swapped', () {
      final range = TrimRange.of(
        clipDuration: clip,
        start: const Duration(seconds: 7),
        end: const Duration(seconds: 2),
      );
      expect(range.start, lessThan(range.end));
      expect(range.span, greaterThanOrEqualTo(TrimRange.minimumSpan));
    });
  });

  group('timeline mapping', () {
    test('fractionOf and positionAt are inverses within the clip', () {
      final range = TrimRange.full(clip);
      expect(range.fractionOf(const Duration(seconds: 5)), closeTo(0.5, 1e-9));
      expect(range.positionAt(0.5), const Duration(seconds: 5));
    });

    test('both ends of the mapping are clamped', () {
      final range = TrimRange.full(clip);
      expect(range.fractionOf(const Duration(seconds: -2)), 0);
      expect(range.fractionOf(const Duration(seconds: 30)), 1);
      expect(range.positionAt(-1), Duration.zero);
      expect(range.positionAt(2), clip);
    });

    test('a zero-length clip maps everything to the start', () {
      final range = TrimRange.full(Duration.zero);
      expect(range.fractionOf(const Duration(seconds: 1)), 0);
      expect(range.positionAt(1), Duration.zero);
    });

    test('contains covers the selected span inclusively', () {
      final range = TrimRange.of(
        clipDuration: clip,
        start: const Duration(seconds: 2),
        end: const Duration(seconds: 4),
      );
      expect(range.contains(const Duration(seconds: 2)), isTrue);
      expect(range.contains(const Duration(seconds: 3)), isTrue);
      expect(range.contains(const Duration(seconds: 4)), isTrue);
      expect(range.contains(const Duration(milliseconds: 1999)), isFalse);
      expect(range.contains(const Duration(milliseconds: 4001)), isFalse);
    });
  });

  group('formatTimecode', () {
    test('renders minutes, padded seconds and tenths', () {
      expect(TrimRange.formatTimecode(Duration.zero), '0:00.0');
      expect(TrimRange.formatTimecode(const Duration(milliseconds: 1250)), '0:01.2');
      expect(
        TrimRange.formatTimecode(const Duration(minutes: 1, seconds: 5, milliseconds: 900)),
        '1:05.9',
      );
    });

    test('a negative value reads as zero rather than as garbage', () {
      expect(TrimRange.formatTimecode(const Duration(milliseconds: -400)), '0:00.0');
    });
  });

  test('equality is by value', () {
    expect(TrimRange.full(clip), TrimRange.full(clip));
    expect(
      TrimRange.full(clip).movingStartTo(const Duration(seconds: 1)),
      isNot(TrimRange.full(clip)),
    );
  });
}
