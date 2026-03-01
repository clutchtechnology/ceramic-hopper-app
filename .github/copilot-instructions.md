# Ceramic Hopper App - AI Coding Instructions

> **料仓监控系统 Flutter 前端开发规范**
>
> **Reading Priority:**
> 1. **[CRITICAL]** - 硬性约束，必须严格遵守
> 2. **[IMPORTANT]** - 核心规范
> 3. **[RULE]** - 编码标准（奥卡姆剃刀原则）

---

## 1. 项目概览

| 属性 | 值 |
|-----|---|
| **项目名称** | ceramic-hopper-app (料仓监控系统) |
| **应用类型** | Windows 桌面工业监控应用 |
| **技术栈** | Flutter 3.29+ + Dart 3.4+ + WebSocket |
| **后端** | FastAPI (Python) + InfluxDB 2.x + Snap7 |
| **目标设备** | 10.4 英寸工业触摸屏 (1280×800 固定分辨率) |
| **核心理念** | **WebSocket 实时通信 + 稳定性 (7×24h) + 简洁性 (奥卡姆剃刀)** |

---

## 2. [CRITICAL] 业务领域：料仓综合监测单元

### 2.1 设备定义

- **设备**: 4号料仓综合监测单元 (`hopper_unit_4`)
- **功能**: 监测料仓的粉尘、温度、电气参数、振动状态
- **关键指标**: PM10 浓度、温度、功率、电流、振动幅值/频率

### 2.2 传感器配置

| 模块 | 类型 | 关键字段 |
|-----|-----|---------|
| **PM10 传感器** | `pm10` | `pm10_value` (μg/m³) |
| **温度传感器** | `temperature` | `temperature_value` (°C) |
| **三相电表** | `electricity` | `Pt` (功率), `ImpEp` (电量), `Ua_0`, `I_0/I_1/I_2` (电压电流) |
| **振动传感器** | `vibration_selected` | `vx/vy/vz` (速度), `vrms_x/y/z` (RMS), `freq_x/y/z` (频率), `cf_x/y/z` (波峰因素), `k_x/y/z` (峭度) |

---

## 3. [CRITICAL] 通信架构：WebSocket 优先

### 3.1 前后端角色定义

**Flutter 前端 = 客户端，后端 = 服务器**

```
┌─────────────────────────────────────────────────────┐
│              后端服务器 (localhost:8080)              │
│  ┌──────────────────┐    ┌──────────────────┐      │
│  │ WebSocket Server │    │   HTTP Server    │      │
│  │  (实时数据推送)   │    │  (历史数据查询)   │      │
│  └────────┬─────────┘    └────────┬─────────┘      │
└───────────┼──────────────────────┼─────────────────┘
            │ WebSocket (0.1s)     │ HTTP (按需)
            ▼                      ▼
┌─────────────────────────────────────────────────────┐
│           Flutter 前端客户端 (1280×800)              │
│  ┌──────────────────┐    ┌──────────────────┐      │
│  │ WebSocketService │    │  HTTP Services   │      │
│  │   (单例模式)      │    │  (多个服务类)     │      │
│  └────────┬─────────┘    └────────┬─────────┘      │
│           │ Callbacks            │ async/await     │
│           ▼                      ▼                  │
│  ┌──────────────────────────────────────────┐      │
│  │         UI Layer (Pages/Widgets)         │      │
│  └──────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────┘
```

### 3.2 WebSocket 客户端（实时数据，主要）

- **端点**: `ws://localhost:8080/ws/realtime`
- **推送间隔**: 0.1s (100ms)
- **连接管理**: 
  - 单例 `WebSocketService`，全局唯一连接
  - 自动重连：指数退避 (1s → 2s → 4s → 8s → 16s → 30s)
  - 心跳保活：客户端每 15s 发送，服务端 45s 超时断开
- **消息类型**:
  - `subscribe` - 订阅实时数据频道
  - `heartbeat` - 发送心跳
  - `realtime_data` - 接收实时数据推送
  - `error` - 接收错误消息

