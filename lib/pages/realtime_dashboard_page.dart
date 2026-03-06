import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../models/hopper_model.dart';
import '../services/hopper_service.dart';
import '../services/realtime_data_cache_service.dart';
import '../utils/app_logger.dart';
import '../utils/ui_watchdog.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';
import '../providers/hopper_threshold_provider.dart';

class RealtimeDashboardPage extends StatefulWidget {
  const RealtimeDashboardPage({super.key});

  @override
  State<RealtimeDashboardPage> createState() => RealtimeDashboardPageState();
}

class RealtimeDashboardPageState extends State<RealtimeDashboardPage>
    with AutomaticKeepAliveClientMixin<RealtimeDashboardPage> {
  final HopperService _hopperService = HopperService();
  final RealtimeDataCacheService _cacheService = RealtimeDataCacheService();

  // 缓存 ColorFilter 避免每次 build 重建对象
  static final ColorFilter _hopperImageFilter = ColorFilter.mode(
    TechColors.glowCyan.withOpacity(0.6),
    BlendMode.srcIn,
  );

  Map<String, HopperData> _hopperData = {};
  final bool _isRefreshingState = false;

  // [CRITICAL] WebSocket 节流控制：后端 0.1s 推送，UI 根据看门狗状态动态调整
  // normal=1s, degraded=3s, critical=5s，防止工控机过载
  DateTime? _lastWsUiUpdate;
  Duration get _wsUiThrottle => UIWatchdog().getThrottle(
        normal: const Duration(seconds: 1),
        degraded: const Duration(seconds: 3),
        critical: const Duration(seconds: 5),
      );

  // [CRITICAL] 磁盘 I/O 节流：缓存保存最多 30s/60s/120s 一次，防止频繁写文件
  DateTime? _lastWsCacheSave;
  Duration get _wsCacheThrottle => UIWatchdog().getThrottle(
        normal: const Duration(seconds: 30),
        degraded: const Duration(seconds: 60),
        critical: const Duration(seconds: 120),
      );

  // [CRITICAL] 缓存 Provider 引用（防止 build() 中频繁查找导致卡死）
  late HopperThresholdProvider _thresholdProvider;

  // Getter for TopBar
  bool get isRefreshing => _isRefreshingState;

  @override
  void initState() {
    super.initState();
    // 缓存 Provider 引用（防止 build() 中频繁查找）
    _thresholdProvider = context.read<HopperThresholdProvider>();
    _initData();
  }

  @override
  void dispose() {
    _hopperService.unsubscribe();
    super.dispose();
  }

  // Exposed method for TopBar
  Future<void> refreshData() async {
    logger.info('RealtimeDashboardPage: 手动刷新数据');
  }

  void pausePolling() {
    logger.info('RealtimeDashboardPage: WebSocket 模式，无需暂停');
  }

  void resumePolling() {
    logger.info('RealtimeDashboardPage: WebSocket 模式，无需恢复');
  }

  void onPageEnter() {
    resumePolling();
  }

  Future<void> _initData() async {
    await _loadCachedData();
    _subscribeWebSocket();
  }

  // 1. 加载缓存数据
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

  // 2. 订阅 WebSocket 实时数据
  void _subscribeWebSocket() {
    _hopperService.onRealtimeDataUpdate = _handleRealtimeData;
    _hopperService.subscribeRealtime();
    logger.info('RealtimeDashboardPage: 已订阅 WebSocket 实时数据');
  }

  // 3. 处理 WebSocket 推送的实时数据 - [CRITICAL] 添加节流保护
  void _handleRealtimeData(HopperRealtimeResponse response) {
    if (!mounted) return;

    // [CRITICAL] 无论节流与否，始终更新内部数据变量（保证数据最新）
    // 这样即使 setState 被节流，下次触发时用的也是最新一帧数据
    _hopperData = response.data;

    // [CRITICAL] 节流 setState：后端 0.1s 推送，UI 最多 1s 重建一次
    // 防止 10Hz 全量重建超复杂 Widget 树导致工控机主线程卡死
    final now = DateTime.now();
    final lastUiUpdate = _lastWsUiUpdate;
    if (lastUiUpdate == null || now.difference(lastUiUpdate) >= _wsUiThrottle) {
      _lastWsUiUpdate = now;
      setState(() {
        // 数据已在上方更新，此处 setState 仅触发重建
      });
    }

    // [CRITICAL] 节流 saveCache：磁盘 I/O 最多 30s 一次，防止频繁写文件
    final lastCacheSave = _lastWsCacheSave;
    if (lastCacheSave == null ||
        now.difference(lastCacheSave) >= _wsCacheThrottle) {
      _lastWsCacheSave = now;
      _cacheService.saveCache(hopperData: _hopperData);
    }

    // 调试日志（每 10 次推送记录一次，避免日志泛滥）
    if (_lastWsUiUpdate != null &&
        now.difference(_lastWsUiUpdate!).inSeconds % 10 == 0) {
      logger.debug('RealtimeDashboardPage: 收到实时数据，设备数: ${_hopperData.length}');
    }
  }

  // 获取第一个料仓数据
  HopperData? _getFirstHopperData() {
    if (_hopperData.isEmpty) return null;
    return _hopperData.values.first;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hopperData = _getFirstHopperData();

    return Container(
      color: TechColors.bgDeep,
      child: Row(
        children: [
          // 左侧：数据列表区域 (40%) - 已注释
          // Expanded(
          //   flex: 40,
          //   child: _buildLeftDataPanel(hopperData),
          // ),
          // 右侧：料仓结构图 (100% 全屏)
          Expanded(
            flex: 100,
            child: _buildRightHopperPanel(hopperData),
          ),
        ],
      ),
    );
  }

  /// 左侧数据面板：两列 10 行, 左列10条(PM10+温度+8电表), 右列9条(振动)+1空
  Widget _buildLeftDataPanel(HopperData? data) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate(10, (rowIndex) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: rowIndex < 9 ? 1 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDataCell(rowIndex, 0, data),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: _buildDataCell(rowIndex, 1, data),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建单个数据单元格 (10行x2列, 左列索引 0-9, 右列索引 10-19)
  Widget _buildDataCell(int row, int col, HopperData? data) {
    // [CRITICAL] 使用缓存的 Provider 引用，避免 build() 中频繁查找
    final thresholdProvider = _thresholdProvider;
    // 左列: row*1, 右列: 10+row
    final index = col == 0 ? row : 10 + row;

    String label = '';
    String value = '--';
    String unit = '';
    Color color = ThresholdColors.normal;
    IconData icon = Icons.sensors;

    // 右列第10行(index=19)为空位
    if (index == 19) {
      return Container(
        decoration: BoxDecoration(
          color: TechColors.bgMedium.withOpacity(0.3),
          border: Border.all(color: TechColors.borderDark, width: 1),
        ),
      );
    }

    if (data != null) {
      double numValue = 0.0;
      final elec = data.electricityModule;
      final vib = data.vibrationModule;

      switch (index) {
        // ===== 左列: PM10 + 温度 + 电表(8) =====
        case 0: // 粉尘浓度
          label = '粉尘浓度';
          numValue = data.pm10Module?.pm10Value ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'ug/m3';
          color = thresholdProvider.getPM10Color(numValue);
          icon = Icons.air;
          break;
        case 1: // 温度
          label = '温度';
          numValue = data.temperatureModule?.temperatureValue ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = '\u00B0C';
          color = thresholdProvider.getTemperatureColor(numValue);
          icon = Icons.thermostat;
          break;
        case 2: // 功率
          label = '功率';
          numValue = elec?.pt ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'kW';
          color = thresholdProvider.getPowerColor(numValue);
          icon = Icons.bolt;
          break;
        case 3: // 能耗
          label = '能耗';
          value = (elec?.impEp ?? 0.0).toStringAsFixed(1);
          unit = 'kWh';
          color = ThresholdColors.normal;
          icon = Icons.electric_meter;
          break;
        case 4: // A相电压
          label = 'A相电压';
          numValue = elec?.voltage ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'V';
          color = thresholdProvider.getVoltageAColor(numValue);
          icon = Icons.bolt;
          break;
        case 5: // B相电压
          label = 'B相电压';
          numValue = elec?.voltageB ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'V';
          color = thresholdProvider.getVoltageBColor(numValue);
          icon = Icons.bolt;
          break;
        case 6: // C相电压
          label = 'C相电压';
          numValue = elec?.voltageC ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'V';
          color = thresholdProvider.getVoltageCColor(numValue);
          icon = Icons.bolt;
          break;
        case 7: // A相电流
          label = 'A相电流';
          numValue = elec?.currentA ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'A';
          color = thresholdProvider.getCurrentAColor(numValue);
          icon = Icons.electric_bolt;
          break;
        case 8: // B相电流
          label = 'B相电流';
          numValue = elec?.currentB ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'A';
          color = thresholdProvider.getCurrentBColor(numValue);
          icon = Icons.electric_bolt;
          break;
        case 9: // C相电流
          label = 'C相电流';
          numValue = elec?.currentC ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'A';
          color = thresholdProvider.getCurrentCColor(numValue);
          icon = Icons.electric_bolt;
          break;

        // ===== 右列: 振动(9) =====
        case 10: // X轴速度
          label = 'X轴速度';
          numValue = vib?.vx ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'mm/s';
          color = thresholdProvider.getSpeedXColor(numValue);
          icon = Icons.vibration;
          break;
        case 11: // Y轴速度
          label = 'Y轴速度';
          numValue = vib?.vy ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'mm/s';
          color = thresholdProvider.getSpeedYColor(numValue);
          icon = Icons.vibration;
          break;
        case 12: // Z轴速度
          label = 'Z轴速度';
          numValue = vib?.vz ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'mm/s';
          color = thresholdProvider.getSpeedZColor(numValue);
          icon = Icons.vibration;
          break;
        case 13: // X轴位移
          label = 'X轴位移';
          numValue = vib?.dx ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'um';
          color = thresholdProvider.getDisplacementXColor(numValue);
          icon = Icons.straighten;
          break;
        case 14: // Y轴位移
          label = 'Y轴位移';
          numValue = vib?.dy ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'um';
          color = thresholdProvider.getDisplacementYColor(numValue);
          icon = Icons.straighten;
          break;
        case 15: // Z轴位移
          label = 'Z轴位移';
          numValue = vib?.dz ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'um';
          color = thresholdProvider.getDisplacementZColor(numValue);
          icon = Icons.straighten;
          break;
        case 16: // X轴频率
          label = 'X轴频率';
          numValue = vib?.freqX ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'Hz';
          color = thresholdProvider.getFreqXColor(numValue);
          icon = Icons.graphic_eq;
          break;
        case 17: // Y轴频率
          label = 'Y轴频率';
          numValue = vib?.freqY ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'Hz';
          color = thresholdProvider.getFreqYColor(numValue);
          icon = Icons.graphic_eq;
          break;
        case 18: // Z轴频率
          label = 'Z轴频率';
          numValue = vib?.freqZ ?? 0.0;
          value = numValue.toStringAsFixed(1);
          unit = 'Hz';
          color = thresholdProvider.getFreqZColor(numValue);
          icon = Icons.graphic_eq;
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.3),
        border: Border.all(
          color: TechColors.borderDark,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 2),
          Text(
            '$label:',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const SizedBox(width: 2),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// 右侧料仓结构面板
  Widget _buildRightHopperPanel(HopperData? data) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图片（右移 40px）
          Positioned(
            left: 40,
            right: -40,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: ColorFiltered(
                colorFilter: _hopperImageFilter,
                child: Image.asset(
                  'assets/images/hopper.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: TechColors.bgMedium.withOpacity(0.3),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: TechColors.textSecondary,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '结构图资源未加载',
                              style: TextStyle(color: TechColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // 左上角：粉尘浓度
          Positioned(
            left: 8,
            top: 8,
            child: _buildPM10TempCard(data),
          ),
          // 右上角：9条振动数据
          Positioned(
            right: 8,
            top: 8,
            child: _buildVibrationCard(data),
          ),
          // 左下角：8条电表数据
          Positioned(
            left: 8,
            bottom: 8,
            child: _buildElectricityCard(data),
          ),
        ],
      ),
    );
  }

  /// 左上角：粉尘浓度 + 温度卡片 (340px 宽)
  Widget _buildPM10TempCard(HopperData? data) {
    // [CRITICAL] 使用缓存的 Provider 引用
    final thresholdProvider = _thresholdProvider;

    final pm10 = data?.pm10Module?.pm10Value ?? 0.0;
    final temp = data?.temperatureModule?.temperatureValue ?? 0.0;

    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgDeep.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDataRow(
            icon: Icons.air,
            label: '粉尘浓度',
            value: pm10.toStringAsFixed(1),
            unit: 'ug/m3',
            color: thresholdProvider.getPM10Color(pm10),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.thermostat,
            label: '温度',
            value: temp.toStringAsFixed(1),
            unit: '\u00B0C',
            color: thresholdProvider.getTemperatureColor(temp),
          ),
        ],
      ),
    );
  }

  /// 右上角：振动数据卡片 (340px 宽，9 条数据，每条 32px)
  Widget _buildVibrationCard(HopperData? data) {
    // [CRITICAL] 使用缓存的 Provider 引用
    final thresholdProvider = _thresholdProvider;
    final vib = data?.vibrationModule;

    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgDeep.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.glowGreen.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDataRow(
            icon: Icons.vibration,
            label: 'X轴速度',
            value: (vib?.vx ?? 0.0).toStringAsFixed(1),
            unit: 'mm/s',
            color: thresholdProvider.getSpeedXColor(vib?.vx ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.vibration,
            label: 'Y轴速度',
            value: (vib?.vy ?? 0.0).toStringAsFixed(1),
            unit: 'mm/s',
            color: thresholdProvider.getSpeedYColor(vib?.vy ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.vibration,
            label: 'Z轴速度',
            value: (vib?.vz ?? 0.0).toStringAsFixed(1),
            unit: 'mm/s',
            color: thresholdProvider.getSpeedZColor(vib?.vz ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.straighten,
            label: 'X轴位移',
            value: (vib?.dx ?? 0.0).toStringAsFixed(1),
            unit: 'um',
            color: thresholdProvider.getDisplacementXColor(vib?.dx ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.straighten,
            label: 'Y轴位移',
            value: (vib?.dy ?? 0.0).toStringAsFixed(1),
            unit: 'um',
            color: thresholdProvider.getDisplacementYColor(vib?.dy ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.straighten,
            label: 'Z轴位移',
            value: (vib?.dz ?? 0.0).toStringAsFixed(1),
            unit: 'um',
            color: thresholdProvider.getDisplacementZColor(vib?.dz ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.graphic_eq,
            label: 'X轴频率',
            value: (vib?.freqX ?? 0.0).toStringAsFixed(1),
            unit: 'Hz',
            color: thresholdProvider.getFreqXColor(vib?.freqX ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.graphic_eq,
            label: 'Y轴频率',
            value: (vib?.freqY ?? 0.0).toStringAsFixed(1),
            unit: 'Hz',
            color: thresholdProvider.getFreqYColor(vib?.freqY ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.graphic_eq,
            label: 'Z轴频率',
            value: (vib?.freqZ ?? 0.0).toStringAsFixed(1),
            unit: 'Hz',
            color: thresholdProvider.getFreqZColor(vib?.freqZ ?? 0.0),
          ),
        ],
      ),
    );
  }

  /// 左下角：电表数据卡片 (340px 宽，8 条数据，每条 32px)
  Widget _buildElectricityCard(HopperData? data) {
    // [CRITICAL] 使用缓存的 Provider 引用
    final thresholdProvider = _thresholdProvider;
    final elec = data?.electricityModule;

    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgDeep.withOpacity(0.9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: TechColors.glowCyan.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDataRow(
            icon: Icons.bolt,
            label: '功率',
            value: (elec?.pt ?? 0.0).toStringAsFixed(1),
            unit: 'kW',
            color: thresholdProvider.getPowerColor(elec?.pt ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.electric_meter,
            label: '能耗',
            value: (elec?.impEp ?? 0.0).toStringAsFixed(1),
            unit: 'kWh',
            color: ThresholdColors.normal,
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.bolt,
            label: 'A相电压',
            value: (elec?.voltage ?? 0.0).toStringAsFixed(1),
            unit: 'V',
            color: thresholdProvider.getVoltageAColor(elec?.voltage ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.bolt,
            label: 'B相电压',
            value: (elec?.voltageB ?? 0.0).toStringAsFixed(1),
            unit: 'V',
            color: thresholdProvider.getVoltageBColor(elec?.voltageB ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.bolt,
            label: 'C相电压',
            value: (elec?.voltageC ?? 0.0).toStringAsFixed(1),
            unit: 'V',
            color: thresholdProvider.getVoltageCColor(elec?.voltageC ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.electric_bolt,
            label: 'A相电流',
            value: (elec?.currentA ?? 0.0).toStringAsFixed(1),
            unit: 'A',
            color: thresholdProvider.getCurrentAColor(elec?.currentA ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.electric_bolt,
            label: 'B相电流',
            value: (elec?.currentB ?? 0.0).toStringAsFixed(1),
            unit: 'A',
            color: thresholdProvider.getCurrentBColor(elec?.currentB ?? 0.0),
          ),
          const SizedBox(height: 2),
          _buildDataRow(
            icon: Icons.electric_bolt,
            label: 'C相电流',
            value: (elec?.currentC ?? 0.0).toStringAsFixed(1),
            unit: 'A',
            color: thresholdProvider.getCurrentCColor(elec?.currentC ?? 0.0),
          ),
        ],
      ),
    );
  }

  /// 构建单行数据（右侧卡片用, 34px 高度）
  Widget _buildDataRow({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            '$label:',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
