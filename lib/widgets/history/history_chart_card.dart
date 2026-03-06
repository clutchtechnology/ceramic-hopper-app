// 历史图表卡片组件 - 通用历史数据图表
// ============================================================
// 功能:
//   - 统一的图表卡片布局
//   - 标题 + 料仓选择 + 时间范围选择 + 刷新按钮
//   - 支持单料仓/多料仓数据展示
//   - 自动聚合查询
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../data_display/data_tech_line_widgets.dart';

/// 历史图表卡片
class HistoryChartCard extends StatelessWidget {
  /// 图表标题
  final String title;

  /// 主题色
  final Color accentColor;

  /// Y轴标签
  final String yAxisLabel;

  /// 是否显示料仓选择器
  final bool showHopperSelector;

  /// 当前选中的料仓索引 (0-6)
  final int selectedHopperIndex;

  /// 料仓选择回调
  final void Function(int?)? onHopperChanged;

  /// 开始时间
  final DateTime startTime;

  /// 结束时间
  final DateTime endTime;

  /// 时间选择回调
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;

  /// 刷新回调
  final VoidCallback onRefresh;

  /// 图表数据 (x为索引, y为值)
  /// 单线模式: data 不为空, multiLineData 为空
  /// 多线模式: data 为空, multiLineData 不为空
  final List<FlSpot> data;

  /// 多线数据 (用于三相电流/电压, 三轴振动)
  /// Map<线名称, 数据点列表>
  /// 例如: {'A': [点], 'B': [点], 'C': [点]} 或 {'X': [点], 'Y': [点], 'Z': [点]}
  final Map<String, List<FlSpot>>? multiLineData;

  /// 多线颜色配置
  final Map<String, Color>? multiLineColors;

  /// 是否正在加载
  final bool isLoading;

  /// 高报警阈值 (可选)
  final double? highAlarmThreshold;

  /// 低报警阈值 (可选)
  final double? lowAlarmThreshold;

