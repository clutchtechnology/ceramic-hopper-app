// 历史数据页面 - 9宫格布局
// ============================================================
// 功能:
//   - 9个图表: PM10/温度/三相电流/三相电压/功率/能耗/速度/位移/频率
//   - 每个图表独立查询和刷新
//   - 默认查询最近24小时数据
//   - 自动聚合间隔计算
// ============================================================

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../widgets/history/history_chart_card.dart';
import '../services/history_data_service.dart';

/// 历史数据页面 - 9宫格布局
class HopperHistoryPage extends StatefulWidget {
  const HopperHistoryPage({super.key});

  @override
  State<HopperHistoryPage> createState() => HopperHistoryPageState();
}

class HopperHistoryPageState extends State<HopperHistoryPage> {
  // 历史数据服务
  final HistoryDataService _historyService = HistoryDataService();

  // 防抖定时器
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  // 设备ID (只有一个设备)
  static const String _deviceId = 'hopper_unit_4';

  // ==================== 9个图表的状态 ====================
  // 1. PM10
  late DateTime _pm10StartTime;
  late DateTime _pm10EndTime;
  List<FlSpot> _pm10Data = [];
  bool _pm10Loading = false;

  // 2. 温度
  late DateTime _tempStartTime;
  late DateTime _tempEndTime;
  List<FlSpot> _tempData = [];
  bool _tempLoading = false;

  // 3. 三相电流
  late DateTime _currentStartTime;
  late DateTime _currentEndTime;
  Map<String, List<FlSpot>> _currentData = {};
  bool _currentLoading = false;

  // 4. 三相电压
  late DateTime _voltageStartTime;
  late DateTime _voltageEndTime;
  Map<String, List<FlSpot>> _voltageData = {};
  bool _voltageLoading = false;

  // 5. 功率
  late DateTime _powerStartTime;
  late DateTime _powerEndTime;
  List<FlSpot> _powerData = [];
  bool _powerLoading = false;

  // 6. 能耗
  late DateTime _energyStartTime;
  late DateTime _energyEndTime;
  List<FlSpot> _energyData = [];
  bool _energyLoading = false;

  // 7. 振动速度 (三轴)
  late DateTime _velocityStartTime;
  late DateTime _velocityEndTime;
  Map<String, List<FlSpot>> _velocityData = {};
  bool _velocityLoading = false;

  // 8. 振动位移 (三轴)
  late DateTime _displacementStartTime;
  late DateTime _displacementEndTime;
  Map<String, List<FlSpot>> _displacementData = {};
  bool _displacementLoading = false;

