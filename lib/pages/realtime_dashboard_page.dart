import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import '../models/hopper_model.dart';
import '../services/hopper_service.dart';
import '../services/realtime_data_cache_service.dart';
import '../utils/app_logger.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';

class RealtimeDashboardPage extends StatefulWidget {
  const RealtimeDashboardPage({super.key});

  @override
  State<RealtimeDashboardPage> createState() => RealtimeDashboardPageState();
}

class RealtimeDashboardPageState extends State<RealtimeDashboardPage> {
  final HopperService _hopperService = HopperService();
  final RealtimeDataCacheService _cacheService = RealtimeDataCacheService();

  Timer? _timer;
  Map<String, HopperData> _hopperData = {};
  bool _isRefreshingState = false;

  // Getter for TopBar
  bool get isRefreshing => _isRefreshingState;

  // 按照您的要求，主要关注这几个料仓
  final List<String> _displayOrderIds = [
    'long_hopper_1',
    'long_hopper_2',
    'long_hopper_3',
  ];

  final Map<String, String> _displayNames = {
    'long_hopper_1': '长窑料仓 #1',
    'long_hopper_2': '长窑料仓 #2',
    'long_hopper_3': '长窑料仓 #3',
  };

  // 轮询控制
  int _consecutiveFailures = 0;
  static const int _normalIntervalSeconds = 5;

  // 三轴速度RMS曲线数据（最多20组）
  static const int _maxVibrationPoints = 20;
  final List<FlSpot> _vrmsXSeries = [];
  final List<FlSpot> _vrmsYSeries = [];
  final List<FlSpot> _vrmsZSeries = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Exposed method for TopBar
  Future<void> refreshData() async {
    await _fetchData();
  }

  void pausePolling() {
    _timer?.cancel();
    _timer = null;
    logger.info('RealtimeDashboardPage: 轮询已暂停');
  }

  void resumePolling() {
    if (_timer == null) {
      _startPolling();
      _fetchData();
      logger.info('RealtimeDashboardPage: 轮询已恢复');
    }
  }

  Future<void> _initData() async {
    await _loadCachedData();
    _fetchData();
    _startPolling();
  }

  Future<void> _loadCachedData() async {
    try {
      final cachedData = await _cacheService.loadCache();
      if (cachedData != null && cachedData.hasData && mounted) {
        setState(() {
          _hopperData = cachedData.hopperData;
        });
      }
    } catch (e) {
      logger.error('加载缓存数据失败', e);
    }
  }

  void _startPolling() {
    _timer?.cancel();
    int interval = _normalIntervalSeconds;
    if (_consecutiveFailures > 0) {
      interval = (_normalIntervalSeconds * (1 << _consecutiveFailures))
          .clamp(_normalIntervalSeconds, 60);
    }

    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      if (mounted) _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (_isRefreshingState) return;

    _isRefreshingState = true;

    try {
      final newData = await _hopperService.getHopperBatchData();
      if (mounted) {
        setState(() {
          _hopperData = newData;
          _consecutiveFailures = 0;
          _appendVibrationSeries(newData);
        });
        // 缓存数据
        _cacheService.saveCache(hopperData: newData);
      }
    } catch (e) {
      _consecutiveFailures++;
      logger.error('获取实时数据失败', e);
    } finally {
      if (mounted) {
        // Only update state if mounted, although _isRefreshingState is not impacting UI directly here
        // But if we used setState above, we should ensure it's safe.
        _isRefreshingState = false;
      } else {
        _isRefreshingState = false;
      }

      // Restart timer if interval needs adjustment
      if (_consecutiveFailures > 0 && _timer != null) {
        _startPolling();
      }
    }
  }

  void _appendVibrationSeries(Map<String, HopperData> data) {
    if (data.isEmpty) return;

    final target = _getTargetHopperData(data);
    final vibration = target?.vibration;
    if (vibration == null) return;

    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    _vrmsXSeries.add(FlSpot(now, vibration.vrmsX));
    _vrmsYSeries.add(FlSpot(now, vibration.vrmsY));
    _vrmsZSeries.add(FlSpot(now, vibration.vrmsZ));

    if (_vrmsXSeries.length > _maxVibrationPoints) {
      _vrmsXSeries.removeAt(0);
      _vrmsYSeries.removeAt(0);
      _vrmsZSeries.removeAt(0);
    }
  }

