import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/states/models_provider.dart';

class ModelDropdown extends ConsumerWidget {
  final String selectedProvider;
  final String selectedModel;
  final Function(String) onModelChanged;
  final Map<String, List<String>> defaultModelOptions;

  const ModelDropdown({
    Key? key,
    required this.selectedProvider,
    required this.selectedModel,
    required this.onModelChanged,
    required this.defaultModelOptions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get models list based on selected provider
    List<String> models = [];
    bool isLoading = false;
    
    // Standardize provider name
    final providerKey = selectedProvider == 'openai_compatible' ? 'openai_compatible' : 
                       selectedProvider == 'openai-compatible' ? 'openai-compatible' : 
                       selectedProvider;
    
    // Get cached models from global provider
    if (providerKey == 'openai_compatible' || providerKey == 'openai-compatible') {
      // Try both naming styles
      final compatibleModels1 = ref.watch(providerModelsProvider('openai_compatible'));
      final compatibleModels2 = ref.watch(providerModelsProvider('openai-compatible'));
      
      // Use non-empty model list
      if (compatibleModels1.isNotEmpty) {
        models = compatibleModels1;
        isLoading = ref.watch(isLoadingModelsProvider('openai_compatible'));
      } else if (compatibleModels2.isNotEmpty) {
        models = compatibleModels2;
        isLoading = ref.watch(isLoadingModelsProvider('openai-compatible'));
      } else {
        // If no models found, check loading status
        isLoading = ref.watch(isLoadingModelsProvider('openai_compatible')) || 
                   ref.watch(isLoadingModelsProvider('openai-compatible'));
      }
      
      // If no models fetched, use default list
      if (models.isEmpty && !isLoading) {
        models = defaultModelOptions['openai-compatible'] ?? [];
      }
      
      // Debug logging
      print("OpenAI兼容API模型列表：${models.join(', ')}");
      print("OpenAI兼容API模型获取状态：${isLoading ? '加载中' : '已完成'}");
    } else if (defaultModelOptions.containsKey(providerKey)) {
      // Use default built-in model list
      models = defaultModelOptions[providerKey] ?? [];
    } else {
      // Handle custom API
      // First try to get models from global provider
      final customModels = ref.watch(providerModelsProvider(providerKey));
      isLoading = ref.watch(isLoadingModelsProvider(providerKey));
      
      if (customModels.isNotEmpty) {
        models = customModels;
        print("从全局提供者获取到 ${providerKey} 的模型列表: ${models.join(", ")}");
      } else {
        // If no models, check if there's a saved single model name
        final apiKeys = ref.watch(apiKeysProvider);
        final modelKey = '${providerKey}_model';
        if (apiKeys.containsKey(modelKey) && apiKeys[modelKey]!.isNotEmpty) {
          models = [apiKeys[modelKey]!];
        } else {
          // Default model for custom API
          models = ['custom-model'];
        }
      }
      
      print("自定义API ${providerKey} 模型列表：${models.join(', ')}");
    }
    
    // Check custom models
    final apiKeys = ref.watch(apiKeysProvider);
    
    // Check multiple possible key names for openai_compatible
    if (providerKey == 'openai_compatible' || providerKey == 'openai-compatible') {
      final possibleModelKeys = [
        'openai_compatible_model',
        'openai-compatible_model',
        'openai_compatible-model',
        'openai-compatible-model'
      ];
      
      for (final key in possibleModelKeys) {
        if (apiKeys.containsKey(key) && apiKeys[key]?.isNotEmpty == true) {
          final customModel = apiKeys[key]!;
          if (!models.contains(customModel)) {
            models.add(customModel);
            print("找到自定义模型：$customModel");
          }
        }
      }
    } else {
      // Regular API model handling
      final customModelKey = '${providerKey}_model';
      if (apiKeys.containsKey(customModelKey) && apiKeys[customModelKey]?.isNotEmpty == true) {
        final customModel = apiKeys[customModelKey]!;
        if (!models.contains(customModel)) {
          models.add(customModel);
        }
      }
    }
    
    // If no model options, add a default
    if (models.isEmpty) {
      models = ['custom-model'];
    }
    
    // If selected model not in list, default to first
    if (!models.contains(selectedModel) && models.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onModelChanged(models.first);
      });
    }
    
    return Stack(
      children: [
        Container(
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
              value: models.contains(selectedModel) ? selectedModel : models.first,
              items: models.map((model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: isLoading ? null : (value) {
                if (value != null) {
                  onModelChanged(value);
                }
              },
            ),
          ),
        ),
        // Loading indicator
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 