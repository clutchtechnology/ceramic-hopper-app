import 'package:flutter/material.dart';

/// 功率图标 (心电图/波形)
class PowerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const PowerIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PowerPainter(color: color),
    );
  }
}

class _PowerPainter extends CustomPainter {
  final Color color;

  _PowerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 波形路径
    path.moveTo(800 * scale, 544 * scale);
    path.lineTo(697.6 * scale, 544 * scale);
    path.lineTo(640 * scale, 313.6 * scale);
    path.cubicTo(
      633.6 * scale,
      300.8 * scale,
      620.8 * scale,
      288 * scale,
      608 * scale,
      288 * scale,
    );
    path.cubicTo(
      595.2 * scale,
      288 * scale,
      582.4 * scale,
      294.4 * scale,
      576 * scale,
      307.2 * scale,
    );
    path.lineTo(486.4 * scale, 588.8 * scale);
    path.lineTo(448 * scale, 441.6 * scale);
    path.cubicTo(
      441.6 * scale,
      428.8 * scale,
      428.8 * scale,
      416 * scale,
      416 * scale,
      416 * scale,
    );
    path.cubicTo(
      403.2 * scale,
      416 * scale,
      390.4 * scale,
      422.4 * scale,
      384 * scale,
      435.2 * scale,
    );
    path.lineTo(332.8 * scale, 544 * scale);
    path.lineTo(224 * scale, 544 * scale);
    path.cubicTo(
      204.8 * scale,
      544 * scale,
      192 * scale,
      563.2 * scale,
      192 * scale,
      576 * scale,
    );
    path.cubicTo(
      192 * scale,
      595.2 * scale,
      204.8 * scale,
      608 * scale,
      224 * scale,
      608 * scale,
    );
    path.lineTo(352 * scale, 608 * scale);
    path.cubicTo(
      364.8 * scale,
      608 * scale,
      377.6 * scale,
      601.6 * scale,
      377.6 * scale,
      588.8 * scale,
    );
    path.lineTo(403.2 * scale, 537.6 * scale);
    path.lineTo(448 * scale, 710.4 * scale);
    path.cubicTo(
      454.4 * scale,
      723.2 * scale,
      460.8 * scale,
      736 * scale,
      480 * scale,
      736 * scale,
    );
    path.cubicTo(
      492.8 * scale,
      736 * scale,
      505.6 * scale,
      729.6 * scale,
      512 * scale,
      716.8 * scale,
    );
    path.lineTo(601.6 * scale, 435.2 * scale);
    path.lineTo(640 * scale, 582.4 * scale);
    path.cubicTo(
      646.4 * scale,
      595.2 * scale,
      659.2 * scale,
      608 * scale,
      672 * scale,
      608 * scale,
    );
    path.lineTo(800 * scale, 608 * scale);
    path.cubicTo(
      819.2 * scale,
      608 * scale,
      832 * scale,
      588.8 * scale,
      832 * scale,
      576 * scale,
    );
    path.cubicTo(
      832 * scale,
      556.8 * scale,
      819.2 * scale,
      544 * scale,
      800 * scale,
      544 * scale,
    );
    path.close();

    canvas.drawPath(path, paint);

    // 圆环路径
    final circlePath = Path();
    circlePath.moveTo(512 * scale, 1024 * scale);
    circlePath.cubicTo(
      230.4 * scale,
      1024 * scale,
      0 * scale,
      793.6 * scale,
      0 * scale,
      512 * scale,
    );
    circlePath.cubicTo(
      0 * scale,
      230.4 * scale,
      230.4 * scale,
      0 * scale,
      512 * scale,
      0 * scale,
    );
    circlePath.cubicTo(
      620.8 * scale,
      0 * scale,
      723.2 * scale,
      32 * scale,
      812.8 * scale,
      96 * scale,
    );
    circlePath.cubicTo(
      825.6 * scale,
      108.8 * scale,
      832 * scale,
      128 * scale,
      819.2 * scale,
      140.8 * scale,
    );
    circlePath.cubicTo(
      806.4 * scale,
      153.6 * scale,
      787.2 * scale,
      160 * scale,
      774.4 * scale,
      147.2 * scale,
    );
    circlePath.cubicTo(
      697.6 * scale,
      89.6 * scale,
      608 * scale,
      64 * scale,
      512 * scale,
      64 * scale,
    );
    circlePath.cubicTo(
      262.4 * scale,
      64 * scale,
      64 * scale,
      262.4 * scale,
      64 * scale,
      512 * scale,
    );
    circlePath.cubicTo(
      64 * scale,
      761.6 * scale,
      262.4 * scale,
      960 * scale,
      512 * scale,
      960 * scale,
    );
    circlePath.cubicTo(
      761.6 * scale,
      960 * scale,
      960 * scale,
      761.6 * scale,
      960 * scale,
      512 * scale,
    );
    circlePath.cubicTo(
      960 * scale,
      435.2 * scale,
      940.8 * scale,
      358.4 * scale,
      902.4 * scale,
      288 * scale,
    );
    circlePath.cubicTo(
      896 * scale,
      275.2 * scale,
      896 * scale,
      256 * scale,
      915.2 * scale,
      243.2 * scale,
    );
    circlePath.cubicTo(
      928 * scale,
      236.8 * scale,
      947.2 * scale,
      236.8 * scale,
      960 * scale,
      256 * scale,
    );
    circlePath.cubicTo(
      998.4 * scale,
      332.8 * scale,
      1024 * scale,
      422.4 * scale,
      1024 * scale,
      512 * scale,
    );
    circlePath.cubicTo(
      1024 * scale,
      793.6 * scale,
      793.6 * scale,
      1024 * scale,
      512 * scale,
      1024 * scale,
    );
    circlePath.close();

    canvas.drawPath(circlePath, paint);
  }

  @override
  bool shouldRepaint(covariant _PowerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
