import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/config_models.dart';

/// 配置服务
/// 负责系统配置的持久化存储和加载
class ConfigService {
  static const String _configFileName = 'system_config.json';

  /// 保存系统配置
  Future<bool> saveConfig(SystemConfig config) async {
    try {
      final file = await _getConfigFile();
      final jsonString = jsonEncode(config.toJson());
      await file.writeAsString(jsonString);
      return true;
    } catch (e) {
      debugPrint('保存配置失败: $e');
      return false;
    }
  }

  /// 加载系统配置
  Future<SystemConfig?> loadConfig() async {
    try {
      final file = await _getConfigFile();
      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      return SystemConfig.fromJson(jsonData);
    } catch (e) {
      debugPrint('加载配置失败: $e');
      return null;
    }
  }

  /// 删除配置文件
  Future<bool> deleteConfig() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (e) {
      debugPrint('删除配置失败: $e');
      return false;
    }
  }

  /// 获取配置文件
  Future<File> _getConfigFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final configDir = Directory('${directory.path}/ceramic_workshop');

    // 确保目录存在
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }

    return File('${configDir.path}/$_configFileName');
  }
}