### 3.3 HTTP 客户端（历史数据和配置，降级）

- **Base URL**: `http://localhost:8080/api`
- **用途**:
  - 历史数据查询（时间范围查询）
  - 配置管理（读取/更新阈值配置）
  - 健康检查（服务状态检测）
  - 报警日志查询

### 3.4 通信策略优先级

```
实时数据 → WebSocket (0.1s 推送) ✅ 主要
历史数据 → HTTP API (按需查询) ⚠️ 降级
配置管理 → HTTP API (按需读写) ⚠️ 降级
健康检查 → HTTP API (定时轮询) ⚠️ 降级
```

---

## 4. [CRITICAL] UI 布局规范

### 4.1 固定分辨率设计

- **分辨率**: 1280×800 (固定，不可调整)
- **窗口模式**: 无边框窗口，隐藏原生标题栏
- **布局策略**: 基于固定尺寸设计，**不需要响应式布局**

```dart
// [正确] 使用固定尺寸
Container(
  width: 1280,
  height: 800,
  child: Row(
    children: [
      SizedBox(width: 640, child: LeftPanel()),
      SizedBox(width: 640, child: RightPanel()),
    ],
  ),
)

// [错误] 使用响应式布局
MediaQuery.of(context).size.width  // 不需要！
```

### 4.2 工业风格 UI

- **主题色**: 科技蓝 `#00D4FF` (`TechColors.primary`)
- **背景色**: 深色背景 `#0A0E27`, `#1A1F3A` (`TechColors.bgDeep`, `TechColors.cardBackground`)
- **字体**: 等宽字体，清晰易读
- **动画**: 简洁流畅，避免过度动画

```dart
// [正确] 使用 TechColors 常量
Container(
  decoration: BoxDecoration(
    color: TechColors.cardBackground,
    border: Border.all(color: TechColors.primary),
  ),
)

// [错误] 硬编码颜色
Container(color: Color(0xFF00D4FF))  // 应使用 TechColors.primary
```

---

## 5. [CRITICAL] 稳定性与奥卡姆剃刀原则

> **核心原则**: 不要无必要地增加实体。简单的代码 = 更少的 Bug。

### 5.1 WebSocket 连接管理

```dart
// [正确] 单例模式，全局共享连接
final wsService = WebSocketService();  // 单例

// [正确] 页面切换时不断开连接
@override
void dispose() {
  // 只清理回调，不断开连接（其他页面可能还在使用）
  wsService.onRealtimeDataUpdate = null;
  wsService.onStateChanged = null;
  super.dispose();
}

// [错误] 每个页面都创建新连接
final wsService = WebSocketService()..connect();  // 会创建多个连接！

// [错误] 页面切换时断开连接
@override
void dispose() {
  wsService.disconnect();  // 错误！其他页面还需要实时数据
  super.dispose();
}
```

### 5.2 定时器管理

**问题**: 定时器是导致应用卡死的首要原因。

```dart
// [RULE] 必须在 dispose 中取消定时器
Timer? _timer;

@override
void initState() {
  super.initState();
  _timer = Timer.periodic(Duration(seconds: 30), (timer) async {
    // 健康检查
  });
}

@override
void dispose() {
  _timer?.cancel();  // [CRITICAL] 必须取消！
  super.dispose();
}

// [RULE] 回调中必须检查 mounted
void _handleData(data) {
  if (mounted) {  // [CRITICAL] 必须检查！
    setState(() => _data = data);
  }
}
```

### 5.3 HTTP 请求规范

```dart
// [RULE] 所有请求必须有超时
Future<void> fetchData() async {
  try {
    final response = await http.get(url)
      .timeout(Duration(seconds: 10));  // [CRITICAL] 必须设置超时！
  } catch (e) {
    // [RULE] 必须处理异常，不能让应用崩溃
    _showError('请求失败: $e');
  }
}

// [RULE] 使用单例 HTTP 客户端
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late final Dio _dio;
  
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      connectTimeout: Duration(seconds: 5),
      receiveTimeout: Duration(seconds: 10),
    ));
  }
}

// [错误] 每次都创建新的 HTTP 客户端
Future<void> fetchData() async {
  final dio = Dio();  // 错误！应该使用单例
  await dio.get('http://localhost:8080/api/data');
}
```

