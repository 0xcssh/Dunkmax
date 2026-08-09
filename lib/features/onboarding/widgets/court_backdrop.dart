import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// The painted gym-court atmosphere that sits behind the whole onboarding
/// flow.
///
/// Deliberately a [CustomPainter] rather than a photograph: a stock court
/// image would be a licensing dependency and a megabyte of asset weight, where
/// this is a few kilobytes of maths we own outright, can tune exactly, and can
/// animate for free.
///
/// Four layers, back to front:
///  1. a dark vertical gradient base — barely warm at the top, near-black at
///     the bottom;
///  2. a soft warm spotlight haze, off-centre, that drifts and breathes;
///  3. floorboards in perspective, converging on a vanishing point on the
///     horizon and fading out with distance;
///  4. a heavy vignette that drops the edges to near-black.
///
/// Every layer is kept low-contrast on purpose. This is atmosphere behind a
/// quiz: legibility of the text on top beats fidelity of the illustration, so
/// no floorboard is drawn above ~16% alpha and the spotlight peaks near 11%.
class CourtBackdrop extends StatefulWidget {
  /// When false the backdrop is painted once and never animates — used to
  /// honour the platform's "reduce motion" accessibility setting.
  final bool animate;

  const CourtBackdrop({super.key, this.animate = true});

  @override
  State<CourtBackdrop> createState() => _CourtBackdropState();
}

class _CourtBackdropState extends State<CourtBackdrop>
    with SingleTickerProviderStateMixin {
  /// One very slow pass. Long enough that the drift is never *seen* moving,
  /// only noticed as the screen not being dead.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 26),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CourtBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Isolated so the drift never repaints the quiz sitting on top of it.
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CourtPainter(_controller),
        size: Size.infinite,
        isComplex: true,
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  /// Runs 0 → 1 → 0 forever; every use of it is eased, so the turn-around at
  /// each end is not a visible flick.
  final Animation<double> progress;

  _CourtPainter(this.progress) : super(repaint: progress);

  // Warm wood tone for the boards. Only ever drawn at low alpha.
  static const Color _plank = Color(0xFF8A5A31);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    if (width <= 0 || height <= 0) return;

    final rect = Offset.zero & size;
    final phase = Curves.easeInOut.transform(
      progress.value.clamp(0.0, 1.0).toDouble(),
    );
    final drift = phase * 2 - 1; // −1 → 1 → −1

    _paintBase(canvas, rect);

    final horizon = height * 0.46;
    final vanishing = Offset(width * (0.5 + 0.045 * drift), horizon);
    _paintFloor(canvas, size, horizon, vanishing);
    _paintSpotlight(canvas, rect, size, drift, phase);
    _paintVignette(canvas, rect);
  }

  void _paintBase(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF17110C), Color(0xFF0E0B0A), DunkColors.background],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );
  }

  /// Floorboards: rails running away from the viewer into [vanishing], plus
  /// plank joints whose spacing compresses toward the horizon. Both share one
  /// vertical fade so the boards dissolve well before they reach it.
  void _paintFloor(Canvas canvas, Size size, double horizon, Offset vanishing) {
    final width = size.width;
    final height = size.height;
    final floor = Rect.fromLTRB(0, horizon, width, height);

    final fade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        _plank.withValues(alpha: 0.0),
        _plank.withValues(alpha: 0.06),
        _plank.withValues(alpha: 0.16),
      ],
      stops: const [0.0, 0.4, 1.0],
    ).createShader(floor);

    final rail = Paint()
      ..shader = fade
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    final joint = Paint()
      ..shader = fade
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.save();
    canvas.clipRect(floor);

    // Rails. Spread far past both edges so the outermost ones still cross the
    // bottom of the screen at a believable angle.
    const railCount = 16;
    for (var i = 0; i <= railCount; i++) {
      final f = i / railCount;
      final xBottom = -1.3 * width + f * 3.6 * width;
      canvas.drawLine(vanishing, Offset(xBottom, height), rail);
    }

    // Plank joints, spaced by a power curve: tight near the horizon, wide near
    // the viewer — which is what sells the depth.
    const jointCount = 9;
    for (var k = 1; k <= jointCount; k++) {
      final f = k / jointCount;
      final y = horizon + (height - horizon) * math.pow(f, 2.4).toDouble();
      canvas.drawLine(Offset(0, y), Offset(width, y), joint);
    }

    canvas.restore();
  }

  void _paintSpotlight(
    Canvas canvas,
    Rect rect,
    Size size,
    double drift,
    double phase,
  ) {
    final centre = Offset(
      size.width * (0.34 + 0.07 * drift),
      size.height * 0.1,
    );
    final radius = math.max(size.width, size.height) * 0.8;
    // Barely-perceptible breathing: about a fifth of the glow's own strength.
    final intensity = 0.085 + 0.022 * (1 - phase);

    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            DunkColors.primaryBright.withValues(alpha: intensity),
            DunkColors.primary.withValues(alpha: intensity * 0.35),
            DunkColors.primary.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.36, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: radius)),
    );
  }

  void _paintVignette(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.5),
            Colors.black.withValues(alpha: 0.86),
          ],
          stops: const [0.42, 0.84, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
