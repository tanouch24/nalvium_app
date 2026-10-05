import 'package:flutter/material.dart';

/// Motif signature de Nalvium : quatre coins de viseur. Nalvium « regarde ».
class ViewfinderCorners extends StatelessWidget {
  const ViewfinderCorners({
    super.key,
    this.color = Colors.white,
    this.length = 22,
    this.stroke = 3.5,
    this.radius = 10,
    this.inset = 0,
  });
  final Color color;
  final double length;
  final double stroke;
  final double radius;
  final double inset;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _CornersPainter(color, length, stroke, radius, inset),
      child: const SizedBox.expand(),
    ),
  );
}

class _CornersPainter extends CustomPainter {
  _CornersPainter(
    this.color,
    this.length,
    this.stroke,
    this.radius,
    this.inset,
  );
  final Color color;
  final double length;
  final double stroke;
  final double radius;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final l = inset + stroke / 2;
    final r = size.width - inset - stroke / 2;
    final t = inset + stroke / 2;
    final b = size.height - inset - stroke / 2;
    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x + dx * length, y)
      ..lineTo(x + dx * radius, y)
      ..quadraticBezierTo(x, y, x, y + dy * radius)
      ..lineTo(x, y + dy * length);
    canvas
      ..drawPath(corner(l, t, 1, 1), p)
      ..drawPath(corner(r, t, -1, 1), p)
      ..drawPath(corner(l, b, 1, -1), p)
      ..drawPath(corner(r, b, -1, -1), p);
  }

  @override
  bool shouldRepaint(_CornersPainter o) =>
      o.color != color ||
      o.length != length ||
      o.stroke != stroke ||
      o.inset != inset;
}
