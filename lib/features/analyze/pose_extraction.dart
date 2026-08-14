import 'dart:io';
import 'dart:math' as math;

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

/// Second-pass budget, spent entirely inside the located jump. Fitting the
/// flight parabola is only as good as the number of airborne samples it has
/// to work with, and this is where they come from.
const _refineFrames = 40;
const _refineMinStepMs = 15;

/// How far either side of the coarse window the dense pass reaches, so the
/// refined series still contains ground frames on both sides of the flight.
const _refinePaddingMs = 200;

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
///
/// [rangeStart]/[rangeEnd] restrict the *coarse* pass to the slice the athlete
/// trimmed to (see `core/trim_range.dart`), which is what makes trimming worth
/// doing: the frame budget is fixed, so a narrower range spends more of it
/// inside the flight. The dense second pass then runs unchanged within that
/// slice. Timestamps stay on the **original clip's** timeline throughout —
/// they are later used to pull a thumbnail out of the original file, so
/// rebasing them to zero would silently grab the wrong frame.
Future<List<PoseSample>> extractPoseSamples(
  File video, {
  Duration? rangeStart,
  Duration? rangeEnd,
}) async {
  final duration = await _videoDuration(video);
  if (duration <= Duration.zero) return const [];
  final totalMs = duration.inMilliseconds;

  final fromMs = (rangeStart?.inMilliseconds ?? 0).clamp(0, totalMs);
  final toMs = (rangeEnd?.inMilliseconds ?? totalMs).clamp(fromMs, totalMs);
  if (toMs <= fromMs) return const [];

  // Pass 1: spread across the selected range, to place the ground baseline
  // and find roughly where the jump is.
  final coarse = await _sampleRange(video, fromMs: fromMs, toMs: toMs);
  final located = PoseJumpDetector.detectWithDiagnostics(coarse).result;
  if (located == null) return coarse;

  // Pass 2: spend the remaining budget inside the jump. Fitting the flight
  // parabola needs several airborne points to pin its curvature, and a pass
  // spread over the whole clip leaves only a handful — on a real capture it
  // left four, 132 ms apart, and the fit came out 6" long.
  //
  // The two passes are then merged and handed to the detector *together*, so
  // the baseline is still drawn from the clip-wide standing frames. That is
  // the difference from an earlier two-pass attempt that re-derived its
  // threshold from the narrow window alone and turned a 20" reading into 50".
  final padMs = _refinePaddingMs;
  final dense = await _sampleRange(
    video,
    fromMs: (located.takeoff.inMilliseconds - padMs).clamp(fromMs, toMs),
    toMs: (located.landing.inMilliseconds + padMs).clamp(fromMs, toMs),
    maxFrames: _refineFrames,
    minStepMs: _refineMinStepMs,
  );

  final byTime = <int, PoseSample>{
    for (final s in coarse) s.timestamp.inMilliseconds: s,
    for (final s in dense) s.timestamp.inMilliseconds: s,
  };
  final merged = byTime.values.toList()
    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  return merged;
}

/// Samples [maxFrames] evenly spaced frames between [fromMs] and [toMs] and
/// reduces each to a [PoseSample].
Future<List<PoseSample>> _sampleRange(
  File video, {
  required int fromMs,
  required int toMs,
  int maxFrames = _maxFrames,
  int minStepMs = _minStepMs,
}) async {
  final totalMs = toMs - fromMs;
  if (totalMs <= 0) return const [];

  var frameCount = maxFrames;
  if (totalMs ~/ minStepMs < frameCount) {
    frameCount = totalMs ~/ minStepMs;
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
      final timeMs =
          (fromMs + i * stepMs).round().clamp(fromMs, fromMs + totalMs - 1);
      String? framePath;
      try {
        framePath = await VideoThumbnail.thumbnailFile(
          video: video.path,
          thumbnailPath: '${workDir.path}/frame_${fromMs}_$i.jpg',
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

Future<Duration> _videoDuration(File video) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();
  final duration = controller.value.duration;
  await controller.dispose();
  return duration;
}
