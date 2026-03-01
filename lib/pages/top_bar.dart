import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';
import '../widgets/top_bar/dt_health_status.dart';
import 'realtime_dashboard_page.dart';
import 'hopper_history_page.dart';
import 'alarm_records_page.dart';
import 'settings_page.dart';

/// 主页面 - 带Tab导航
/// Tab1: 实时数据
/// Tab2: 历史曲线
/// Tab3: 报警记录
/// Tab4: 系统设置
class DigitalTwinPage extends StatefulWidget {
  const DigitalTwinPage({super.key});

  @override
  State<DigitalTwinPage> createState() => _DigitalTwinPageState();
}

class _DigitalTwinPageState extends State<DigitalTwinPage>
    with SingleTickerProviderStateMixin {
  // 1, Tab 控制器
  late TabController _tabController;

  // 2, HopperHistoryPage 的 GlobalKey，用于调用刷新方法
  final GlobalKey<HopperHistoryPageState> _hopperHistoryPageKey = GlobalKey();

  // 3, 实时数据页面 Key
  final GlobalKey<RealtimeDashboardPageState> _realtimePageKey = GlobalKey();

  // 4, 报警记录页面 Key
  final GlobalKey<AlarmRecordsPageState> _alarmRecordsPageKey = GlobalKey();

  // 4, 跟踪当前 Tab 索引
  int _currentTabIndex = 0;

  // 5, 时钟定时器
  Timer? _clockTimer;
  final ValueNotifier<String> _clockTimeNotifier = ValueNotifier('--:--:--');

  // 6, 窗口最大化状态
  bool _isMaximized = true; // 默认启动时是最大化的

  @override
  void initState() {
    super.initState();
    // 1, 初始化 Tab 控制器（4个Tab：实时数据、历史曲线、报警记录、系统设置）
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);

    // 5, 启动时钟定时器
    _startClockTimer();
  }

  /// Tab 切换回调
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    _currentTabIndex = newIndex;

    // 进入历史曲线页面时刷新
    if (newIndex == 1) {
      _hopperHistoryPageKey.currentState?.refreshData();
    }

    // 进入报警记录页面时刷新
    if (newIndex == 2) {
      _alarmRecordsPageKey.currentState?.refreshData();
    }
  }

  /// 切换 Tab 页面
  void _switchTab(int index) {
    if (!mounted || _currentTabIndex == index) return;
    setState(() {
      _currentTabIndex = index;
      _tabController.animateTo(index);
    });
  }

  /// 5, 启动时钟定时器 (替代 StreamBuilder 避免无法取消的 Stream)
  void _startClockTimer() {
    _updateClockTime();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateClockTime();
    });
  }

  /// 5, 更新时钟显示
  void _updateClockTime() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    if (_clockTimeNotifier.value != timeStr) {
      _clockTimeNotifier.value = timeStr;
    }
  }

  @override
  void dispose() {
    // 1, 移除 Tab 监听器
    _tabController.removeListener(_onTabChanged);

    // 1, 释放 Tab 控制器
    _tabController.dispose();

    // 5, 取消时钟定时器
    _clockTimer?.cancel();
    _clockTimer = null;
    _clockTimeNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TechColors.bgDeep,
      body: AnimatedGridBackground(
        gridColor: TechColors.borderDark.withOpacity(0.3),
        gridSize: 40,
        child: Column(
          children: [
            // 顶部导航栏
            _buildTopBar(),
            // 主内容区
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Tab1: 实时数据
                  RealtimeDashboardPage(key: _realtimePageKey),
                  // Tab2: 历史曲线
                  HopperHistoryPage(key: _hopperHistoryPageKey),
                  // Tab3: 报警记录
                  AlarmRecordsPage(key: _alarmRecordsPageKey),
                  // Tab4: 系统设置
                  const SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部导航栏
  Widget _buildTopBar() {
    return GestureDetector(
      // 添加窗口拖动功能
      onPanStart: (_) => windowManager.startDragging(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: TechColors.bgDark.withOpacity(0.95),
          border: Border(
            bottom: BorderSide(color: TechColors.glowCyan.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: TechColors.glowCyan,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: TechColors.glowCyan.withOpacity(0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 标题
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [TechColors.glowCyan, TechColors.glowCyanLight],
              ).createShader(bounds),
              child: const Text(
                '南料仓',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Tab切换按钮
            _buildTabButtons(),
            const Spacer(),
            // 健康状态指示器
            const HealthStatusWidget(),
            const SizedBox(width: 12),
            // 时钟
            _buildClock(),
            const SizedBox(width: 12),
            // 设置按钮
            _buildSettingsButton(),
            const SizedBox(width: 12),
            // 窗口控制按钮
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS)
              _buildWindowButtons(),
          ],
        ),
      ),
    );
  }

  /// Tab切换按钮
  Widget _buildTabButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTabButton(0, '实时数据'),
        const SizedBox(width: 4),
        _buildTabButton(1, '历史曲线'),
        const SizedBox(width: 4),
        _buildTabButton(2, '报警记录'),
      ],
    );
  }

  Widget _buildTabButton(int index, String label) {
    // 使用 _currentTabIndex 而不是 _tabController.index，避免未初始化错误
    final isSelected = _currentTabIndex == index;
    final color = isSelected ? TechColors.glowCyan : TechColors.textSecondary;

    return GestureDetector(
      onTap: () => _switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? TechColors.glowCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? TechColors.glowCyan.withOpacity(0.5)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// 设置按钮
  Widget _buildSettingsButton() {
    final isSelected = _currentTabIndex == 3;
    return GestureDetector(
      // 直接跳转到设置页面，不需要密码验证
      onTap: () => _switchTab(3),
      // 如果需要密码验证，取消上面的注释，使用下面的代码
      // onTap: () => _showPasswordDialog(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected
              ? TechColors.glowCyan.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.settings,
          color: isSelected ? TechColors.glowCyan : TechColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  /// 时钟显示 (使用Timer而非StreamBuilder，避免无法取消的Stream)
  Widget _buildClock() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: TechColors.bgMedium,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.glowCyan.withOpacity(0.3)),
      ),
      child: ValueListenableBuilder<String>(
        valueListenable: _clockTimeNotifier,
        builder: (context, clockValue, child) {
          return Text(
            clockValue,
            style: const TextStyle(
              color: TechColors.glowCyan,
              fontSize: 13,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w500,
            ),
          );
        },
      ),
    );
  }

  /// 窗口控制按钮
  Widget _buildWindowButtons() {
    return Row(
      children: [
        _buildWindowButton(
          icon: Icons.remove,
          onTap: () => windowManager.minimize(),
          hoverColor: TechColors.glowCyan,
        ),
        const SizedBox(width: 4),
        _buildWindowButton(
          icon: _isMaximized ? Icons.fullscreen_exit : Icons.crop_square,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
              setState(() => _isMaximized = false);
            } else {
              await windowManager.maximize();
              setState(() => _isMaximized = true);
            }
          },
          hoverColor: TechColors.glowCyan,
        ),
        const SizedBox(width: 4),
        _buildWindowButton(
          icon: Icons.close,
          onTap: () => _showCloseDialog(),
          hoverColor: TechColors.statusAlarm,
        ),
      ],
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color hoverColor,
  }) {
    // [修复] 移除外层 MouseRegion, 避免嵌套导致 MouseTracker 重入断言错误
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 28,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: _HoverBuilder(
          hoverColor: hoverColor,
          child: Icon(icon, size: 16, color: TechColors.textSecondary),
        ),
      ),
    );
  }

  /// 关闭确认对话框
  void _showCloseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TechColors.bgDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: TechColors.borderDark),
        ),
        title:
            const Text('确认退出', style: TextStyle(color: TechColors.textPrimary)),
        content: const Text('确定要关闭应用程序吗？',
            style: TextStyle(color: TechColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消',
                style: TextStyle(color: TechColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => windowManager.close(),
            style: ElevatedButton.styleFrom(
              backgroundColor: TechColors.statusAlarm.withOpacity(0.2),
              foregroundColor: TechColors.statusAlarm,
            ),
            child: const Text('确认关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示密码验证对话框（已禁用，如需启用请取消注释）
  // Future<void> _showPasswordDialog() async {
  //   final result = await showDialog<bool>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (dialogContext) => const _AdminPasswordDialog(),
  //   );
  //
  //   // 延迟一小段时间，避免在弹窗退场过程中触发页面重建
  //   if (result == true && mounted) {
  //     await Future.delayed(const Duration(milliseconds: 200));
  //     if (mounted) {
  //       setState(() {
  //         _currentTabIndex = 3;
  //         _tabController.animateTo(3);
  //       });
  //     }
  //   }
  // }
}

// ============================================================
// 管理员密码验证对话框（已禁用，如需启用请取消注释）
// ============================================================
// class _AdminPasswordDialog extends StatefulWidget {
//   const _AdminPasswordDialog();
//
//   @override
//   State<_AdminPasswordDialog> createState() => _AdminPasswordDialogState();
// }
//
// class _AdminPasswordDialogState extends State<_AdminPasswordDialog> {
//   final TextEditingController _passwordController = TextEditingController();
//   bool _showPassword = false;
//
//   @override
//   void dispose() {
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   void _verify() {
//     final adminProvider = context.read<AdminProvider>();
//     final password = _passwordController.text;
//
//     if (adminProvider.authenticate('admin', password)) {
//       Navigator.of(context).pop(true);
//       return;
//     }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: const Text('密码错误'),
//         backgroundColor: TechColors.statusAlarm,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//     _passwordController.clear();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: TechColors.bgMedium,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(4),
//         side: BorderSide(
//           color: TechColors.glowCyan.withOpacity(0.5),
//         ),
//       ),
//       child: Container(
//         width: 400,
//         padding: const EdgeInsets.all(24),
//         decoration: BoxDecoration(
//           color: TechColors.bgMedium,
//           borderRadius: BorderRadius.circular(4),
//           border: Border.all(
//             color: TechColors.glowCyan.withOpacity(0.5),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(
//                   Icons.lock,
//                   color: TechColors.glowCyan,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 const Text(
//                   '管理员验证',
//                   style: TextStyle(
//                     color: TechColors.textPrimary,
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             const Text(
//               '请输入管理员密码:',
//               style: TextStyle(
//                 color: TechColors.textSecondary,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _passwordController,
//               obscureText: !_showPassword,
//               autofocus: true,
//               onSubmitted: (_) => _verify(),
//               style: const TextStyle(
//                 color: TechColors.textPrimary,
//                 fontSize: 14,
//               ),
//               decoration: InputDecoration(
//                 filled: true,
//                 fillColor: TechColors.bgDeep,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4),
//                   borderSide: BorderSide(
//                     color: TechColors.borderDark,
//                   ),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4),
//                   borderSide: BorderSide(
//                     color: TechColors.borderDark,
//                   ),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(4),
//                   borderSide: BorderSide(
//                     color: TechColors.glowCyan,
//                   ),
//                 ),
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _showPassword ? Icons.visibility : Icons.visibility_off,
//                     color: TechColors.textSecondary,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       _showPassword = !_showPassword;
//                     });
//                   },
//                 ),
//                 hintText: '输入密码',
//                 hintStyle: TextStyle(
//                   color: TechColors.textSecondary.withOpacity(0.5),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 OutlinedButton(
//                   onPressed: () {
//                     Navigator.of(context).pop(false);
//                   },
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: TechColors.textSecondary,
//                     side: BorderSide(
//                       color: TechColors.borderDark,
//                     ),
//                   ),
//                   child: const Text('取消'),
//                 ),
//                 const SizedBox(width: 12),
//                 ElevatedButton(
//                   onPressed: _verify,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: TechColors.glowCyan.withOpacity(0.2),
//                     foregroundColor: TechColors.glowCyan,
//                     side: BorderSide(
//                       color: TechColors.glowCyan.withOpacity(0.5),
//                     ),
//                   ),
//                   child: const Text('确认'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

/// 悬停效果构建器
class _HoverBuilder extends StatefulWidget {
  final Widget child;
  final Color hoverColor;

  const _HoverBuilder({
    required this.child,
    required this.hoverColor,
  });

  @override
  State<_HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<_HoverBuilder> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (!_isHovered) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (_isHovered) setState(() => _isHovered = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered
              ? widget.hoverColor.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: _isHovered
              ? Icon(
                  (widget.child as Icon).icon,
                  size: (widget.child as Icon).size,
                  color: widget.hoverColor,
                )
              : widget.child,
        ),
      ),
    );
  }
}
