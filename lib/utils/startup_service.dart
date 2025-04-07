import 'package:zenx/api/api_service.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 应用启动服务，负责初始化各种组件
class StartupService {
  final ProviderContainer container;
  final ApiService _apiService = ApiService();
  
  StartupService(this.container);
  
  /// 初始化所有需要的服务
  Future<void> initialize() async {
    try {
      print("启动服务初始化开始...");
      await _initializeCustomApis();
      print("启动服务初始化完成");
    } catch (e) {
      print("启动服务初始化失败: $e");
    }
  }
  
  /// 初始化所有自定义API
  Future<void> _initializeCustomApis() async {
    try {
      // 获取设置
      final settings = container.read(settingsProvider);
      
      // 打印API信息，便于调试
      print("启动时API显示名称: ${settings.apiDisplayNames}");
      print("启动时API可见性: ${settings.apiVisibility}");
      print("启动时API密钥: ${settings.apiKeys.keys.join(', ')}");
      
      // 使用新的完整初始化方法
      await _apiService.initializeAllCustomApis(
        settings.apiKeys,
        settings.apiDisplayNames
      );
      
      // 初始化后打印所有支持的API提供商
      print("已支持的API提供商: ${_apiService.supportedProviders.join(', ')}");
    } catch (e) {
      print("初始化自定义API时出错: $e");
    }
  }
} 