  // 9. 振动频率 (三轴)
  late DateTime _frequencyStartTime;
  late DateTime _frequencyEndTime;
  Map<String, List<FlSpot>> _frequencyData = {};
  bool _frequencyLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeTimeRanges();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// 初始化所有图表的时间范围 (默认最近24小时)
  void _initializeTimeRanges() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(hours: 24));

    _pm10StartTime = start;
    _pm10EndTime = now;
    _tempStartTime = start;
    _tempEndTime = now;
    _currentStartTime = start;
    _currentEndTime = now;
    _voltageStartTime = start;
    _voltageEndTime = now;
    _powerStartTime = start;
    _powerEndTime = now;
    _energyStartTime = start;
    _energyEndTime = now;
    _velocityStartTime = start;
    _velocityEndTime = now;
    _displacementStartTime = start;
    _displacementEndTime = now;
    _frequencyStartTime = start;
    _frequencyEndTime = now;
  }

  /// 外部调用刷新方法 (进入页面时调用)
  void refreshData() {
    _refreshAllCharts();
  }

  /// 刷新所有图表数据
  Future<void> _refreshAllCharts() async {
    await Future.wait([
      _refreshPM10Data(),
      _refreshTempData(),
      _refreshCurrentData(),
      _refreshVoltageData(),
      _refreshPowerData(),
      _refreshEnergyData(),
      _refreshVelocityData(),
      _refreshDisplacementData(),
      _refreshFrequencyData(),
    ]);
  }

  /// 转换历史数据点为FlSpot列表
  List<FlSpot> _convertToFlSpots(List<HistoryDataPoint> data,
      double Function(HistoryDataPoint) valueExtractor) {
    if (data.isEmpty) return [];
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), valueExtractor(entry.value));
    }).toList();
  }

  /// 转换三相/三轴历史数据为FlSpot Map
  Map<String, List<FlSpot>> _convertToMultiLineFlSpots(
    Map<String, List<HistoryDataPoint>> data,
    Map<String, double Function(HistoryDataPoint)> extractors,
  ) {
    final result = <String, List<FlSpot>>{};
    for (final entry in data.entries) {
      final key = entry.key;
      final extractor = extractors[key];
      if (extractor != null) {
        result[key] = _convertToFlSpots(entry.value, extractor);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0E27),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // 第一行: PM10 | 温度 | 三相电流
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildPM10Chart()),
                const SizedBox(width: 8),
                Expanded(child: _buildTempChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildCurrentChart()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 第二行: 三相电压 | 功率 | 能耗
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVoltageChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildPowerChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildEnergyChart()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 第三行: 速度 | 位移 | 频率
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildVelocityChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildDisplacementChart()),
                const SizedBox(width: 8),
                Expanded(child: _buildFrequencyChart()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 1. PM10数据刷新 ====================
  Future<void> _refreshPM10Data() async {
    setState(() => _pm10Loading = true);
    try {
      final response = await _historyService.queryHopperPM10History(
        _deviceId,
        _pm10StartTime,
        _pm10EndTime,
      );
      if (mounted) {
        setState(() {
          _pm10Data =
              _convertToFlSpots(response.data ?? [], (d) => d.pm10Value);
          _pm10Loading = false;
        });
      }
    } catch (e) {
      debugPrint('加载PM10数据失败: $e');
      if (mounted) setState(() => _pm10Loading = false);
    }
  }

  // ==================== 2. 温度数据刷新 ====================
  Future<void> _refreshTempData() async {
    setState(() => _tempLoading = true);
    try {
      final response = await _historyService.queryHopperTemperatureHistory(
        _deviceId,
        _tempStartTime,
        _tempEndTime,
      );
      if (mounted) {
        setState(() {
          _tempData =
              _convertToFlSpots(response.data ?? [], (d) => d.temperature);
          _tempLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载温度数据失败: $e');
      if (mounted) setState(() => _tempLoading = false);
    }
  }

  // ==================== 3. 电流数据刷新 (三相) ====================
  Future<void> _refreshCurrentData() async {
    setState(() => _currentLoading = true);
    try {
      final response =
          await _historyService.queryHopperThreePhaseCurrentHistory(
        _deviceId,
        _currentStartTime,
        _currentEndTime,
      );
      if (mounted) {
        setState(() {
          _currentData = _convertToMultiLineFlSpots(
            response,
            {
              'A': (d) => d.currentA,
              'B': (d) => d.currentB,
              'C': (d) => d.currentC,
            },
          );
          _currentLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载电流数据失败: $e');
      if (mounted) setState(() => _currentLoading = false);
    }
  }

  // ==================== 4. 电压数据刷新 (三相) ====================
  Future<void> _refreshVoltageData() async {
    setState(() => _voltageLoading = true);
    try {
      final response =
          await _historyService.queryHopperThreePhaseVoltageHistory(
        _deviceId,
        _voltageStartTime,
        _voltageEndTime,
      );
      if (mounted) {
        setState(() {
          _voltageData = _convertToMultiLineFlSpots(
            response,
            {
              'A': (d) => d.voltageA,
              'B': (d) => d.voltageB,
              'C': (d) => d.voltageC,
            },
          );
          _voltageLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载电压数据失败: $e');
      if (mounted) setState(() => _voltageLoading = false);
    }
  }

  // ==================== 5. 功率数据刷新 ====================
  Future<void> _refreshPowerData() async {
    setState(() => _powerLoading = true);
    try {
      final response = await _historyService.queryHopperPowerHistory(
        _deviceId,
        _powerStartTime,
        _powerEndTime,
      );
      if (mounted) {
        setState(() {
          _powerData = _convertToFlSpots(response.data ?? [], (d) => d.pt);
          _powerLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载功率数据失败: $e');
      if (mounted) setState(() => _powerLoading = false);
    }
  }

  // ==================== 6. 能耗数据刷新 ====================
  Future<void> _refreshEnergyData() async {
    setState(() => _energyLoading = true);
    try {
      final response = await _historyService.queryHopperEnergyHistory(
        _deviceId,
        _energyStartTime,
        _energyEndTime,
      );
      if (mounted) {
        setState(() {
          _energyData = _convertToFlSpots(response.data ?? [], (d) => d.impEp);
          _energyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载能耗数据失败: $e');
      if (mounted) setState(() => _energyLoading = false);
    }
  }

  // ==================== 7. 振动速度数据刷新 (三轴) ====================
  Future<void> _refreshVelocityData() async {
    setState(() => _velocityLoading = true);
    try {
      final response =
          await _historyService.queryHopperThreeAxisVelocityHistory(
        _deviceId,
        _velocityStartTime,
        _velocityEndTime,
      );
      if (mounted) {
        setState(() {
          _velocityData = _convertToMultiLineFlSpots(
            response,
            {
              'X': (d) => d.vx,
              'Y': (d) => d.vy,
              'Z': (d) => d.vz,
            },
          );
          _velocityLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载振动速度数据失败: $e');
      if (mounted) setState(() => _velocityLoading = false);
    }
  }

  // ==================== 8. 振动位移数据刷新 (三轴) ====================
  Future<void> _refreshDisplacementData() async {
    setState(() => _displacementLoading = true);
    try {
      final response =
          await _historyService.queryHopperThreeAxisDisplacementHistory(
        _deviceId,
        _displacementStartTime,
        _displacementEndTime,
      );
      if (mounted) {
        setState(() {
          _displacementData = _convertToMultiLineFlSpots(
            response,
            {
              'X': (d) => d.dx,
              'Y': (d) => d.dy,
              'Z': (d) => d.dz,
            },
          );
          _displacementLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载振动位移数据失败: $e');
      if (mounted) setState(() => _displacementLoading = false);
    }
  }

  // ==================== 9. 振动频率数据刷新 (三轴) ====================
  Future<void> _refreshFrequencyData() async {
    setState(() => _frequencyLoading = true);
    try {
      final response =
          await _historyService.queryHopperThreeAxisFrequencyHistory(
        _deviceId,
        _frequencyStartTime,
        _frequencyEndTime,
      );
      if (mounted) {
        setState(() {
          _frequencyData = _convertToMultiLineFlSpots(
            response,
            {
              'X': (d) => d.freqX,
              'Y': (d) => d.freqY,
              'Z': (d) => d.freqZ,
            },
          );
          _frequencyLoading = false;
        });
      }
    } catch (e) {
      debugPrint('加载振动频率数据失败: $e');
      if (mounted) setState(() => _frequencyLoading = false);
    }
  }

  // ==================== 时间选择方法 ====================
  Future<void> _selectStartTime(String chartType) async {
    final currentStart = _getStartTime(chartType);
    final accentColor = const Color(0xFF00D4FF);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => _buildDatePickerTheme(child, accentColor),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: currentStart.hour, minute: 0),
        builder: (context, child) => _buildTimePickerTheme(child, accentColor),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          final newStart = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            0,
          );
          _setStartTime(chartType, newStart);
        });
        _refreshChart(chartType);
      }
    }
  }

  Future<void> _selectEndTime(String chartType) async {
    final currentEnd = _getEndTime(chartType);
    final accentColor = const Color(0xFF00D4FF);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentEnd,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
      builder: (context, child) => _buildDatePickerTheme(child, accentColor),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: currentEnd.hour, minute: 0),
        builder: (context, child) => _buildTimePickerTheme(child, accentColor),
      );

      if (pickedTime != null && mounted) {
        setState(() {
          final newEnd = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            0,
          );
          _setEndTime(chartType, newEnd);
        });
        _refreshChart(chartType);
      }
    }
  }

  Widget _buildDatePickerTheme(Widget? child, Color accentColor) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accentColor),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      child: child!,
    );
  }

  Widget _buildTimePickerTheme(Widget? child, Color accentColor) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accentColor),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(80, 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
      child: child!,
    );
  }

  DateTime _getStartTime(String chartType) {
    switch (chartType) {
      case 'pm10':
        return _pm10StartTime;
      case 'temp':
        return _tempStartTime;
      case 'current':
        return _currentStartTime;
      case 'voltage':
        return _voltageStartTime;
      case 'power':
        return _powerStartTime;
      case 'energy':
        return _energyStartTime;
      case 'velocity':
        return _velocityStartTime;
      case 'displacement':
        return _displacementStartTime;
      case 'frequency':
        return _frequencyStartTime;
      default:
        return DateTime.now().subtract(const Duration(hours: 24));
    }
  }

  DateTime _getEndTime(String chartType) {
    switch (chartType) {
      case 'pm10':
        return _pm10EndTime;
      case 'temp':
        return _tempEndTime;
      case 'current':
        return _currentEndTime;
      case 'voltage':
        return _voltageEndTime;
      case 'power':
        return _powerEndTime;
      case 'energy':
        return _energyEndTime;
      case 'velocity':
        return _velocityEndTime;
      case 'displacement':
        return _displacementEndTime;
      case 'frequency':
        return _frequencyEndTime;
      default:
        return DateTime.now();
    }
  }

  void _setStartTime(String chartType, DateTime time) {
    switch (chartType) {
      case 'pm10':
        _pm10StartTime = time;
        break;
      case 'temp':
        _tempStartTime = time;
        break;
      case 'current':
        _currentStartTime = time;
        break;
      case 'voltage':
        _voltageStartTime = time;
        break;
      case 'power':
        _powerStartTime = time;
        break;
      case 'energy':
        _energyStartTime = time;
        break;
      case 'velocity':
        _velocityStartTime = time;
        break;
      case 'displacement':
        _displacementStartTime = time;
        break;
      case 'frequency':
        _frequencyStartTime = time;
        break;
    }
  }

  void _setEndTime(String chartType, DateTime time) {
    switch (chartType) {
      case 'pm10':
        _pm10EndTime = time;
        break;
      case 'temp':
        _tempEndTime = time;
        break;
      case 'current':
        _currentEndTime = time;
        break;
      case 'voltage':
        _voltageEndTime = time;
        break;
      case 'power':
        _powerEndTime = time;
        break;
      case 'energy':
        _energyEndTime = time;
        break;
      case 'velocity':
        _velocityEndTime = time;
        break;
      case 'displacement':
        _displacementEndTime = time;
        break;
      case 'frequency':
        _frequencyEndTime = time;
        break;
    }
  }

  void _refreshChart(String chartType) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      switch (chartType) {
        case 'pm10':
          _refreshPM10Data();
          break;
        case 'temp':
          _refreshTempData();
          break;
        case 'current':
          _refreshCurrentData();
          break;
        case 'voltage':
          _refreshVoltageData();
          break;
        case 'power':
          _refreshPowerData();
          break;
        case 'energy':
          _refreshEnergyData();
          break;
        case 'velocity':
          _refreshVelocityData();
          break;
        case 'displacement':
          _refreshDisplacementData();
          break;
        case 'frequency':
          _refreshFrequencyData();
          break;
      }
    });
  }

  // ==================== 9个图表构建方法 ====================

  Widget _buildPM10Chart() {
    return HistoryChartCard(
      title: 'PM10',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'μg/m³',
      startTime: _pm10StartTime,
      endTime: _pm10EndTime,
      onStartTimeTap: () => _selectStartTime('pm10'),
      onEndTimeTap: () => _selectEndTime('pm10'),
      onRefresh: _refreshPM10Data,
      data: _pm10Data,
      isLoading: _pm10Loading,
    );
  }

  Widget _buildTempChart() {
    return HistoryChartCard(
      title: '温度',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: '°C',
      startTime: _tempStartTime,
      endTime: _tempEndTime,
      onStartTimeTap: () => _selectStartTime('temp'),
      onEndTimeTap: () => _selectEndTime('temp'),
      onRefresh: _refreshTempData,
      data: _tempData,
      isLoading: _tempLoading,
    );
  }

  Widget _buildCurrentChart() {
    return HistoryChartCard(
      title: '电流',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'A',
      startTime: _currentStartTime,
      endTime: _currentEndTime,
      onStartTimeTap: () => _selectStartTime('current'),
      onEndTimeTap: () => _selectEndTime('current'),
      onRefresh: _refreshCurrentData,
      multiLineData: _currentData,
      isLoading: _currentLoading,
    );
  }

  Widget _buildVoltageChart() {
    return HistoryChartCard(
      title: '电压',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'V',
      startTime: _voltageStartTime,
      endTime: _voltageEndTime,
      onStartTimeTap: () => _selectStartTime('voltage'),
      onEndTimeTap: () => _selectEndTime('voltage'),
      onRefresh: _refreshVoltageData,
      multiLineData: _voltageData,
      isLoading: _voltageLoading,
    );
  }

  Widget _buildPowerChart() {
    return HistoryChartCard(
      title: '功率',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'kW',
      startTime: _powerStartTime,
      endTime: _powerEndTime,
      onStartTimeTap: () => _selectStartTime('power'),
      onEndTimeTap: () => _selectEndTime('power'),
      onRefresh: _refreshPowerData,
      data: _powerData,
      isLoading: _powerLoading,
    );
  }

  Widget _buildEnergyChart() {
    return HistoryChartCard(
      title: '能耗',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'kWh',
      startTime: _energyStartTime,
      endTime: _energyEndTime,
      onStartTimeTap: () => _selectStartTime('energy'),
      onEndTimeTap: () => _selectEndTime('energy'),
      onRefresh: _refreshEnergyData,
      data: _energyData,
      isLoading: _energyLoading,
    );
  }

  Widget _buildVelocityChart() {
    return HistoryChartCard(
      title: '速度',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'mm/s',
      startTime: _velocityStartTime,
      endTime: _velocityEndTime,
      onStartTimeTap: () => _selectStartTime('velocity'),
      onEndTimeTap: () => _selectEndTime('velocity'),
      onRefresh: _refreshVelocityData,
      multiLineData: _velocityData,
      isLoading: _velocityLoading,
    );
  }

  Widget _buildDisplacementChart() {
    return HistoryChartCard(
      title: '位移',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'μm',
      startTime: _displacementStartTime,
      endTime: _displacementEndTime,
      onStartTimeTap: () => _selectStartTime('displacement'),
      onEndTimeTap: () => _selectEndTime('displacement'),
      onRefresh: _refreshDisplacementData,
      multiLineData: _displacementData,
      isLoading: _displacementLoading,
    );
  }

  Widget _buildFrequencyChart() {
    return HistoryChartCard(
      title: '频率',
      accentColor: const Color(0xFF00D4FF),
      yAxisLabel: 'Hz',
      startTime: _frequencyStartTime,
      endTime: _frequencyEndTime,
      onStartTimeTap: () => _selectStartTime('frequency'),
      onEndTimeTap: () => _selectEndTime('frequency'),
      onRefresh: _refreshFrequencyData,
      multiLineData: _frequencyData,
      isLoading: _frequencyLoading,
    );
  }
}
