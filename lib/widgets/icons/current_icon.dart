import 'package:flutter/material.dart';

/// 电流图标 (电池/电流符号)
class CurrentIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CurrentIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CurrentPainter(color: color),
    );
  }
}

class _CurrentPainter extends CustomPainter {
  final Color color;

  _CurrentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024; // 基于1024x1024的viewBox

    final path = Path();

    // 电池/电流符号 SVG 路径
    path.moveTo(643.015211 * scale, 36.664962 * scale);
    path.lineTo(720.755956 * scale, 36.664962 * scale);
    path.lineTo(720.755956 * scale, 0.551353 * scale);
    path.lineTo(303.244044 * scale, 0.551353 * scale);
    path.lineTo(303.244044 * scale, 37.216314 * scale);
    path.lineTo(381.673980 * scale, 37.216314 * scale);

    // 左侧圆角矩形部分
    path.cubicTo(417.836317 * scale, 37.216314 * scale, 447.560641 * scale,
        67.037754 * scale, 447.560641 * scale, 97.038094 * scale);
    path.lineTo(447.560641 * scale, 926.410553 * scale);
    path.cubicTo(447.560641 * scale, 959.949483 * scale, 417.836317 * scale,
        987.335038 * scale, 381.673980 * scale, 987.335038 * scale);
    path.lineTo(303.244044 * scale, 987.335038 * scale);
    path.lineTo(303.244044 * scale, 1024 * scale);
    path.lineTo(720.755956 * scale, 1024 * scale);
    path.lineTo(720.755956 * scale, 987.335038 * scale);
    path.lineTo(643.015211 * scale, 987.335038 * scale);

    // 右侧圆角矩形部分
    path.cubicTo(606.577198 * scale, 987.335038 * scale, 576.577197 * scale,
        957.335038 * scale, 576.577197 * scale, 920.897025 * scale);
    path.lineTo(576.577197 * scale, 104.343519 * scale);
    path.lineTo(576.577197 * scale, 103.102975 * scale);
    path.cubicTo(576.577197 * scale, 66.664962 * scale, 606.577198 * scale,
        36.664962 * scale, 643.015211 * scale, 36.664962 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurrentPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
