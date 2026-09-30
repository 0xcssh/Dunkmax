import 'dart:io';
import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/pose_jump_detector.dart';

/// Frame width handed to ML Kit. The pose model needs enough pixels to resolve
/// ankles on a full-body subject; 640 px is comfortably enough while keeping
/// the decode cheap.
const _frameWidth = 640;

/// Lowest landmark confidence accepted. ML Kit reports a likelihood per
/// landmark; a low-confidence ankle is a guess, and a guessed foot position is
/// exactly the kind of fabricated data this project refuses to act on.
const _minLikelihood = 0.5;

/// Decodes frames of one clip and reduces each to a [PoseSample].
///
/// Thin plugin glue by design. *Which* frames to look at is decided by
/// `core/jump_analysis_pipeline.dart` and *what they mean* by
/// `core/pose_jump_detector.dart`, both pure and tested; this only turns a
/// timestamp into landmarks. One pose model and one scratch directory are held
/// for the whole analysis rather than rebuilt per pass.
///
/// Timestamps are on the **original clip's** timeline throughout — they are
/// later used to pull a thumbnail out of the original file, so rebasing them
/// to zero would silently grab the wrong frame.
class PoseFrameExtractor {
  final File video;

  /// Called after every frame, decoded or not, so the processing screen can
  /// show real progress.
  final void Function()? onFrame;

  PoseFrameExtractor(this.video, {this.onFrame});

  PoseDetector? _detector;
  Directory? _workDir;
  var _frameIndex = 0;

  /// Frames asked for, and how many of those could not even be decoded.
  var requested = 0;
  var undecoded = 0;

  /// The last decode or inference error, for the developer-facing details.
  Object? lastError;

  /// One [PoseSample] per timestamp, in order.
  ///
  /// A frame where no athlete was found (or where the needed landmarks were
  /// low-confidence) comes back as a sample with null measurements, never as a
  /// zero: "not found" must not read as "at the very top of the frame". A
  /// frame that could not be decoded is reported the same way, so the
  /// detector's missing-frame guards can see it rather than the series
  /// silently getting shorter — but when *no* frame of a pass decodes, the
  /// list comes back empty, which the pipeline reports as an unreadable clip
  /// instead of as an athlete who was never in shot.
  Future<List<PoseSample>> sample(List<Duration> timestamps) async {
    if (timestamps.isEmpty) return const [];
    final detector = _detector ??= PoseDetector(
      options: PoseDetectorOptions(
        // Still images, one at a time: the accurate model in single-image mode
        // is exactly the configuration this pass is. Stream mode would trade
        // the landmark precision we are here for against a latency we do not
        // need.
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.single,
      ),
    );
    final workDir = _workDir ??= await _createWorkDir();

    final samples = <PoseSample>[];
    var decoded = 0;
    for (final timestamp in timestamps) {
      requested++;
      String? framePath;
      try {
        framePath = await VideoThumbnail.thumbnailFile(
          video: video.path,
          thumbnailPath: '${workDir.path}/frame_${_frameIndex++}.jpg',
          imageFormat: ImageFormat.JPEG,
          maxWidth: _frameWidth,
          quality: 85,
          timeMs: timestamp.inMilliseconds,
        );
        final path = framePath;
        if (path == null) {
          undecoded++;
          samples.add(PoseSample(timestamp: timestamp));
          continue;
        }
        decoded++;
        final poses =
            await detector.processImage(InputImage.fromFilePath(path));
        samples.add(_toSample(timestamp, poses));
      } catch (error) {
        // One unreadable frame or one failed inference must not sink the
        // whole clip — it is just a missing detection.
        lastError = error;
        if (framePath == null) undecoded++;
        samples.add(PoseSample(timestamp: timestamp));
      } finally {
        if (framePath != null) {
          try {
            await File(framePath).delete();
          } catch (_) {
            // Best-effort cleanup; the directory is removed in [close].
          }
        }
        onFrame?.call();
      }
    }
    return decoded == 0 ? const [] : samples;
  }

