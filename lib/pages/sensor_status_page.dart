import 'package:flutter/material.dart';
import 'dart:async';
import '../models/sensor_status_model.dart';
import '../services/sensor_status_service.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';
import '../utils/app_logger.dart';

/// 设备状态位显示页面 (单页面垂直布局)
/// 同时显示 DB3(回转窑) / DB7(辊道窑) / DB11(SCR/风机) 的模块状态
/// 高度按各DB设备数量比例分配
class SensorStatusPage extends StatefulWidget {
  const SensorStatusPage({super.key});

  @override
  State<SensorStatusPage> createState() => SensorStatusPageState();
}

/// 🔧 公开 State 类以便通过 GlobalKey 访问 (用于页面切换时暂停/恢复轮询)
class SensorStatusPageState extends State<SensorStatusPage> {
  // ============================================================
  // 常量定义
  // ============================================================

  // 6, 每个DB区块内的列数
  static const int _columnCount = 3;
  // 7, 轮询间隔 (秒)
  static const int _pollIntervalSeconds = 5;
  // 🔧 网络异常退避配置
  static const int _maxBackoffSeconds = 60;

  // ============================================================
  // 状态变量
  // ============================================================

  // 1, 状态位查询服务 (单例，内部管理HTTP Client)
  final SensorStatusService _statusService = SensorStatusService();

  // 2, 5秒轮询定时器 (用于定期刷新状态)
  Timer? _timer;
  // 3, API响应数据 (包含db3/db7/db11三个状态列表 + summary统计)
  AllStatusResponse? _response;
  // 4, 防抖标志: 防止重复请求
  bool _isRefreshing = false;
  // 5, 错误信息 (用于UI显示网络/API错误)
  String? _errorMessage;

  // 🔧 网络异常退避计数
  int _consecutiveFailures = 0;

  // 🔧 [CRITICAL] 防止 _isRefreshing 卡死
  DateTime? _refreshStartTime;
  static const int _maxRefreshDurationSeconds = 15;

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void initState() {
    super.initState();
    // 🔧 [CRITICAL] 不在 initState 中启动轮询！
    // 由 top_bar.dart 的 _onNavItemTap() 控制，避免 Offstage 中的隐藏页面也在轮询
    // resumePolling(); // 已移除
  }

