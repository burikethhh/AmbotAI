import 'dart:math';
import 'package:flutter/material.dart';

class HexDot extends StatelessWidget {
  final double size;
  final Color color;

  const HexDot({required this.size, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _HexDotPainter(color: color),
      ),
    );
  }
}

class _HexDotPainter extends CustomPainter {
  final Color color;
  _HexDotPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 2;
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HexDotPainter old) => color != old.color;
}