  Future<Directory> _createWorkDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(
      '${tempDir.path}/pose_frames_${DateTime.now().millisecondsSinceEpoch}',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> close() async {
    try {
      await _detector?.close();
    } catch (_) {
      // Nothing useful to do about a detector that will not close.
    }
    _detector = null;
    try {
      await _workDir?.delete(recursive: true);
    } catch (_) {
      // Temp dir cleanup is best-effort.
    }
    _workDir = null;
  }
}

/// Reduces one frame's poses to a [PoseSample].
///
/// - `foot` / `footY`: the *lower* of the two feet. Heel and foot-index
///   landmarks are preferred over the ankle when confident, because they sit at
///   the actual ground-contact point; the ankle is the fallback. "Lower" is
///   judged along **this frame's own torso direction**, not along image y: on a
///   phone clip whose rotation flag was never applied the athlete lies sideways,
///   and image y then picks whichever foot happens to be leftmost. That per
///   frame direction only decides *which* foot to take — a discrete choice
///   between two landmarks — while the measurement itself is projected onto the
///   clip-wide axis `PoseJumpDetector` derives from the grounded frames.
///   `footY` is kept alongside the point for series that only read the scalar.
/// - `torsoPixels`: shoulder-midpoint to hip-midpoint, as a **full 2-D
///   distance**. Rigid through a jump, unlike anything that includes the legs
///   (which tuck mid-flight), so it tracks only how far the athlete is from the
///   camera. This used to be the difference of the two y coordinates, which
///   collapses to nearly zero on a sideways frame and took the whole scale
///   reference down with it.
/// - the individual ankle/knee/hip/shoulder/wrist landmarks, which the form
///   scores (`core/jump_form_scores.dart`) need and the timing does not. Each
///   goes through the same [_minLikelihood] gate independently, so a frame can
///   carry a confident hip and no wrist at all — and the score that needed the
///   wrist is then honestly absent rather than defaulted.
///
/// If more than one person was found, the largest (nearest) is taken as the
/// athlete.
PoseSample _toSample(Duration timestamp, List<Pose> poses) {
  if (poses.isEmpty) return PoseSample(timestamp: timestamp);

  Pose? best;
  var bestTorso = 0.0;
  for (final pose in poses) {
    final torso = _torsoPixels(pose);
    if (torso != null && torso > bestTorso) {
      best = pose;
      bestTorso = torso;
    }
  }
  if (best == null) return PoseSample(timestamp: timestamp);

  final foot = _foot(best);
  if (foot == null) return PoseSample(timestamp: timestamp);

  return PoseSample(
    timestamp: timestamp,
    footY: foot.y,
    foot: foot,
    torsoPixels: bestTorso,
    leftAnkle: _point(best, PoseLandmarkType.leftAnkle),
    rightAnkle: _point(best, PoseLandmarkType.rightAnkle),
    leftKnee: _point(best, PoseLandmarkType.leftKnee),
    rightKnee: _point(best, PoseLandmarkType.rightKnee),
    leftHip: _point(best, PoseLandmarkType.leftHip),
    rightHip: _point(best, PoseLandmarkType.rightHip),
    leftShoulder: _point(best, PoseLandmarkType.leftShoulder),
    rightShoulder: _point(best, PoseLandmarkType.rightShoulder),
    leftWrist: _point(best, PoseLandmarkType.leftWrist),
    rightWrist: _point(best, PoseLandmarkType.rightWrist),
  );
}

/// One landmark as a [PosePoint], or null when the model was not confident
/// enough about it. Never a zeroed point — see [PoseSample].
PosePoint? _point(Pose pose, PoseLandmarkType type) {
  final landmark = pose.landmarks[type];
  if (landmark == null) return null;
  if (landmark.likelihood < _minLikelihood) return null;
  return PosePoint(landmark.x, landmark.y);
}

/// Shoulder-midpoint to hip-midpoint, as a 2-D distance so it survives a frame
/// the athlete appears sideways in.
double? _torsoPixels(Pose pose) {
  final shoulder = _mid(
    pose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
  );
  final hip = _mid(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
  if (shoulder == null || hip == null) return null;
  final dx = hip.x - shoulder.x;
  final dy = hip.y - shoulder.y;
  final torso = math.sqrt(dx * dx + dy * dy);
  return torso > 0 ? torso : null;
}

/// This frame's torso direction, pointing from the hips toward the shoulders.
/// Used only to decide which foot is the lower one; the measurement itself
/// runs on the clip-wide axis (see `core/pose_jump_detector.dart`).
({double x, double y})? _torsoUp(Pose pose) {
  final shoulder = _mid(
    pose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
  );
  final hip = _mid(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
  if (shoulder == null || hip == null) return null;
  final x = shoulder.x - hip.x;
  final y = shoulder.y - hip.y;
  if (x == 0 && y == 0) return null;
  return (x: x, y: y);
}

/// Midpoint of two confident landmarks, or the single confident one, or null.
PosePoint? _mid(Pose pose, PoseLandmarkType a, PoseLandmarkType b) =>
    PosePoint.mid(_point(pose, a), _point(pose, b));

/// Lowest confident foot landmark of either leg — heel and foot index first,
/// ankle as the fallback.
///
/// "Lowest" means furthest *down the athlete's own torso direction* when that
/// is available, and furthest down the image otherwise. On an upright frame the
/// two agree; on a sideways one only the former picks the right foot.
PosePoint? _foot(Pose pose) {
  final up = _torsoUp(pose);
  double descent(PosePoint p) =>
      up == null ? p.y : -(p.x * up.x + p.y * up.y);

  const candidates = [
    PoseLandmarkType.leftHeel,
    PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex,
    PoseLandmarkType.rightFootIndex,
  ];
  const ankles = [PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle];

  PosePoint? lowestOf(List<PoseLandmarkType> types) {
    PosePoint? lowest;
    for (final type in types) {
      final p = _point(pose, type);
      if (p == null) continue;
      if (lowest == null || descent(p) > descent(lowest)) lowest = p;
    }
    return lowest;
  }

  return lowestOf(candidates) ?? lowestOf(ankles);
}