  @override
  void dispose() {
    // 2, 取消定时器防止内存泄漏
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  // ============================================================
  // 轮询控制 (供外部通过GlobalKey调用)
  // ============================================================

  /// 暂停定时器（页面不可见时调用）
  void pausePolling() {
    // 2, 取消定时器
    if (_timer == null) return;
    _timer?.cancel();
    _timer = null;
    logger.info('SensorStatusPage: 轮询已暂停');
  }

  /// 恢复定时器（页面可见时调用）
  void resumePolling() {
    // 2, 防止重复创建定时器
    if (_timer != null) return;

    // 重置退避计数
    _consecutiveFailures = 0;

    // 立即获取一次数据
    _fetchData();

    // 2, 创建轮询定时器 (7, 使用常量间隔)
    _startPollingWithInterval(_pollIntervalSeconds);
    logger.info('SensorStatusPage: 轮询已恢复');
  }

  /// 🔧 启动轮询定时器（支持动态间隔）
  void _startPollingWithInterval(int intervalSeconds) {
    _timer?.cancel();
    _timer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) async {
        if (!mounted) return;
        try {
          await _fetchData();
        } catch (e, stack) {
          logger.error('状态位定时器回调异常', e, stack);
        }
      },
    );
  }

  /// 🔧 调整轮询间隔（网络异常时退避）
  void _adjustPollingInterval(bool wasSuccess) {
    if (!mounted || _timer == null) return;

    if (wasSuccess) {
      if (_consecutiveFailures > 0) {
        _consecutiveFailures = 0;
        _startPollingWithInterval(_pollIntervalSeconds);
      }
    } else {
      _consecutiveFailures = (_consecutiveFailures + 1).clamp(0, 4);
      final newInterval = (_pollIntervalSeconds * (1 << _consecutiveFailures))
          .clamp(_pollIntervalSeconds, _maxBackoffSeconds);
      if (_consecutiveFailures == 1) {
        logger.warning('SensorStatusPage: 网络异常，轮询间隔延长至 ${newInterval}s');
      }
      _startPollingWithInterval(newInterval);
    }
  }

  // ============================================================
  // 数据获取
  // ============================================================

  /// 获取状态数据
  Future<void> _fetchData() async {
    // 🔧 [CRITICAL] 检测 _isRefreshing 是否卡死
    if (_isRefreshing) {
      if (_refreshStartTime != null) {
        final duration =
            DateTime.now().difference(_refreshStartTime!).inSeconds;
        if (duration > _maxRefreshDurationSeconds) {
          logger
              .error('SensorStatusPage: _isRefreshing 卡死超过 ${duration}s，强制重置！');
          _isRefreshing = false;
          _refreshStartTime = null;
        } else {
          return;
        }
      } else {
        _isRefreshing = false;
      }
    }
    if (!mounted) return;

    _refreshStartTime = DateTime.now();
    setState(() {
      _isRefreshing = true;
      // 5, 清除旧错误
      _errorMessage = null;
    });

    try {
      // 3, 调用API获取所有DB状态
      final response = await _statusService.getAllStatus();

      if (!mounted) return;
      setState(() {
        if (response.success) {
          // 3, 更新响应数据
          _response = response;
          // 🔧 成功时重置退避
          _adjustPollingInterval(true);
        } else {
          // 5, 记录错误信息
          _errorMessage = response.error ?? '获取状态失败';
          // 🔧 失败时启动退避
          _adjustPollingInterval(false);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // 5, 记录网络错误
        _errorMessage = '网络错误: $e';
      });
      // 🔧 网络异常时启动退避
      _adjustPollingInterval(false);
    } finally {
      // 🔧 [CRITICAL] 无论成功失败，都必须重置状态
      _refreshStartTime = null;
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      } else {
        _isRefreshing = false;
      }
    }
  }

  /// 根据 DB 号获取状态列表
  List<ModuleStatus> _getStatusByDb(int dbNumber) {
    // 3, 从响应数据中提取对应DB的状态列表
    return _response?.data?['db$dbNumber'] ?? [];
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            // 5, 有错误时显示错误界面，否则显示状态列表
            child: _errorMessage != null
                ? _buildErrorWidget()
                : _buildVerticalLayout(),
          ),
        ],
      ),
    );
  }

  /// 垂直布局: 仅显示回转窑 (DB3)
  Widget _buildVerticalLayout() {
    // 3, 获取DB3的状态列表
    final db3List = _getStatusByDb(3);

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: _buildDbSection('DB3 回转窑 (料仓)', db3List, TechColors.glowOrange),
          ),
        ],
      ),
    );
  }

  /// 单个DB区块
  Widget _buildDbSection(
    String title,
    List<ModuleStatus> statusList,
    Color accentColor,
  ) {
    final normalCount = statusList.where((s) => s.isNormal).length;

    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // 区块标题栏
          _buildSectionHeader(
              title, normalCount, statusList.length, accentColor),
          // 状态列表 (6, 水平多列布局)
          Expanded(
            child: statusList.isEmpty
                ? _buildEmptyHint()
                : _buildStatusGrid(statusList),
          ),
        ],
      ),
    );
  }

  /// 区块标题栏
  Widget _buildSectionHeader(
    String title,
    int normalCount,
    int totalCount,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
        border: Border(bottom: BorderSide(color: accentColor.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Spacer(),
          Text(
            '正常: $normalCount/$totalCount',
            style: TextStyle(
              color: accentColor.withOpacity(0.8),
              fontSize: 11,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  /// 空数据提示
  Widget _buildEmptyHint() {
    return Center(
      child: Text(
        '暂无数据',
        style: TextStyle(
          color: TechColors.textSecondary.withOpacity(0.5),
          fontSize: 11,
        ),
      ),
    );
  }

  /// 状态网格 (6, 分列显示)
  Widget _buildStatusGrid(List<ModuleStatus> statusList) {
    final itemsPerColumn = (statusList.length / _columnCount).ceil();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_columnCount, (colIndex) {
          final startIndex = colIndex * itemsPerColumn;
          final endIndex =
              (startIndex + itemsPerColumn).clamp(0, statusList.length);

          return Expanded(
            child: Column(
              children: [
                for (int i = startIndex; i < endIndex; i++)
                  _buildStatusCard(statusList[i], i),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 顶部状态栏
  Widget _buildHeader() {
    // 3, 从响应数据中获取统计摘要
    final summary = _response?.summary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border(
          bottom: BorderSide(color: TechColors.borderDark.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            '设备状态位监控',
            style: TextStyle(
              color: TechColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
          const Spacer(),
          // 3, 统计信息显示
          _buildStatChip('总计', summary?.total ?? 0, TechColors.glowCyan),
          const SizedBox(width: 10),
          _buildStatChip('正常', summary?.normal ?? 0, TechColors.glowGreen),
          const SizedBox(width: 10),
          _buildStatChip('异常', summary?.error ?? 0, TechColors.glowRed),
          const SizedBox(width: 12),
          // 4, 刷新按钮 (显示加载状态)
          IconButton(
            onPressed: _isRefreshing ? null : _fetchData,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TechColors.glowCyan,
                    ),
                  )
                : const Icon(Icons.refresh,
                    color: TechColors.glowCyan, size: 20),
          ),
        ],
      ),
    );
  }

  /// 统计标签
  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ],
      ),
    );
  }

  /// 错误提示
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: TechColors.glowRed, size: 48),
          const SizedBox(height: 16),
          // 5, 显示错误信息
          Text(
            _errorMessage ?? '未知错误',
            style:
                const TextStyle(color: TechColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.glowCyan.withOpacity(0.2),
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  /// 单个状态卡片
  Widget _buildStatusCard(ModuleStatus status, int index) {
    final hasError = !status.isNormal;
    final accentColor = hasError ? TechColors.glowRed : TechColors.glowGreen;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: hasError
              ? TechColors.glowRed.withOpacity(0.3)
              : TechColors.borderDark.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          // 序号
          SizedBox(
            width: 20,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 10,
                fontFamily: 'Roboto Mono',
              ),
            ),
          ),
          // 状态灯
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.5),
                  blurRadius: 3,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // 设备名
          Expanded(
            child: Text(
              status.deviceName,
              style: const TextStyle(
                color: TechColors.textPrimary,
                fontSize: 11,
                fontFamily: 'Roboto Mono',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // E值 (Error位)
          _buildValueBadge('E', status.error ? '1' : '0', status.error),
          const SizedBox(width: 4),
          // S值 (Status Code - 十六进制)
          _buildValueBadge(
            'S',
            status.statusCode.toRadixString(16).toUpperCase().padLeft(4, '0'),
            status.statusCode != 0,
          ),
        ],
      ),
    );
  }

  /// 通用值徽章 (合并原 _buildCompactValue 和 _buildCompactStatus)
  Widget _buildValueBadge(String label, String value, bool isError) {
    final color = isError ? TechColors.glowRed : TechColors.textSecondary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label:',
          style: const TextStyle(color: TechColors.textSecondary, fontSize: 9),
        ),
        const SizedBox(width: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isError
                ? TechColors.glowRed.withOpacity(0.2)
                : TechColors.bgMedium.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto Mono',
            ),
          ),
        ),
      ],
    );
  }
}
