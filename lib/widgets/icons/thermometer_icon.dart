import 'package:flutter/material.dart';

/// 自定义温度计图标
/// 使用 CustomPainter 绘制 SVG 路径
class ThermometerIcon extends StatelessWidget {
  final double size;
  final Color color;

  const ThermometerIcon({
    super.key,
    this.size = 16,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ThermometerPainter(color: color),
    );
  }
}

class _ThermometerPainter extends CustomPainter {
  final Color color;

  _ThermometerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 缩放因子 (原始 SVG 是 1024x1024)
    final scale = size.width / 1024;

    final path = Path();

    // 外轮廓路径
    path.moveTo(615.622 * scale, 589.014 * scale);
    path.lineTo(615.622 * scale, 165.222 * scale);
    path.cubicTo(
      615.622 * scale,
      147.549 * scale,
      601.295 * scale,
      133.222 * scale,
      583.622 * scale,
      133.222 * scale,
    );
    path.lineTo(414.9 * scale, 133.222 * scale);
    path.cubicTo(
      397.227 * scale,
      133.222 * scale,
      382.9 * scale,
      147.549 * scale,
      382.9 * scale,
      165.222 * scale,
    );
    path.lineTo(382.9 * scale, 590.842 * scale);
    path.cubicTo(
      342.177 * scale,
      625.272 * scale,
      318.316 * scale,
      676.046 * scale,
      318.316 * scale,
      729.804 * scale,
    );
    path.cubicTo(
      318.316 * scale,
      830.159 * scale,
      399.961 * scale,
      911.804 * scale,
      500.316 * scale,
      911.804 * scale,
    );
    path.cubicTo(
      600.671 * scale,
      911.804 * scale,
      682.316 * scale,
      830.159 * scale,
      682.316 * scale,
      729.804 * scale,
    );
    path.cubicTo(
      682.315 * scale,
      674.879 * scale,
      657.673 * scale,
      623.44 * scale,
      615.622 * scale,
      589.014 * scale,
    );
    path.close();

    // 内轮廓（镂空）
    path.moveTo(500.315 * scale, 847.804 * scale);
    path.cubicTo(
      435.25 * scale,
      847.804 * scale,
      382.315 * scale,
      794.869 * scale,
      382.315 * scale,
      729.804 * scale,
    );
    path.cubicTo(
      382.315 * scale,
      691.211 * scale,
      401.32 * scale,
      654.972 * scale,
      433.154 * scale,
      632.863 * scale,
    );
    path.cubicTo(
      442.354 * scale,
      626.263 * scale,
      446.9 * scale,
      618.163 * scale,
      446.9 * scale,
      606.58 * scale,
    );
    path.lineTo(446.9 * scale, 197.222 * scale);
    path.lineTo(551.622 * scale, 197.222 * scale);
    path.lineTo(551.622 * scale, 605.081 * scale);
    path.cubicTo(
      551.622 * scale,
      616.081 * scale,
      556.222 * scale,
      624.681 * scale,
      565.824 * scale,
      631.675 * scale,
    );
    path.cubicTo(
      598.692 * scale,
      653.673 * scale,
      618.315 * scale,
      690.357 * scale,
      618.315 * scale,
      729.804 * scale,
    );
    path.cubicTo(
      618.315 * scale,
      794.869 * scale,
      565.38 * scale,
      847.804 * scale,
      500.315 * scale,
      847.804 * scale,
    );
    path.close();

    canvas.drawPath(path, paint);

    // 温度指示器（内部填充部分）
    final indicatorPath = Path();
    indicatorPath.moveTo(516.315 * scale, 670.423 * scale);
    indicatorPath.lineTo(516.315 * scale, 466.785 * scale);
    indicatorPath.cubicTo(
      516.315 * scale,
      457.949 * scale,
      509.151 * scale,
      450.785 * scale,
      500.315 * scale,
      450.785 * scale,
    );
    indicatorPath.cubicTo(
      491.479 * scale,
      450.785 * scale,
      484.315 * scale,
      457.949 * scale,
      484.315 * scale,
      466.785 * scale,
    );
    indicatorPath.lineTo(484.315 * scale, 670.423 * scale);
    indicatorPath.cubicTo(
      457.55 * scale,
      677.492 * scale,
      437.815 * scale,
      701.861 * scale,
      437.815 * scale,
      730.847 * scale,
    );
    indicatorPath.cubicTo(
      437.815 * scale,
      765.365 * scale,
      465.797 * scale,
      793.347 * scale,
      500.315 * scale,
      793.347 * scale,
    );
    indicatorPath.cubicTo(
      534.833 * scale,
      793.347 * scale,
      562.815 * scale,
      765.365 * scale,
      562.815 * scale,
      730.847 * scale,
    );
    indicatorPath.cubicTo(
      562.815 * scale,
      701.861 * scale,
      543.08 * scale,
      677.492 * scale,
      516.315 * scale,
      670.423 * scale,
    );
    indicatorPath.close();

    canvas.drawPath(indicatorPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ThermometerPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
