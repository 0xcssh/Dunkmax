import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/models/motion_sample.dart';

const _maxSamples = 80;
const _thumbSize = 32;

/// Samples evenly-spaced still frames and computes frame-to-frame motion
/// energy between them, for JumpAutoDetector (see
/// core/jump_auto_detector.dart) to find the airborne window from. Thin
/// Flutter/plugin glue — the actual detection logic is pure and lives in
/// core/.
///
/// By default samples ~[_maxSamples] frames across the whole clip. Pass
/// [rangeStart]/[rangeEnd] to restrict sampling to a narrower window (e.g. a
/// coarse jump window found by a first pass) and/or a higher [sampleCount]
/// to sample that window much more densely, for a more precise second pass.
Future<List<MotionSample>> extractMotionSamples(
  File video, {
  Duration? rangeStart,
  Duration? rangeEnd,
  int sampleCount = _maxSamples,
}) async {
  final start = rangeStart ?? Duration.zero;
  final end = rangeEnd ?? await _videoDuration(video);
  if (end <= start) return const [];

  final totalMs = (end - start).inMilliseconds;
  final stepMs = totalMs / sampleCount;

  img.Image? previousGray;
  final samples = <MotionSample>[];

  for (var i = 0; i < sampleCount; i++) {
    final timeMs = (start.inMilliseconds + i * stepMs).round().clamp(
          start.inMilliseconds,
          end.inMilliseconds - 1,
        );
    final Uint8List? bytes = await VideoThumbnail.thumbnailData(
      video: video.path,
      imageFormat: ImageFormat.JPEG,
      maxWidth: _thumbSize,
      quality: 30,
      timeMs: timeMs,
    );
    if (bytes == null) continue;

    final decoded = img.decodeImage(bytes);
    if (decoded == null) continue;
    final gray = img.grayscale(decoded);

    if (previousGray != null) {
      final energy = _frameDifference(previousGray, gray);
      samples.add(MotionSample(timestamp: Duration(milliseconds: timeMs), energy: energy));
    }
    previousGray = gray;
  }

  return samples;
}

Future<Duration> _videoDuration(File video) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();
  final duration = controller.value.duration;
  await controller.dispose();
  return duration;
}

/// Mean absolute pixel-luminance difference between two same-size grayscale
/// frames, normalized to roughly 0..1.
///
/// NOTE: `image` v4.x API used here — `Image.getPixel(x, y)` returns a
/// `Pixel` object exposing `.r`/`.g`/`.b` as num getters (already-decoded
/// channel values, not raw ints requiring bit-shifting like in v2/v3), and
/// `img.grayscale(image)` returns a new grayscale `Image`. This could not be
/// verified against a locally resolved package, so double-check against the
/// actual resolved `image` version if analysis fails on this file.
double _frameDifference(img.Image a, img.Image b) {
  final width = a.width < b.width ? a.width : b.width;
  final height = a.height < b.height ? a.height : b.height;
  if (width == 0 || height == 0) return 0;

  double total = 0;
  var count = 0;
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final pa = a.getPixel(x, y);
      final pb = b.getPixel(x, y);
      final diff = (pa.r - pb.r).abs();
      total += diff;
      count++;
    }
  }
  if (count == 0) return 0;
  return (total / count) / 255.0;
}
