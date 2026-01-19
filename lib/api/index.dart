// 网络请求统一入口
// 用于处理全局的网络请求配置、拦截器、基础请求方法等

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart'; // IOClient 需要单独导入
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'api.dart';
import '../utils/app_logger.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final String baseUrl = Api.baseUrl;

  // ===== HTTP Client 配置 =====
  // 1, HTTP Client 单例（定期刷新防止僵尸连接）
  static http.Client _httpClient = _createClient();
  static DateTime _lastRefresh = DateTime.now();
  static const Duration _refreshInterval = Duration(minutes: 10); // 🔧 缩短到10分钟
  static bool _isDisposed = false;

  // 2, 超时配置（覆盖连接+响应全过程）
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _connectionTimeout = Duration(seconds: 5);

  // 3, 连续失败计数（用于日志记录和诊断）
  static int _consecutiveFailures = 0; // 🔧 改为 static，全局共享

  /// 🔧 [CRITICAL] 创建带连接超时的 HTTP Client
  /// 解决 Windows 工控机上 TCP 连接卡死的问题
  static http.Client _createClient() {
    final httpClient = HttpClient()
      ..connectionTimeout = _connectionTimeout // TCP 连接超时
      ..idleTimeout = const Duration(seconds: 30); // 空闲连接超时
    return IOClient(httpClient); // IOClient 已从 io_client.dart 导入
  }

  /// 获取 HTTP Client（自动刷新过期连接）
  static http.Client get _client {
    if (_isDisposed) {
      _httpClient = _createClient();
      _isDisposed = false;
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0; // 🔧 重置失败计数
    } else if (DateTime.now().difference(_lastRefresh) > _refreshInterval) {
      logger.info('HTTP Client 定期刷新（防止僵尸连接）');
      _httpClient.close();
      _httpClient = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    } else if (_consecutiveFailures >= 3) {
      // 🔧 [CRITICAL] 连续失败3次，强制刷新 Client（可能连接已损坏）
      logger.warning('连续失败 $_consecutiveFailures 次，强制刷新 HTTP Client');
      _httpClient.close();
      _httpClient = _createClient();
      _lastRefresh = DateTime.now();
      _consecutiveFailures = 0;
    }
    return _httpClient;
  }

  Future<dynamic> get(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      // 2, 超时控制覆盖整个请求过程（连接+传输+响应）
      final response = await _client.get(uri).timeout(_timeout);
      _consecutiveFailures = 0; // 3, 成功后重置失败计数
      return _processResponse(response, uri.toString());
    } on TimeoutException {
      _handleError('GET', uri.toString(),
          'Request timeout after ${_timeout.inSeconds}s');
      rethrow;
    } on SocketException catch (e) {
      // 🔧 [CRITICAL] 捕获 Socket 异常（连接被拒绝、网络不可达等）
      _handleError('GET', uri.toString(), 'Socket error: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _handleError('GET', uri.toString(), 'Client error: $e');
      rethrow;
    } catch (e) {
      _handleError('GET', uri.toString(), e.toString());
      rethrow;
    }
  }

  Future<dynamic> post(String path,
      {Map<String, String>? params, dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      final response = await _client.post(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      _consecutiveFailures = 0;
      return _processResponse(response, uri.toString());
    } on TimeoutException {
      _handleError('POST', uri.toString(),
          'Request timeout after ${_timeout.inSeconds}s');
      rethrow;
    } on SocketException catch (e) {
      _handleError('POST', uri.toString(), 'Socket error: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _handleError('POST', uri.toString(), 'Client error: $e');
      rethrow;
    } catch (e) {
      _handleError('POST', uri.toString(), e.toString());
      rethrow;
    }
  }

  Future<dynamic> put(String path,
      {Map<String, String>? params, dynamic body}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      final response = await _client.put(
        uri,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_timeout);
      _consecutiveFailures = 0;
      return _processResponse(response, uri.toString());
    } on TimeoutException {
      _handleError('PUT', uri.toString(),
          'Request timeout after ${_timeout.inSeconds}s');
      rethrow;
    } on SocketException catch (e) {
      _handleError('PUT', uri.toString(), 'Socket error: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _handleError('PUT', uri.toString(), 'Client error: $e');
      rethrow;
    } catch (e) {
      _handleError('PUT', uri.toString(), e.toString());
      rethrow;
    }
  }

  Future<dynamic> delete(String path, {Map<String, String>? params}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params);

    try {
      final response = await _client.delete(uri).timeout(_timeout);
      _consecutiveFailures = 0;
      return _processResponse(response, uri.toString());
    } on TimeoutException {
      _handleError('DELETE', uri.toString(),
          'Request timeout after ${_timeout.inSeconds}s');
      rethrow;
    } on SocketException catch (e) {
      _handleError('DELETE', uri.toString(), 'Socket error: $e');
      rethrow;
    } on http.ClientException catch (e) {
      _handleError('DELETE', uri.toString(), 'Client error: $e');
      rethrow;
    } catch (e) {
      _handleError('DELETE', uri.toString(), e.toString());
      rethrow;
    }
  }

  dynamic _processResponse(http.Response response, String url) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 🔧 记录成功的网络请求（仅在连续失败后恢复时记录）
      if (_consecutiveFailures > 0) {
        logger.network('RECOVERED', url, statusCode: response.statusCode);
      }
      // 🔧 安全的 JSON 解析，避免解析失败导致崩溃
      try {
        return jsonDecode(response.body);
      } catch (e) {
        logger.error('JSON 解析失败', e);
        return {'success': false, 'error': 'JSON 解析失败', 'data': null};
      }
    } else {
      _handleError('RESPONSE', url, 'HTTP ${response.statusCode}');
      throw Exception('网络请求错误: ${response.statusCode}');
    }
  }

  void _handleError(String method, String url, String error) {
    _consecutiveFailures++;

    // 🔧 记录网络错误到日志
    logger.network(method, url, error: error);

    // 连续失败5次以上，记录警告
    if (_consecutiveFailures >= 5 && _consecutiveFailures % 5 == 0) {
      logger.warning('网络连续失败 $_consecutiveFailures 次，请检查后端服务');
    }
  }

  /// 关闭 HTTP Client（应用退出时调用）
  static void dispose() {
    if (!_isDisposed) {
      _httpClient.close();
      _isDisposed = true;
      logger.info('HTTP Client 已关闭');
    }
  }
}
