import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/realtime_config_provider.dart';
import '../data_display/data_tech_line_widgets.dart';

/// 实时数据设置页面 (电炉料仓版)
/// 用于配置各传感器的阈值 (PM10/温度/震动/电表)
class RealtimeDataSettingsWidget extends StatefulWidget {
  const RealtimeDataSettingsWidget({super.key});

  @override
  State<RealtimeDataSettingsWidget> createState() =>
      _RealtimeDataSettingsWidgetState();
}

class _RealtimeDataSettingsWidgetState
    extends State<RealtimeDataSettingsWidget> {
  // ============================================================
  // 状态变量
  // ============================================================

  // 当前展开的配置区块索引
  int _expandedIndex = 0;

  // 输入框控制器集合 (key格式: "{configKey}_{fieldType}")
  final Map<String, TextEditingController> _controllers = {};

  // ============================================================
  // 生命周期
  // ============================================================

  @override
  void initState() {
    super.initState();
    // 延迟初始化，确保 Provider 已经准备好
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initControllers();
    });
  }

  /// 初始化所有输入框控制器
  void _initControllers() {
    if (!mounted) return;

    final RealtimeConfigProvider provider;
    try {
      provider = context.read<RealtimeConfigProvider>();
    } catch (e) {
      return;
    }

    _initThresholdControllers(provider.pm10Configs);
    _initThresholdControllers(provider.tempConfigs);
    _initThresholdControllers(provider.vibRmsConfigs);
    _initThresholdControllers(provider.vibTempConfigs);
    _initThresholdControllers(provider.elecPowerConfigs);
    _initThresholdControllers(provider.elecCurrentConfigs);

    setState(() {});
  }

  /// 初始化阈值配置控制器
  void _initThresholdControllers(List<ThresholdConfig> configs) {
    for (var config in configs) {
      _controllers['${config.key}_normal'] =
          TextEditingController(text: config.normalMax.toString());
      _controllers['${config.key}_warning'] =
          TextEditingController(text: config.warningMax.toString());
    }
  }

  /// 从 Provider 更新所有控制器的值 (重置时调用)
  void _updateControllersFromConfig() {
    final provider = context.read<RealtimeConfigProvider>();

    _updateThresholdControllers(provider.pm10Configs);
    _updateThresholdControllers(provider.tempConfigs);
    _updateThresholdControllers(provider.vibRmsConfigs);
    _updateThresholdControllers(provider.vibTempConfigs);
    _updateThresholdControllers(provider.elecPowerConfigs);
    _updateThresholdControllers(provider.elecCurrentConfigs);
  }

  void _updateThresholdControllers(List<ThresholdConfig> configs) {
    for (var config in configs) {
      _controllers['${config.key}_normal']?.text = config.normalMax.toString();
      _controllers['${config.key}_warning']?.text =
          config.warningMax.toString();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_controllers.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<RealtimeConfigProvider>(
      builder: (context, provider, child) {
        return TechPanel(
          title: '实时数据阈值配置',
          child: Column(
            children: [
              _buildTopBar(provider),
              const SizedBox(height: 16),
              SizedBox(
                height: 420,
                child: ListView(
                  children: [
                    _buildConfigSection(
                      index: 0,
                      title: 'PM10 传感器',
                      icon: Icons.air,
                      items: provider.pm10Configs,
                      unit: 'μg/m³',
                    ),
                    const SizedBox(height: 12),
                    _buildConfigSection(
                      index: 1,
                      title: '料仓温度传感器',
                      icon: Icons.thermostat,
                      items: provider.tempConfigs,
                      unit: '°C',
                    ),
                    const SizedBox(height: 12),
                    _buildConfigSection(
                      index: 2,
                      title: '震动传感器 (RMS & 温度)',
                      icon: Icons.vibration,
                      items: [
                        ...provider.vibRmsConfigs,
                        ...provider.vibTempConfigs
                      ],
                      unit: '混合',
                    ),
                    const SizedBox(height: 12),
                    _buildConfigSection(
                      index: 3,
                      title: '电表 (功率 & 电流)',
                      icon: Icons.electric_meter,
                      items: [
                        ...provider.elecPowerConfigs,
                        ...provider.elecCurrentConfigs
                      ],
                      unit: '混合',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 顶部操作栏
  Widget _buildTopBar(RealtimeConfigProvider provider) {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: TechColors.glowCyan, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '说明: 数值只能输入数字。绿色=正常(≤正常值)，黄色=警告(≤警告值)，红色=报警(>警告值)',
            style: TextStyle(color: TechColors.textSecondary, fontSize: 12),
          ),
        ),
        TextButton.icon(
          onPressed: () {
            _showResetDialog(provider);
          },
          icon: const Icon(Icons.restore, color: TechColors.textSecondary),
          label: const Text('恢复默认',
              style: TextStyle(color: TechColors.textSecondary)),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => _saveConfig(provider),
          icon: const Icon(Icons.save),
          label: const Text('保存配置'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TechColors.glowCyan.withOpacity(0.2),
            foregroundColor: TechColors.glowCyan,
            side: const BorderSide(color: TechColors.glowCyan),
          ),
        ),
      ],
    );
  }

  /// 构建配置区块
  Widget _buildConfigSection({
    required int index,
    required String title,
    required IconData icon,
    required List<ThresholdConfig> items,
    required String unit,
  }) {
    final isExpanded = _expandedIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgDark,
        border: Border.all(
          color: isExpanded
              ? TechColors.glowCyan.withOpacity(0.5)
              : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 标题栏 (点击展开/折叠)
          InkWell(
            onTap: () {
              setState(() {
                if (_expandedIndex == index) {
                  _expandedIndex = -1;
                } else {
                  _expandedIndex = index;
                }
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isExpanded
                        ? TechColors.glowCyan
                        : TechColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isExpanded
                            ? TechColors.textPrimary
                            : TechColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (unit != '混合')
                    Text(
                      '单位: $unit',
                      style: const TextStyle(
                          color: TechColors.textSecondary, fontSize: 12),
                    ),
                  const SizedBox(width: 12),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: TechColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // 内容区域
          if (isExpanded)
            Container(
              height: 400, // 限制高度，允许内部滚动
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2列
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  return _buildParamsCard(items[idx]);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 参数卡片
  Widget _buildParamsCard(ThresholdConfig config) {
    final normalCtrl = _controllers['${config.key}_normal'];
    final warningCtrl = _controllers['${config.key}_warning'];

    if (normalCtrl == null || warningCtrl == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TechColors.textSecondary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(config.displayName,
              style: const TextStyle(
                  color: TechColors.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  label: '正常上限',
                  controller: normalCtrl,
                  color: TechColors.statusNormal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(
                  label: '警告上限',
                  controller: warningCtrl,
                  color: TechColors.statusWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: color, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: TechColors.textSecondary.withOpacity(0.7), fontSize: 12),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: color.withOpacity(0.3))),
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: color)),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      onChanged: (value) {
        // 实时更新 Provider 中的值?
        // 还是只在保存时更新？
        // 为了性能，通常只在保存时批量更新
      },
    );
  }

  // ============================================================
  // 操作方法
  // ============================================================

  /// 保存配置
  Future<void> _saveConfig(RealtimeConfigProvider provider) async {
    // 1. 将控制器中的值写回 Provider 的数据模型
    _updateConfigFromControllers(provider.pm10Configs);
    _updateConfigFromControllers(provider.tempConfigs);
    _updateConfigFromControllers(provider.vibRmsConfigs);
    _updateConfigFromControllers(provider.vibTempConfigs);
    _updateConfigFromControllers(provider.elecPowerConfigs);
    _updateConfigFromControllers(provider.elecCurrentConfigs);

    // 2. 持久化保存
    final success = await provider.saveConfig();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '配置已保存并生效' : '保存失败，请重试'),
        backgroundColor:
            success ? TechColors.statusNormal : TechColors.statusAlarm,
      ),
    );
  }

  void _updateConfigFromControllers(List<ThresholdConfig> configs) {
    // 使用 context.read 获取 provider 来调用更新方法
    final provider = context.read<RealtimeConfigProvider>();

    for (var config in configs) {
      final normalText = _controllers['${config.key}_normal']?.text ?? '0';
      final warningText = _controllers['${config.key}_warning']?.text ?? '0';

      final normal = double.tryParse(normalText) ?? config.normalMax;
      final warning = double.tryParse(warningText) ?? config.warningMax;

      provider.updateConfig(config.key, normalMax: normal, warningMax: warning);
    }
  }

  /// 恢复默认
  void _showResetDialog(RealtimeConfigProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TechColors.bgMedium,
        title:
            const Text('确认重置', style: TextStyle(color: TechColors.textPrimary)),
        content: const Text('确定要将所有实时数据阈值恢复为默认值吗？此操作不可撤销。',
            style: TextStyle(color: TechColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.resetToDefault();
              _updateControllersFromConfig();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已恢复默认配置')),
                );
              }
            },
            child: const Text('重置',
                style: TextStyle(color: TechColors.statusAlarm)),
          ),
        ],
      ),
    );
  }
}
