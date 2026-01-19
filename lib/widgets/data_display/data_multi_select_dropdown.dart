import 'package:flutter/material.dart';
import 'data_tech_line_widgets.dart';

/// 多选下拉框组件
/// 用于选择多个设备/项目，支持复选框和颜色指示器
/// 样式与 SingleSelectDropdown 保持一致
class MultiSelectDropdown extends StatefulWidget {
  final String label;
  final int itemCount;
  final List<bool> selectedItems;
  final List<Color> itemColors;
  final String Function(int index) getItemLabel;
  final Color accentColor;
  final ValueChanged<int> onItemToggle;

  /// 是否使用紧凑模式（更小的字体和间距）
  final bool compact;

  const MultiSelectDropdown({
    super.key,
    required this.label,
    required this.itemCount,
    required this.selectedItems,
    required this.itemColors,
    required this.getItemLabel,
    required this.accentColor,
    required this.onItemToggle,
    this.compact = false,
  });

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
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
              width: size.width + 20,
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
                : widget.accentColor.withOpacity(0.5),
          ),
        ),
        child: _buildHeader(),
      ),
    );
  }

  /// 构建下拉框头部
  Widget _buildHeader() {
    // 获取选中的项目数量
    final selectedCount = widget.selectedItems.where((s) => s).length;

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
            // 显示选中数量
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: widget.accentColor,
                  width: 1,
                ),
              ),
              child: Text(
                '$selectedCount/${widget.itemCount}',
                style: TextStyle(
                  color: widget.accentColor,
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

  /// 构建下拉列表
  Widget _buildDropdownList() {
    return Container(
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.accentColor.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.itemCount, (index) {
            return _buildDropdownItem(index);
          }),
        ),
      ),
    );
  }

  /// 构建下拉列表项
  Widget _buildDropdownItem(int index) {
    final isSelected = widget.selectedItems[index];
    final color = widget.itemColors[index];

    return InkWell(
      onTap: () {
        widget.onItemToggle(index);
        // 更新 overlay 以反映选中状态变化
        setState(() {});
        _overlayEntry?.markNeedsBuild();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: TechColors.borderDark,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // 复选框
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                border: Border.all(
                  color: color,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: TechColors.bgDeep,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            // 颜色指示器
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // 标签文字
            Text(
              widget.getItemLabel(index),
              style: TextStyle(
                color: isSelected ? color : TechColors.textPrimary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
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
}
