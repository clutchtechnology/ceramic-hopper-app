import 'package:flutter/material.dart';

/// 实时流量图标 (火焰/燃气)
class FlowRateIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FlowRateIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _FlowRatePainter(color: color),
    );
  }
}

class _FlowRatePainter extends CustomPainter {
  final Color color;

  _FlowRatePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1024;

    final path = Path();

    // 火焰/燃气路径
    path.moveTo(770.389333 * scale, 286.037333 * scale);
    path.cubicTo(
      720.554666 * scale,
      152.234666 * scale,
      591.530666 * scale,
      56.661333 * scale,
      440.661333 * scale,
      56.661333 * scale,
    );
    path.cubicTo(
      246.784 * scale,
      56.661333 * scale,
      89.088 * scale,
      214.357333 * scale,
      89.088 * scale,
      408.234667 * scale,
    );
    path.cubicTo(
      89.088 * scale,
      556.032 * scale,
      180.906667 * scale,
      683.008 * scale,
      310.613333 * scale,
      734.890667 * scale,
    );
    path.lineTo(310.613333 * scale, 817.834667 * scale);
    path.lineTo(334.848 * scale, 817.834667 * scale);
    path.cubicTo(
      334.848 * scale,
      818.858667 * scale,
      334.506667 * scale,
      820.565333 * scale,
      334.506667 * scale,
      821.589333 * scale,
    );
    path.lineTo(334.506667 * scale, 894.634667 * scale);
    path.cubicTo(
      334.506667 * scale,
      933.888 * scale,
      366.592 * scale,
      965.632 * scale,
      405.504 * scale,
      965.632 * scale,
    );
    path.lineTo(480.597333 * scale, 965.632 * scale);
    path.cubicTo(
      519.850667 * scale,
      965.632 * scale,
      551.594667 * scale,
      933.546667 * scale,
      551.594667 * scale,
      894.634667 * scale,
    );
    path.lineTo(551.594667 * scale, 821.589333 * scale);
    path.cubicTo(
      551.594667 * scale,
      820.565333 * scale,
      551.594667 * scale,
      818.858667 * scale,
      551.253333 * scale,
      817.834667 * scale,
    );
    path.lineTo(575.488 * scale, 817.834667 * scale);
    path.lineTo(575.488 * scale, 732.842667 * scale);
    path.cubicTo(
      666.965333 * scale,
      694.954667 * scale,
      738.645333 * scale,
      619.861333 * scale,
      772.437333 * scale,
      526.677333 * scale,
    );
    path.lineTo(935.594667 * scale, 526.677333 * scale);
    path.lineTo(935.594667 * scale, 286.037333 * scale);
    path.lineTo(770.389333 * scale, 286.037333 * scale);
    path.close();

    // 内部火焰
    path.moveTo(479.914667 * scale, 634.538667 * scale);
    path.cubicTo(
      493.909333 * scale,
      615.765333 * scale,
      508.928 * scale,
      577.194667 * scale,
      509.269333 * scale,
      557.397333 * scale,
    );
    path.cubicTo(
      509.269333 * scale,
      537.941333 * scale,
      490.496 * scale,
      506.88 * scale,
      468.992 * scale,
      487.765333 * scale,
    );
    path.cubicTo(
      446.805333 * scale,
      468.309333 * scale,
      435.541333 * scale,
      436.224 * scale,
      435.882667 * scale,
      418.133333 * scale,
    );
    path.cubicTo(
      436.224 * scale,
      399.701333 * scale,
      438.613333 * scale,
      389.12 * scale,
      439.296 * scale,
      389.12 * scale,
    );
    path.cubicTo(
      409.6 * scale,
      406.528 * scale,
      347.477333 * scale,
      449.194667 * scale,
      347.477333 * scale,
      513.024 * scale,
    );
    path.cubicTo(
      347.818667 * scale,
      577.194667 * scale,
      399.018667 * scale,
      634.538667 * scale,
      399.018667 * scale,
      633.856 * scale,
    );
    path.cubicTo(
      272.725333 * scale,
      606.208 * scale,
      236.885333 * scale,
      535.210667 * scale,
      237.568 * scale,
      470.016 * scale,
    );
    path.cubicTo(
      238.250667 * scale,
      404.821333 * scale,
      271.701333 * scale,
      369.322667 * scale,
      336.554667 * scale,
      320.512 * scale,
    );
    path.cubicTo(
      401.408 * scale,
      271.701333 * scale,
      413.354667 * scale,
      207.530667 * scale,
      413.696 * scale,
      192.853333 * scale,
    );
    path.cubicTo(
      414.037333 * scale,
      178.858667 * scale,
      405.845333 * scale,
      144.384 * scale,
      405.845333 * scale,
      141.994667 * scale,
    );
    path.cubicTo(
      579.242667 * scale,
      211.626667 * scale,
      527.018667 * scale,
      351.573333 * scale,
      527.018667 * scale,
      350.208 * scale,
    );
    path.cubicTo(
      546.474667 * scale,
      340.992 * scale,
      563.882667 * scale,
      310.272 * scale,
      563.882667 * scale,
      310.272 * scale,
    );
    path.cubicTo(
      563.882667 * scale,
      310.272 * scale,
      648.192 * scale,
      368.981333 * scale,
      648.192 * scale,
      471.381333 * scale,
    );
    path.cubicTo(
      626.005333 * scale,
      622.933333 * scale,
      479.914667 * scale,
      634.538667 * scale,
      479.914667 * scale,
      634.538667 * scale,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
