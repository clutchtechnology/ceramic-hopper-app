import 'package:flutter/material.dart';
import 'dart:math' as math;

/// ============================================================================
/// 科技风 UI 组件库 (Tech Style Widgets)
/// ============================================================================
///
/// 设计风格: 深色背景、发光边框、扫描线动画、数据流动效果
/// 配色方案:
///   - 背景: 深灰黑 (#0d1117, #161b22, #21262d)
///   - 主强调: 青色 (#00d4ff, #00f0ff)
///   - 辅助: 绿色 (#00ff88), 橙色 (#ff9500), 红色 (#ff3b30)

/// 科技风配色系统
class TechColors {
  // ===== 背景层级 =====
  static const Color bgDeep = Color(0xFF0d1117); // 最深背景
  static const Color bgDark = Color(0xFF161b22); // 深色背景
  static const Color bgMedium = Color(0xFF21262d); // 中间背景
  static const Color bgLight = Color(0xFF30363d); // 浅色背景/卡片

  // ===== 边框与线条 =====
  static const Color borderDark = Color(0xFF30363d);
  static const Color borderGlow = Color(0xFF00d4ff); // 发光边框
  static const Color gridLine = Color(0xFF21262d);

  // ===== 发光色 =====
  static const Color glowCyan = Color(0xFF00d4ff);
  static const Color glowCyanLight = Color(0xFF00f0ff);
  static const Color glowGreen = Color(0xFF00ff88);
  static const Color glowOrange = Color(0xFFff9500);
  static const Color glowRed = Color(0xFFff3b30);
  static const Color glowBlue = Color(0xFF0088ff);
  static const Color glowPurple = Color(0xFF9966ff); // 紫色

  // ===== 文字 =====
  static const Color textPrimary = Color(0xFFe6edf3);
  static const Color textSecondary = Color(0xFF8b949e);
  static const Color textMuted = Color(0xFF484f58);

  // ===== 状态色 =====
  static const Color statusNormal = Color(0xFF00ff88);
  static const Color statusWarning = Color(0xFFffcc00);
  static const Color statusAlarm = Color(0xFFff3b30);
  static const Color statusOffline = Color(0xFF484f58);
}

/// ============================================================================
/// 发光边框容器 (Glow Border Container)
/// ============================================================================
class GlowBorderContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color glowColor;
  final double glowIntensity;
  final double borderRadius;
  final EdgeInsets padding;
  final bool showCornerMarks;

  const GlowBorderContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.glowColor = TechColors.glowCyan,
    this.glowIntensity = 0.3,
    this.borderRadius = 4,
    this.padding = const EdgeInsets.all(12),
    this.showCornerMarks = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: glowColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(glowIntensity),
            blurRadius: 8,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: glowColor.withOpacity(glowIntensity * 0.5),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 角落标记
          if (showCornerMarks) ...[
            Positioned(top: 0, left: 0, child: _buildCornerMark(0)),
            Positioned(top: 0, right: 0, child: _buildCornerMark(1)),
            Positioned(bottom: 0, left: 0, child: _buildCornerMark(2)),
            Positioned(bottom: 0, right: 0, child: _buildCornerMark(3)),
          ],
          // 内容
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMark(int position) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: _CornerMarkPainter(
        color: glowColor,
        position: position,
      ),
    );
  }
}

class _CornerMarkPainter extends CustomPainter {
  final Color color;
  final int
      position; // 0: top-left, 1: top-right, 2: bottom-left, 3: bottom-right

