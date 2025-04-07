import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

// Settings state class
class Settings {
  // Theme settings
  final ThemeMode themeMode;
  
  // API Keys
  final Map<String, String> apiKeys;
  
  // API Display Names and Visibility
  final Map<String, String> apiDisplayNames;
  final Map<String, bool> apiVisibility;
  
  // Title Generation API settings - dedicated configuration
  final bool titleGenerationApiEnabled;
  final String? titleGenerationApiKey;
  final String? titleGenerationApiUrl;
  final String? titleGenerationApiModel;
  
  // Other preferences
  final bool enableStreamingResponses;
  final String language;
  final bool enableSoundEffects;
  final bool enableHapticFeedback;

  const Settings({
    this.themeMode = ThemeMode.system,
    this.apiKeys = const {},
    this.apiDisplayNames = const {},
    this.apiVisibility = const {},
    this.titleGenerationApiEnabled = false,
    this.titleGenerationApiKey,
    this.titleGenerationApiUrl = "https://api.openai.com/v1",
    this.titleGenerationApiModel = "gpt-3.5-turbo",
    this.enableStreamingResponses = true,
    this.language = 'zh_CN',
    this.enableSoundEffects = true,
    this.enableHapticFeedback = true,
  });

  Settings copyWith({
    ThemeMode? themeMode,
    Map<String, String>? apiKeys,
    Map<String, String>? apiDisplayNames,
    Map<String, bool>? apiVisibility,
    bool? titleGenerationApiEnabled,
    String? titleGenerationApiKey,
    String? titleGenerationApiUrl,
    String? titleGenerationApiModel,
    bool? enableStreamingResponses,
    String? language,
    bool? enableSoundEffects,
    bool? enableHapticFeedback,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      apiKeys: apiKeys ?? this.apiKeys,
      apiDisplayNames: apiDisplayNames ?? this.apiDisplayNames,
      apiVisibility: apiVisibility ?? this.apiVisibility,
      titleGenerationApiEnabled: titleGenerationApiEnabled ?? this.titleGenerationApiEnabled,
      titleGenerationApiKey: titleGenerationApiKey ?? this.titleGenerationApiKey,
      titleGenerationApiUrl: titleGenerationApiUrl ?? this.titleGenerationApiUrl,
      titleGenerationApiModel: titleGenerationApiModel ?? this.titleGenerationApiModel,
      enableStreamingResponses: enableStreamingResponses ?? this.enableStreamingResponses,
      language: language ?? this.language,
      enableSoundEffects: enableSoundEffects ?? this.enableSoundEffects,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.index,
      'enableStreamingResponses': enableStreamingResponses,
      'language': language,
      'enableSoundEffects': enableSoundEffects,
      'enableHapticFeedback': enableHapticFeedback,
      'apiDisplayNames': apiDisplayNames,
      'apiVisibility': apiVisibility,
      'titleGenerationApiEnabled': titleGenerationApiEnabled,
      'titleGenerationApiUrl': titleGenerationApiUrl,
      'titleGenerationApiModel': titleGenerationApiModel,
      // API keys are stored separately in secure storage
    };
  }

  // Create from JSON
  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      themeMode: ThemeMode.values[json['themeMode'] ?? 0],
      enableStreamingResponses: json['enableStreamingResponses'] ?? true,
      language: json['language'] ?? 'zh_CN',
      enableSoundEffects: json['enableSoundEffects'] ?? true,
      enableHapticFeedback: json['enableHapticFeedback'] ?? true,
      titleGenerationApiEnabled: json['titleGenerationApiEnabled'] ?? false,
      titleGenerationApiUrl: json['titleGenerationApiUrl'] ?? "https://api.openai.com/v1",
      titleGenerationApiModel: json['titleGenerationApiModel'] ?? "gpt-3.5-turbo",
      apiDisplayNames: json['apiDisplayNames'] != null 
          ? Map<String, String>.from(json['apiDisplayNames']) 
          : {},
      apiVisibility: json['apiVisibility'] != null 
          ? Map<String, bool>.from(json['apiVisibility']) 
          : {},
    );
  }
}

