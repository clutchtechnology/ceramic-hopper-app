import 'package:flutter/material.dart';

/// 能耗/电力图标 (闪电)
class EnergyIcon extends StatelessWidget {
  final double size;
  final Color color;

  const EnergyIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EnergyPainter(color: color),
    );
  }
}

class _EnergyPainter extends CustomPainter {
  final Color color;

  _EnergyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 24; // 基于24x24的viewBox

    final path = Path();

    // 闪电图标路径
    path.moveTo(13 * scale, 2 * scale);
    path.lineTo(3 * scale, 14 * scale);
    path.lineTo(12 * scale, 14 * scale);
    path.lineTo(11 * scale, 22 * scale);
    path.lineTo(21 * scale, 10 * scale);
    path.lineTo(12 * scale, 10 * scale);
    path.lineTo(13 * scale, 2 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _EnergyPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
