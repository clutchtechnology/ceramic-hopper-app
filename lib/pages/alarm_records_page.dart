import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';

class _GridConfig {
  final String title;
  final Color accentColor;
  final Map<String, String> params;
  final bool isPlaceholder;

  const _GridConfig({
    required this.title,
    required this.accentColor,
    this.params = const {},
    this.isPlaceholder = false,
  });
}

class _AlarmListScrollBehavior extends MaterialScrollBehavior {
  const _AlarmListScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

const List<_GridConfig> _gridConfigs = [
  _GridConfig(
    title: '电压参数',
    accentColor: TechColors.glowCyan,
    params: {
      '全部': '',
      'A相电压': 'voltage_a',
      'B相电压': 'voltage_b',
      'C相电压': 'voltage_c',
    },
  ),
  _GridConfig(
    title: '电流参数',
    accentColor: TechColors.glowCyan,
    params: {
      '全部': '',
      'A相电流': 'current_a',
      'B相电流': 'current_b',
      'C相电流': 'current_c',
    },
  ),
  _GridConfig(
    title: '功率参数',
    accentColor: TechColors.glowCyan,
    params: {
      '全部': '',
      '功率': 'power',
    },
  ),
  _GridConfig(
    title: '速度参数',
    accentColor: TechColors.glowOrange,
    params: {
      '全部': '',
      'X轴速度': 'speed_x',
      'Y轴速度': 'speed_y',
      'Z轴速度': 'speed_z',
    },
  ),
  _GridConfig(
    title: '位移参数',
    accentColor: TechColors.glowOrange,
    params: {
      '全部': '',
      'X轴位移': 'displacement_x',
      'Y轴位移': 'displacement_y',
      'Z轴位移': 'displacement_z',
    },
  ),
  _GridConfig(
    title: '频率参数',
    accentColor: TechColors.glowOrange,
    params: {
      '全部': '',
      'X轴频率': 'freq_x',
      'Y轴频率': 'freq_y',
      'Z轴频率': 'freq_z',
    },
  ),
  _GridConfig(
    title: '环境参数',
    accentColor: TechColors.glowPurple,
    params: {
      '全部': '',
      'PM10': 'pm10',
      '温度': 'temperature',
    },
  ),
  _GridConfig(
    title: '占位',
    accentColor: TechColors.borderDark,
    isPlaceholder: true,
  ),
];

class AlarmRecordsPage extends StatefulWidget {
  const AlarmRecordsPage({super.key});

