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
  };
  
  /// 获取指定提供商的API实现
  BaseChatAPI? getApi(String provider) {
    return _apis[provider.toLowerCase()];
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