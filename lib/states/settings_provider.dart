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
  
  // Other preferences
  final bool enableStreamingResponses;
  final String language;
  final bool enableSoundEffects;
  final bool enableHapticFeedback;

  const Settings({
    this.themeMode = ThemeMode.system,
    this.apiKeys = const {},
    this.enableStreamingResponses = true,
    this.language = 'zh_CN',
    this.enableSoundEffects = true,
    this.enableHapticFeedback = true,
  });

  Settings copyWith({
    ThemeMode? themeMode,
    Map<String, String>? apiKeys,
    bool? enableStreamingResponses,
    String? language,
    bool? enableSoundEffects,
    bool? enableHapticFeedback,
  }) {
    return Settings(
      themeMode: themeMode ?? this.themeMode,
      apiKeys: apiKeys ?? this.apiKeys,
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
  Future<void> setApiConfig(String provider, String apiKey, {String? baseUrl, String? model}) async {
    final updatedApiKeys = Map<String, String>.from(state.apiKeys);
    updatedApiKeys[provider] = apiKey;
    
    // Save additional metadata if provided
    if (baseUrl != null) {
      updatedApiKeys['${provider}_url'] = baseUrl;
    }
    
    if (model != null) {
      updatedApiKeys['${provider}_model'] = model;
    }
    
    state = state.copyWith(apiKeys: updatedApiKeys);
    await _saveSettings();
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

final streamingResponsesProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).enableStreamingResponses;
}); 