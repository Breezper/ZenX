import 'dart:async';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/api/openai_api.dart';
import 'package:zenx/api/openai_compatible_api.dart';
import 'package:zenx/api/custom_api.dart';
import 'package:zenx/api/deepseek_api.dart';
import 'package:zenx/api/claude_api.dart';
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
    'deepseek': DeepSeekAPI(), // 使用专用DeepSeek API实现
    'claude': ClaudeAPI(), // 使用新的Claude API实现
    'anthropic': ClaudeAPI(), // 添加Anthropic作为别名
  };
  
  /// 注册自定义API提供商
  void registerCustomApi(String provider, BaseChatAPI implementation) {
    // 标准化提供商名称
    String normalizedProvider = provider.toLowerCase();
    
    // 检查是否已存在
    if (_apis.containsKey(normalizedProvider)) {
      print("警告: API提供商 $normalizedProvider 已存在，将被覆盖");
    }
    
    // 注册API实现
    _apis[normalizedProvider] = implementation;
    print("成功注册自定义API提供商: $normalizedProvider");
  }
  
  /// 取消注册自定义API提供商
  void unregisterCustomApi(String provider) {
    // 标准化提供商名称
    String normalizedProvider = provider.toLowerCase();
    
    // 检查是否是内置API
    if (['openai', 'openai_compatible', 'openai-compatible', 'claude', 'gemini', 'deepseek'].contains(normalizedProvider)) {
      print("警告: 无法删除内置API提供商: $normalizedProvider");
      return;
    }
    
    // 检查是否存在，但不提前返回
    if (!_apis.containsKey(normalizedProvider)) {
      print("注意: API提供商 $normalizedProvider 不在内存中，可能已被移除");
      // 继续尝试移除，以防万一有残留
    }
    
    try {
      // 尝试移除API实现，即使它可能已经不存在
      _apis.remove(normalizedProvider);
      print("已从API服务中移除提供商: $normalizedProvider");
    } catch (e) {
      print("移除API提供商时出错: $e");
    }
  }
  
  /// 创建并注册自定义API
  CustomAPI createCustomApi(String provider, String displayName) {
    // 标准化提供商名称
    String normalizedProvider = provider.toLowerCase();
    
    // 创建自定义API实现
    final customApi = CustomAPI(
      name: displayName,
    );
    
    // 注册API
    registerCustomApi(normalizedProvider, customApi);
    
    return customApi;
  }
  
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
    
    // 检查是否存在已注册的API实现
    BaseChatAPI? api = _apis[normalizedProvider];
    
    // 如果没有找到已注册的API实现，则自动创建一个CustomAPI实例
    if (api == null) {
      print("未找到提供商 $normalizedProvider 的API实现，创建自定义API实现");
      api = CustomAPI(name: provider);
      _apis[normalizedProvider] = api;
    }
    
    return api;
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
    print("验证API密钥: 提供商=$provider, 密钥长度=${apiKey.length}");
    
    final api = getApi(provider);
    if (api == null) {
      print("警告: 未找到提供商 $provider 的API实现");
      return false;
    }
    
    try {
      final result = await api.validateApiKey(apiKey);
      print("API密钥验证结果: $result");
      return result;
    } catch (e) {
      print("API密钥验证出错: $e");
      return false;
    }
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
    
    final streamController = StreamController<String>();
    
    try {
      final api = getApi(config.provider);
      // 虽然getApi方法现在总是返回一个API实现，但仍保留null检查以确保代码安全
      if (api == null) {
        final error = '无法创建API实现: ${config.provider}';
        print(error);
        streamController.addError(error);
        streamController.close();
        return StreamedResponse(textStream: streamController.stream);
      }
      
      // 打印更多调试信息
      print("使用API实现: ${api.vendorName}, 使用模型: ${config.model ?? '未指定'}");
      
      try {
        // 使用特定API实现发送消息
        return await api.sendMessage(
          message: message,
          history: history,
          config: config,
        );
      } catch (e) {
        final error = '${api.vendorName} API调用出错: $e';
        print(error);
        streamController.addError(error);
      }
    } catch (e) {
      final error = '发送消息时出现意外错误: $e';
      print(error);
      streamController.addError(error);
    } finally {
      if (!streamController.isClosed) {
        streamController.close();
      }
    }
    
    return StreamedResponse(textStream: streamController.stream);
  }
  
  /// 初始化所有自定义API
  Future<void> initializeCustomApis(Map<String, String> apiDisplayNames) async {
    final knownProviders = ['openai', 'openai_compatible', 'openai-compatible', 'claude', 'gemini', 'deepseek'];
    
    // 首先从显示名称映射初始化自定义API
    apiDisplayNames.forEach((provider, displayName) {
      // 跳过已知的内置API
      if (!knownProviders.contains(provider)) {
        // 创建自定义API实现
        createCustomApi(provider, displayName);
        print("从显示名称初始化自定义API: $provider ($displayName)");
      }
    });
  }
  
  /// 完整API初始化 - 从API键和显示名称初始化所有自定义API
  Future<void> initializeAllCustomApis(Map<String, String> apiKeys, Map<String, String> apiDisplayNames) async {
    final knownProviders = ['openai', 'openai_compatible', 'openai-compatible', 'claude', 'gemini', 'deepseek'];
    
    // 从API键中查找可能的自定义API
    for (final key in apiKeys.keys) {
      // 跳过URL和模型键以及已知的内置API
      if (!key.contains('_url') && 
          !key.contains('_model') && 
          !knownProviders.contains(key) &&
          !_apis.containsKey(key)) {
        
        // 获取显示名称或使用默认名称
        final displayName = apiDisplayNames[key] ?? key[0].toUpperCase() + key.substring(1);
        
        // 创建自定义API
        createCustomApi(key, displayName);
        print("从API键初始化自定义API: $key ($displayName)");
      }
    }
    
    // 然后从显示名称映射初始化自定义API（确保不遗漏）
    apiDisplayNames.forEach((provider, displayName) {
      // 跳过已知的内置API和已经初始化的API
      if (!knownProviders.contains(provider) && 
          !_apis.containsKey(provider.toLowerCase())) {
        
        createCustomApi(provider, displayName);
        print("从显示名称初始化自定义API: $provider ($displayName)");
      }
    });
  }
  
  /// 验证自定义API配置
  Future<bool> validateCustomApiConfig(ApiConfig config) async {
    print("验证自定义API配置: provider=${config.provider}, baseUrl=${config.baseUrl}");
    
    // 获取API实现
    final api = getApi(config.provider);
    if (api == null) {
      print("警告: 未找到提供商 ${config.provider} 的API实现");
      return false;
    }
    
    // 检查是否是CustomAPI类型并支持validateConfig方法
    if (api is CustomAPI) {
      try {
        final result = await api.validateConfig(config);
        print("自定义API配置验证结果: $result");
        return result;
      } catch (e) {
        print("自定义API配置验证出错: $e");
        return false;
      }
    }
    
    // 对于其他API类型，仅验证API密钥
    return await validateApiKey(config.provider, config.apiKey);
  }
} 