  const HistoryChartCard({
    super.key,
    required this.title,
    required this.accentColor,
    required this.yAxisLabel,
    this.showHopperSelector = false,
    this.selectedHopperIndex = 0,
    this.onHopperChanged,
    required this.startTime,
    required this.endTime,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
    required this.onRefresh,
    this.data = const [],
    this.multiLineData,
    this.multiLineColors,
    this.isLoading = false,
    this.highAlarmThreshold,
    this.lowAlarmThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          // 标题栏
          _buildHeader(),
          const SizedBox(height: 4),
          // 图表主体
          Expanded(
            child: isLoading ? _buildLoadingIndicator() : _buildChart(),
          ),
        ],
      ),
    );
  }

  /// 构建标题栏
  Widget _buildHeader() {
    return Row(
      children: [
        // 标题
        Container(
          width: 2,
          height: 12,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(1),
            boxShadow: [
              BoxShadow(color: accentColor.withOpacity(0.5), blurRadius: 3),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$title($yAxisLabel)',
          style: TextStyle(
            color: accentColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),

        // 料仓选择器
        if (showHopperSelector) ...[
          _buildHopperSelector(),
          const SizedBox(width: 8),
        ],

        // 时间范围选择
        _buildTimeSelector(),

        const SizedBox(width: 6),

        // 刷新按钮
        _buildRefreshButton(),
      ],
    );
  }

  /// 构建料仓选择器
  Widget _buildHopperSelector() {
    final hopperNames = [
      '短窑#1',
      '短窑#2',
      '短窑#3',
      '短窑#4',
      '长窑#1',
      '长窑#2',
      '长窑#3'
    ];

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedHopperIndex,
          isDense: true,
          style: TextStyle(color: accentColor, fontSize: 14),
          dropdownColor: TechColors.bgDark,
          icon: Icon(Icons.arrow_drop_down, color: accentColor, size: 16),
          items: List.generate(hopperNames.length, (i) {
            return DropdownMenuItem(
              value: i,
              child: Text(hopperNames[i], style: const TextStyle(fontSize: 14)),
            );
          }),
          onChanged: (value) {
            if (value != null && onHopperChanged != null) {
              onHopperChanged!(value);
            }
          },
        ),
      ),
    );
  }

  /// 构建时间选择器
  Widget _buildTimeSelector() {
    final dateFormat = DateFormat('MM-dd');
    return Row(
      children: [
        _buildTimeButton(dateFormat.format(startTime), onStartTimeTap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Text('-', style: TextStyle(color: accentColor, fontSize: 14)),
        ),
        _buildTimeButton(dateFormat.format(endTime), onEndTimeTap),
      ],
    );
  }

  /// 构建时间按钮
  Widget _buildTimeButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: TechColors.bgMedium,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(color: accentColor, fontSize: 14),
          ),
        ),
      ),
    );
  }

  /// 构建刷新按钮
  Widget _buildRefreshButton() {
    return GestureDetector(
      onTap: onRefresh,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: accentColor.withOpacity(0.3)),
        ),
        child: Icon(Icons.refresh, color: accentColor, size: 14),
      ),
    );
  }

  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: accentColor,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '加载中...',
            style: TextStyle(color: accentColor.withOpacity(0.6), fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// 构建图表
  Widget _buildChart() {
    // 判断是单线还是多线模式
    final isMultiLine = multiLineData != null && multiLineData!.isNotEmpty;

    if (!isMultiLine && data.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: accentColor.withOpacity(0.4), fontSize: 12),
        ),
      );
    }

    if (isMultiLine && multiLineData!.values.every((list) => list.isEmpty)) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: accentColor.withOpacity(0.4), fontSize: 12),
        ),
      );
    }

    // 计算Y轴范围
    List<double> allValues = [];
    if (isMultiLine) {
      for (final lineData in multiLineData!.values) {
        allValues.addAll(lineData.map((e) => e.y));
      }
    } else {
      allValues = data.map((e) => e.y).toList();
    }

    if (allValues.isEmpty) {
      return Center(
        child: Text(
          '暂无数据',
          style: TextStyle(color: accentColor.withOpacity(0.4), fontSize: 12),
        ),
      );
    }

    final minY = allValues.reduce((a, b) => a < b ? a : b);
    final maxY = allValues.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final padding = range * 0.1;

    final chartMinY = (minY - padding).clamp(0.0, double.infinity);
    final chartMaxY = maxY + padding;

    // 构建线条数据
    List<LineChartBarData> lineBarsData = [];

    if (isMultiLine) {
      // 多线模式
      final defaultColors = {
        'A': const Color(0xFF00D4FF), // 青色 - A相
        'B': const Color(0xFF0080FF), // 蓝色 - B相
        'C': const Color(0xFFFFFFFF), // 白色 - C相
        'X': const Color(0xFF00D4FF), // 青色 - X轴
        'Y': const Color(0xFF0080FF), // 蓝色 - Y轴
        'Z': const Color(0xFFFFFFFF), // 白色 - Z轴
      };

      for (final entry in multiLineData!.entries) {
        final lineName = entry.key;
        final lineData = entry.value;
        final lineColor = multiLineColors?[lineName] ??
            defaultColors[lineName] ??
            accentColor;

        if (lineData.isNotEmpty) {
          lineBarsData.add(
            LineChartBarData(
              spots: lineData,
              isCurved: true,
              color: lineColor,
              barWidth: 1.5,
              dotData: FlDotData(
                show: lineData.length <= 50,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 1.5,
                    color: lineColor,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(show: false),
            ),
          );
        }
      }
    } else {
      // 单线模式
      lineBarsData.add(
        LineChartBarData(
          spots: data,
          isCurved: true,
          color: accentColor,
          barWidth: 1.5,
          dotData: FlDotData(
            show: data.length <= 50,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 1.5,
                color: accentColor,
                strokeWidth: 0,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                accentColor.withOpacity(0.2),
                accentColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      );
    }

    // 数据点总数 (用于 X 轴时间标签计算)
    final maxLength = isMultiLine
        ? (multiLineData!.values.isNotEmpty
            ? multiLineData!.values.first.length
            : 0)
        : data.length;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4, bottom: 4),
      child: LineChart(
        LineChartData(
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: lineBarsData,
          // 高报警阈值线
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (highAlarmThreshold != null)
                HorizontalLine(
                  y: highAlarmThreshold!,
                  color: TechColors.statusAlarm.withOpacity(0.6),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(
                      color: TechColors.statusAlarm,
                      fontSize: 8,
                    ),
                  ),
                ),
              if (lowAlarmThreshold != null)
                HorizontalLine(
                  y: lowAlarmThreshold!,
                  color: TechColors.statusWarning.withOpacity(0.6),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.bottomRight,
                    style: const TextStyle(
                      color: TechColors.statusWarning,
                      fontSize: 8,
                    ),
                  ),
                ),
            ],
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                interval: maxLength > 8 ? (maxLength / 8).ceilToDouble() : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= maxLength || maxLength <= 1) {
                    return const SizedBox.shrink();
                  }
                  // 跳过离终点过近的标签，防止与最后一个标签重叠
                  final step = maxLength > 8 ? (maxLength / 8).ceil() : 1;
                  if (index > 0 &&
                      index != maxLength - 1 &&
                      (maxLength - 1 - index) < step * 0.6) {
                    return const SizedBox.shrink();
                  }
                  final totalDuration = endTime.difference(startTime);
                  final pointTime = startTime.add(Duration(
                    milliseconds:
                        (totalDuration.inMilliseconds * index / (maxLength - 1))
                            .round(),
                  ));
                  return Text(
                    DateFormat('HH:mm').format(pointTime),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval:
                ((chartMaxY - chartMinY) / 5).clamp(0.1, double.infinity),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: TechColors.borderDark.withOpacity(0.3),
                strokeWidth: 0.5,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: TechColors.borderDark.withOpacity(0.2),
                strokeWidth: 0.5,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: accentColor.withOpacity(0.3), width: 0.5),
              bottom:
                  BorderSide(color: accentColor.withOpacity(0.3), width: 0.5),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => TechColors.bgDark,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    spot.y.toStringAsFixed(2),
                    TextStyle(color: accentColor, fontSize: 9),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
