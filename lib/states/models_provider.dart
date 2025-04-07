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
      // 统一使用一个标准化的键名格式
      const standardProvider = 'openai_compatible';
      print("初始化模型 - 标准化提供商命名: $standardProvider");
      await fetchModelsForProvider(standardProvider);
    }
    
    // 可以在这里添加其他API提供商的模型列表初始化
  }
  
  // 检查是否有OpenAI兼容API的配置，支持不同的键名格式
  bool _hasOpenAICompatibleConfig(Map<String, String> apiKeys) {
    // 检查可能的API密钥键名
    final hasApiKey = apiKeys.containsKey('openai_compatible');
    
    // 检查可能的URL键名
    final hasBaseUrl = apiKeys.containsKey('openai_compatible_url');
    
    return hasApiKey && hasBaseUrl;
  }
  
  // 获取OpenAI兼容API的配置
  Map<String, String> _getOpenAICompatibleConfig(Map<String, String> apiKeys) {
    Map<String, String> config = {};
    
    // 获取API密钥
    if (apiKeys.containsKey('openai_compatible')) {
      config['apiKey'] = apiKeys['openai_compatible']!;
    }
    
    // 获取基础URL
    if (apiKeys.containsKey('openai_compatible_url')) {
      config['baseUrl'] = apiKeys['openai_compatible_url']!;
    }
    
    // 获取模型
    if (apiKeys.containsKey('openai_compatible_model')) {
      config['model'] = apiKeys['openai_compatible_model']!;
    } else {
      config['model'] = 'custom-model';
    }
    
    return config;
  }
  
  /// 获取指定提供商的模型列表
  Future<List<String>> fetchModelsForProvider(String provider) async {
    // 标准化提供商名称，避免命名差异
    final standardProvider = _standardizeProviderName(provider);
    
    // 设置加载状态
    final loadingState = Map<String, bool>.from(state.isLoadingByProvider);
    loadingState[standardProvider] = true;
    state = state.copyWith(isLoadingByProvider: loadingState);
    
    try {
      final apiKeys = ref.read(apiKeysProvider);
      List<String> models = [];
      
      // 根据提供商类型选择不同的API实现
      if (standardProvider == 'openai_compatible') {
        final api = OpenAICompatibleAPI();
        
        // 获取兼容API的配置
        final compatibleConfig = _getOpenAICompatibleConfig(apiKeys);
        
        final config = ApiConfig(
          provider: standardProvider,
          apiKey: compatibleConfig['apiKey'] ?? '',
          baseUrl: compatibleConfig['baseUrl'] ?? '',
          model: compatibleConfig['model'] ?? 'custom-model',
          headers: {},
        );
        
        models = await api.fetchModels(config);
        print("获取到的OpenAI兼容API模型: $models");
        
        // 标准化模型存储
        final modelsList = Map<String, List<String>>.from(state.modelsByProvider);
        modelsList['openai_compatible'] = models;
        
        // 更新加载状态
        loadingState['openai_compatible'] = false;
        
        state = state.copyWith(
          modelsByProvider: modelsList,
          isLoadingByProvider: loadingState,
        );
      }
      // 可以添加其他提供商的处理
      else {
        // 默认实现
        // 更新模型列表
        final modelsList = Map<String, List<String>>.from(state.modelsByProvider);
        modelsList[standardProvider] = models;
        
        // 更新加载状态
        loadingState[standardProvider] = false;
        
        state = state.copyWith(
          modelsByProvider: modelsList,
          isLoadingByProvider: loadingState,
        );
      }
      
      return models;
    } catch (e) {
      print("获取模型出错: $e");
      // 出错时重置加载状态
      final loadingState = Map<String, bool>.from(state.isLoadingByProvider);
      loadingState[standardProvider] = false;
      
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
  
  // 标准化提供商名称，处理命名不一致问题
  String _standardizeProviderName(String provider) {
    if (provider == 'openai-compatible') {
      // 统一使用下划线格式
      return 'openai_compatible';
    }
    return provider;
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