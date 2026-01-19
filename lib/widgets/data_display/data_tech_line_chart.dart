import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'data_tech_line_widgets.dart';
import 'data_multi_select_dropdown.dart';
import 'data_single_select_dropdown.dart';

/// 可复用的技术风格折线图组件
/// 支持单选和多选两种模式
class TechLineChart extends StatelessWidget {
  /// 图表标题
  final String title;

  /// 标题左侧装饰条颜色
  final Color accentColor;

  /// Y轴单位标签
  final String yAxisLabel;

  /// X轴单位标签
  final String xAxisLabel;

  /// Y轴最小值（可选，不传则自动计算）
  final double? minY;

  /// Y轴最大值（可选，不传则自动计算）
  final double? maxY;

  /// Y轴间隔（可选，不传则自动计算）
  final double? yInterval;

  /// X轴间隔
  final double xInterval;

  /// 数据源映射 (设备索引 -> 数据点列表)
  final Map<int, List<FlSpot>> dataMap;

  /// 是否为单选模式（默认false为多选模式）
  final bool isSingleSelect;

  /// 单选模式：当前选中的索引
  final int? selectedIndex;

  /// 多选模式：设备选择状态列表
  final List<bool>? selectedItems;

  /// 设备颜色列表
  final List<Color> itemColors;

  /// 设备数量
  final int itemCount;

  /// 获取设备标签的函数
  final String Function(int index) getItemLabel;

  /// 下拉框标签
  final String selectorLabel;

  /// 标题栏右侧自定义组件（如时间选择器）
  final List<Widget>? headerActions;

  /// 单选模式：设备选择回调
  final void Function(int index)? onItemSelect;

  /// 多选模式：设备切换回调
  final void Function(int index)? onItemToggle;

  /// 是否使用紧凑模式（更小的字体和间距）
  final bool compact;

  /// 是否显示选择器（默认true）
  /// 设置为false时不显示设备选择器和时间选择器
  final bool showSelector;

  /// 是否使用平滑曲线（默认true）
  final bool isCurved;

  /// 是否防止曲线过冲（默认true，防止数据点之间产生不合理的波动）
  final bool preventCurveOverShooting;

  /// 自定义底部标签格式化函数
  final String Function(double value)? getBottomTitle;

  const TechLineChart({
    super.key,
    required this.title,
    required this.accentColor,
    required this.yAxisLabel,
    required this.xAxisLabel,
    this.minY,
    this.maxY,
    this.yInterval,
    required this.xInterval,
    required this.dataMap,
    required this.itemColors,
    required this.itemCount,
    required this.getItemLabel,
    required this.selectorLabel,
    this.headerActions,
    this.isSingleSelect = false,
    this.selectedIndex,
    this.selectedItems,
    this.onItemSelect,
    this.onItemToggle,
    this.compact = false,
    this.showSelector = true,
    this.isCurved = true,
    this.preventCurveOverShooting = true,
    this.getBottomTitle,
  }) : assert(
          // 当 showSelector 为 true 时才需要验证选择器参数
          !showSelector ||
              (isSingleSelect
                  ? (selectedIndex != null && onItemSelect != null)
                  : (selectedItems != null && onItemToggle != null)),
          '单选模式需要 selectedIndex 和 onItemSelect，多选模式需要 selectedItems 和 onItemToggle',
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 只有当 showSelector 为 true 时才显示 header
          if (showSelector) ...[
            _buildHeader(),
            SizedBox(height: compact ? 6 : 12),
          ],
          // Y轴标签（水平放置在左上角）
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 4),
            child: Text(
              yAxisLabel,
              style: const TextStyle(
                color: Color(0xFFD0D0D0),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );
  }

