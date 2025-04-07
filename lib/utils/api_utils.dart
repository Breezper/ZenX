import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/states/models_provider.dart';

class ApiUtils {
  /// Standardizes provider name format
  static String standardizeProviderName(String provider) {
    if (provider == 'openai_compatible') return 'openai-compatible';
    if (provider == 'openai-compatible') return 'openai-compatible';
    return provider;
  }
  
  /// Gets appropriate API key name for a provider
  static String getApiKeyName(String provider) {
    // For OpenAI compatible API, handle special cases
    if (provider == 'openai-compatible' || provider == 'openai_compatible') {
      return 'openai_compatible';
    }
    return provider;
  }
  
  /// Gets appropriate URL key name for a provider
  static String getUrlKeyName(String provider) {
    // For OpenAI compatible API, handle special cases
    if (provider == 'openai-compatible' || provider == 'openai_compatible') {
      return 'openai_compatible_url';
    }
    return '${provider}_url';
  }
  
  /// Checks if a provider has valid API key and URL (if needed)
  static bool hasValidApiConfig(String provider, Map<String, String> apiKeys) {
    final apiKeyName = getApiKeyName(provider);
    final hasApiKey = apiKeys.containsKey(apiKeyName) && apiKeys[apiKeyName]?.isNotEmpty == true;
    
    // Special case for OpenAI compatible API
    if (provider == 'openai-compatible' || provider == 'openai_compatible') {
      final urlKeyName = getUrlKeyName(provider);
      final hasUrl = apiKeys.containsKey(urlKeyName) && apiKeys[urlKeyName]?.isNotEmpty == true;
      return hasApiKey && hasUrl;
    }
    
    return hasApiKey;
  }
  
  /// Fetches models for a provider if needed
  static void fetchModelsForProviderIfNeeded(String provider, WidgetRef ref) {
    final standardProvider = standardizeProviderName(provider);
    final apiKeys = ref.read(apiKeysProvider);
    
    if (standardProvider == 'openai-compatible') {
      final hasApiKey = apiKeys.containsKey('openai_compatible') || apiKeys.containsKey('openai-compatible');
      final hasBaseUrl = apiKeys.containsKey('openai_compatible_url') || 
                        apiKeys.containsKey('openai-compatible_url') ||
                        apiKeys.containsKey('openai-compatible-url') ||
                        apiKeys.containsKey('openai_compatible-url');
      
      if (hasApiKey && hasBaseUrl) {
        // Only fetch if models not already available
        final models = ref.read(providerModelsProvider('openai_compatible'));
        if (models.isEmpty) {
          ref.read(apiModelsProvider.notifier).fetchModelsForProvider('openai_compatible');
        }
      }
    } else if (!['openai', 'anthropic', 'gemini'].contains(standardProvider)) {
      // For custom providers, check for API key and URL
      if (apiKeys.containsKey(standardProvider) && 
          apiKeys.containsKey('${standardProvider}_url')) {
        
        // Only fetch if models not already available
        final models = ref.read(providerModelsProvider(standardProvider));
        if (models.isEmpty) {
          ref.read(apiModelsProvider.notifier).fetchModelsForProvider(standardProvider);
        }
      }
    }
  }
} 