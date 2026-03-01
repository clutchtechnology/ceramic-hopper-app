import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/hopper_threshold_provider.dart';
import '../../services/alarm_service.dart';
import '../data_display/data_tech_line_widgets.dart';

/// 料仓阈值设置Widget
/// 用于在设置页面中配置报警阈值
class HopperThresholdSettingsWidget extends StatefulWidget {
  final HopperThresholdProvider provider;

  const HopperThresholdSettingsWidget({
    super.key,
    required this.provider,
  });

  @override
  State<HopperThresholdSettingsWidget> createState() =>
      _HopperThresholdSettingsWidgetState();
}

class _HopperThresholdSettingsWidgetState
    extends State<HopperThresholdSettingsWidget> {
  final AlarmService _alarmService = AlarmService();
  // 当前选中的类别
  int _selectedCategory =
      0; // 0: 三相电流, 1: 三相电压, 2: XYZ速度, 3: XYZ位移, 4: XYZ频率, 5: 温度, 6: PM10

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 类别选择器
        _buildCategorySelector(),
        const SizedBox(height: 16),
        // 配置内容
        Expanded(
          child: SingleChildScrollView(
            child: _buildCategoryContent(),
          ),
        ),
        // 底部操作按钮
        _buildActionButtons(),
      ],
    );
  }

  /// 类别选择器
  Widget _buildCategorySelector() {
    final categories = [
      {
        'icon': Icons.electrical_services,
        'label': '三相电流',
        'color': TechColors.glowCyan
      },
      {'icon': Icons.bolt, 'label': '三相电压', 'color': TechColors.glowCyan},
      {'icon': Icons.speed, 'label': 'XYZ速度', 'color': TechColors.glowCyan},
      {'icon': Icons.open_with, 'label': 'XYZ位移', 'color': TechColors.glowCyan},
      {
        'icon': Icons.graphic_eq,
        'label': 'XYZ频率',
        'color': TechColors.glowCyan
      },
      {'icon': Icons.thermostat, 'label': '温度', 'color': TechColors.glowOrange},
      {'icon': Icons.air, 'label': 'PM10', 'color': TechColors.glowPurple},
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Row(
        children: List.generate(categories.length, (index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == index;
          final color = cat['color'] as Color;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = index),
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.5))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: isSelected ? color : TechColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        color: isSelected ? color : TechColors.textSecondary,
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 配置内容
  Widget _buildCategoryContent() {
    switch (_selectedCategory) {
      case 0:
        return _buildCurrentConfig();
      case 1:
        return _buildVoltageConfig();
      case 2:
        return _buildSpeedConfig();
      case 3:
        return _buildDisplacementConfig();
      case 4:
        return _buildFrequencyConfig();
      case 5:
        return _buildTemperatureConfig();
      case 6:
        return _buildPM10Config();
      default:
        return const SizedBox();
    }
  }

  /// 三相电流阈值配置
  Widget _buildCurrentConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: 'A相电流',
          normalMax: widget.provider.currentAConfig.normalMax,
          warningMax: widget.provider.currentAConfig.warningMax,
          unit: 'A',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.currentAConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.currentAConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'B相电流',
          normalMax: widget.provider.currentBConfig.normalMax,
          warningMax: widget.provider.currentBConfig.warningMax,
          unit: 'A',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.currentBConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.currentBConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'C相电流',
          normalMax: widget.provider.currentCConfig.normalMax,
          warningMax: widget.provider.currentCConfig.warningMax,
          unit: 'A',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.currentCConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.currentCConfig.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// XYZ位移阈值配置
  Widget _buildDisplacementConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: 'X轴位移',
          normalMax: widget.provider.displacementXConfig.normalMax,
          warningMax: widget.provider.displacementXConfig.warningMax,
          unit: 'um',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.displacementXConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.displacementXConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'Y轴位移',
          normalMax: widget.provider.displacementYConfig.normalMax,
          warningMax: widget.provider.displacementYConfig.warningMax,
          unit: 'um',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.displacementYConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.displacementYConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'Z轴位移',
          normalMax: widget.provider.displacementZConfig.normalMax,
          warningMax: widget.provider.displacementZConfig.warningMax,
          unit: 'um',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.displacementZConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.displacementZConfig.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// 三相电压阈值配置
  Widget _buildVoltageConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: 'A相电压',
          normalMax: widget.provider.voltageAConfig.normalMax,
          warningMax: widget.provider.voltageAConfig.warningMax,
          unit: 'V',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.voltageAConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.voltageAConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'B相电压',
          normalMax: widget.provider.voltageBConfig.normalMax,
          warningMax: widget.provider.voltageBConfig.warningMax,
          unit: 'V',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.voltageBConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.voltageBConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'C相电压',
          normalMax: widget.provider.voltageCConfig.normalMax,
          warningMax: widget.provider.voltageCConfig.warningMax,
          unit: 'V',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.voltageCConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.voltageCConfig.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// XYZ速度阈值配置
  Widget _buildSpeedConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: 'X轴速度',
          normalMax: widget.provider.speedXConfig.normalMax,
          warningMax: widget.provider.speedXConfig.warningMax,
          unit: 'mm/s',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.speedXConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.speedXConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'Y轴速度',
          normalMax: widget.provider.speedYConfig.normalMax,
          warningMax: widget.provider.speedYConfig.warningMax,
          unit: 'mm/s',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.speedYConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.speedYConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'Z轴速度',
          normalMax: widget.provider.speedZConfig.normalMax,
          warningMax: widget.provider.speedZConfig.warningMax,
          unit: 'mm/s',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.speedZConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.speedZConfig.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// XYZ频率阈值配置
  Widget _buildFrequencyConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: 'X轴频率',
          normalMax: widget.provider.freqXConfig.normalMax,
          warningMax: widget.provider.freqXConfig.warningMax,
          unit: 'Hz',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.freqXConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.freqXConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'Y轴频率',
          normalMax: widget.provider.freqYConfig.normalMax,
          warningMax: widget.provider.freqYConfig.warningMax,
          unit: 'Hz',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.freqYConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.freqYConfig.warningMax = value;
            });
          },
        ),
        _buildThresholdRow(
          label: 'Z轴频率',
          normalMax: widget.provider.freqZConfig.normalMax,
          warningMax: widget.provider.freqZConfig.warningMax,
          unit: 'Hz',
          color: TechColors.glowCyan,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.freqZConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.freqZConfig.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// 温度阈值配置
  Widget _buildTemperatureConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: '料仓温度',
          normalMax: widget.provider.temperatureConfig.normalMax,
          warningMax: widget.provider.temperatureConfig.warningMax,
          unit: '°C',
          color: TechColors.glowOrange,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.temperatureConfig.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.temperatureConfig.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// PM10阈值配置
  Widget _buildPM10Config() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThresholdRow(
          label: 'PM10',
          normalMax: widget.provider.pm10Config.normalMax,
          warningMax: widget.provider.pm10Config.warningMax,
          unit: 'μg/m³',
          color: TechColors.glowPurple,
          onNormalChanged: (value) {
            setState(() {
              widget.provider.pm10Config.normalMax = value;
            });
          },
          onWarningChanged: (value) {
            setState(() {
              widget.provider.pm10Config.warningMax = value;
            });
          },
        ),
      ],
    );
  }

  /// 阈值配置行
  Widget _buildThresholdRow({
    required String label,
    required double normalMax,
    required double warningMax,
    required String unit,
    required Color color,
    required ValueChanged<double> onNormalChanged,
    required ValueChanged<double> onWarningChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Row(
        children: [
          // 标签
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        color: TechColors.textPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          // 正常上限
          const SizedBox(width: 12),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ThresholdColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('正常上限',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),
          _buildNumberInput(
            value: normalMax,
            onChanged: onNormalChanged,
          ),
          // 警告上限
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: ThresholdColors.alarm,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('警告上限',
                  style:
                      TextStyle(color: TechColors.textSecondary, fontSize: 16)),
            ],
          ),
          const SizedBox(width: 8),
          _buildNumberInput(
            value: warningMax,
            onChanged: onWarningChanged,
          ),
          const SizedBox(width: 8),
          Text(unit,
              style: const TextStyle(
                  color: TechColors.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  /// 数字输入框（带增减按钮 - 固定宽度）
  Widget _buildNumberInput({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 减少按钮
        SizedBox(
          width: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValue = value - 1;
                if (newValue >= 0) {
                  onChanged(newValue);
                }
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                decoration: BoxDecoration(
                  color: TechColors.bgMedium,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: TechColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    '-',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // 输入框
        SizedBox(
          width: 64,
          child: _NumberInputField(
            value: value,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        // 增加按钮
        SizedBox(
          width: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final newValue = value + 1;
                onChanged(newValue);
              },
              borderRadius: BorderRadius.circular(2),
              child: Container(
                decoration: BoxDecoration(
                  color: TechColors.bgMedium,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: TechColors.borderDark),
                ),
                child: const Center(
                  child: Text(
                    '+',
                    style: TextStyle(
                      color: TechColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 底部操作按钮
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TechColors.borderDark)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                widget.provider.resetToDefault();
              });
            },
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('恢复默认'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TechColors.statusWarning,
              side: BorderSide(
                  color: TechColors.statusWarning.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final localSuccess = await widget.provider.saveConfig();
              final syncSuccess = localSuccess
                  ? await _alarmService.syncThresholds(widget.provider)
                  : false;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !localSuccess
                          ? '保存失败'
                          : (syncSuccess ? '阈值配置已保存并同步后端' : '本地已保存，后端同步失败'),
                    ),
                    backgroundColor: (localSuccess && syncSuccess)
                        ? TechColors.glowGreen
                        : TechColors.statusAlarm,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.save, size: 16),
            label: const Text('保存配置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.glowCyan.withValues(alpha: 0.2),
              foregroundColor: TechColors.glowCyan,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                    color: TechColors.glowCyan.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 独立的数字输入框 StatefulWidget
/// 解决 TextEditingController 在父组件 setState 时被重建的问题
class _NumberInputField extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _NumberInputField({
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<_NumberInputField> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(_NumberInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 只有在非编辑状态下，且外部值变化时才更新
    if (!_isEditing && oldWidget.value != widget.value) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(
        color: TechColors.textPrimary,
        fontSize: 16,
        fontFamily: 'Roboto Mono',
      ),
      textAlign: TextAlign.center,
      onTap: () {
        _isEditing = true;
      },
      onChanged: (text) {
        final newValue = double.tryParse(text);
        if (newValue != null) {
          widget.onChanged(newValue);
        }
      },
      onEditingComplete: () {
        _isEditing = false;
        FocusScope.of(context).unfocus();
      },
      onSubmitted: (_) {
        _isEditing = false;
      },
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        filled: true,
        fillColor: TechColors.bgDeep,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: TechColors.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: TechColors.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
          borderSide: BorderSide(color: TechColors.glowCyan),
        ),
      ),
    );
  }
}
