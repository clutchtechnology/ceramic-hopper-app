import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理员配置数据模型
class AdminConfigData {
  final String username;
  final String password;

  AdminConfigData({
    required this.username,
    required this.password,
  });

  factory AdminConfigData.fromJson(Map<String, dynamic> json) {
    return AdminConfigData(
      username: json['username'] as String? ?? 'admin',
      password: json['password'] as String? ?? 'Imerys666',
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'password': password,
      };

  AdminConfigData copyWith({
    String? username,
    String? password,
  }) {
    return AdminConfigData(
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

/// 管理员配置 Provider
/// 用于持久化存储管理员账号和密码
///
/// 存储键值:
/// - admin_config (JSON 格式)
///
/// 默认值:
/// - 用户名: admin
/// - 密码: admin123
///
/// 超级管理员密码:
/// - admin78 (固定密码，不可修改，永远有效)
class AdminProvider extends ChangeNotifier {
  static const String _storageKey = 'admin_config';

  /// 超级管理员密码（固定，不可修改）
  static const String _superAdminPassword = 'Imerys666';

  AdminConfigData? _adminConfig;
  bool _isLoading = false;
  String? _error;

  // Getters
  AdminConfigData? get adminConfig => _adminConfig;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化 Provider，从本地存储加载配置
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);

      if (jsonStr != null && jsonStr.isNotEmpty) {
        // 从本地存储加载
        try {
          final decodedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
          _adminConfig = AdminConfigData.fromJson(decodedJson);
        } catch (e) {
          // JSON 解析失败，使用默认值
          debugPrint('Failed to parse admin config: $e');
          _adminConfig = AdminConfigData(
            username: 'admin',
            password: 'Imerys666',
          );
          await _saveToPreferences(_adminConfig!);
        }
      } else {
        // 首次使用，创建默认配置
        _adminConfig = AdminConfigData(
          username: 'admin',
          password: 'Imerys666',
        );
        await _saveToPreferences(_adminConfig!);
      }
    } catch (e) {
      _error = 'Failed to initialize admin config: $e';
      debugPrint(_error);
      // 发生错误时使用默认值
      _adminConfig = AdminConfigData(
        username: 'admin',
        password: 'admin123',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 验证管理员账号和密码
  /// 返回 true 表示验证成功，false 表示失败
  ///
  /// 验证逻辑：
  /// 1. 超级管理员密码 (admin78) - 永远有效，不可修改
  /// 2. 普通管理员密码 - 可在设置中修改
  bool authenticate(String username, String password) {
    // 超级管理员密码验证（用户名必须是 admin）
    if (username == 'admin' && password == _superAdminPassword) {
      return true;
    }

    // 普通管理员密码验证
    if (_adminConfig == null) {
      return false;
    }
    return _adminConfig!.username == username &&
        _adminConfig!.password == password;
  }

  /// 修改密码
  /// 返回 true 表示修改成功，false 表示失败
  Future<bool> updatePassword(String oldPassword, String newPassword) async {
    if (_adminConfig == null) {
      _error = 'Admin config not initialized';
      notifyListeners();
      return false;
    }

    // 验证旧密码
    if (_adminConfig!.password != oldPassword) {
      _error = '旧密码不正确';
      notifyListeners();
      return false;
    }

    try {
      final updatedConfig = _adminConfig!.copyWith(password: newPassword);
      await _saveToPreferences(updatedConfig);
      _adminConfig = updatedConfig;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update password: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// 修改用户名
  Future<bool> updateUsername(String newUsername) async {
    if (_adminConfig == null) {
      _error = 'Admin config not initialized';
      notifyListeners();
      return false;
    }

    try {
      final updatedConfig = _adminConfig!.copyWith(username: newUsername);
      await _saveToPreferences(updatedConfig);
      _adminConfig = updatedConfig;
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update username: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// 保存配置到本地存储
  Future<void> _saveToPreferences(AdminConfigData config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(config.toJson());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      _error = 'Failed to save admin config: $e';
      debugPrint(_error);
      rethrow;
    }
  }
}