// Settings notifier class
class SettingsNotifier extends StateNotifier<Settings> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _mounted = true; // Track mounted state
  
  SettingsNotifier() : super(const Settings()) {
    _loadSettings();
  }
  
  @override
  void dispose() {
    _mounted = false; // Mark as unmounted
    super.dispose();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      // Load general settings
      final settingsJson = await _secureStorage.read(key: 'settings');
      if (settingsJson != null && _mounted) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        state = Settings.fromJson(settingsMap);
      }

      // Load API keys separately
      final apiKeysJson = await _secureStorage.read(key: 'api_keys');
      if (apiKeysJson != null && _mounted) {
        final Map<String, dynamic> apiKeysMap = jsonDecode(apiKeysJson);
        final Map<String, String> apiKeys = {};
        
        apiKeysMap.forEach((key, value) {
          apiKeys[key] = value.toString();
        });
        
        state = state.copyWith(apiKeys: apiKeys);
      }
      
      // Load title generation API key separately for security
      final titleApiKey = await _secureStorage.read(key: 'title_generation_api_key');
      if (titleApiKey != null && _mounted) {
        state = state.copyWith(titleGenerationApiKey: titleApiKey);
      }
    } catch (e) {
      // If there's an error, use default settings
      if (_mounted) {
        state = const Settings();
      }
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    if (!_mounted) {
      print("警告: 尝试在销毁后保存设置");
      return; // Skip if unmounted
    }
    
    try {
      // 打印保存前的数据，便于调试
      print("保存设置 - API显示名称: ${state.apiDisplayNames}");
      print("保存设置 - API可见性: ${state.apiVisibility}");
      print("保存设置 - API密钥: ${state.apiKeys.keys.join(', ')}");
      print("保存设置 - 标题生成配置: 开启=${state.titleGenerationApiEnabled}, URL=${state.titleGenerationApiUrl}, 模型=${state.titleGenerationApiModel}");
      
      // Save general settings
      final settingsJson = jsonEncode(state.toJson());
      await _secureStorage.write(
        key: 'settings',
        value: settingsJson,
      );

      // Check again if still mounted after async operation
      if (!_mounted) return;

      // Save API keys separately for security
      final apiKeysJson = jsonEncode(state.apiKeys);
      await _secureStorage.write(
        key: 'api_keys',
        value: apiKeysJson,
      );
      
      // Save title generation API key separately for security
      if (state.titleGenerationApiKey != null) {
        await _secureStorage.write(
          key: 'title_generation_api_key',
          value: state.titleGenerationApiKey!,
        );
      }
      
      print("设置保存成功");
    } catch (e) {
      // Handle errors with more detail
      final errorMsg = 'Error saving settings: $e';
      debugPrint(errorMsg);
      print(errorMsg);
      
      // Don't rethrow if unmounted
      if (_mounted) {
        // Rethrow to allow handling by caller
        rethrow;
      }
    }
  }

  // Update theme mode
  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _saveSettings();
  }

  // Update API key
  Future<void> setApiKey(String provider, String apiKey) async {
    final updatedApiKeys = Map<String, String>.from(state.apiKeys);
    updatedApiKeys[provider] = apiKey;
    state = state.copyWith(apiKeys: updatedApiKeys);
    await _saveSettings();
  }

  // Set API configuration with additional metadata
  Future<void> setApiConfig(String provider, String apiKey, {String? baseUrl, String? model, String? displayName, bool? isVisible}) async {
    if (!_mounted) {
      print("警告: 尝试在销毁后设置API配置");
      return; // Skip if unmounted
    }
    
    try {
      // 标准化提供商名称
      final standardProvider = _standardizeProviderName(provider);
      
      // Debug inputs
      print("设置API配置：");
      print("- 提供商: $provider → 标准化: $standardProvider");
      print("- API密钥: [长度: ${apiKey.length}]");
      print("- 基础URL: $baseUrl");
      print("- 模型: $model");
      print("- 显示名称: $displayName");
      print("- 可见性: $isVisible");
      
      final updatedApiKeys = Map<String, String>.from(state.apiKeys);
      updatedApiKeys[standardProvider] = apiKey;
      
      // Save additional metadata if provided
      if (baseUrl != null) {
        final urlKey = '${standardProvider}_url';
        updatedApiKeys[urlKey] = baseUrl;
        print("- 保存基础URL, 键名: $urlKey, 值: $baseUrl");
      }
      
      if (model != null) {
        updatedApiKeys['${standardProvider}_model'] = model;
      }
      
      // Update display name if provided
      Map<String, String>? updatedDisplayNames;
      if (displayName != null) {
        updatedDisplayNames = Map<String, String>.from(state.apiDisplayNames);
        updatedDisplayNames[standardProvider] = displayName;
      }
      
      // Update visibility if provided
      Map<String, bool>? updatedVisibility;
      if (isVisible != null) {
        updatedVisibility = Map<String, bool>.from(state.apiVisibility);
        updatedVisibility[standardProvider] = isVisible;
      }
      
      if (!_mounted) return; // Check again before updating state
      
      state = state.copyWith(
        apiKeys: updatedApiKeys,
        apiDisplayNames: updatedDisplayNames,
        apiVisibility: updatedVisibility,
      );
      
      // 详细输出apiKeys以便调试
      print("API密钥表内容:");
      state.apiKeys.forEach((key, value) {
        print("- $key: ${key.contains('key') ? '[API密钥]' : value}");
      });
      
      // Log for debugging
      print("已更新API配置: provider=$standardProvider, displayName=$displayName, isVisible=$isVisible");
      print("当前API显示名称: ${state.apiDisplayNames}");
      print("当前API可见性: ${state.apiVisibility}");
      
      await _saveSettings();
    } catch (e) {
      print("保存API配置时出错: $e");
      // Rethrow only if still mounted
      if (_mounted) {
        rethrow;
      }
    }
  }

  // Set API display name
  Future<void> setApiDisplayName(String provider, String displayName) async {
    if (!_mounted) {
      print("警告: 尝试在销毁后设置API显示名称");
      return;
    }
    
    final standardProvider = _standardizeProviderName(provider);
    final updatedDisplayNames = Map<String, String>.from(state.apiDisplayNames);
    updatedDisplayNames[standardProvider] = displayName;
    
    if (!_mounted) return;
    
    state = state.copyWith(apiDisplayNames: updatedDisplayNames);
    await _saveSettings();
  }

  // Set API visibility
  Future<void> setApiVisibility(String provider, bool isVisible) async {
    if (!_mounted) {
      print("警告: 尝试在销毁后设置API可见性");
      return;
    }
    
    final standardProvider = _standardizeProviderName(provider);
    final updatedVisibility = Map<String, bool>.from(state.apiVisibility);
    updatedVisibility[standardProvider] = isVisible;
    
    if (!_mounted) return;
    
    state = state.copyWith(apiVisibility: updatedVisibility);
    await _saveSettings();
  }

  // Get API display name
  String getApiDisplayName(String provider) {
    final standardProvider = _standardizeProviderName(provider);
    return state.apiDisplayNames[standardProvider] ?? provider.toUpperCase();
  }

  // Get API visibility
  bool getApiVisibility(String provider) {
    final standardProvider = _standardizeProviderName(provider);
    return state.apiVisibility[standardProvider] ?? true; // Default is visible
  }
  
  // 标准化提供商名称，确保命名一致性
  String _standardizeProviderName(String provider) {
    if (provider.toLowerCase() == 'openai-compatible') {
      return 'openai_compatible';
    }
    return provider.toLowerCase();
  }

  // Get all visible API providers
  List<String> getVisibleApiProviders() {
    final List<String> result = [];
    
    // Get all API providers with keys
    final apiProviders = state.apiKeys.keys.where(
      (key) => !key.contains('_url') && !key.contains('_model')
    ).toList();
    
    // Filter by visibility
    for (var provider in apiProviders) {
      if (getApiVisibility(provider)) {
        result.add(provider);
      }
    }
    
    return result;
  }

  // Remove API key
  Future<void> removeApiKey(String provider) async {
    final updatedApiKeys = Map<String, String>.from(state.apiKeys);
    updatedApiKeys.remove(provider);
    state = state.copyWith(apiKeys: updatedApiKeys);
    await _saveSettings();
  }

  // Get API key for provider
  String? getApiKey(String provider) {
    return state.apiKeys[provider];
  }

  // Delete an API completely (removes keys, display name, and visibility settings)
  Future<void> deleteApi(String provider) async {
    if (!_mounted) {
      print("警告: 尝试在销毁后删除API");
      return;
    }
    
    try {
      final standardProvider = _standardizeProviderName(provider);
      print("删除API: $standardProvider");
      
      // Remove API key, URL, and model entries
      final updatedApiKeys = Map<String, String>.from(state.apiKeys);
      updatedApiKeys.remove(standardProvider);
      updatedApiKeys.remove('${standardProvider}_url');
      updatedApiKeys.remove('${standardProvider}_model');
      
      // Remove display name
      final updatedDisplayNames = Map<String, String>.from(state.apiDisplayNames);
      updatedDisplayNames.remove(standardProvider);
      
      // Remove visibility setting
      final updatedVisibility = Map<String, bool>.from(state.apiVisibility);
      updatedVisibility.remove(standardProvider);
      
      if (!_mounted) return;
      
      // Update state with all removals
      state = state.copyWith(
        apiKeys: updatedApiKeys,
        apiDisplayNames: updatedDisplayNames,
        apiVisibility: updatedVisibility,
      );
      
      print("API删除成功: $standardProvider");
      await _saveSettings();
    } catch (e) {
      print("删除API时出错: $e");
      if (_mounted) {
        rethrow;
      }
    }
  }

  // Toggle streaming responses
  void toggleStreamingResponses(bool enable) {
    state = state.copyWith(enableStreamingResponses: enable);
    _saveSettings();
  }

  // Set language
  void setLanguage(String languageCode) {
    state = state.copyWith(language: languageCode);
    _saveSettings();
  }

  // Toggle sound effects
  void toggleSoundEffects(bool enable) {
    state = state.copyWith(enableSoundEffects: enable);
    _saveSettings();
  }

  // Toggle haptic feedback
  void toggleHapticFeedback(bool enable) {
    state = state.copyWith(enableHapticFeedback: enable);
    _saveSettings();
  }

  // Toggle title generation API
  Future<void> toggleTitleGenerationApi(bool enable) async {
    state = state.copyWith(titleGenerationApiEnabled: enable);
    await _saveSettings();
  }

  // Set title generation API settings
  Future<void> setTitleGenerationApiSettings({
    bool? enabled,
    String? apiKey,
    String? apiUrl,
    String? apiModel,
  }) async {
    if (!_mounted) {
      print("警告: 尝试在销毁后设置标题生成API配置");
      return;
    }
    
    try {
      state = state.copyWith(
        titleGenerationApiEnabled: enabled ?? state.titleGenerationApiEnabled,
        titleGenerationApiKey: apiKey ?? state.titleGenerationApiKey,
        titleGenerationApiUrl: apiUrl ?? state.titleGenerationApiUrl,
        titleGenerationApiModel: apiModel ?? state.titleGenerationApiModel,
      );
      
      print("标题生成API设置已更新:");
      if (enabled != null) print("- 开启状态: $enabled");
      if (apiKey != null) print("- API密钥: [已更新]");
      if (apiUrl != null) print("- 基础URL: $apiUrl");
      if (apiModel != null) print("- 模型: $apiModel");
      
      await _saveSettings();
    } catch (e) {
      print("保存标题生成API设置时出错: $e");
      if (_mounted) {
        rethrow;
      }
    }
  }
  
  // Set title generation API key
  Future<void> setTitleGenerationApiKey(String apiKey) async {
    await setTitleGenerationApiSettings(apiKey: apiKey);
  }
  
  // Set title generation API URL
  Future<void> setTitleGenerationApiUrl(String apiUrl) async {
    await setTitleGenerationApiSettings(apiUrl: apiUrl);
  }
  
  // Set title generation API model
  Future<void> setTitleGenerationApiModel(String apiModel) async {
    await setTitleGenerationApiSettings(apiModel: apiModel);
  }

  // Reset all settings to default
  Future<void> resetSettings() async {
    state = const Settings();
    await _saveSettings();
  }
}

