/// The slice of a clip the athlete chose to analyse.
///
/// Trimming here is a *range selection*, never an export: no new video file is
/// ever written. The range is handed to the frame samplers so they spend their
/// fixed frame budget inside the one jump that matters — a shorter range means
/// more samples inside the flight, and flight-time accuracy rides directly on
/// that. It also removes the multi-jump case (which the pose detector rightly
/// refuses to answer) before it can arise.
///
/// Pure Dart, no Flutter imports — the clamping rules are the part worth
/// testing, so they live here rather than in the drag handler.
class TrimRange {
  /// The shortest selection the handles may produce.
  ///
  /// A real jump's airborne time is a few tenths of a second and the athlete
  /// needs ground frames on both sides of it for the ground baseline, so
  /// anything under ~0.6 s cannot contain a measurable jump. Clamping at this
  /// value stops a stray drag from trimming the jump away entirely.
  static const Duration minimumSpan = Duration(milliseconds: 600);

  /// Full length of the underlying clip. Both marks are on this timeline, and
  /// they stay on it all the way through analysis — the takeoff/landing that
  /// come back are used to pull a thumbnail out of the *original* file.
  final Duration clipDuration;
  final Duration start;
  final Duration end;

  const TrimRange._({
    required this.clipDuration,
    required this.start,
    required this.end,
  });

  /// The whole clip selected, i.e. the state the trim screen opens in.
  factory TrimRange.full(Duration clipDuration) {
    final total = clipDuration.isNegative ? Duration.zero : clipDuration;
    return TrimRange._(clipDuration: total, start: Duration.zero, end: total);
  }

  /// Builds a range from arbitrary marks, clamped to the clip and to
  /// [minimumSpan]. Marks that cross are pushed apart, never swapped.
  factory TrimRange.of({
    required Duration clipDuration,
    required Duration start,
    required Duration end,
  }) =>
      TrimRange.full(clipDuration).movingStartTo(start).movingEndTo(end);

  Duration get span => end - start;

  bool get isFullClip => start == Duration.zero && end == clipDuration;

  /// [minimumSpan], except on a clip too short to hold it — then the whole
  /// clip is the floor and the handles simply cannot move.
  Duration get _floor =>
      clipDuration < minimumSpan ? clipDuration : minimumSpan;

  /// Moves the start handle, clamping it into `[0, end - minimumSpan]`.
  TrimRange movingStartTo(Duration value) {
    var maxStart = end - _floor;
    if (maxStart.isNegative) maxStart = Duration.zero;
    var next = value;
    if (next.isNegative) next = Duration.zero;
    if (next > maxStart) next = maxStart;
    return TrimRange._(clipDuration: clipDuration, start: next, end: end);
  }

  /// Moves the end handle, clamping it into
  /// `[start + minimumSpan, clipDuration]`.
  TrimRange movingEndTo(Duration value) {
    var minEnd = start + _floor;
    if (minEnd > clipDuration) minEnd = clipDuration;
    var next = value;
    if (next > clipDuration) next = clipDuration;
    if (next < minEnd) next = minEnd;
    return TrimRange._(clipDuration: clipDuration, start: start, end: next);
  }

  bool contains(Duration position) => position >= start && position <= end;

  /// Where [position] sits along the whole clip, as 0..1 — the timeline's
  /// pixel mapping, kept pure so the drag handler stays trivial.
  double fractionOf(Duration position) {
    final total = clipDuration.inMicroseconds;
    if (total <= 0) return 0;
    final fraction = position.inMicroseconds / total;
    if (fraction < 0) return 0;
    if (fraction > 1) return 1;
    return fraction;
  }

  /// Inverse of [fractionOf].
  Duration positionAt(double fraction) {
    var clamped = fraction;
    if (clamped.isNaN) clamped = 0;
    if (clamped < 0) clamped = 0;
    if (clamped > 1) clamped = 1;
    return Duration(microseconds: (clipDuration.inMicroseconds * clamped).round());
  }

  /// `0:00.0` — minutes, zero-padded seconds, tenths. Matches the reference
  /// app's START/END readout.
  static String formatTimecode(Duration value) {
    final clamped = value.isNegative ? Duration.zero : value;
    final minutes = clamped.inMinutes;
    final seconds = clamped.inSeconds % 60;
    final tenths = (clamped.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  @override
  bool operator ==(Object other) =>
      other is TrimRange &&
      other.clipDuration == clipDuration &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(clipDuration, start, end);

  @override
  String toString() =>
      'TrimRange(${formatTimecode(start)} → ${formatTimecode(end)} '
      'of ${formatTimecode(clipDuration)})';
}
