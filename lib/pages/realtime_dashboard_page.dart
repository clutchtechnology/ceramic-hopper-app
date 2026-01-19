import 'package:flutter/material.dart';
import 'dart:async';
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
  Widget _buildVibrationSpectrumChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.graphic_eq, size: 48, color: TechColors.glowOrange.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            '振动频谱实时曲线',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '50.0 Hz',
            style: TextStyle(
              color: TechColors.glowOrange,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationAmplitudeChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waves, size: 48, color: TechColors.glowCyan.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            '振动幅值实时曲线',
            style: TextStyle(
              color: TechColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '2.8 mm/s',
            style: TextStyle(
              color: TechColors.glowCyan,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto Mono',
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Add onPageEnter compatibility if needed, though TopBar error only mentioned HistoryDataPage
  void onPageEnter() {
      resumePolling();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0d1117), 
      child: Row(
        children: [
          // 左侧：振动曲线图区域 (40%)
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: Color(0xFF30363d))),
              ),
              child: Column(
                children: [
                  // 上半部分：振动频谱图
                  Expanded(
                    child: TechPanel(
                      title: '振动频谱',
                      accentColor: TechColors.glowOrange,
                      height: double.infinity,
                      child: _buildVibrationSpectrumChart(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 下半部分：振幅曲线图
                  Expanded(
                    child: TechPanel(
                      title: '振动幅值',
                      accentColor: TechColors.glowCyan,
                      height: double.infinity,
                      child: _buildVibrationAmplitudeChart(),
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
              margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
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
                      padding: const EdgeInsets.all(8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 背景图片
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
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
                                        Icon(Icons.image_not_supported, size: 48, color: TechColors.textSecondary),
                                        SizedBox(height: 8),
                                        Text('结构图资源未加载', style: TextStyle(color: TechColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // 左上角：总重量卡片
                          Positioned(
                            left: 8,
                            top: 8,
                            child: _buildInfoCard(
                              icon: Icons.scale,
                              label: '总重量',
                              value: _getTotalWeight().toStringAsFixed(1),
                              unit: 'kg',
                              color: TechColors.glowCyan,
                            ),
                          ),
                          // 右上角：平均下料速度
                          Positioned(
                            right: 8,
                            top: 8,
                            child: _buildInfoCard(
                              icon: Icons.speed,
                              label: '平均速度',
                              value: _getAvgFeedRate().toStringAsFixed(1),
                              unit: 'kg/h',
                              color: TechColors.glowGreen,
                            ),
                          ),
                          // 左下角：平均温度
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: _buildInfoCard(
                              icon: Icons.thermostat,
                              label: '平均温度',
                              value: _getAvgTemperature().toStringAsFixed(1),
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
                              value: '${_getOnlineCount()}/${_displayOrderIds.length}',
                              unit: '台',
                              color: _getOnlineCount() == _displayOrderIds.length 
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
    final temp = data?.temperatureSensor?.temperature ?? 0.0; // Fixed .value -> .temperature
    
    // 颜色定义
    final glowColor = isOnline ? const Color(0xFF00ff88) : const Color(0xFF484f58);

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
                boxShadow: isOnline ? [
                  BoxShadow(color: glowColor.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)
                ] : [],
              ),
            ),
            const SizedBox(width: 8),
            
            // 设备名称
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  )),
                  Text(isOnline ? 'RUNNING' : 'OFFLINE', style: TextStyle(
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
          Text(value, style: const TextStyle(
            color: Color(0xFF00d4ff),
            fontSize: 11,
            fontFamily: 'Roboto Mono',
            fontWeight: FontWeight.w500,
          )),
          Text(label, style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
          )),
        ],
      ),
    );
  }
}
