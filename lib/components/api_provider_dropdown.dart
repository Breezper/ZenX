import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/states/settings_provider.dart';

class ApiProviderDropdown extends ConsumerStatefulWidget {
  final String selectedProvider;
  final Function(String) onProviderChanged;
  final Function() onFetchModels;

  const ApiProviderDropdown({
    Key? key,
    required this.selectedProvider,
    required this.onProviderChanged,
    required this.onFetchModels,
  }) : super(key: key);

  @override
  ConsumerState<ApiProviderDropdown> createState() => _ApiProviderDropdownState();
}

class _ApiProviderDropdownState extends ConsumerState<ApiProviderDropdown> {
  // Default model options for each provider
  final Map<String, List<String>> _defaultModelOptions = {
    'openai': ['gpt-4o', 'gpt-4', 'gpt-3.5-turbo'],
    'anthropic': ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'],
    'gemini': ['gemini-pro', 'gemini-ultra'],
    'openai-compatible': ['custom-model'], // Will be replaced with fetched models
  };

  @override
  Widget build(BuildContext context) {
    // Get API keys, display names, and visible providers
    final apiKeys = ref.watch(apiKeysProvider);
    final apiDisplayNames = ref.watch(apiDisplayNamesProvider);
    final visibleProviders = ref.watch(visibleApiProvidersProvider);
    
    // Debug output
    print("可见API提供商列表: ${visibleProviders.join(', ')}");
    print("API密钥列表: ${apiKeys.keys.where((key) => !key.contains('_url') && !key.contains('_model')).join(', ')}");
    print("API显示名称: $apiDisplayNames");
    
    // Create list of available providers
    final List<String> availableProviders = [..._defaultModelOptions.keys];
    
    // Add custom API providers
    for (final key in apiKeys.keys) {
      if (!key.contains('_url') && 
          !key.contains('_model') && 
          !availableProviders.contains(key) &&
          !['openai', 'claude', 'gemini', 'openai_compatible', 'openai-compatible'].contains(key)) {
        availableProviders.add(key);
        print("添加自定义API提供商: $key (显示名称: ${apiDisplayNames[key] ?? key})");
      }
    }
    
    // Ensure visible custom APIs are added to the list
    for (final key in apiDisplayNames.keys) {
      if (!availableProviders.contains(key) && 
          !key.contains('_url') && 
          !key.contains('_model')) {
        availableProviders.add(key);
        print("从显示名称映射添加API提供商: $key (显示名称: ${apiDisplayNames[key]})");
      }
    }
    
    // Filter visible providers
    final List<String> providers = availableProviders.where((provider) {
      // Check if API key is configured
      final hasKey = apiKeys.containsKey(provider) && apiKeys[provider]?.isNotEmpty == true;
      
      // Special handling for OpenAI compatible API
      if (provider == 'openai-compatible') {
        final hasCompatibleKey = apiKeys.containsKey('openai-compatible') || 
                                apiKeys.containsKey('openai_compatible');
        final hasBaseUrl = apiKeys.containsKey('openai-compatible_url') || 
                          apiKeys.containsKey('openai_compatible_url') ||
                          apiKeys.containsKey('openai-compatible-url') ||
                          apiKeys.containsKey('openai_compatible-url');
        
        if (hasCompatibleKey && hasBaseUrl) {
          return visibleProviders.contains('openai_compatible') || 
                 visibleProviders.contains('openai-compatible');
        }
        return false;
      }
      
      // For other providers, check if visible
      if (!_defaultModelOptions.containsKey(provider)) {
        return hasKey || 
              (apiDisplayNames.containsKey(provider) && 
               (visibleProviders.contains(provider) || 
                !apiKeys.containsKey(provider)));
      }
      
      return hasKey && visibleProviders.contains(provider);
    }).toList();
    
    // If no visible providers, add default option
    if (providers.isEmpty && _defaultModelOptions.isNotEmpty) {
      providers.add(_defaultModelOptions.keys.first);
    }
    
    // Check if selected provider is in list
    if (!providers.contains(widget.selectedProvider) && providers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onProviderChanged(providers.first);
        }
      });
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.dividerDark
              : AppTheme.dividerLight,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: providers.contains(widget.selectedProvider) ? widget.selectedProvider : providers.first,
          items: providers.map((provider) {
            bool hasKey = apiKeys.containsKey(provider) && apiKeys[provider]?.isNotEmpty == true;
            
            // Special handling for OpenAI compatible API
            if (provider == 'openai-compatible') {
              hasKey = (apiKeys.containsKey('openai-compatible') || apiKeys.containsKey('openai_compatible')) &&
                       (apiKeys.containsKey('openai-compatible_url') || apiKeys.containsKey('openai_compatible_url'));
              
              String displayName = apiDisplayNames['openai_compatible'] ?? 
                                 apiDisplayNames['openai-compatible'] ?? 
                                 'OPENAI兼容API';
                                 
              return DropdownMenuItem<String>(
                value: provider,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(displayName),
                    if (hasKey)
                      Icon(Icons.check_circle, color: Colors.green, size: 16)
                    else
                      Icon(Icons.error_outline, color: Colors.orange, size: 16),
                  ],
                ),
              );
            }
            
            // Regular API handling
            String displayName = apiDisplayNames[provider] ?? provider.toUpperCase();
            
            // Custom API handling
            bool isCustomApi = !_defaultModelOptions.containsKey(provider) && 
                             !['openai', 'claude', 'gemini', 'openai_compatible', 'openai-compatible'].contains(provider);
            
            return DropdownMenuItem<String>(
              value: provider,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(displayName),
                        if (isCustomApi) 
                          Container(
                            margin: EdgeInsets.only(left: 4),
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '自定义',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasKey)
                    Icon(Icons.check_circle, color: Colors.green, size: 16)
                  else
                    Icon(Icons.error_outline, color: Colors.orange, size: 16),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              widget.onProviderChanged(value);
              
              // Trigger model fetch for OpenAI compatible API
              if (value == 'openai-compatible') {
                widget.onFetchModels();
              }
            }
          },
        ),
      ),
    );
  }
} 