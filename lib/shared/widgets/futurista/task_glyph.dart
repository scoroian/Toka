import 'package:flutter/material.dart';

enum TaskGlyphKind {
  ring, tri, hex, square, plus, diamond, star4, arcs, dot, cross,
}

/// Glifos geométricos futuristas usados como icono de tarea.
/// 10 variantes basadas en el canvas tocka.
class TaskGlyph extends StatelessWidget {
  const TaskGlyph({
    super.key,
    required this.kind,
    required this.color,
    this.size = 20,
  });

  final TaskGlyphKind kind;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TaskGlyphPainter(kind: kind, color: color),
    );
  }
}

class _TaskGlyphPainter extends CustomPainter {
  _TaskGlyphPainter({required this.kind, required this.color});

  final TaskGlyphKind kind;
  final Color color;

  static const double _vb = 24; // viewport base

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _vb;
    canvas.save();
    canvas.scale(scale);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (kind) {
      case TaskGlyphKind.ring:
        canvas.drawCircle(const Offset(12, 12), 7, stroke);
        canvas.drawCircle(const Offset(12, 12), 2, fill);
        break;
      case TaskGlyphKind.tri:
        final p = Path()
          ..moveTo(12, 4)
          ..lineTo(21, 20)
          ..lineTo(3, 20)
          ..close();
        canvas.drawPath(p, stroke);
        break;
      case TaskGlyphKind.hex:
        final p = Path()
          ..moveTo(12, 3)
          ..lineTo(20, 8)
          ..lineTo(20, 16)
          ..lineTo(12, 21)
          ..lineTo(4, 16)
          ..lineTo(4, 8)
          ..close();
        canvas.drawPath(p, stroke);
        break;
      case TaskGlyphKind.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(5, 5, 14, 14),
            const Radius.circular(2),
          ),
          stroke,
        );
        break;
      case TaskGlyphKind.plus:
        canvas.drawLine(const Offset(12, 4), const Offset(12, 20), stroke);
        canvas.drawLine(const Offset(4, 12), const Offset(20, 12), stroke);
        break;
      case TaskGlyphKind.diamond:
        final p = Path()
          ..moveTo(12, 3)
          ..lineTo(21, 12)
          ..lineTo(12, 21)
          ..lineTo(3, 12)
          ..close();
        canvas.drawPath(p, stroke);
        break;
      case TaskGlyphKind.star4:
        final starStroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round;
        final p = Path()
          ..moveTo(12, 3)
          ..lineTo(14, 11)
          ..lineTo(22, 12)
          ..lineTo(14, 13)
          ..lineTo(12, 21)
          ..lineTo(10, 13)
          ..lineTo(2, 12)
          ..lineTo(10, 11)
          ..close();
        canvas.drawPath(p, starStroke);
        break;
      case TaskGlyphKind.arcs:
        final topRect = Rect.fromCircle(center: const Offset(12, 12), radius: 7);
        canvas.drawArc(topRect, 3.14159, 3.14159, false, stroke);
        final dashStroke = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round;
        const dashCount = 8;
        const double startAngle = 0;
        const double sweep = 3.14159 / dashCount;
        for (var i = 0; i < dashCount; i++) {
          if (i.isEven) {
            canvas.drawArc(
              topRect,
              startAngle + sweep * i,
              sweep,
              false,
              dashStroke,
            );
          }
        }
        break;
      case TaskGlyphKind.dot:
        canvas.drawCircle(const Offset(12, 12), 6, fill);
        break;
      case TaskGlyphKind.cross:
        canvas.drawLine(const Offset(6, 6), const Offset(18, 18), stroke);
        canvas.drawLine(const Offset(6, 18), const Offset(18, 6), stroke);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TaskGlyphPainter old) =>
      old.kind != kind || old.color != color;
}
