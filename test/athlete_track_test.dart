import 'package:dunkmax/core/athlete_track.dart';
import 'package:dunkmax/core/pose_jump_detector.dart';
import 'package:flutter_test/flutter_test.dart';

PoseSample _athlete({
  required int ms,
  required double x,
  required double footY,
  double height = 170,
}) =>
    PoseSample(
      timestamp: Duration(milliseconds: ms),
      foot: PosePoint(x, footY),
      footY: footY,
      torsoPixels: height * 0.3,
      leftHip: PosePoint(x - 8, footY - height * 0.5),
      rightHip: PosePoint(x + 8, footY - height * 0.5),
      leftShoulder: PosePoint(x - 10, footY - height * 0.8),
      rightShoulder: PosePoint(x + 10, footY - height * 0.8),
    );

void main() {
  group('AthleteBox', () {
    test('is centred on the tracked landmarks, with room around them', () {
      final box = AthleteBox.around(_athlete(ms: 0, x: 300, footY: 640))!;

      expect(box.centerX, closeTo(300, 1));
      // Feet at 640, shoulders at 640 − 136: centre halfway.
      expect(box.centerY, closeTo(640 - 68, 1));
      expect(box.side, closeTo(136 * AthleteBox.margin, 1));
    });

    test('never shrinks below the smallest useful crop', () {
      final box =
          AthleteBox.around(_athlete(ms: 0, x: 300, footY: 640, height: 30))!;

      expect(box.side, AthleteBox.minSide);
    });

    test('a sample with nothing tracked has no box', () {
      expect(
        AthleteBox.around(const PoseSample(timestamp: Duration.zero)),
        isNull,
      );
    });

    test('the crop is slid back inside the frame, not clipped', () {
      const box = AthleteBox(centerX: 620, centerY: 1120, side: 300);
      final crop = box.cropIn(640, 1138);

      expect(crop.side, 300);
      expect(crop.left, 340);
      expect(crop.top, 838);
    });

    test('a box bigger than the frame becomes the frame\'s short side', () {
      const box = AthleteBox(centerX: 320, centerY: 600, side: 2000);
      final crop = box.cropIn(640, 1138);

      expect(crop.side, 640);
      expect(crop.left, 0);
      expect(crop.top, closeTo(280, 1e-9));
    });
  });

  group('AthleteTrack', () {
    test('answers with the sighting nearest in time', () {
      final track = AthleteTrack()
        ..remember(_athlete(ms: 1000, x: 100, footY: 800))
        ..remember(_athlete(ms: 1600, x: 400, footY: 650));

      expect(track.near(const Duration(milliseconds: 1100))!.centerX,
          closeTo(100, 1));
      expect(track.near(const Duration(milliseconds: 1500))!.centerX,
          closeTo(400, 1));
    });

    test('works backwards in time too — frames are not visited in order', () {
      final track = AthleteTrack()
        ..remember(_athlete(ms: 2000, x: 400, footY: 650));

      expect(track.near(const Duration(milliseconds: 1700)), isNotNull);
    });

    test('a sighting more than a second old says nothing', () {
      final track = AthleteTrack()
        ..remember(_athlete(ms: 1000, x: 100, footY: 800));

      expect(track.near(const Duration(milliseconds: 2001)), isNull);
      expect(track.near(const Duration(milliseconds: 2000)), isNotNull);
    });

    test('an empty frame is not a sighting', () {
      final track = AthleteTrack()
        ..remember(const PoseSample(timestamp: Duration(milliseconds: 500)));

      expect(track.near(const Duration(milliseconds: 500)), isNull);
    });
  });
}