  _CornerMarkPainter({required this.color, required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    switch (position) {
      case 0: // top-left
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case 1: // top-right
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case 2: // bottom-left
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case 3: // bottom-right
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ============================================================================
/// 科技风标题栏 (Tech Header)
/// ============================================================================
class TechHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Color accentColor;

  const TechHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.accentColor = TechColors.glowCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 左侧装饰线
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Text(
            title,
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 16),
            Text(
              subtitle!,
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          const Spacer(),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// ============================================================================
/// 科技风面板 (Tech Panel)
/// ============================================================================
class TechPanel extends StatelessWidget {
  final String? title;
  final Widget child;
  final double? width;
  final double? height;
  final Color accentColor;
  final EdgeInsets padding;
  final List<Widget>? headerActions;
  final Widget? titleAction; // 新增：标题右侧自定义组件

  const TechPanel({
    super.key,
    this.title,
    required this.child,
    this.width,
    this.height,
    this.accentColor = TechColors.glowCyan,
    this.padding = const EdgeInsets.all(4),
    this.headerActions,
    this.titleAction,
  });

  @override
  Widget build(BuildContext context) {
    return GlowBorderContainer(
      width: width,
      height: height,
      glowColor: accentColor,
      glowIntensity: 0.2,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) _buildHeader(),
          if (height != null)
            Expanded(
              child: Padding(
                padding: padding,
                child: child,
              ),
            )
          else
            Padding(
              padding: padding,
              child: child,
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: accentColor.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题前装饰
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title!,
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const Spacer(),
          if (titleAction != null) titleAction!,
          if (headerActions != null) ...headerActions!,
        ],
      ),
    );
  }
}

/// ============================================================================
/// 数据指标卡片 (Data Metric Card)
/// ============================================================================
class DataMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? valueColor;
  final IconData? icon;
  final bool showGlow;

  const DataMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.valueColor,
    this.icon,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? TechColors.glowCyan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.borderDark,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: TechColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Roboto Mono',
                        shadows: showGlow
                            ? [
                                Shadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          unit!,
                          style: const TextStyle(
                            color: TechColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ============================================================================
/// 圆形进度指示器 (Circular Progress)
/// ============================================================================
class TechCircularProgress extends StatelessWidget {
  final double value; // 0.0 - 1.0
  final double size;
  final Color? color;
  final String? centerText;
  final String? label;

  const TechCircularProgress({
    super.key,
    required this.value,
    this.size = 80,
    this.color,
    this.centerText,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? TechColors.glowCyan;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CircularProgressPainter(
              value: value,
              color: progressColor,
            ),
            child: Center(
              child: Text(
                centerText ?? '${(value * 100).toInt()}%',
                style: TextStyle(
                  color: progressColor,
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double value;
  final Color color;

  _CircularProgressPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // 背景圆环
    final bgPaint = Paint()
      ..color = TechColors.bgLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度圆弧
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      progressPaint,
    );

    // 发光效果
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

/// ============================================================================
/// 警报列表项 (Alarm List Item)
/// ============================================================================
class AlarmListItem extends StatelessWidget {
  final String type;
  final String device;
  final String message;
  final String solution;
  final AlarmLevel level;
  final VoidCallback? onTap;

  const AlarmListItem({
    super.key,
    required this.type,
    required this.device,
    required this.message,
    required this.solution,
    this.level = AlarmLevel.warning,
    this.onTap,
  });

  Color get _levelColor {
    switch (level) {
      case AlarmLevel.info:
        return TechColors.glowBlue;
      case AlarmLevel.warning:
        return TechColors.statusWarning;
      case AlarmLevel.alarm:
        return TechColors.statusAlarm;
    }
  }

  IconData get _levelIcon {
    switch (level) {
      case AlarmLevel.info:
        return Icons.info_outline;
      case AlarmLevel.warning:
        return Icons.warning_amber;
      case AlarmLevel.alarm:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _levelColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border(
            left: BorderSide(
              color: _levelColor,
              width: 3,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _levelIcon,
              color: _levelColor,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _levelColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            color: _levelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        device,
                        style: const TextStyle(
                          color: TechColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text(
                        '解决建议: ',
                        style: TextStyle(
                          color: TechColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          solution,
                          style: TextStyle(
                            color: TechColors.glowCyan.withOpacity(0.8),
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AlarmLevel { info, warning, alarm }

// [CRITICAL] 静态网格背景 - 不使用 AnimationController
// 原 AnimatedGridBackground 使用 60fps 动画持续绘制，10+ 小时后:
// - 2,160,000 次 _GridPainter 对象创建 + 1.62 亿次 drawLine 调用
// - 无 RepaintBoundary 隔离，导致整个 Widget 树每帧重绘
// - GPU 纹理缓存膨胀 + GDI 句柄累积 + Dart GC 压力 -> 主线程卡死
// 修复: 改为 StatelessWidget，网格只绘制一次，通过 RepaintBoundary 隔离
class AnimatedGridBackground extends StatelessWidget {
  final Widget child;
  final Color gridColor;
  final double gridSize;

  const AnimatedGridBackground({
    super.key,
    required this.child,
    this.gridColor = TechColors.borderDark,
    this.gridSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 静态网格背景 (只绘制一次，不再 60fps 刷新)
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _GridPainter(
                color: gridColor,
                gridSize: gridSize,
                offset: 0,
              ),
              // isComplex: true 告诉 Flutter 缓存此绘制结果
              isComplex: true,
              willChange: false,
            ),
          ),
        ),
        // 内容区域，RepaintBoundary 隔离网格和内容的重绘
        RepaintBoundary(
          child: child,
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  final double gridSize;
  final double offset;

  _GridPainter({
    required this.color,
    required this.gridSize,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // [CRITICAL] 窗口最小化/恢复过程中 size 可能为 0，跳过绘制防止异常
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // 垂直线
    for (double x = -gridSize + (offset % gridSize);
        x < size.width;
        x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // 水平线
    for (double y = -gridSize + (offset % gridSize);
        y < size.height;
        y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.offset != offset;
  }
}

// [已删除] DataFlowLine - 60fps 动画，未被任何页面使用，已清理