// Provider definitions
final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});

// Convenience providers for specific settings
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final apiKeysProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(settingsProvider).apiKeys;
});

final apiDisplayNamesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(settingsProvider).apiDisplayNames;
});

final apiVisibilityProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(settingsProvider).apiVisibility;
});

final visibleApiProvidersProvider = Provider<List<String>>((ref) {
  // 监听settings变化，以确保UI更新
  final settings = ref.watch(settingsProvider);
  
  // 获取所有API提供商
  final apiProviders = settings.apiKeys.keys.where(
    (key) => !key.contains('_url') && !key.contains('_model')
  ).toList();
  
  // 过滤可见的提供商
  final List<String> result = [];
  for (var provider in apiProviders) {
    if (settings.apiVisibility[provider] ?? true) {
      result.add(provider);
    }
  }
  
  return result;
});

final streamingResponsesProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableStreamingResponses;
});

// Title generation API providers
final titleGenerationApiEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).titleGenerationApiEnabled;
});

final titleGenerationApiKeyProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).titleGenerationApiKey;
});

final titleGenerationApiUrlProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).titleGenerationApiUrl;
});

final titleGenerationApiModelProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).titleGenerationApiModel;
});

// 用于存储标题生成API可用模型的状态提供者
final titleGenerationAvailableModelsProvider = StateProvider<List<String>>((ref) {
  return ['gpt-3.5-turbo', 'gpt-4']; // 默认值
});

// 根据baseURL缓存模型列表
final modelsCacheProvider = StateProvider<Map<String, List<String>>>((ref) {
  return {}; // 空缓存
}); 