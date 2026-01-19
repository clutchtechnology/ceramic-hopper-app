import 'package:flutter/material.dart';

/// 下料速度图标 (向下箭头+漏斗)
class FeedRateIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FeedRateIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FeedRatePainter(color: color),
    );
  }
}

class _FeedRatePainter extends CustomPainter {
  final Color color;

  _FeedRatePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 底部容器
    path.moveTo(923.2 * scale, 684 * scale);
    path.lineTo(889.6 * scale, 867.2 * scale);
    path.lineTo(134.4 * scale, 867.2 * scale);
    path.lineTo(100.8 * scale, 684 * scale);
    path.lineTo(16.8 * scale, 684 * scale);
    path.lineTo(16.8 * scale, 976 * scale);
    path.lineTo(1008 * scale, 976 * scale);
    path.lineTo(1008 * scale, 684 * scale);
    path.lineTo(923.2 * scale, 684 * scale);
    path.close();

    // 向下箭头
    path.moveTo(902.4 * scale, 357.6 * scale);
    path.lineTo(653.6 * scale, 357.6 * scale);
    path.lineTo(653.6 * scale, 252 * scale);
    path.lineTo(370.4 * scale, 252 * scale);
    path.lineTo(370.4 * scale, 358.4 * scale);
    path.lineTo(124.8 * scale, 358.4 * scale);
    path.lineTo(511.2 * scale, 771.2 * scale);
    path.lineTo(902.4 * scale, 357.6 * scale);
    path.close();

    // 顶部两条横线
    path.moveTo(653.6 * scale, 69.6 * scale);
    path.lineTo(370.4 * scale, 69.6 * scale);
    path.lineTo(370.4 * scale, 108 * scale);
    path.lineTo(653.6 * scale, 108 * scale);
    path.lineTo(653.6 * scale, 69.6 * scale);
    path.close();

    path.moveTo(653.6 * scale, 141.6 * scale);
    path.lineTo(370.4 * scale, 141.6 * scale);
    path.lineTo(370.4 * scale, 215.2 * scale);
    path.lineTo(653.6 * scale, 215.2 * scale);
    path.lineTo(653.6 * scale, 141.6 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FeedRatePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