  HopperData? _getTargetHopperData(Map<String, HopperData> data) {
    if (data.isEmpty) return null;
    for (final id in _displayOrderIds) {
      if (data[id] != null) return data[id];
    }
    return data.values.first;
  }

  VibrationData? _getTargetVibration(Map<String, HopperData> data) {
    return _getTargetHopperData(data)?.vibration;
  }

  // ===== 统计计算方法 =====
  double _getTotalWeight() {
    double total = 0.0;
    for (final id in _displayOrderIds) {
      total += _hopperData[id]?.weighSensor?.weight ?? 0.0;
    }
    return total;
  }

  double _getAvgFeedRate() {
    double sum = 0.0;
    int count = 0;
    for (final id in _displayOrderIds) {
      final rate = _hopperData[id]?.weighSensor?.feedRate;
      if (rate != null && rate > 0) {
        sum += rate;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  double _getAvgTemperature() {
    double sum = 0.0;
    int count = 0;
    for (final id in _displayOrderIds) {
      final temp = _hopperData[id]?.temperatureSensor?.temperature;
      if (temp != null && temp > 0) {
        sum += temp;
        count++;
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  int _getOnlineCount() {
    int count = 0;
    for (final id in _displayOrderIds) {
      if (_hopperData[id] != null) count++;
    }
    return count;
  }

  // ===== 构建振动曲线图 =====
  Widget _buildVibrationRmsChart(VibrationData? vibration) {
    if (_vrmsXSeries.isEmpty || _vrmsYSeries.isEmpty || _vrmsZSeries.isEmpty) {
      return const Center(
        child: Text('暂无振动速度数据', style: TextStyle(color: Colors.grey)),
      );
    }

    final allY = [
      ..._vrmsXSeries.map((e) => e.y),
      ..._vrmsYSeries.map((e) => e.y),
      ..._vrmsZSeries.map((e) => e.y),
    ];
    final maxY =
        (allY.isEmpty ? 1.0 : allY.reduce((a, b) => a > b ? a : b)) * 1.2;
    final minX = _vrmsXSeries.length == 1
        ? _vrmsXSeries.first.x - 1
        : _vrmsXSeries.first.x;
    final maxX = _vrmsXSeries.length == 1
        ? _vrmsXSeries.first.x + 1
        : _vrmsXSeries.last.x;

    return Column(
      children: [
        if (vibration != null) ...[
          _buildAxisBadge(
            title: '频率 (Hz)',
            icon: Icons.waves,
            values: [
              _AxisValue('X', vibration.freqX, TechColors.glowCyan),
              _AxisValue('Y', vibration.freqY, TechColors.glowOrange),
              _AxisValue('Z', vibration.freqZ, TechColors.glowGreen),
            ],
          ),
          const SizedBox(height: 6),
          _buildAxisBadge(
            title: '峭度 (g)',
            icon: Icons.analytics_outlined,
            values: [
              _AxisValue('KX', vibration.kx, TechColors.glowCyan),
              _AxisValue('KY', vibration.ky, TechColors.glowOrange),
              _AxisValue('KZ', vibration.kz, TechColors.glowGreen),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) => const FlLine(
                  color: Color(0xFF21262d),
                  strokeWidth: 1,
                ),
                getDrawingVerticalLine: (value) => const FlLine(
                  color: Color(0xFF21262d),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: maxY,
              lineBarsData: [
                _buildLine(_vrmsXSeries, TechColors.glowCyan),
                _buildLine(_vrmsYSeries, TechColors.glowOrange),
                _buildLine(_vrmsZSeries, TechColors.glowGreen),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('VRMSX', TechColors.glowCyan),
            const SizedBox(width: 12),
            _buildLegendItem('VRMSY', TechColors.glowOrange),
            const SizedBox(width: 12),
            _buildLegendItem('VRMSZ', TechColors.glowGreen),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplacementTrapezoid(VibrationData? vibration) {
    if (vibration == null) {
      return const Center(
        child: Text('暂无位移数据', style: TextStyle(color: Colors.grey)),
      );
    }

    return SizedBox(
      height: 120,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAxisValue('X', vibration.dx, TechColors.glowCyan),
                _buildAxisValue('Y', vibration.dy, TechColors.glowOrange),
                _buildAxisValue('Z', vibration.dz, TechColors.glowGreen),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomPaint(
              painter: _TrapezoidPainter(
                borderColor: TechColors.glowCyan,
                axisColors: const [
                  TechColors.glowCyan,
                  TechColors.glowOrange,
                  TechColors.glowGreen,
                ],
                gridColor: TechColors.gridLine,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAxisValue(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Roboto Mono',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  LineChartBarData _buildLine(List<FlSpot> data, Color color) {
    return LineChartBarData(
      spots: data,
      isCurved: true,
      color: color,
      barWidth: 2,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildAxisBadge({
    required String title,
    required IconData icon,
    required List<_AxisValue> values,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: TechColors.glowCyan),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 10),
          ...values.map((v) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${v.label}: ',
                        style: TextStyle(
                          color: v.color.withOpacity(0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: v.value.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'Roboto Mono',
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // ===== 信息卡片构建 =====
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElectricCard(ElectricityMeter? meter) {
    final pt = meter?.pt ?? 0.0;
    final impEp = meter?.impEp ?? 0.0;
    final ia = meter?.currentA ?? 0.0;
    final ib = meter?.currentB ?? 0.0;
    final ic = meter?.currentC ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.85),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: TechColors.glowCyan.withOpacity(0.25),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, size: 16, color: TechColors.glowCyan),
              const SizedBox(width: 6),
              Text(
                '功率 / 电流',
                style: TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              _buildMiniStat('Pt', pt, 'kW', TechColors.glowCyan),
              const SizedBox(width: 8),
              _buildMiniStat('Ep', impEp, 'kWh', TechColors.glowCyan),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildMiniStat('IA', ia, 'A', TechColors.glowGreen),
              const SizedBox(width: 8),
              _buildMiniStat('IB', ib, 'A', TechColors.glowOrange),
              const SizedBox(width: 8),
              _buildMiniStat('IC', ic, 'A', TechColors.glowCyanLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, double value, String unit, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: TextStyle(color: color, fontSize: 11),
        ),
        const SizedBox(width: 4),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'Roboto Mono',
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }

  // Add onPageEnter compatibility if needed, though TopBar error only mentioned HistoryDataPage
  void onPageEnter() {
    resumePolling();
  }

  @override
  Widget build(BuildContext context) {
    final targetHopper = _getTargetHopperData(_hopperData);
    final targetVibration = targetHopper?.vibration;
    final targetElectricity = targetHopper?.electricityMeter;
    final targetTemperature = targetHopper?.temperatureSensor?.temperature ??
        targetHopper?.temperatureSensor1?.temperature ??
        targetHopper?.temperatureSensor2?.temperature ??
        _getAvgTemperature();
    final pm10Value = targetHopper?.pm10Sensor?.pm10 ?? 0.0;

    return Container(
      color: const Color(0xFF0d1117),
      child: Row(
        children: [
          // 左侧：振动曲线图区域 (40%)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFF30363d))),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: TechPanel(
                      title: '三轴速度RMS (mm/s)',
                      accentColor: TechColors.glowCyan,
                      child: _buildVibrationRmsChart(targetVibration),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    child: TechPanel(
                      title: '位移幅值 (μm)',
                      accentColor: TechColors.glowCyan,
                      child: _buildDisplacementTrapezoid(targetVibration),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 右侧：料仓结构面板 (60%) - 类似电炉除尘器面板样式
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
              decoration: BoxDecoration(
                color: TechColors.bgDark,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: TechColors.glowCyan.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: TechColors.glowCyan.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 标题栏
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: TechColors.bgMedium.withOpacity(0.5),
                      border: Border(
                        bottom: BorderSide(
                          color: TechColors.glowCyan.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: TechColors.glowCyan,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '料仓结构',
                          style: TextStyle(
                            color: TechColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: TechColors.glowCyan.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 主体内容区域 - 使用 Expanded 填充剩余空间
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 背景图片
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                TechColors.glowCyan.withOpacity(0.6),
                                BlendMode.srcIn,
                              ),
                              child: Image.asset(
                                'assets/images/hopper.png',
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: TechColors.bgMedium.withOpacity(0.3),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.image_not_supported,
                                              size: 48,
                                              color: TechColors.textSecondary),
                                          SizedBox(height: 8),
                                          Text('结构图资源未加载',
                                              style: TextStyle(
                                                  color: TechColors
                                                      .textSecondary)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // 左上角：PM10
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _buildInfoCard(
                              icon: Icons.air,
                              label: 'PM10',
                              value: pm10Value.toStringAsFixed(1),
                              unit: 'μg/m³',
                              color: TechColors.glowCyan,
                            ),
                          ),
                          // 右上角：功率/电流
                          Positioned(
                            right: 8,
                            top: 8,
                            child: _buildElectricCard(targetElectricity),
                          ),
                          // 左下角：温度
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: _buildInfoCard(
                              icon: Icons.thermostat,
                              label: '温度',
                              value: targetTemperature.toStringAsFixed(1),
                              unit: '°C',
                              color: TechColors.glowOrange,
                            ),
                          ),
                          // 右下角：在线设备数
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: _buildInfoCard(
                              icon: Icons.sensors,
                              label: '在线设备',
                              value:
                                  '${_getOnlineCount()}/${_displayOrderIds.length}',
                              unit: '台',
                              color:
                                  _getOnlineCount() == _displayOrderIds.length
                                      ? TechColors.statusNormal
                                      : TechColors.statusWarning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHopperCard(String id, HopperData? data) {
    final name = _displayNames[id] ?? id;
    final isOnline = data != null; // 简单判断在线状态

    // 解析具体数值
    final weight = data?.weighSensor?.weight ?? 0.0;
    final feedRate = data?.weighSensor?.feedRate ?? 0.0;
    final temp = data?.temperatureSensor?.temperature ??
        0.0; // Fixed .value -> .temperature

    // 颜色定义
    final glowColor =
        isOnline ? const Color(0xFF00ff88) : const Color(0xFF484f58);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: TechPanel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // 状态指示灯
            Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                color: glowColor,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isOnline
                    ? [
                        BoxShadow(
                            color: glowColor.withOpacity(0.5),
                            blurRadius: 6,
                            spreadRadius: 1)
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 8),

            // 设备名称
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      )),
                  Text(isOnline ? 'RUNNING' : 'OFFLINE',
                      style: TextStyle(
                        color: glowColor,
                        fontSize: 9,
                        letterSpacing: 1,
                      )),
                ],
              ),
            ),

            // 数据显示 (重量/速度/温度)
            _buildMiniMetric('重量', '${weight.toStringAsFixed(1)} kg'),
            _buildMiniMetric('速度', '${feedRate.toStringAsFixed(1)} kg/h'),
            _buildMiniMetric('温度', '${temp.toStringAsFixed(1)} °C'),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Expanded(
      flex: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(value,
              style: const TextStyle(
                color: Color(0xFF00d4ff),
                fontSize: 11,
                fontFamily: 'Roboto Mono',
                fontWeight: FontWeight.w500,
              )),
          Text(label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 9,
              )),
        ],
      ),
    );
  }
}

class _AxisValue {
  final String label;
  final double value;
  final Color color;

  _AxisValue(this.label, this.value, this.color);
}

class _TrapezoidPainter extends CustomPainter {
  final Color borderColor;
  final Color gridColor;
  final List<Color> axisColors;

  _TrapezoidPainter({
    required this.borderColor,
    required this.axisColors,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final padding = 8.0;
    final left = padding;
    final right = size.width - padding;
    final top = padding;
    final bottom = size.height - padding;

    // 顺时针旋转90度的梯形外框（左侧长、右侧短）
    final path = Path()
      ..moveTo(left, top)
      ..lineTo(left, bottom)
      ..lineTo(right, bottom - (size.height * 0.25))
      ..lineTo(right, top + (size.height * 0.25))
      ..close();

    final fillPaint = Paint()
      ..color = gridColor.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    canvas.drawPath(path, paint);

    // 内部三条横向灯线（对应 X/Y/Z）
    final y1 = top + (bottom - top) * 0.2;
    final y2 = top + (bottom - top) * 0.5;
    final y3 = top + (bottom - top) * 0.8;

    final axisPaints = List<Paint>.generate(3, (i) {
      final color = i < axisColors.length ? axisColors[i] : borderColor;
      return Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
    });

    canvas.drawLine(
        Offset(left, y1), Offset(right, y1 - size.height * 0.1), axisPaints[0]);
    canvas.drawLine(Offset(left, y2), Offset(right, y2), axisPaints[1]);
    canvas.drawLine(
        Offset(left, y3), Offset(right, y3 + size.height * 0.1), axisPaints[2]);

    // 发光边框叠层
    final glowPaint = Paint()
      ..color = borderColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