### 5.4 状态管理规范

```dart
// [正确] 使用 StatefulWidget + setState（简单场景）
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  HopperRealtimeResponse? _data;
  
  void _updateData(HopperRealtimeResponse data) {
    if (mounted) {  // [CRITICAL] 必须检查 mounted
      setState(() {
        _data = data;
      });
    }
  }
}

// [正确] 使用 ValueNotifier（减少重建）
class _MyWidgetState extends State<MyWidget> {
  final ValueNotifier<double> _pm10 = ValueNotifier(0.0);
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _pm10,
      builder: (context, value, child) {
        return Text('$value μg/m³');
      },
    );
  }
  
  @override
  void dispose() {
    _pm10.dispose();  // [CRITICAL] 必须释放！
    super.dispose();
  }
}

// [错误] 使用复杂的状态管理（Bloc/Redux）
// 对于简单的 UI 切换，不需要复杂的状态管理！
```

---

## 6. [IMPORTANT] 代码设计原则

### 6.1 避免过度抽象

```dart
// [正确] 直接写，简洁明了
void updateDisplay(HopperRealtimeResponse data) {
  if (mounted) {
    setState(() {
      pm10Label.text = '${data.data.hopperUnit4.modules.pm10.fields.pm10Value.toStringAsFixed(1)} μg/m³';
    });
  }
}

// [错误] 过度抽象
String _formatPM10(double value) {
  return '${value.toStringAsFixed(1)} μg/m³';
}

void _updateLabel(Widget label, String text) {
  label.text = text;
}

void updateDisplay(HopperRealtimeResponse data) {
  if (mounted) {
    setState(() {
      final pm10Text = _formatPM10(data.data.hopperUnit4.modules.pm10.fields.pm10Value);
      _updateLabel(pm10Label, pm10Text);
    });
  }
}
```

### 6.2 禁止使用 Emoji 表情符号

```dart
// [正确] 使用纯文本注释
// 1. 初始化 WebSocket 服务
// 注意：这里需要检查连接状态
// 警告：不要在主线程执行耗时操作
// 成功：连接建立完成
// 错误：连接失败

// [错误] 使用 Emoji（禁止！）
// 初始化 WebSocket 服务
// 注意：这里需要检查连接状态
// 错误：连接失败
```

**原因**:
1. 编码兼容性问题
2. 代码审查困难
3. 工业控制系统应保持专业风格
4. Git diff 中可能显示为乱码
5. 跨平台兼容性差

---

## 7. [RULE] 性能优化

### 7.1 图表性能优化

```dart
// [正确] 限制数据点数量
List<FlSpot> _prepareChartData(List<HistoryPoint> data) {
  if (data.length > 100) {
    // 采样：每 N 个点取 1 个
    final step = data.length ~/ 100;
    return data
        .where((point) => data.indexOf(point) % step == 0)
        .map((point) => FlSpot(point.x, point.y))
        .toList();
  }
  return data.map((point) => FlSpot(point.x, point.y)).toList();
}

// [错误] 显示所有数据点
final spots = data.map((p) => FlSpot(p.x, p.y)).toList();  // 可能有 10000+ 个点！
```

### 7.2 HTTP 请求缓存

