import 'package:flutter/material.dart';

/// 累计流量图标 (仪表盘/流量计)
class TotalFlowIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TotalFlowIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TotalFlowPainter(color: color),
    );
  }
}

class _TotalFlowPainter extends CustomPainter {
  final Color color;

  _TotalFlowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 1070;

    final path = Path();

    // 仪表盘指针
    path.moveTo(839.57268 * scale, 260.646 * scale);
    path.cubicTo(
      839.57268 * scale - 49.834667 * scale,
      260.646 * scale - 16.936667 * scale,
      769.00068 * scale,
      243.709 * scale,
      769.00068 * scale,
      243.709 * scale,
    );
    path.lineTo(568.10568 * scale, 444.604 * scale);
    path.lineTo(560.34368 * scale, 442.487 * scale);
    path.cubicTo(
      560.34368 * scale + 95.743 * scale * 0.1,
      442.487 * scale - 95.743 * scale * 0.1,
      627.85768 * scale,
      509.765 * scale,
      627.85768 * scale - 67.749 * scale,
      509.765 * scale + 67.278 * scale,
    );
    path.lineTo(558.22668 * scale, 501.769 * scale);
    path.lineTo(757.94468 * scale, 302.05 * scale);
    path.cubicTo(
      757.94468 * scale + 41.167 * scale * 0.3,
      302.05 * scale - 41.167 * scale * 0.3,
      853.45268 * scale,
      302.048 * scale,
      839.57268 * scale,
      260.646 * scale,
    );
    path.close();

    // 仪表盘主体
    path.moveTo(920.02568 * scale, 576.103 * scale);
    path.lineTo(1029.88268 * scale, 576.103 * scale);
    path.cubicTo(
      1070.57868 * scale,
      576.103 * scale,
      1070.57868 * scale,
      535.171 * scale,
      1070.57868 * scale,
      535.171 * scale,
    );
    path.cubicTo(
      1070.57868 * scale,
      0 * scale,
      0 * scale,
      0 * scale + 0.235 * scale,
      0 * scale,
      535.406 * scale,
    );
    path.cubicTo(
      0 * scale,
      576.103 * scale,
      40.696 * scale,
      576.103 * scale,
      40.696 * scale,
      576.103 * scale,
    );
    path.lineTo(150.79068 * scale, 576.103 * scale);
    path.cubicTo(
      191.72268 * scale,
      576.103 * scale,
      150.79068 * scale,
      494.475 * scale,
      150.79068 * scale,
      494.475 * scale,
    );
    path.lineTo(83.27668 * scale, 494.475 * scale);
    path.lineTo(85.15868 * scale, 478.714 * scale);
    path.cubicTo(
      85.15868 * scale + 91.742 * scale,
      478.714 * scale - 221.126 * scale,
      176.90068 * scale,
      257.588 * scale,
      176.90068 * scale,
      257.588 * scale,
    );
    path.lineTo(186.78068 * scale, 244.885 * scale);
    path.lineTo(215.71568 * scale, 273.819 * scale);
    path.cubicTo(
      244.41568 * scale,
      285.581 * scale,
      244.41568 * scale,
      285.581 * scale,
      244.17868 * scale,
      244.009 * scale,
    );
    path.cubicTo(
      272.64168 * scale,
      173.437 * scale,
      187.81468 * scale,
      186.012 * scale,
      187.01568 * scale,
      217.202 * scale,
    );
    path.lineTo(158.31568 * scale, 190.385 * scale);
    path.lineTo(170.78468 * scale, 180.505 * scale);
    path.cubicTo(
      170.78468 * scale + 222.066 * scale,
      180.505 * scale - 92.214 * scale,
      392.85068 * scale,
      88.291 * scale,
      392.85068 * scale,
      88.291 * scale,
    );
    path.lineTo(408.14068 * scale, 85.468 * scale);
    path.lineTo(408.14068 * scale, 152.982 * scale);
    path.cubicTo(
      448.86868 * scale,
      152.982 * scale,
      489.77068 * scale,
      152.982 * scale,
      489.77068 * scale,
      111.757 * scale,
    );
    path.lineTo(489.77068 * scale, 83.275 * scale);
    path.lineTo(505.53068 * scale, 85.392 * scale);

    canvas.drawPath(path, paint);

    // 波浪线 - 第一条
    final wavePath1 = Path();
    wavePath1.moveTo(14.82068 * scale, 729.244 * scale);
    wavePath1.cubicTo(
      14.82068 * scale + 60.221 * scale,
      729.244 * scale - 35.992 * scale,
      111.50368 * scale,
      693.252 * scale,
      111.50368 * scale,
      693.252 * scale,
    );
    wavePath1.cubicTo(
      180.19368 * scale,
      695.605 * scale,
      182.07668 * scale,
      736.537 * scale,
      214.06868 * scale,
      736.537 * scale,
    );
    wavePath1.cubicTo(
      246.06068 * scale,
      736.537 * scale,
      258.99968 * scale,
      693.252 * scale,
      320.86868 * scale,
      693.252 * scale,
    );
    wavePath1.cubicTo(
      382.73768 * scale,
      693.252 * scale,
      388.38168 * scale,
      736.537 * scale,
      427.66668 * scale,
      736.537 * scale,
    );
    canvas.drawPath(wavePath1, paint);

    // 波浪线 - 第二条
    final wavePath2 = Path();
    wavePath2.moveTo(17.17268 * scale, 947.547 * scale);
    wavePath2.cubicTo(
      17.17268 * scale + 60.222 * scale,
      947.547 * scale - 35.992 * scale,
      113.85668 * scale,
      911.555 * scale,
      113.85668 * scale,
      911.555 * scale,
    );
    wavePath2.cubicTo(
      182.54668 * scale,
      913.908 * scale,
      184.42968 * scale,
      954.839 * scale,
      216.42168 * scale,
      954.839 * scale,
    );
    wavePath2.cubicTo(
      248.41368 * scale,
      954.839 * scale,
      261.35268 * scale,
      911.555 * scale,
      323.22168 * scale,
      911.555 * scale,
    );
    canvas.drawPath(wavePath2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
