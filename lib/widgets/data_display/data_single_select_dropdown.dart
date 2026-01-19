import 'package:flutter/material.dart';
import 'data_tech_line_widgets.dart';

/// 单选下拉框组件
/// 用于选择单个设备或区域
class SingleSelectDropdown extends StatefulWidget {
  /// 下拉框标签
  final String label;

  /// 设备数量
  final int itemCount;

  /// 当前选中的设备索引
  final int selectedIndex;

  /// 设备颜色列表
  final List<Color> itemColors;

  /// 获取设备标签的函数
  final String Function(int index) getItemLabel;

  /// 标题左侧装饰条颜色
  final Color accentColor;

  /// 设备选择回调
  final void Function(int index) onItemSelect;

  /// 是否使用紧凑模式（更小的字体和间距）
  final bool compact;

  const SingleSelectDropdown({
    super.key,
    required this.label,
    required this.itemCount,
    required this.selectedIndex,
    required this.itemColors,
    required this.getItemLabel,
    required this.accentColor,
    required this.onItemSelect,
    this.compact = false,
  });

  @override
  State<SingleSelectDropdown> createState() => _SingleSelectDropdownState();
}

class _SingleSelectDropdownState extends State<SingleSelectDropdown> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_overlayEntry != null) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.transparent,
                  child: _buildDropdownList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(
          color: TechColors.bgMedium.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: _overlayEntry != null
                ? widget.accentColor
                : TechColors.borderDark,
          ),
        ),
        child: _buildHeader(),
      ),
    );
  }

  /// 构建下拉框头部
  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.compact ? _getCompactLabel() : widget.label,
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 11,
              ),
            ),
            SizedBox(width: widget.compact ? 2 : 4),
            // 显示当前选中项
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: widget.itemColors[widget.selectedIndex].withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: widget.itemColors[widget.selectedIndex],
                  width: 1,
                ),
              ),
              child: Text(
                widget.compact
                    ? _getCompactItemLabel(widget.selectedIndex)
                    : widget.getItemLabel(widget.selectedIndex),
                style: TextStyle(
                  color: widget.itemColors[widget.selectedIndex],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(width: widget.compact ? 2 : 4),
            Icon(
              _overlayEntry != null ? Icons.expand_less : Icons.expand_more,
              color: TechColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 获取紧凑模式的标签（缩短显示）
  String _getCompactLabel() {
    // 将 "选择温区" -> "温区"
    if (widget.label.startsWith('选择')) {
      return widget.label.substring(2);
    }
    return widget.label;
  }

  /// 获取紧凑模式的项目标签（缩短显示）
  String _getCompactItemLabel(int index) {
    final label = widget.getItemLabel(index);
    // 将 "温区1" -> "1", "短料仓1" -> "1"
    final match = RegExp(r'(\d+)').firstMatch(label);
    if (match != null) {
      return match.group(1)!;
    }
    return label;
  }

  /// 构建下拉列表
  Widget _buildDropdownList() {
    return Container(
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: widget.accentColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.itemCount, (index) {
          final isSelected = index == widget.selectedIndex;
          return InkWell(
            onTap: () {
              widget.onItemSelect(index);
              _removeOverlay();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.accentColor.withOpacity(0.1)
                    : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: TechColors.borderDark.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 颜色指示器
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: widget.itemColors[index].withOpacity(0.3),
                      border: Border.all(
                        color: widget.itemColors[index],
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 8,
                            color: widget.itemColors[index],
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  // 设备名称
                  Text(
                    widget.getItemLabel(index),
                    style: TextStyle(
                      color: isSelected
                          ? widget.itemColors[index]
                          : TechColors.textSecondary,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