  /// 构建图表头部 - 选择器和时间选择器靠右上角
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // 设备选择器
        _buildSelector(),
        // 间距
        if (headerActions != null) SizedBox(width: compact ? 4 : 0),
        // 时间选择器（headerActions）
        if (headerActions != null) ...headerActions!,
      ],
    );
  }

  /// 构建设备选择器
  Widget _buildSelector() {
    if (isSingleSelect) {
      return SingleSelectDropdown(
        label: selectorLabel,
        itemCount: itemCount,
        selectedIndex: selectedIndex!,
        itemColors: itemColors,
        getItemLabel: getItemLabel,
        accentColor: accentColor,
        onItemSelect: onItemSelect!,
        compact: compact,
      );
    } else {
      return MultiSelectDropdown(
        label: selectorLabel,
        itemCount: itemCount,
        selectedItems: selectedItems!,
        itemColors: itemColors,
        getItemLabel: getItemLabel,
        accentColor: accentColor,
        onItemToggle: onItemToggle!,
        compact: compact,
      );
    }
  }

  /// 计算数据的Y轴范围（自动计算时使用）
  ({double min, double max, double interval}) _calculateYAxisRange() {
    // 收集所有选中设备的Y值
    List<double> allYValues = [];

    if (isSingleSelect) {
      if (dataMap.containsKey(selectedIndex)) {
        allYValues.addAll(dataMap[selectedIndex]!.map((spot) => spot.y));
      }
    } else {
      for (int i = 0; i < itemCount; i++) {
        if (selectedItems![i] && dataMap.containsKey(i)) {
          allYValues.addAll(dataMap[i]!.map((spot) => spot.y));
        }
      }
    }

    // 如果没有数据，返回默认范围
    if (allYValues.isEmpty) {
      return (min: 0, max: 100, interval: 20);
    }

    double dataMin = allYValues.reduce((a, b) => a < b ? a : b);
    double dataMax = allYValues.reduce((a, b) => a > b ? a : b);

    // 添加10%的边距，让数据线不贴边
    double range = dataMax - dataMin;
    if (range < 0.01) range = dataMax * 0.2; // 如果数据几乎不变，用数据值的20%作为范围
    if (range < 1) range = 10; // 最小范围

    double padding = range * 0.1;
    double calculatedMin = dataMin - padding;
    double calculatedMax = dataMax + padding;

    // 计算合适的间隔（大约5-8条网格线）
    double rawInterval = range / 5;
    // 向上取整到"好看"的数字
    double magnitude = 1;
    while (rawInterval >= 10) {
      rawInterval /= 10;
      magnitude *= 10;
    }
    while (rawInterval < 1) {
      rawInterval *= 10;
      magnitude /= 10;
    }
    double niceInterval =
        (rawInterval <= 2 ? 2 : (rawInterval <= 5 ? 5 : 10)) * magnitude;

    // 调整min/max到间隔的整数倍
    calculatedMin = (calculatedMin / niceInterval).floor() * niceInterval;
    calculatedMax = (calculatedMax / niceInterval).ceil() * niceInterval;

    return (min: calculatedMin, max: calculatedMax, interval: niceInterval);
  }

  /// 构建折线图
  Widget _buildChart() {
    // 计算Y轴范围
    final yAxisRange = _calculateYAxisRange();
    final effectiveMinY = minY ?? yAxisRange.min;
    final effectiveMaxY = maxY ?? yAxisRange.max;
    final effectiveYInterval = yInterval ?? yAxisRange.interval;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: effectiveYInterval,
          verticalInterval: xInterval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: TechColors.borderDark.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: TechColors.borderDark.withOpacity(0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: effectiveYInterval,
              getTitlesWidget: (value, meta) {
                // 只显示在范围内的标签
                if (value < effectiveMinY || value > effectiveMaxY) {
                  return const SizedBox.shrink();
                }
                return Text(
                  value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1),
                  style: const TextStyle(
                    color: Color(0xFFD0D0D0),
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 16,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                if (getBottomTitle != null) {
                  return Text(
                    getBottomTitle!(value),
                    style: const TextStyle(
                      color: TechColors.textSecondary,
                      fontSize: 9,
                    ),
                  );
                }
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: TechColors.textSecondary,
                    fontSize: 9,
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
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: TechColors.borderDark.withOpacity(0.5),
          ),
        ),
        lineBarsData: _getSelectedData(),
        minY: effectiveMinY,
        maxY: effectiveMaxY,
      ),
    );
  }

  /// 获取选中设备的数据
  List<LineChartBarData> _getSelectedData() {
    List<LineChartBarData> result = [];

    if (isSingleSelect) {
      // 单选模式：只显示选中项的数据
      if (dataMap.containsKey(selectedIndex)) {
        result.add(
          LineChartBarData(
            spots: dataMap[selectedIndex]!,
            isCurved: isCurved,
            preventCurveOverShooting: preventCurveOverShooting,
            color: itemColors[selectedIndex!],
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        );
      }
    } else {
      // 多选模式：显示所有选中项的数据
      for (int i = 0; i < itemCount; i++) {
        if (selectedItems![i] && dataMap.containsKey(i)) {
          result.add(
            LineChartBarData(
              spots: dataMap[i]!,
              isCurved: isCurved,
              preventCurveOverShooting: preventCurveOverShooting,
              color: itemColors[i],
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          );
        }
      }
    }

    return result;
  }
}
