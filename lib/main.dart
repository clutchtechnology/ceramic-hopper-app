import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'pages/top_bar.dart';
import 'providers/realtime_config_provider.dart';
import 'providers/admin_provider.dart';
import 'utils/app_logger.dart';
import 'api/index.dart';

void main() async {
  // 捕获所有未处理的异步错误
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 初始化日志系统
    await logger.initialize();
    await logger.info('应用程序启动中...');

    // 捕获 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      // 异步记录但不等待（fire-and-forget）
      logger.fatal('Flutter框架错误', details.exception, details.stack);
      // 在 Release 模式下也显示错误（避免静默崩溃）
      FlutterError.presentError(details);
    };

    // 捕获平台错误
    PlatformDispatcher.instance.onError = (error, stack) {
      logger.fatal('平台错误', error, stack);
      return true; // 返回 true 表示已处理
    };

    await _initializeApp();
  }, (error, stack) async {
    // 捕获 Zone 外的异步错误
    await logger.fatal('未捕获的异步错误', error, stack);
  });
}

Future<void> _initializeApp() async {
  // 初始化窗口管理器 - 最大化显示（不覆盖任务栏）
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await logger.info('初始化窗口管理器...');
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 隐藏原生标题栏
      windowButtonVisibility: false, // 隐藏原生窗口按钮
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setResizable(false); // 禁止调整大小
      // 设置固定分辨率 1336x768
      await windowManager.setSize(const Size(1336, 768));
      await windowManager.center(); // 居中显示
      await windowManager.show();
      await windowManager.focus();
      await logger.info('窗口已初始化 (1336x768)');
    });
  }

  // 创建并初始化 Provider
  await logger.info('初始化配置提供者...');
  final realtimeConfigProvider = RealtimeConfigProvider();
  await realtimeConfigProvider.loadConfig();

  final adminProvider = AdminProvider();
  await adminProvider.initialize();

  await logger.info('应用程序初始化完成');

  runApp(MyApp(
    realtimeConfigProvider: realtimeConfigProvider,
    adminProvider: adminProvider,
  ));
}

class MyApp extends StatefulWidget {
  final RealtimeConfigProvider realtimeConfigProvider;
  final AdminProvider adminProvider;

  const MyApp({
    super.key,
    required this.realtimeConfigProvider,
    required this.adminProvider,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // ===== 状态变量 =====
  // 1, 资源清理标志 → _cleanupResources() 中防止重复清理
  bool _isDisposed = false;

  // ===== 生命周期 =====
  @override
  void initState() {
    super.initState();
    // 监听应用生命周期
    WidgetsBinding.instance.addObserver(this);
    logger.lifecycle('应用进入前台');
  }

  @override
  void dispose() {
    _cleanupResources();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ===== 资源清理 =====
  /// 统一资源清理方法（dispose 和 detached 都调用）
  void _cleanupResources() {
    // 1, 检查是否已清理，防止重复执行
    if (_isDisposed) return;
    _isDisposed = true;

    logger.lifecycle('开始清理资源...');

    // 1. 关闭 HTTP Client
    ApiClient.dispose();

    // 2. 清理 Provider 资源（如果有）
    // widget.realtimeConfigProvider.dispose(); // 如果 Provider 有 dispose

    // 3. 关闭日志系统（最后执行）
    logger.lifecycle('资源清理完成');
    logger.close();
  }

  // ===== 应用生命周期监听 =====
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        logger.lifecycle('应用进入前台 (resumed)');
        break;
      case AppLifecycleState.inactive:
        logger.lifecycle('应用失去焦点 (inactive)');
        break;
      case AppLifecycleState.paused:
        logger.lifecycle('应用进入后台 (paused)');
        break;
      case AppLifecycleState.detached:
        // 🔧 [CRITICAL] Windows 关闭时 dispose 可能不执行，这里是最后机会
        logger.lifecycle('应用即将退出 (detached)');
        _cleanupResources();
        break;
      case AppLifecycleState.hidden:
        logger.lifecycle('应用被隐藏 (hidden)');
        break;
    }
  }

  // ===== UI 构建 =====
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.realtimeConfigProvider),
        ChangeNotifierProvider.value(value: widget.adminProvider),
      ],
      child: GestureDetector(
        // 点击空白处时取消焦点，隐藏键盘
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: MaterialApp(
          title: 'Ceramic Workshop Digital Twin',
          theme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          // 中文本地化支持
          locale: const Locale('zh', 'CN'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'), // 中文简体
            Locale('en', 'US'), // 英文
          ],
          home: const DigitalTwinPage(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
