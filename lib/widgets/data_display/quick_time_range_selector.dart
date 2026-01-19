import 'package:flutter/material.dart';
import 'data_tech_line_widgets.dart';

class QuickTimeRangeSelector extends StatelessWidget {
  final Function(Duration duration) onDurationSelected;
  final Color accentColor;

  const QuickTimeRangeSelector({
    super.key,
    required this.onDurationSelected,
    this.accentColor = TechColors.glowCyan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: TechColors.bgLight.withOpacity(0.3),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Duration>(
          icon: Icon(Icons.arrow_drop_down, color: accentColor, size: 16),
          dropdownColor: TechColors.bgMedium,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 12,
            fontFamily: 'Roboto Mono',
          ),
          hint: Text(
            '选择时间',
            style: TextStyle(color: accentColor, fontSize: 12),
          ),
          onChanged: (Duration? value) {
            if (value != null) {
              onDurationSelected(value);
            }
          },
          items: const [
            DropdownMenuItem(
              value: Duration(hours: 12),
              child: Text('最近 12 小时'),
            ),
            DropdownMenuItem(
              value: Duration(days: 1),
              child: Text('最近 1 天'),
            ),
            DropdownMenuItem(
              value: Duration(days: 3),
              child: Text('最近 3 天'),
            ),
            DropdownMenuItem(
              value: Duration(days: 7),
              child: Text('最近 7 天'),
            ),
            DropdownMenuItem(
              value: Duration(days: 30),
              child: Text('最近 1 个月'),
            ),
          ],
        ),
      ),
    );
  }
}