```dart
// [正确] 缓存配置数据，避免重复请求
class ConfigService {
  static Map<String, dynamic>? _cachedConfig;
  static DateTime? _cacheTime;
  
  static Future<Map<String, dynamic>> getConfig({bool forceRefresh = false}) async {
    // 缓存 5 分钟
    if (!forceRefresh && 
        _cachedConfig != null && 
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < Duration(minutes: 5)) {
      return _cachedConfig!;
    }
    
    final response = await ApiClient().get('/config');
    _cachedConfig = response.data;
    _cacheTime = DateTime.now();
    return _cachedConfig!;
  }
}

// [错误] 频繁发起相同的 HTTP 请求
Timer.periodic(Duration(milliseconds: 100), (timer) async {
  await ConfigService.getConfig();  // 错误！配置不需要这么频繁更新
});
```

---

## 8. [RULE] 反模式（禁止事项）

### 8.1 WebSocket 反模式

- ❌ **禁止**: 每个页面创建新的 WebSocket 连接
- ❌ **禁止**: 页面切换时断开 WebSocket 连接
- ❌ **禁止**: 不检查 `mounted` 就调用 `setState`
- ❌ **禁止**: 不清理 WebSocket 回调就 dispose

### 8.2 HTTP 反模式

- ❌ **禁止**: 不设置超时时间
- ❌ **禁止**: 不处理异常（让应用崩溃）
- ❌ **禁止**: 每次都创建新的 HTTP 客户端
- ❌ **禁止**: 无限重试循环（没有延迟）

### 8.3 UI 反模式

- ❌ **禁止**: 使用响应式布局（固定 1280×800）
- ❌ **禁止**: 硬编码颜色（应使用 TechColors）
- ❌ **禁止**: 频繁调用 `setState` 重建整个页面
- ❌ **禁止**: 不限制图表数据点数量

### 8.4 状态管理反模式

- ❌ **禁止**: 对简单 UI 使用复杂状态管理（Bloc/Redux）
- ❌ **禁止**: 过度抽象（创建大量工具方法）
- ❌ **禁止**: 不释放 ValueNotifier/Timer

---

## 9. 文件结构速查

```
lib/
├── main.dart                          # 入口文件
├── services/
│   ├── websocket_service.dart         # [核心] WebSocket 服务（单例）
│   ├── hopper_service.dart            # 料仓实时数据服务
│   ├── history_data_service.dart      # 历史数据服务（HTTP）
│   ├── config_service.dart            # 配置管理服务（HTTP）
│   └── sensor_status_service.dart     # 设备状态服务（HTTP）
├── models/
│   ├── hopper_model.dart              # 料仓数据模型
│   └── sensor_status_model.dart       # 设备状态模型
├── pages/
│   ├── realtime_dashboard_page.dart   # 实时监控主页面
│   ├── data_history_page.dart         # 历史数据页面
│   ├── sensor_status_page.dart        # 设备状态页面
│   └── settings_page.dart             # 设置页面
├── widgets/
│   ├── data_display/                  # 数据显示组件
│   │   ├── data_tech_line_chart.dart  # 科技风格折线图
│   │   └── data_time_range_selector.dart # 时间范围选择器
│   └── icons/                         # 自定义图标
└── utils/
    └── constants.dart                 # [重要] TechColors 常量定义
```

---

## 10. AI 编码指令总结

生成代码时，请始终验证：

1. **[CRITICAL]** WebSocket 是否使用单例模式？
2. **[CRITICAL]** 是否在 `dispose` 中清理回调和定时器？
3. **[CRITICAL]** 是否在 `setState` 前检查 `mounted`？
4. **[CRITICAL]** HTTP 请求是否设置了超时？
5. **[IMPORTANT]** 是否使用固定尺寸布局（1280×800）？
6. **[IMPORTANT]** 是否使用 TechColors 常量而非硬编码颜色？
7. **[RULE]** 是否避免了过度抽象？
8. **[RULE]** 是否避免了使用 Emoji 表情符号？
9. **[RULE]** 是否处理了所有异常（不让应用崩溃）？
10. **[RULE]** 代码是否简洁、稳定、易维护？

---

**最后提醒**: 这是一个 **7×24h 运行的工业监控系统**，稳定性 > 功能性 > 美观性。简单的代码 = 更少的 Bug = 更高的稳定性。