  @override
  State<AlarmRecordsPage> createState() => AlarmRecordsPageState();
}

class AlarmRecordsPageState extends State<AlarmRecordsPage> {
  final AlarmService _alarmService = AlarmService();

  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 24));
  DateTime _endTime = DateTime.now();

  final List<String> _selectedParamValues =
      List.filled(_gridConfigs.length, '');
  final List<List<AlarmRecord>> _gridRecords =
      List.generate(_gridConfigs.length, (_) => []);
  final List<bool> _gridLoading = List.filled(_gridConfigs.length, false);

  AlarmCount _count = AlarmCount.zero;

  @override
  void initState() {
    super.initState();
    _queryAll();
  }

  void pausePolling() {}

  void resumePolling() {
    _queryAll();
  }

  Future<void> refreshData() async {
    await _queryAll();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _startTime : _endTime;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startTime = DateTime(picked.year, picked.month, picked.day);
      } else {
        _endTime = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
  }

  // 获取当前宫格实际需要查询的参数列表
  // 若选择了"全部"(空字符串), 返回该宫格所有子参数; 否则返回当前选中的参数
  List<String> _getEffectiveParams(int index) {
    final selected = _selectedParamValues[index];
    if (selected.isNotEmpty) return [selected];
    return _gridConfigs[index]
        .params
        .values
        .where((v) => v.isNotEmpty)
        .toList();
  }

  // 查询单个宫格的报警记录 (利用 paramNames 一次请求如该宫格全部参数)
  Future<List<AlarmRecord>> _fetchGridRecords(int index) async {
    final effectiveParams = _getEffectiveParams(index);
    return _alarmService.queryAlarms(
      start: _startTime,
      end: _endTime,
      level: 'alarm',
      paramNames: effectiveParams,
      limit: 100,
    );
  }

  Future<void> _queryAll() async {
    // 1. 批量设置 loading 状态 (单次 setState, 减少 UI 重建)
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < _gridConfigs.length; i++) {
        if (!_gridConfigs[i].isPlaceholder) {
          _gridLoading[i] = true;
        }
      }
    });

    // 2. 并行查询所有网格数据 ("全部"时自动限定本宫格参数范围)
    final results = <int, List<AlarmRecord>>{};
    final futures = <Future<void>>[];
    for (int i = 0; i < _gridConfigs.length; i++) {
      if (_gridConfigs[i].isPlaceholder) continue;
      final idx = i;
      futures.add(() async {
        try {
          results[idx] = await _fetchGridRecords(idx);
        } catch (_) {
          results[idx] = [];
        }
      }());
    }
    await Future.wait(futures);

    // 3. 查询报警统计
    final count = await _alarmService.getAlarmCount(hours: 24);

    // 4. 批量更新所有数据 (单次 setState, 从 14次降至 1次)
    if (!mounted) return;
    setState(() {
      for (final entry in results.entries) {
        _gridRecords[entry.key] = entry.value;
        _gridLoading[entry.key] = false;
      }
      _count = count;
    });
  }

  Future<void> _queryGrid(int index) async {
    final config = _gridConfigs[index];
    if (config.isPlaceholder) return;
    if (_gridLoading[index]) {
      while (mounted && _gridLoading[index]) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }
    setState(() => _gridLoading[index] = true);

    try {
      final records = await _fetchGridRecords(index);

      if (!mounted) return;
      setState(() {
        _gridRecords[index] = records;
      });
    } finally {
      if (mounted) {
        setState(() {
          _gridLoading[index] = false;
        });
      }
    }
  }

  void _resetTimeRange() {
    setState(() {
      _startTime = DateTime.now().subtract(const Duration(hours: 24));
      _endTime = DateTime.now();
    });
  }

  String _fmtTime(String value) {
    if (value.isEmpty) return '--';
    final dt = DateTime.tryParse(value)?.toLocal();
    if (dt == null) return value;
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  String _fmtDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildTopFilterBar(),
          const SizedBox(height: 8),
          _buildCountBar(),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildGridCard(0)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(1)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(2)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(3)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildGridCard(4)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(5)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(6)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildGridCard(7)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterBar() {
    final startDate = _fmtDate(_startTime);
    final endDate = _fmtDate(_endTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.glowCyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _dateBtn('开始: $startDate', true),
          const SizedBox(width: 8),
          const Text('至', style: TextStyle(color: TechColors.textSecondary)),
          const SizedBox(width: 8),
          _dateBtn('结束: $endDate', false),
          const SizedBox(width: 16),
          _actionButton(
            label: '查询全部',
            color: TechColors.glowCyan,
            onTap: _queryAll,
          ),
          const SizedBox(width: 8),
          _actionButton(
            label: '重置时间',
            color: TechColors.textSecondary,
            onTap: _resetTimeRange,
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _dateBtn(String label, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart: isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: TechColors.bgMedium,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: TechColors.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month,
                size: 14, color: TechColors.glowCyan),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: TechColors.textPrimary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(int index) {
    final config = _gridConfigs[index];
    if (config.isPlaceholder) {
      return Container(
        decoration: BoxDecoration(
          color: TechColors.bgDark,
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: TechColors.borderDark.withValues(alpha: 0.4)),
        ),
        child: const Center(
          child: Text(
            '占位',
            style: TextStyle(color: TechColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final records = _gridRecords[index];
    final loading = _gridLoading[index];

    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: config.accentColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: config.accentColor.withValues(alpha: 0.35)),
              ),
            ),
            child: Row(
              children: [
                Text(
                  config.title,
                  style: TextStyle(
                    color: config.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dropdown(
                    value: _selectedParamValues[index],
                    options: config.params,
                    onChanged: (value) =>
                        setState(() => _selectedParamValues[index] = value),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _queryGrid(index),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: config.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: config.accentColor.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      '查询',
                      style: TextStyle(
                        color: config.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : _buildGroupTable(records),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border.all(color: TechColors.borderDark),
        borderRadius: BorderRadius.circular(4),
        color: TechColors.bgMedium.withValues(alpha: 0.35),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: TechColors.bgDark,
        style: const TextStyle(color: TechColors.textPrimary, fontSize: 12),
        items: options.entries
            .map((entry) => DropdownMenuItem<String>(
                  value: entry.value,
                  child: Text(entry.key, overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: (next) {
          if (next != null) onChanged(next);
        },
      ),
    );
  }

  Widget _buildCountBar() {
    return Row(
      children: [
        Text('24小时统计: 总数 ${_count.total}',
            style: const TextStyle(color: TechColors.textPrimary)),
        const SizedBox(width: 16),
        Text('报警 ${_count.alarm}',
            style: const TextStyle(color: TechColors.statusAlarm)),
      ],
    );
  }

  Widget _buildGroupTable(List<AlarmRecord> records) {
    if (records.isEmpty) {
      return const Center(
        child:
            Text('当前无报警记录', style: TextStyle(color: TechColors.textSecondary)),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: TechColors.bgMedium.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                  color: TechColors.borderDark.withValues(alpha: 0.5)),
            ),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 42,
                  child: Text('时间',
                      style: TextStyle(
                          color: TechColors.textSecondary, fontSize: 12))),
              Expanded(
                  flex: 24,
                  child: Text('参数',
                      style: TextStyle(
                          color: TechColors.textSecondary, fontSize: 12))),
              Expanded(
                  flex: 28,
                  child: Text('值',
                      style: TextStyle(
                          color: TechColors.textSecondary, fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: ScrollConfiguration(
            behavior: const _AlarmListScrollBehavior(),
            child: ListView.separated(
              physics: const ClampingScrollPhysics(),
              itemCount: records.length,
              separatorBuilder: (_, __) => Divider(
                  color: TechColors.borderDark.withValues(alpha: 0.4),
                  height: 1),
              itemBuilder: (context, index) {
                final record = records[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 42,
                        child: Text(
                          _fmtTime(record.time),
                          style: const TextStyle(
                              color: TechColors.textSecondary, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 24,
                        child: Text(
                          record.paramName,
                          style: const TextStyle(
                              color: TechColors.textPrimary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Expanded(
                        flex: 28,
                        child: Text(
                          '${record.value?.toStringAsFixed(2) ?? '--'} / ${record.threshold?.toStringAsFixed(2) ?? '--'}',
                          style: const TextStyle(
                              color: TechColors.textPrimary, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
