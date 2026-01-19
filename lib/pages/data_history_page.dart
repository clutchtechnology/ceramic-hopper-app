import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/data_display/data_tech_line_widgets.dart';
import '../widgets/data_display/data_time_range_selector.dart';
import '../services/history_data_service.dart';
import '../utils/app_logger.dart';

class HistoryDataPage extends StatefulWidget {
  const HistoryDataPage({super.key});

  @override
  State<HistoryDataPage> createState() => HistoryDataPageState();
}

class HistoryDataPageState extends State<HistoryDataPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final HistoryDataService _historyService = HistoryDataService();
  bool _isLoading = false;

  // 时间范围
  late DateTime _startTime;
  late DateTime _endTime;

  // 当前选择的设备
  int _selectedHopperIndex = 0; // 对应列表索引
  
  // 设备列表定义 (Index -> ID)
  final List<String> _hopperIds = [
    'short_hopper_1', 'short_hopper_2', 'short_hopper_3', 'short_hopper_4',
    'long_hopper_1', 'long_hopper_2', 'long_hopper_3'
  ];
  
  final List<String> _hopperNames = [
    '短窑料仓 #1', '短窑料仓 #2', '短窑料仓 #3', '短窑料仓 #4',
    '长窑料仓 #1', '长窑料仓 #2', '长窑料仓 #3'
  ];

  // 数据缓存
  List<FlSpot> _temperatureData = [];
  List<FlSpot> _weightData = [];
  List<FlSpot> _speedData = [];
  List<FlSpot> _energyData = [];

  @override
  void initState() {
    super.initState();
    // 默认查询最近24小时
    _endTime = DateTime.now();
    _startTime = _endTime.subtract(const Duration(hours: 24));
    
    // 延迟加载避免 build 冲突
    Future.delayed(Duration.zero, _loadData);
  }
  
  // Exposed method for TopBar compatibility
  void onPageEnter() {
      // Refresh data when entering page if needed
      _loadData();
  }
  
  void pausePolling() {
      // History page doesn't usually poll, but if it did, pause here
  }
  
  void resumePolling() {
      // History page doesn't usually poll
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final deviceId = _hopperIds[_selectedHopperIndex];
      
      // 并行请求各项数据
      await Future.wait([
        _loadTemperature(deviceId),
        _loadWeightAndSpeed(deviceId),
        _loadEnergy(deviceId),
      ]);

    } catch (e) {
      logger.error('加载历史数据失败', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTemperature(String deviceId) async {
    final res = await _historyService.queryHopperTemperatureHistory(
      deviceId, _startTime, _endTime
    );
    if (res.success && res.data != null) {
      _temperatureData = _convertToFlSpots(res.data!, (d) => d.value);
    }
  }

  Future<void> _loadWeightAndSpeed(String deviceId) async {
    final res = await _historyService.queryHopperWeightHistory(
      deviceId, _startTime, _endTime
    );
    if (res.success && res.data != null) {
      _weightData = _convertToFlSpots(res.data!, (d) => d.weight);
      _speedData = _convertToFlSpots(res.data!, (d) => d.feedRate);
    }
  }

  Future<void> _loadEnergy(String deviceId) async {
    final res = await _historyService.queryHopperEnergyHistory(
      deviceId, _startTime, _endTime
    );
    if (res.success && res.data != null) {
      _energyData = _convertToFlSpots(res.data!, (d) => d.pt);
    }
  }

  List<FlSpot> _convertToFlSpots<T extends HistoryDataPoint>(
    List<T> data, 
    double Function(T) valueExtractor
  ) {
    return data.map((item) {
      return FlSpot(
        item.timestamp.millisecondsSinceEpoch.toDouble(),
        valueExtractor(item),
      );
    }).toList();
  }
  
  Future<void> _pickTime(bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00ff88),
              onPrimary: Colors.black,
              surface: Color(0xFF161b22),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF0d1117),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final initialTime = TimeOfDay.fromDateTime(initialDate);
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: initialTime,
      );
      
      if (pickedTime != null && mounted) {
        setState(() {
          final newDateTime = DateTime(
            pickedDate.year, 
            pickedDate.month, 
            pickedDate.day, 
            pickedTime.hour, 
            pickedTime.minute
          );
          
          if (isStart) {
            _startTime = newDateTime;
          } else {
            _endTime = newDateTime;
          }
        });
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0d1117),
      body: Column(
        children: [
          // 顶部控制栏
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF161b22),
            child: Row(
              children: [
                _buildDeviceSelector(),
                const SizedBox(width: 24),
                Expanded(
                  child: Center(
                    child: TimeRangeSelector(
                      startTime: _startTime,
                      endTime: _endTime,
                      onStartTimeTap: () => _pickTime(true),
                      onEndTimeTap: () => _pickTime(false),
                    ),
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          
          // 图表列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildChartContainer('温度趋势 (°C)', _temperatureData, const Color(0xFFff3b30)),
                _buildChartContainer('料仓重量 (kg)', _weightData, const Color(0xFF00d4ff)),
                _buildChartContainer('下料速度 (kg/h)', _speedData, const Color(0xFFff9500)),
                _buildChartContainer('能耗功率 (kW)', _energyData, const Color(0xFF00ff88)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF21262d),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF30363d)),
      ),
      child: DropdownButton<int>(
        value: _selectedHopperIndex,
        dropdownColor: const Color(0xFF21262d),
        underline: const SizedBox(),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        items: List.generate(_hopperNames.length, (index) {
          return DropdownMenuItem(
            value: index,
            child: Text(_hopperNames[index]),
          );
        }),
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedHopperIndex = value);
            _loadData();
          }
        },
      ),
    );
  }

  Widget _buildChartContainer(String title, List<FlSpot> data, Color color) {
    return Container(
      height: 300,
      margin: const EdgeInsets.only(bottom: 16),
      child: TechPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 16),
            Expanded(
              child: SimpleTechLineChart(
                data: data,
                color: color,
                // 根据数据自动调整最大值，给予1.2倍余量
                maxY: data.isEmpty ? 100 : (data.map((e) => e.y).reduce((a, b) => a > b ? a : b) * 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleTechLineChart extends StatelessWidget {
  final List<FlSpot> data;
  final Color color;
  final double maxY;
  
  const SimpleTechLineChart({
    super.key,
    required this.data,
    required this.color,
    this.maxY = 100,
  });
  
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
        return const Center(child: Text('暂无数据', style: TextStyle(color: Colors.grey)));
    }
      
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFF21262d), strokeWidth: 1),
          getDrawingVerticalLine: (value) => const FlLine(color: Color(0xFF21262d), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                        final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                                '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                        );
                    },
                    reservedSize: 30,
                    interval: (data.last.x - data.first.x) / 5, // Show roughly 5 labels
                ),
            ),
            leftTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(color: Colors.grey, fontSize: 10));
                    }
                )
            ),
        ),
        borderData: FlBorderData(show: false),
        minX: data.first.x,
        maxX: data.last.x,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
