import 'dart:io';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/pose_jump_detector.dart';

/// How many frames the clip is sampled at, at most.
///
/// Every frame costs a JPEG decode *plus* an ML Kit inference, so this is a
/// direct trade of processing seconds against temporal resolution — and
/// temporal resolution is what the whole feature's accuracy rides on. 60
/// frames over a typical 2–3 s jump clip is a ~40–50 ms step, which after
/// [PoseJumpDetector]'s between-sample interpolation leaves quantisation well
/// below the millisecond scale that matters. On a modern phone that is a few
/// seconds of work, which the processing screen already covers honestly.
const _maxFrames = 60;

/// Never sample finer than this. Below ~30 ms we would be asking the decoder
/// for frames that a 30 fps clip does not contain, paying full inference cost
/// for duplicates.
const _minStepMs = 30;

/// Frame width handed to ML Kit. The pose model needs enough pixels to resolve
/// ankles on a full-body subject; 640 px is comfortably enough while keeping
/// the decode cheap. (Unlike the motion-energy path, resolution genuinely
/// matters here — that path measured a ratio of moving area to total area and
/// was therefore scale-invariant; landmark localisation is not.)
const _frameWidth = 640;

/// Lowest landmark confidence accepted. ML Kit reports a likelihood per
/// landmark; a low-confidence ankle is a guess, and a guessed foot position is
/// exactly the kind of fabricated data this project refuses to act on.
const _minLikelihood = 0.5;

/// Samples still frames across the clip, runs on-device pose detection on each
/// and reduces every frame to the two numbers [PoseJumpDetector] needs: where
/// the athlete's lower foot was, and how big the athlete is in that frame.
///
/// Thin plugin glue by design — the detection rule itself is pure and tested
/// in `core/pose_jump_detector.dart`. Frames where no athlete was found (or
/// where the needed landmarks were low-confidence) come back as a sample with
/// null measurements, never as a zero: "not found" must not read as "at the
/// very top of the frame".
Future<List<PoseSample>> extractPoseSamples(File video) async {
  final duration = await _videoDuration(video);
  if (duration <= Duration.zero) return const [];

  final totalMs = duration.inMilliseconds;
  var frameCount = _maxFrames;
  if (totalMs ~/ _minStepMs < frameCount) {
    frameCount = totalMs ~/ _minStepMs;
  }
  if (frameCount < 2) return const [];
  final stepMs = totalMs / frameCount;

  final tempDir = await getTemporaryDirectory();
  final workDir = Directory(
    '${tempDir.path}/pose_frames_${DateTime.now().millisecondsSinceEpoch}',
  );
  await workDir.create(recursive: true);

  final detector = PoseDetector(
    options: PoseDetectorOptions(
      // Still images, one at a time: the accurate model in single-image mode
      // is exactly the configuration this pass is. Stream mode would trade the
      // landmark precision we are here for against a latency we do not need.
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.single,
    ),
  );

  final samples = <PoseSample>[];
  try {
    for (var i = 0; i < frameCount; i++) {
      final timeMs = (i * stepMs).round().clamp(0, totalMs - 1);
      String? framePath;
      try {
        framePath = await VideoThumbnail.thumbnailFile(
          video: video.path,
          thumbnailPath: '${workDir.path}/frame_$i.jpg',
          imageFormat: ImageFormat.JPEG,
          maxWidth: _frameWidth,
          quality: 85,
          timeMs: timeMs,
        );
        final path = framePath;
        if (path == null) {
          // Frame could not be decoded — count it as a missing detection so
          // the detector's "athlete not found often enough" guard can see it,
          // rather than silently shortening the series.
          samples.add(PoseSample(timestamp: Duration(milliseconds: timeMs)));
          continue;
        }

        final poses =
            await detector.processImage(InputImage.fromFilePath(path));
        samples.add(_toSample(Duration(milliseconds: timeMs), poses));
      } catch (_) {
        // One unreadable frame or one failed inference must not sink the
        // whole clip — it is just a missing detection.
        samples.add(PoseSample(timestamp: Duration(milliseconds: timeMs)));
      } finally {
        if (framePath != null) {
          try {
            await File(framePath).delete();
          } catch (_) {
            // Best-effort cleanup; the directory is removed below anyway.
          }
        }
      }
    }
  } finally {
    await detector.close();
    try {
      await workDir.delete(recursive: true);
    } catch (_) {
      // Temp dir cleanup is best-effort.
    }
  }

  return samples;
}

/// Reduces one frame's poses to a [PoseSample].
///
/// - `footY`: the *lower* of the two feet, i.e. the larger y (image
///   coordinates grow downward). Heel and foot-index landmarks are preferred
///   over the ankle when confident, because they sit at the actual
///   ground-contact point; the ankle is the fallback.
/// - `torsoPixels`: shoulder-midpoint to hip-midpoint. Rigid through a jump,
///   unlike anything that includes the legs (which tuck mid-flight), so it
///   tracks only how far the athlete is from the camera.
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

  final footY = _footY(best);
  if (footY == null) return PoseSample(timestamp: timestamp);

  return PoseSample(
    timestamp: timestamp,
    footY: footY,
    torsoPixels: bestTorso,
  );
}

double? _torsoPixels(Pose pose) {
  final shoulderY = _midY(
    pose,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
  );
  final hipY = _midY(pose, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
  if (shoulderY == null || hipY == null) return null;
  final torso = (hipY - shoulderY).abs();
  return torso > 0 ? torso : null;
}

/// Mean y of two confident landmarks, or the single confident one, or null.
double? _midY(Pose pose, PoseLandmarkType a, PoseLandmarkType b) {
  final ya = _landmarkY(pose, a);
  final yb = _landmarkY(pose, b);
  if (ya != null && yb != null) return (ya + yb) / 2;
  return ya ?? yb;
}

/// Largest y (lowest point on screen) among the confident foot landmarks of
/// either leg — heel and foot index first, ankle as the fallback.
double? _footY(Pose pose) {
  const candidates = [
    PoseLandmarkType.leftHeel,
    PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex,
    PoseLandmarkType.rightFootIndex,
  ];

  double? lowest;
  for (final type in candidates) {
    final y = _landmarkY(pose, type);
    if (y != null && (lowest == null || y > lowest)) lowest = y;
  }
  if (lowest != null) return lowest;

  const ankles = [PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle];
  for (final type in ankles) {
    final y = _landmarkY(pose, type);
    if (y != null && (lowest == null || y > lowest)) lowest = y;
  }
  return lowest;
}

double? _landmarkY(Pose pose, PoseLandmarkType type) {
  final landmark = pose.landmarks[type];
  if (landmark == null) return null;
  if (landmark.likelihood < _minLikelihood) return null;
  return landmark.y;
}

Future<Duration> _videoDuration(File video) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();
  final duration = controller.value.duration;
  await controller.dispose();
  return duration;
}
