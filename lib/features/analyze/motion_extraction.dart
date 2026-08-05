import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../core/models/motion_sample.dart';

const _maxSamples = 50;
const _thumbSize = 32;

/// Samples ~[_maxSamples] evenly-spaced still frames across [video] and
/// computes frame-to-frame motion energy between them, for
/// JumpAutoDetector (see core/jump_auto_detector.dart) to find the
/// airborne window from. Thin Flutter/plugin glue — the actual detection
/// logic is pure and lives in core/.
Future<List<MotionSample>> extractMotionSamples(File video) async {
  final controller = VideoPlayerController.file(video);
  await controller.initialize();
  final duration = controller.value.duration;
  await controller.dispose();

  if (duration <= Duration.zero) return const [];

  final sampleCount = _maxSamples;
  final stepMs = duration.inMilliseconds / sampleCount;

  img.Image? previousGray;
  final samples = <MotionSample>[];

  for (var i = 0; i < sampleCount; i++) {
    final timeMs = (i * stepMs).round().clamp(0, duration.inMilliseconds - 1);
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
