import 'package:flutter/material.dart';
import '../../providers/hopper_threshold_provider.dart';
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
  final HopperThresholdProvider _provider = HopperThresholdProvider();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    await _provider.loadConfig();
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
