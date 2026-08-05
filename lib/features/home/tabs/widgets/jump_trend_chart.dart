import 'package:flutter/material.dart';

import '../../../../core/models/jump_log_entry.dart';
import '../../../../theme/app_theme.dart';

/// Hand-rolled line chart of vertical-jump readings over time — deliberately
/// not backed by a charting package, to avoid extra native/build risk for
/// what is a fairly simple visual.
class JumpTrendChart extends StatelessWidget {
  final List<JumpLogEntry> entries;

  const JumpTrendChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    final plotted = sorted.length > 8
        ? sorted.sublist(sorted.length - 8)
        : sorted;

    if (plotted.length < 2) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'Log a few more jumps to see your trend',
            style: DunkTheme.onboardingSubtitle,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: CustomPaint(
        painter: _JumpTrendPainter(entries: plotted),
        size: Size.infinite,
      ),
    );
  }
}

class _JumpTrendPainter extends CustomPainter {
  final List<JumpLogEntry> entries;

  _JumpTrendPainter({required this.entries});

  static const double _leftMargin = 28;
  static const double _bottomMargin = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final values = entries.map((e) => e.verticalInches.toDouble()).toList();
    var minInches = values.reduce((a, b) => a < b ? a : b);
    var maxInches = values.reduce((a, b) => a > b ? a : b);

    if (minInches == maxInches) {
      minInches -= 3;
      maxInches += 3;
    } else {
      final pad = (maxInches - minInches) * 0.1;
      minInches -= pad;
      maxInches += pad;
    }

    final plotRect = Rect.fromLTWH(
      _leftMargin,
      0,
      size.width - _leftMargin,
      size.height - _bottomMargin,
    );

    _drawGridlines(canvas, plotRect, minInches, maxInches);

    final points = <Offset>[];
    for (var i = 0; i < entries.length; i++) {
      final x = entries.length == 1
          ? plotRect.left
          : plotRect.left + (plotRect.width * i / (entries.length - 1));
      final t = (values[i] - minInches) / (maxInches - minInches);
      final y = plotRect.bottom - t * plotRect.height;
      points.add(Offset(x, y));
    }

    // Filled area under the line.
    final areaPath = Path()..moveTo(points.first.dx, plotRect.bottom);
    for (final p in points) {
      areaPath.lineTo(p.dx, p.dy);
    }
    areaPath.lineTo(points.last.dx, plotRect.bottom);
    areaPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        DunkColors.primary.withValues(alpha: 0.35),
        DunkColors.primary.withValues(alpha: 0.0),
      ],
    );
    final areaPaint = Paint()..shader = gradient.createShader(plotRect);
    canvas.drawPath(areaPath, areaPaint);

    // The line itself.
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }
    final linePaint = Paint()
      ..color = DunkColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // Point markers with a ring.
    final dotPaint = Paint()..color = DunkColors.primary;
    final ringPaint = Paint()
      ..color = DunkColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final p in points) {
      canvas.drawCircle(p, 4, dotPaint);
      canvas.drawCircle(p, 4, ringPaint);
    }

    // Date labels beneath each point.
    for (var i = 0; i < entries.length; i++) {
      final date = entries[i].recordedAt;
      _drawText(
        canvas,
        '${date.month}/${date.day}',
        Offset(points[i].dx, plotRect.bottom + 4),
        align: TextAlign.center,
      );
    }
  }

  void _drawGridlines(Canvas canvas, Rect plotRect, double minInches, double maxInches) {
    final gridPaint = Paint()
      ..color = DunkColors.stroke
      ..strokeWidth = 1;

    final steps = [minInches, (minInches + maxInches) / 2, maxInches];
    for (final v in steps) {
      final t = (v - minInches) / (maxInches - minInches);
      final y = plotRect.bottom - t * plotRect.height;
      canvas.drawLine(Offset(plotRect.left, y), Offset(plotRect.right, y), gridPaint);
      _drawText(
        canvas,
        '${v.round()}"',
        Offset(_leftMargin - 4, y),
        align: TextAlign.right,
        anchorRight: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset anchor, {
    TextAlign align = TextAlign.left,
    bool anchorRight = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(color: DunkColors.textTertiary, fontSize: 10),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();

    double dx;
    if (anchorRight) {
      dx = anchor.dx - painter.width;
    } else if (align == TextAlign.center) {
      dx = anchor.dx - painter.width / 2;
    } else {
      dx = anchor.dx;
    }
    final dy = anchorRight ? anchor.dy - painter.height / 2 : anchor.dy;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _JumpTrendPainter oldDelegate) {
    if (entries.length != oldDelegate.entries.length) return true;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].verticalInches != oldDelegate.entries[i].verticalInches ||
          entries[i].recordedAt != oldDelegate.entries[i].recordedAt) {
        return true;
      }
    }
    return false;
  }
}
