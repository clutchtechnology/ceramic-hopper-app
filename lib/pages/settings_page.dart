import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';
import '../widgets/settings/realtime_data_settings_widget.dart';
import '../providers/backend_config_provider.dart';
import '../providers/admin_provider.dart';

/// 系统配置页
/// 支持配置服务器、PLC等参数
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 状态变量

  // 1, 当前选中的配置区块索引 (0:服务, 1:PLC, 2:实时数据, 3:管理员)
  int _selectedSection = 0;

  // 2, 后端配置 Provider (管理服务器/PLC配置)
  final BackendConfigProvider _configProvider = BackendConfigProvider();

  // 5, 密码修改输入控制器 (提升到类级别，避免每次build重建)
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 6, PLC连接测试状态
  bool _isTestingConnection = false;
  // 7, 连接测试结果消息
  String? _connectionTestResult;
  // 8, 连接测试是否成功
  bool? _connectionTestSuccess;

  // 生命周期

  @override
  void initState() {
    super.initState();
    _initializeConfig();
  }

  Future<void> _initializeConfig() async {
    await _configProvider.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // 5, 释放密码输入控制器
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: TechColors.bgDeep,
      child: AnimatedGridBackground(
        gridColor: TechColors.borderDark.withOpacity(0.3),
        gridSize: 40,
        child: SizedBox.expand(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 左侧导航菜单
              _buildNavigationMenu(),
              // 右侧配置内容
              Expanded(
                child: _buildConfigContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 左侧导航菜单
  Widget _buildNavigationMenu() {
    final sections = [
      {'icon': Icons.dns, 'label': '服务配置'},
      {'icon': Icons.settings_input_component, 'label': 'PLC 配置'},
      {'icon': Icons.dashboard_customize, 'label': '实时数据设置'},
      {'icon': Icons.security, 'label': '管理员设置'},
    ];

    return Container(
      width: 220,
      margin: const EdgeInsets.all(12),
      child: TechPanel(
        title: '配置菜单',
        accentColor: TechColors.glowCyan,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 菜单项列表
            ...List.generate(sections.length, (index) {
              final section = sections[index];
              final isSelected = _selectedSection == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedSection = index;
                        _connectionTestResult = null;
                        _connectionTestSuccess = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? TechColors.glowCyan.withOpacity(0.15)
                            : TechColors.bgMedium.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSelected
                              ? TechColors.glowCyan.withOpacity(0.5)
                              : TechColors.borderDark,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            section['icon'] as IconData,
                            size: 20,
                            color: isSelected
                                ? TechColors.glowCyan
                                : TechColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              section['label'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? TechColors.glowCyan
                                    : TechColors.textPrimary,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: TechColors.glowCyan,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            // 分隔线
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 1,
              color: TechColors.borderDark,
            ),
            // 窗口控制按钮
            _buildWindowControlButtons(),
          ],
        ),
      ),
    );
  }

  /// 窗口控制按钮（退出程序）
  Widget _buildWindowControlButtons() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          // 显示确认对话框
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: TechColors.bgDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: TechColors.statusAlarm.withOpacity(0.5),
                ),
              ),
              title: const Text(
                '确认关闭',
                style: TextStyle(color: TechColors.textPrimary),
              ),
              content: const Text(
                '确定要关闭应用程序吗？',
                style: TextStyle(color: TechColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: TechColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TechColors.statusAlarm.withOpacity(0.2),
                    foregroundColor: TechColors.statusAlarm,
                  ),
                  child: const Text('确认关闭'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await windowManager.close();
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TechColors.statusAlarm.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: TechColors.statusAlarm.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.close,
                size: 20,
                color: TechColors.statusAlarm,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '退出程序',
                  style: TextStyle(
                    color: TechColors.statusAlarm,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 右侧配置内容区域
  Widget _buildConfigContent() {
    // 实时数据设置页面使用独立的布局
    if (_selectedSection == 2) {
      return Container(
        margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
        child: TechPanel(
          title: '实时数据阈值与颜色配置',
          accentColor: TechColors.glowOrange,
          height: double.infinity,
          child: const RealtimeDataSettingsWidget(),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: TechPanel(
        title: _getSectionTitle(),
        accentColor: TechColors.glowCyan,
        height: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionContent(),
            ],
          ),
        ),
      ),
    );
  }

  String _getSectionTitle() {
    switch (_selectedSection) {
      case 0:
        return '服务配置 (只读)';
      case 1:
        return 'PLC 配置 (只读)';
      case 2:
        return '实时数据阈值与颜色配置';
      case 3:
        return '管理员设置';
      default:
        return '系统配置';
    }
  }

  Widget _buildSectionContent() {
    switch (_selectedSection) {
      case 0:
        return _buildServerConfig();
      case 1:
        return _buildPLCConfig();
      case 3:
        return _buildAdminSettings();
      default:
        return const SizedBox();
    }
  }

  // ============================================================================
  // 服务配置 (只读)
  // ============================================================================

  Widget _buildServerConfig() {
    if (_configProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TechColors.glowCyan),
        ),
      );
    }

    if (_configProvider.error != null && _configProvider.serverConfig == null) {
      return _buildErrorWidget(_configProvider.error!);
    }

    final serverConfig = _configProvider.serverConfig;
    if (serverConfig == null) {
      return _buildErrorWidget('无法获取服务配置');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: '后端服务信息',
          icon: Icons.dns,
          children: [
            _buildInfoRow(
              '主机地址',
              serverConfig.host,
              Icons.computer,
              envKey: 'SERVER_HOST',
            ),
            _buildInfoRow(
              '端口号',
              serverConfig.port.toString(),
              Icons.settings_ethernet,
              envKey: 'SERVER_PORT',
            ),
            _buildInfoRow(
              '调试模式',
              serverConfig.debug ? '开启' : '关闭',
              Icons.bug_report,
              envKey: 'DEBUG',
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 刷新按钮
        OutlinedButton.icon(
          onPressed: () async {
            await _configProvider.refreshFromBackend();
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('刷新配置'),
          style: OutlinedButton.styleFrom(
            foregroundColor: TechColors.glowCyan,
            side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // PLC 配置 (只读)
  // ============================================================================

  Widget _buildPLCConfig() {
    if (_configProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TechColors.glowCyan),
        ),
      );
    }

    if (_configProvider.error != null && _configProvider.plcConfig == null) {
      return _buildErrorWidget(_configProvider.error!);
    }

    final plcConfig = _configProvider.plcConfig;
    if (plcConfig == null) {
      return _buildErrorWidget('无法获取PLC配置');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: 'PLC 连接信息 (只读)',
          icon: Icons.info_outline,
          children: [
            _buildInfoRow(
              'PLC 地址',
              plcConfig.ipAddress,
              Icons.router,
              envKey: 'PLC_IP',
            ),
            _buildInfoRow(
              'Rack',
              plcConfig.rack.toString(),
              Icons.view_module,
              envKey: 'PLC_RACK',
            ),
            _buildInfoRow(
              'Slot',
              plcConfig.slot.toString(),
              Icons.memory,
              envKey: 'PLC_SLOT',
            ),
            _buildInfoRow(
              '超时时间',
              '${plcConfig.timeoutMs} ms',
              Icons.timer,
              envKey: 'PLC_TIMEOUT',
            ),
            _buildInfoRow(
              '轮询间隔',
              '${_formatSeconds(plcConfig.pollInterval)} 秒',
              Icons.update,
              envKey: 'PLC_POLL_INTERVAL',
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildReadonlyNotice(),
        const SizedBox(height: 16),
        _buildPlcReadonlyActionButtons(),

        // 连接测试结果
        if (_connectionTestResult != null) ...[
          const SizedBox(height: 16),
          _buildConnectionTestResult(),
        ],
      ],
    );
  }

  Widget _buildPlcReadonlyActionButtons() {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await _configProvider.refreshFromBackend();
            if (mounted) setState(() {});
          },
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('刷新配置'),
          style: OutlinedButton.styleFrom(
            foregroundColor: TechColors.glowCyan,
            side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isTestingConnection ? null : _testPlcConnection,
          icon: _isTestingConnection
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(TechColors.glowGreen),
                  ),
                )
              : const Icon(Icons.wifi_tethering, size: 18),
          label: Text(_isTestingConnection ? '测试中...' : '测试连接'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TechColors.glowGreen.withOpacity(0.2),
            foregroundColor: TechColors.glowGreen,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: TechColors.glowGreen.withOpacity(0.5)),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // 通用组件
  // ============================================================================

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TechColors.glowCyan),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: TechColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    String? envKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: TechColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: const TextStyle(
              color: TechColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: TechColors.textPrimary,
              fontSize: 13,
              fontFamily: 'Roboto Mono',
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (envKey != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: TechColors.bgDeep,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: TechColors.borderDark),
              ),
              child: Text(
                envKey,
                style: const TextStyle(
                  color: TechColors.textSecondary,
                  fontSize: 11,
                  fontFamily: 'Roboto Mono',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatSeconds(double seconds) {
    final integer = seconds.toInt();
    if (seconds == integer.toDouble()) {
      return integer.toString();
    }
    return seconds.toString();
  }

  Widget _buildReadonlyNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TechColors.bgMedium.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.borderDark),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, color: TechColors.textSecondary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '当前页面为只读显示，配置值来自后端加载的 .env 变量。',
              style: TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TechColors.statusAlarm.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TechColors.statusAlarm.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: TechColors.statusAlarm, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style:
                  const TextStyle(color: TechColors.statusAlarm, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () async {
              await _configProvider.refreshFromBackend();
              if (mounted) setState(() {});
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: TechColors.statusAlarm,
              side: BorderSide(color: TechColors.statusAlarm.withOpacity(0.5)),
            ),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 管理员设置
  // ============================================================================

  Widget _buildAdminSettings() {
    // 🔧 [CRITICAL] 使用 context.watch 替代 Consumer
    // 避免在页面切换时 '_dependents.isEmpty' 错误
    final AdminProvider adminProvider;
    try {
      adminProvider = context.watch<AdminProvider>();
    } catch (e) {
      // Provider 未就绪时显示加载状态
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TechColors.glowCyan),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          title: '账号信息',
          icon: Icons.account_circle,
          children: [
            _buildInfoRow('用户名', adminProvider.adminConfig?.username ?? '-',
                Icons.person),
          ],
        ),
        const SizedBox(height: 24),
        _buildChangePasswordSection(adminProvider),
      ],
    );
  }

  Widget _buildChangePasswordSection(AdminProvider adminProvider) {
    // 5, 使用类级别的密码控制器 (已在 dispose 中释放)
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '修改密码',
              style: TextStyle(
                color: TechColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildPasswordField(
              label: '旧密码',
              controller: _oldPasswordController,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: '新密码',
              controller: _newPasswordController,
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              label: '确认新密码',
              controller: _confirmPasswordController,
            ),
            const SizedBox(height: 24),
            _buildPasswordActionButtons(adminProvider),
          ],
        );
      },
    );
  }

  /// 密码操作按钮
  Widget _buildPasswordActionButtons(AdminProvider adminProvider) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleChangePassword(adminProvider),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('确认修改'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TechColors.glowCyan.withOpacity(0.2),
            foregroundColor: TechColors.glowCyan,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(color: TechColors.glowCyan.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: _clearPasswordFields,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('重置'),
          style: OutlinedButton.styleFrom(
            foregroundColor: TechColors.textSecondary,
            side: const BorderSide(color: TechColors.borderDark),
          ),
        ),
      ],
    );
  }

  /// 处理密码修改
  Future<void> _handleChangePassword(AdminProvider adminProvider) async {
    // 5, 获取密码输入值
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 验证输入
    if (oldPassword.isEmpty) {
      _showSnackBar('请输入旧密码', isError: true);
      return;
    }
    if (newPassword.isEmpty) {
      _showSnackBar('请输入新密码', isError: true);
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnackBar('两次输入的新密码不一致', isError: true);
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar('新密码长度至少6位', isError: true);
      return;
    }

    // 修改密码
    final success =
        await adminProvider.updatePassword(oldPassword, newPassword);
    if (!mounted) return;

    if (success) {
      _clearPasswordFields();
      _showSnackBar('密码修改成功', isError: false);
    } else {
      _showSnackBar(adminProvider.error ?? '密码修改失败', isError: true);
    }
  }

  /// 清空密码输入框
  void _clearPasswordFields() {
    // 5, 清空密码控制器
    _oldPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  /// 显示 SnackBar 消息
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? TechColors.statusAlarm : TechColors.glowGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lock, size: 16, color: TechColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: TechColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(
            color: TechColors.textPrimary,
            fontSize: 13,
            fontFamily: 'Roboto Mono',
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: TechColors.bgDeep,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: TechColors.glowCyan),
            ),
            hintText: '输入 $label',
            hintStyle: TextStyle(
              color: TechColors.textSecondary.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionTestResult() {
    final isSuccess = _connectionTestSuccess == true;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isSuccess ? TechColors.glowGreen : TechColors.statusAlarm)
            .withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: (isSuccess ? TechColors.glowGreen : TechColors.statusAlarm)
              .withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? TechColors.glowGreen : TechColors.statusAlarm,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _connectionTestResult ?? '',
              style: TextStyle(
                color:
                    isSuccess ? TechColors.glowGreen : TechColors.statusAlarm,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 操作方法

  Future<void> _testPlcConnection() async {
    setState(() {
      _isTestingConnection = true;
      _connectionTestResult = null;
      _connectionTestSuccess = null;
    });

    final result = await _configProvider.testPlcConnection();

    if (!mounted) return;

    setState(() {
      _isTestingConnection = false;
      _connectionTestSuccess = result['connected'] == true;
      _connectionTestResult = result['message'] as String?;
    });
  }
}
