import 'dart:math' as math;

import 'pose_jump_detector.dart';

/// Where the athlete was in one frame: a square around their tracked
/// landmarks, in that frame's pixel coordinates.
///
/// ## Why this exists
///
/// A pose model finds the person first and the joints second, and the first
/// step works on the whole frame shrunk to a couple of hundred pixels. An
/// athlete who runs five metres away from the phone before jumping ends up
/// ~170 px tall in a 1138 px frame — about 30 px in what the person-finder
/// sees — and is simply not found, in the very frames that hold the jump. On
/// the clip that showed this, the model lost him in 65 of 121 frames.
///
/// He has not gone anywhere, though: he is where he was a frame ago, give or
/// take. Cropping the frame to a square around his last known position and
/// running the model on *that* puts him back at a size it can see. Measured
/// on that clip: 121 of 121 frames tracked.
class AthleteBox {
  final double centerX;
  final double centerY;

  /// Side of the square to crop, before it is fitted to a frame.
  final double side;

  const AthleteBox({
    required this.centerX,
    required this.centerY,
    required this.side,
  });

  /// How much wider than the tracked landmarks the crop is. The landmarks a
  /// [PoseSample] keeps stop at the shoulders, and the athlete moves between
  /// frames — 2.2x leaves the head, a raised arm and a stride's travel inside.
  static const double margin = 2.2;

  /// Smallest crop worth making. Below this there are too few pixels in the
  /// square for the model to work with whatever it is scaled to.
  static const double minSide = 160;

  /// The box around a tracked sample, or null when it carries no points to
  /// put a box around.
  static AthleteBox? around(PoseSample sample) {
    final points = [
      sample.foot,
      sample.leftAnkle,
      sample.rightAnkle,
      sample.leftKnee,
      sample.rightKnee,
      sample.leftHip,
      sample.rightHip,
      sample.leftShoulder,
      sample.rightShoulder,
      sample.leftWrist,
      sample.rightWrist,
    ].whereType<PosePoint>().toList();
    if (points.length < 2) return null;

    var minX = points.first.x, maxX = points.first.x;
    var minY = points.first.y, maxY = points.first.y;
    for (final p in points) {
      minX = math.min(minX, p.x);
      maxX = math.max(maxX, p.x);
      minY = math.min(minY, p.y);
      maxY = math.max(maxY, p.y);
    }
    final extent = math.max(maxX - minX, maxY - minY);
    return AthleteBox(
      centerX: (minX + maxX) / 2,
      centerY: (minY + maxY) / 2,
      side: math.max(minSide, extent * margin),
    );
  }

  /// This box fitted inside a [frameWidth] x [frameHeight] frame: shrunk to
  /// the frame's short side if need be, then slid back in bounds rather than
  /// clipped, so the crop is always a full square of real pixels.
  ({double left, double top, double side}) cropIn(
    double frameWidth,
    double frameHeight,
  ) {
    final fitted = math.min(side, math.min(frameWidth, frameHeight));
    final left = (centerX - fitted / 2).clamp(0.0, frameWidth - fitted);
    final top = (centerY - fitted / 2).clamp(0.0, frameHeight - fitted);
    return (left: left, top: top, side: fitted);
  }
}

/// Remembers where the athlete was at each instant they were found, and
/// answers where to look at an instant they were not.
///
/// Keyed by time rather than "the previous frame" because frames are not
/// visited in order: the pipeline scans the clip sparsely, then goes back over
/// one stretch of it densely.
class AthleteTrack {
  /// How stale a sighting may be and still say where to look. An athlete at a
  /// sprint covers a body length in well under this; past it the box is a
  /// guess, and on a clip where the athlete is simply not in shot it would
  /// cost a second inference on every empty frame for nothing.
  static const Duration maxAge = Duration(seconds: 1);

  final _sightings = <({Duration at, AthleteBox box})>[];

  void remember(PoseSample sample) {
    if (!sample.isDetected) return;
    final box = AthleteBox.around(sample);
    if (box != null) _sightings.add((at: sample.timestamp, box: box));
  }

  /// The sighting nearest in time to [instant], if one is within [maxAge].
  AthleteBox? near(Duration instant) {
    AthleteBox? best;
    var bestGap = maxAge + const Duration(microseconds: 1);
    for (final sighting in _sightings) {
      final gap = (sighting.at - instant).abs();
      if (gap < bestGap) {
        bestGap = gap;
        best = sighting.box;
      }
    }
    return best;
  }
}
