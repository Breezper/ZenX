import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/api/openai_compatible_api.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/states/settings_provider.dart';

/// 存储各提供商API模型的状态类
class ApiModelsState {
  final Map<String, List<String>> modelsByProvider;
  final Map<String, bool> isLoadingByProvider;
  
  const ApiModelsState({
    this.modelsByProvider = const {},
    this.isLoadingByProvider = const {},
  });
  
  ApiModelsState copyWith({
    Map<String, List<String>>? modelsByProvider,
    Map<String, bool>? isLoadingByProvider,
  }) {
    return ApiModelsState(
      modelsByProvider: modelsByProvider ?? this.modelsByProvider,
      isLoadingByProvider: isLoadingByProvider ?? this.isLoadingByProvider,
    );
  }
  
  /// 获取指定提供商的模型列表
  List<String> getModelsForProvider(String provider) {
    return modelsByProvider[provider] ?? [];
  }
  
  /// 检查指定提供商是否正在加载模型
  bool isLoadingForProvider(String provider) {
    return isLoadingByProvider[provider] ?? false;
  }
}

/// API模型状态提供者
class ApiModelsNotifier extends StateNotifier<ApiModelsState> {
  final StateNotifierProviderRef<ApiModelsNotifier, ApiModelsState> ref;
  
  ApiModelsNotifier(this.ref) : super(const ApiModelsState()) {
    // 在初始化时加载已配置的API模型
    _initializeModels();
  }
  
  /// 初始化已配置的API提供商模型列表
  Future<void> _initializeModels() async {
    // 获取API配置
    final apiKeys = ref.read(apiKeysProvider);
    
    // 如果有OpenAI兼容API配置，加载其模型
    if (_hasOpenAICompatibleConfig(apiKeys)) {
      await fetchModelsForProvider('openai-compatible');
    }
    
    // 可以在这里添加其他API提供商的模型列表初始化
  }
  
  // 检查是否有OpenAI兼容API的配置，支持不同的键名格式
  bool _hasOpenAICompatibleConfig(Map<String, String> apiKeys) {
    // 检查可能的API密钥键名
    final hasApiKey = apiKeys.containsKey('openai-compatible') || apiKeys.containsKey('openai_compatible');
    
    // 检查可能的URL键名
    final hasBaseUrl = apiKeys.containsKey('openai-compatible_url') || 
                      apiKeys.containsKey('openai_compatible_url') ||
                      apiKeys.containsKey('openai-compatible-url') ||
                      apiKeys.containsKey('openai_compatible-url');
    
    return hasApiKey && hasBaseUrl;
  }
  
  // 获取OpenAI兼容API的配置
  Map<String, String> _getOpenAICompatibleConfig(Map<String, String> apiKeys) {
    Map<String, String> config = {};
    
    // 获取API密钥
    if (apiKeys.containsKey('openai-compatible')) {
      config['apiKey'] = apiKeys['openai-compatible']!;
    } else if (apiKeys.containsKey('openai_compatible')) {
      config['apiKey'] = apiKeys['openai_compatible']!;
    }
    
    // 获取基础URL
    if (apiKeys.containsKey('openai-compatible_url')) {
      config['baseUrl'] = apiKeys['openai-compatible_url']!;
    } else if (apiKeys.containsKey('openai_compatible_url')) {
      config['baseUrl'] = apiKeys['openai_compatible_url']!;
    } else if (apiKeys.containsKey('openai-compatible-url')) {
      config['baseUrl'] = apiKeys['openai-compatible-url']!;
    } else if (apiKeys.containsKey('openai_compatible-url')) {
      config['baseUrl'] = apiKeys['openai_compatible-url']!;
    }
    
    // 获取模型
    if (apiKeys.containsKey('openai-compatible_model')) {
      config['model'] = apiKeys['openai-compatible_model']!;
    } else if (apiKeys.containsKey('openai_compatible_model')) {
      config['model'] = apiKeys['openai_compatible_model']!;
    } else {
      config['model'] = 'custom-model';
    }
    
    return config;
  }
  
  /// 获取指定提供商的模型列表
  Future<List<String>> fetchModelsForProvider(String provider) async {
    // 设置加载状态
    final loadingState = Map<String, bool>.from(state.isLoadingByProvider);
    loadingState[provider] = true;
    state = state.copyWith(isLoadingByProvider: loadingState);
    
    try {
      final apiKeys = ref.read(apiKeysProvider);
      List<String> models = [];
      
      // 根据提供商类型选择不同的API实现
      if (provider == 'openai-compatible') {
        final api = OpenAICompatibleAPI();
        
        // 获取兼容API的配置
        final compatibleConfig = _getOpenAICompatibleConfig(apiKeys);
        
        final config = ApiConfig(
          provider: provider,
          apiKey: compatibleConfig['apiKey'] ?? '',
          baseUrl: compatibleConfig['baseUrl'] ?? '',
          model: compatibleConfig['model'] ?? 'custom-model',
          headers: {},
        );
        
        models = await api.fetchModels(config);
        print("获取到的OpenAI兼容API模型: $models");
      }
      // 可以添加其他提供商的处理
      
      // 更新模型列表
      final modelsList = Map<String, List<String>>.from(state.modelsByProvider);
      modelsList[provider] = models;
      
      // 更新加载状态
      loadingState[provider] = false;
      
      state = state.copyWith(
        modelsByProvider: modelsList,
        isLoadingByProvider: loadingState,
      );
      
      return models;
    } catch (e) {
      // 出错时重置加载状态
      final loadingState = Map<String, bool>.from(state.isLoadingByProvider);
      loadingState[provider] = false;
      state = state.copyWith(isLoadingByProvider: loadingState);
      
      return [];
    }
  }
  
  /// 重置指定提供商的模型缓存
  void resetModelsForProvider(String provider) {
    final modelsList = Map<String, List<String>>.from(state.modelsByProvider);
    modelsList.remove(provider);
    
    state = state.copyWith(modelsByProvider: modelsList);
  }
  
  /// 重置所有缓存
  void resetAllModels() {
    state = const ApiModelsState();
  }
}

/// 全局API模型提供者
final apiModelsProvider = StateNotifierProvider<ApiModelsNotifier, ApiModelsState>((ref) {
  return ApiModelsNotifier(ref);
});

/// 便捷访问特定提供商模型的提供者
final providerModelsProvider = Provider.family<List<String>, String>((ref, provider) {
  return ref.watch(apiModelsProvider).getModelsForProvider(provider);
});

/// 判断特定提供商是否在加载模型的提供者
final isLoadingModelsProvider = Provider.family<bool, String>((ref, provider) {
  return ref.watch(apiModelsProvider).isLoadingForProvider(provider);
}); 