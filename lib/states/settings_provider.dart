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
  
  SettingsNotifier() : super(const Settings()) {
    _loadSettings();
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      // Load general settings
      final settingsJson = await _secureStorage.read(key: 'settings');
      if (settingsJson != null) {
        final Map<String, dynamic> settingsMap = jsonDecode(settingsJson);
        state = Settings.fromJson(settingsMap);
      }

      // Load API keys separately
      final apiKeysJson = await _secureStorage.read(key: 'api_keys');
      if (apiKeysJson != null) {
        final Map<String, dynamic> apiKeysMap = jsonDecode(apiKeysJson);
        final Map<String, String> apiKeys = {};
        
        apiKeysMap.forEach((key, value) {
          apiKeys[key] = value.toString();
        });
        
        state = state.copyWith(apiKeys: apiKeys);
      }
    } catch (e) {
      // If there's an error, use default settings
      state = const Settings();
    }
  }

  // Save settings to storage
  Future<void> _saveSettings() async {
    try {
      // Save general settings
      await _secureStorage.write(
        key: 'settings',
        value: jsonEncode(state.toJson()),
      );

      // Save API keys separately for security
      await _secureStorage.write(
        key: 'api_keys',
        value: jsonEncode(state.apiKeys),
      );
    } catch (e) {
      // Handle errors
      debugPrint('Error saving settings: $e');
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
    // 标准化提供商名称
    final standardProvider = _standardizeProviderName(provider);
    
    final updatedApiKeys = Map<String, String>.from(state.apiKeys);
    updatedApiKeys[standardProvider] = apiKey;
    
    // Save additional metadata if provided
    if (baseUrl != null) {
      updatedApiKeys['${standardProvider}_url'] = baseUrl;
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
    
    state = state.copyWith(
      apiKeys: updatedApiKeys,
      apiDisplayNames: updatedDisplayNames,
      apiVisibility: updatedVisibility,
    );
    
    await _saveSettings();
  }

  // Set API display name
  Future<void> setApiDisplayName(String provider, String displayName) async {
    final standardProvider = _standardizeProviderName(provider);
    final updatedDisplayNames = Map<String, String>.from(state.apiDisplayNames);
    updatedDisplayNames[standardProvider] = displayName;
    state = state.copyWith(apiDisplayNames: updatedDisplayNames);
    await _saveSettings();
  }

  // Set API visibility
  Future<void> setApiVisibility(String provider, bool isVisible) async {
    final standardProvider = _standardizeProviderName(provider);
    final updatedVisibility = Map<String, bool>.from(state.apiVisibility);
    updatedVisibility[standardProvider] = isVisible;
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
  return ref.read(settingsProvider.notifier).getVisibleApiProviders();
});

final streamingResponsesProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableStreamingResponses;
}); 