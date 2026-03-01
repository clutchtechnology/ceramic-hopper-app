import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/hopper_threshold_provider.dart';
import '../../services/alarm_service.dart';
import 'hopper_threshold_settings_widget.dart';

/// 实时数据设置 Widget (包装器)
/// 内部使用 HopperThresholdProvider 实例加载阈值配置
class RealtimeDataSettingsWidget extends StatefulWidget {
  const RealtimeDataSettingsWidget({super.key});

  @override
  State<RealtimeDataSettingsWidget> createState() =>
      _RealtimeDataSettingsWidgetState();
}

class _RealtimeDataSettingsWidgetState
    extends State<RealtimeDataSettingsWidget> {
  final AlarmService _alarmService = AlarmService();
  late HopperThresholdProvider _provider;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<HopperThresholdProvider>();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    if (!_provider.isLoaded) {
      await _provider.loadConfig();
    }
    await _alarmService.fetchThresholds(_provider);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return HopperThresholdSettingsWidget(provider: _provider);
  }
}
