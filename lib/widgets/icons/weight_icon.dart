import 'package:flutter/material.dart';

/// 重量图标 (t)
class WeightIcon extends StatelessWidget {
  final double size;
  final Color color;

  const WeightIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WeightPainter(color: color),
    );
  }
}

class _WeightPainter extends CustomPainter {
  final Color color;

  _WeightPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 外框和底座
    path.moveTo(918.341818 * scale, 845.265455 * scale);
    path.lineTo(820.596364 * scale, 443.578182 * scale);
    path.cubicTo(
      813.149091 * scale,
      412.392727 * scale,
      785.221818 * scale,
      390.516364 * scale,
      753.105455 * scale,
      390.516364 * scale,
    );
    path.lineTo(600.901818 * scale, 390.516364 * scale);

    // 顶部圆形
    path.moveTo(512 * scale, 93.090909 * scale);
    path.cubicTo(
      422.632727 * scale,
      93.090909 * scale,
      350.021818 * scale,
      165.701818 * scale,
      350.021818 * scale,
      255.069091 * scale,
    );
    path.cubicTo(
      350.021818 * scale,
      311.389091 * scale,
      379.345455 * scale,
      361.192727 * scale,
      423.098182 * scale,
      390.516364 * scale,
    );
    path.lineTo(270.894545 * scale, 390.516364 * scale);
    path.cubicTo(
      238.778182 * scale,
      390.516364 * scale,
      211.316364 * scale,
      412.392727 * scale,
      203.403636 * scale,
      443.578182 * scale,
    );
    path.lineTo(105.658182 * scale, 845.265455 * scale);
    path.cubicTo(
      100.538182 * scale,
      866.210909 * scale,
      105.658182 * scale,
      887.621818 * scale,
      118.690909 * scale,
      904.378182 * scale,
    );
    path.cubicTo(
      131.723636 * scale,
      921.134545 * scale,
      151.738182 * scale,
      930.909091 * scale,
      173.149091 * scale,
      930.909091 * scale,
    );
    path.lineTo(851.316364 * scale, 930.909091 * scale);
    path.cubicTo(
      872.727273 * scale,
      930.909091 * scale,
      892.741818 * scale,
      921.134545 * scale,
      905.774545 * scale,
      904.378182 * scale,
    );
    path.cubicTo(
      918.807273 * scale,
      887.621818 * scale,
      923.461818 * scale,
      865.745455 * scale,
      918.341818 * scale,
      845.265455 * scale,
    );
    path.close();

    // 内圆
    path.moveTo(512 * scale, 155.927273 * scale);
    path.cubicTo(
      566.923636 * scale,
      155.927273 * scale,
      611.141818 * scale,
      200.610909 * scale,
      611.141818 * scale,
      255.069091 * scale,
    );
    path.cubicTo(
      611.141818 * scale,
      309.992727 * scale,
      566.458182 * scale,
      354.210909 * scale,
      512 * scale,
      354.210909 * scale,
    );
    path.cubicTo(
      457.076364 * scale,
      354.210909 * scale,
      412.858182 * scale,
      309.527273 * scale,
      412.858182 * scale,
      255.069091 * scale,
    );
    path.cubicTo(
      412.858182 * scale,
      200.610909 * scale,
      457.541818 * scale,
      155.927273 * scale,
      512 * scale,
      155.927273 * scale,
    );
    path.close();

    canvas.drawPath(path, paint);

    // "t" 字母
    final tPath = Path();
    tPath.moveTo(572.974545 * scale, 787.549091 * scale);
    tPath.cubicTo(
      546.443636 * scale,
      787.549091 * scale,
      535.738182 * scale,
      771.723636 * scale,
      535.738182 * scale,
      741.003636 * scale,
    );
    tPath.lineTo(535.738182 * scale, 611.607273 * scale);
    tPath.lineTo(602.298182 * scale, 611.607273 * scale);
    tPath.lineTo(602.298182 * scale, 568.785455 * scale);
    tPath.lineTo(535.738182 * scale, 568.785455 * scale);
    tPath.lineTo(535.738182 * scale, 498.036364 * scale);
    tPath.lineTo(490.589091 * scale, 498.036364 * scale);
    tPath.lineTo(484.538182 * scale, 568.785455 * scale);
    tPath.lineTo(444.974545 * scale, 571.578182 * scale);
    tPath.lineTo(444.974545 * scale, 611.607273 * scale);
    tPath.lineTo(482.210909 * scale, 611.607273 * scale);
    tPath.lineTo(482.210909 * scale, 740.538182 * scale);
    tPath.cubicTo(
      482.210909 * scale,
      794.530909 * scale,
      502.225455 * scale,
      830.370909 * scale,
      559.941818 * scale,
      830.370909 * scale,
    );
    tPath.cubicTo(
      578.56 * scale,
      830.370909 * scale,
      595.781818 * scale,
      825.716364 * scale,
      610.210909 * scale,
      821.061818 * scale,
    );
    tPath.lineTo(600.436364 * scale, 781.498182 * scale);
    tPath.cubicTo(
      592.989091 * scale,
      784.756364 * scale,
      581.818182 * scale,
      787.549091 * scale,
      572.974545 * scale,
      787.549091 * scale,
    );
    tPath.close();

    canvas.drawPath(tPath, paint);
  }

  @override
  bool shouldRepaint(covariant _WeightPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
