import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Radar chart futurista (8-axis típicamente). Polígono translúcido + ejes
/// + círculos concéntricos guía + labels mono.
class RadarChart extends StatelessWidget {
  const RadarChart({
    super.key,
    required this.values,
    required this.labels,
    this.size = 220,
    this.color,
  })  : assert(values.length == labels.length,
            'values and labels must have the same length'),
        assert(values.length >= 3 && values.length <= 12,
            'RadarChart supports 3..12 axes');

  final List<double> values; // 0..1 por eje
  final List<String> labels;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = color ?? theme.colorScheme.primary;
    final guide = theme.colorScheme.onSurface.withValues(alpha: 0.16);
    final labelColor =
        theme.colorScheme.onSurface.withValues(alpha: 0.62);
    return CustomPaint(
      size: Size(size, size),
      painter: _RadarPainter(
        values: values.map((v) => v.clamp(0.0, 1.0)).toList(),
        labels: labels,
        polygonColor: resolved,
        guideColor: guide,
        labelColor: labelColor,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.values,
    required this.labels,
    required this.polygonColor,
    required this.guideColor,
    required this.labelColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color polygonColor;
  final Color guideColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 20;

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 4 círculos concéntricos
    for (final f in const [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(Offset(cx, cy), r * f, guidePaint);
    }
    // N líneas radiales
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i / n) * 2 * math.pi;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + math.cos(a) * r, cy + math.sin(a) * r),
        guidePaint,
      );
    }

    // Polígono valores
    final path = Path();
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i / n) * 2 * math.pi;
      final p = Offset(
        cx + math.cos(a) * r * values[i],
        cy + math.sin(a) * r * values[i],
      );
      pts.add(p);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();

    final fill = Paint()
      ..color = polygonColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = polygonColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, stroke);

    // Vertices
    final vertexPaint = Paint()
      ..color = polygonColor
      ..style = PaintingStyle.fill;
    for (final p in pts) {
      canvas.drawCircle(p, 3, vertexPaint);
    }

    // Labels
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + (i / n) * 2 * math.pi;
      final lp = Offset(
        cx + math.cos(a) * r * 1.12,
        cy + math.sin(a) * r * 1.12,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: labelColor,
            fontFamily: 'JetBrainsMono',
            fontSize: 10,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(lp.dx - tp.width / 2, lp.dy - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.values != values ||
      old.labels != labels ||
      old.polygonColor != polygonColor;
}
