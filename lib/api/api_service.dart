import 'dart:async';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/api/openai_api.dart';
import 'package:zenx/api/openai_compatible_api.dart';
import 'package:zenx/models/api_config.dart';

/// API服务类，管理和提供各种API实现
class ApiService {
  // 单例模式
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // API实现字典
  final Map<String, BaseChatAPI> _apis = {
    'openai': OpenAIAPI(),
    'openai_compatible': OpenAICompatibleAPI(),
    'openai-compatible': OpenAICompatibleAPI(), // 添加连字符版本
  };
  
  /// 获取指定提供商的API实现
  BaseChatAPI? getApi(String provider) {
    // 标准化提供商名称（统一使用小写和处理连字符/下划线变体）
    String normalizedProvider = provider.toLowerCase();
    
    // 处理openai-compatible和openai_compatible的互换性
    if (normalizedProvider == 'openai-compatible' && !_apis.containsKey('openai-compatible')) {
      normalizedProvider = 'openai_compatible';
    } else if (normalizedProvider == 'openai_compatible' && !_apis.containsKey('openai_compatible')) {
      normalizedProvider = 'openai-compatible';
    }
    
    // 打印调试信息
    print("获取API实现: 原始提供商=$provider, 标准化后=$normalizedProvider");
    
    return _apis[normalizedProvider];
  }
  
  /// 获取所有支持的API提供商
  List<String> get supportedProviders => _apis.keys.toList();
  
  /// 获取指定提供商支持的模型
  List<String> getSupportedModels(String provider) {
    final api = getApi(provider);
    return api?.supportedModels ?? [];
  }
  
  /// 验证API密钥
  Future<bool> validateApiKey(String provider, String apiKey) async {
    final api = getApi(provider);
    if (api == null) {
      return false;
    }
    
    return await api.validateApiKey(apiKey);
  }
  
  /// 验证OpenAI兼容API的完整配置（包括baseUrl）
  Future<bool> validateCompatibleApiConfig(ApiConfig config) async {
    final api = getApi('openai_compatible');
    if (api == null) {
      return false;
    }
    
    if (api is OpenAICompatibleAPI) {
      return await api.validateConfig(config);
    }
    
    return false;
  }
  
  /// 获取OpenAI兼容API的可用模型
  Future<List<String>> fetchCompatibleApiModels(ApiConfig config) async {
    final api = getApi('openai_compatible');
    if (api == null) {
      return [];
    }
    
    if (api is OpenAICompatibleAPI) {
      return await api.fetchModels(config);
    }
    
    return [];
  }
  
  /// 发送消息
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    // 在发送消息前打印API配置
    print("发送消息API配置: provider=${config.provider}, apiKey=${config.apiKey.isNotEmpty ? '已设置' : '空'}, baseUrl=${config.baseUrl}");
    
    final api = getApi(config.provider);
    if (api == null) {
      final streamController = StreamController<String>();
      streamController.addError('不支持的API提供商: ${config.provider}');
      streamController.close();
      return StreamedResponse(textStream: streamController.stream);
    }
    
    return await api.sendMessage(
      message: message,
      history: history,
      config: config,
    );
  }
} 