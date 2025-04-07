import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/api/api_service.dart';
import 'package:zenx/api/custom_api.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/states/models_provider.dart';
// Import the new components
import 'package:zenx/components/api_config_dialog.dart';
import 'package:zenx/components/add_api_dialog.dart';
import 'package:zenx/components/settings_item.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    // Force a complete refresh by watching all relevant providers
    final settings = ref.watch(settingsProvider);
    final apiKeys = ref.watch(apiKeysProvider);
    final apiDisplayNames = ref.watch(apiDisplayNamesProvider);
    final apiVisibility = ref.watch(apiVisibilityProvider);
    
    // Debug all API-related settings
    print("设置页面 - API密钥: ${apiKeys.keys.join(", ")}");
    print("设置页面 - API显示名称: $apiDisplayNames");
    print("设置页面 - API可见性: $apiVisibility");
    
    // Get all API providers from combined sources
    final Set<String> allProviders = {
      // Include standard providers
      'openai', 'claude', 'gemini', 'openai_compatible',
      // Include all providers from apiKeys that don't contain special suffixes
      ...apiKeys.keys.where((key) => !key.contains('_url') && !key.contains('_model')),
      // Include all providers from apiDisplayNames 
      ...apiDisplayNames.keys,
    };
    
    // Debug log for providers
    print("所有API提供商: ${allProviders.join(", ")}");
    
    // Convert apiKeys to ApiConfig objects
    final Map<String, ApiConfig?> apiConfigs = {};
    
    // First add standard providers
    apiConfigs['OpenAI'] = apiKeys.containsKey('openai') 
        ? ApiConfig(
            provider: 'openai',
            apiKey: apiKeys['openai']!,
            baseUrl: 'https://api.openai.com/v1',
          )
        : null;
    
    apiConfigs['Claude'] = apiKeys.containsKey('claude')
        ? ApiConfig(
            provider: 'claude',
            apiKey: apiKeys['claude']!,
            baseUrl: 'https://api.anthropic.com/v1',
          )
        : null;
    
    apiConfigs['Gemini'] = apiKeys.containsKey('gemini')
        ? ApiConfig(
            provider: 'gemini',
            apiKey: apiKeys['gemini']!,
            baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
          )
        : null;
    
    apiConfigs['OpenAI兼容'] = apiKeys.containsKey('openai_compatible')
        ? ApiConfig(
            provider: apiKeys['openai_compatible_model'] ?? 'gpt-3.5-turbo',
            apiKey: apiKeys['openai_compatible']!,
            baseUrl: apiKeys['openai_compatible_url'] ?? 'http://localhost:8000',
          )
        : null;
    
    // Then add all custom providers
    for (var key in allProviders) {
      // Skip standard providers as they're already added
      if (['openai', 'claude', 'gemini', 'openai_compatible'].contains(key)) {
        continue;
      }
      
      // Check if we have API key for this provider
      if (apiKeys.containsKey(key)) {
        final displayName = apiDisplayNames[key] ?? key.toUpperCase();
        final baseUrl = apiKeys['${key}_url'] ?? '';
        
        print('Custom provider: $key, BaseURL: $baseUrl');
        
        apiConfigs[displayName] = ApiConfig(
          provider: key,
          apiKey: apiKeys[key]!,
          baseUrl: baseUrl,
        );
      } else if (apiDisplayNames.containsKey(key)) {
        // Provider is registered but has no API key yet
        final displayName = apiDisplayNames[key]!;
        apiConfigs[displayName] = null;
      }
    }

    // Debug log for API configs
    print("所有API配置: ${apiConfigs.keys.join(", ")}");

    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppTheme.defaultPadding),
        children: [
          SectionHeader(title: 'API配置'),
          ..._buildApiConfigItems(context, ref, apiConfigs),
          _buildAddApiButton(context),
          
          SizedBox(height: 32),
          SectionHeader(title: '导出备份'),
          ExportOptionItem(
            title: '导出对话',
            icon: Icons.chat_bubble_outline,
            onTap: () => _exportConversations(context),
          ),
          ExportOptionItem(
            title: '导出设置',
            icon: Icons.settings_outlined,
            onTap: () => _exportSettings(context),
          ),
          
          SizedBox(height: 32),
          SectionHeader(title: '应用主题'),
          _buildThemeSelector(context, ref, settings.themeMode),
          
          SizedBox(height: 32),
          SectionHeader(title: '其他设置'),
          ToggleSettingItem(
            title: '流式响应',
            subtitle: '实时显示AI回复内容',
            value: settings.enableStreamingResponses,
            onChanged: (value) => ref.read(settingsProvider.notifier).toggleStreamingResponses(value),
          ),
          ToggleSettingItem(
            title: '声音效果',
            subtitle: '启用提示音效',
            value: settings.enableSoundEffects,
            onChanged: (value) => ref.read(settingsProvider.notifier).toggleSoundEffects(value),
          ),
          ToggleSettingItem(
            title: '触感反馈',
            subtitle: '启用轻微振动',
            value: settings.enableHapticFeedback,
            onChanged: (value) => ref.read(settingsProvider.notifier).toggleHapticFeedback(value),
          ),
          
          SizedBox(height: 32),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  List<Widget> _buildApiConfigItems(BuildContext context, WidgetRef ref, Map<String, ApiConfig?> apiConfigs) {
    // 获取API显示名称
    final apiDisplayNames = ref.watch(apiDisplayNamesProvider);
    // 获取API可见性
    final apiVisibility = ref.watch(apiVisibilityProvider);
    // 获取API基础URL
    final apiKeys = ref.watch(apiKeysProvider);
    
    // Debug log
    print("构建API配置项，所有配置项: ${apiConfigs.keys.join(", ")}");
    print("构建API配置项，显示名称: $apiDisplayNames");
    print("API可见性: $apiVisibility");
    print("API密钥表内容:");
    apiKeys.forEach((key, value) {
      if (key.endsWith('_url')) {
        print("- $key: $value");
      }
    });
    
    return apiConfigs.entries.map((entry) {
      final provider = entry.key;
      final config = entry.value;
      
      // 标准化提供商键名以匹配存储的键名
      String providerKey = config != null ? config.provider : _standardizeProviderName(provider);
      
      // 获取可见性
      final isVisible = apiVisibility[providerKey] ?? true;
      
      // Debug providerKey mapping
      print("API项目 - 显示名称: $provider, 提供商键名: $providerKey, 可见性: $isVisible");
      
      return ApiConfigItem(
        displayName: provider,
        isConfigured: config != null,
        isVisible: isVisible,
        onTap: () => _configureApi(context, ref, provider, config),
        onDelete: !['OpenAI', 'Claude', 'Gemini', 'OpenAI兼容'].contains(provider) 
            ? () => _confirmDeleteApi(context, ref, providerKey, provider)
            : null,
      );
    }).toList();
  }
  
  Widget _buildAddApiButton(BuildContext context) {
    return TextButton.icon(
      icon: Icon(Icons.add),
      label: Text('添加新API'),
      onPressed: () => _addNewApi(context),
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    return SettingsCard(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ThemeOptionItem(
              mode: ThemeMode.system, 
              icon: Icons.brightness_auto, 
              label: '跟随系统',
              currentThemeMode: currentThemeMode,
              onTap: (mode) => _changeTheme(context, ref, mode),
            ),
            ThemeOptionItem(
              mode: ThemeMode.light, 
              icon: Icons.light_mode, 
              label: '浅色',
              currentThemeMode: currentThemeMode,
              onTap: (mode) => _changeTheme(context, ref, mode),
            ),
            ThemeOptionItem(
              mode: ThemeMode.dark, 
              icon: Icons.dark_mode, 
              label: '深色',
              currentThemeMode: currentThemeMode,
              onTap: (mode) => _changeTheme(context, ref, mode),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVersionInfo() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'ZenX v1.0.0',
          style: AppTheme.captionTextStyle,
        ),
      ),
    );
  }
  
  void _configureApi(BuildContext context, WidgetRef ref, String provider, ApiConfig? config) {
    // Get the actual provider key
    String providerKey = config != null ? config.provider : _standardizeProviderName(provider);
    
    // Debug logs
    print("打开API配置对话框: $provider");
    print("标准化后的提供商键名: $providerKey");
    
    // Get settings to access API keys
    final settings = ref.read(settingsProvider);
    
    // If config is null but we have an API key, build a config
    if (config == null && settings.apiKeys.containsKey(providerKey)) {
      final apiKey = settings.apiKeys[providerKey]!;
      final baseUrl = settings.apiKeys['${providerKey}_url'] ?? '';
      print("从设置中获取基础URL，键名: ${providerKey}_url，值: $baseUrl");
      
      config = ApiConfig(
        provider: providerKey,
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
    }
    
    if (config != null) {
      print("配置信息: API密钥长度: ${config.apiKey.length}, 基础URL: ${config.baseUrl}");
    }
    
    // 打开API配置页面
    showDialog(
      context: context,
      builder: (context) => ApiConfigDialog(
        provider: providerKey,
        config: config,
        onSave: (newConfig) {
          // No need to call settings provider again - it's handled in the dialog
        },
      ),
    );
  }
  
  void _addNewApi(BuildContext context) {
    // 获取WidgetRef的引用
    final widgetRef = ref;
    
    // 打开添加新API页面
    showDialog(
      context: context,
      builder: (context) => AddNewApiDialog(
        onAdd: (String providerKey, String displayName) {
          // 添加后打开配置页面
          Navigator.of(context).pop();
          
          // 强制刷新UI
          widgetRef.invalidate(settingsProvider);
          
          showDialog(
            context: context,
            builder: (context) => ApiConfigDialog(
              provider: providerKey,
              config: null,
              onSave: (_) {
                // 配置保存后再次刷新UI
                widgetRef.invalidate(settingsProvider);
              },
            ),
          );
        },
      ),
    );
  }
  
  void _exportConversations(BuildContext context) {
    // 导出对话功能
    // 实现待完善
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出对话功能将在后续版本实现')),
    );
  }
  
  void _exportSettings(BuildContext context) {
    // 导出设置功能
    // 实现待完善
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出设置功能将在后续版本实现')),
    );
  }
  
  void _changeTheme(BuildContext context, WidgetRef ref, ThemeMode mode) {
    // 使用状态管理器更新主题
    ref.read(settingsProvider.notifier).setThemeMode(mode);
  }

  // 标准化提供商名称
  String _standardizeProviderName(String provider) {
    // First check if this is a display name we know
    final apiDisplayNames = ref.read(apiDisplayNamesProvider);
    for (var entry in apiDisplayNames.entries) {
      if (entry.value.toLowerCase() == provider.toLowerCase()) {
        return entry.key;
      }
    }
    
    // Otherwise standardize based on known provider names
    switch (provider.toLowerCase()) {
      case 'openai':
        return 'openai';
      case 'claude':
        return 'claude';
      case 'gemini':
        return 'gemini';
      case 'openai兼容':
        return 'openai_compatible';
      default:
        return provider.toLowerCase();
    }
  }

  // Helper method to get display name from key
  String _getDisplayNameFromKey(String key, dynamic settings) {
    // Check if we have a display name in settings
    if (settings.apiDisplayNames.containsKey(key)) {
      return settings.apiDisplayNames[key]!;
    }
    
    // Handle standard providers
    switch (key) {
      case 'openai':
        return 'OpenAI';
      case 'claude':
        return 'Claude';
      case 'gemini':
        return 'Gemini';
      case 'openai_compatible':
        return 'OpenAI兼容';
      default:
        // For custom providers, use uppercase or the key itself
        return key.toUpperCase();
    }
  }

  // 重建所有API设置
  void _rebuildApiSettings() {
    // 获取API服务实例
    final apiService = ApiService();
    final settingsState = ref.read(settingsProvider);
    
    // 刷新所有相关状态
    try {
      // 重新初始化所有自定义API
      apiService.initializeAllCustomApis(
        settingsState.apiKeys, 
        settingsState.apiDisplayNames
      );
    } catch (e) {
      print("重建API设置时出错: $e");
    }
    
    // 强制刷新UI
    setState(() {});
  }
  
  void _confirmDeleteApi(BuildContext context, WidgetRef ref, String providerKey, String displayName) {
    // 获取API服务实例
    final apiService = ApiService();
    
    // Implement the confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认删除API'),
        content: Text('您确定要删除API "$displayName"吗？\n\n删除后，相关配置将被移除，但不会影响已创建的对话。'),
        actions: [
          TextButton(
            child: Text('取消'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('删除'),
            onPressed: () async {
              try {
                // 从设置中删除API
                await ref.read(settingsProvider.notifier).deleteApi(providerKey);
                
                // 从API服务中取消注册
                apiService.unregisterCustomApi(providerKey);
                
                // 更彻底地刷新所有相关状态
                ref.invalidate(settingsProvider);
                ref.invalidate(apiKeysProvider);
                ref.invalidate(apiDisplayNamesProvider);
                ref.invalidate(apiVisibilityProvider);
                
                if (context.mounted) {
                  // 显示删除成功提示
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('API "$displayName" 已成功删除')),
                  );
                  
                  // 在确认框关闭后刷新UI
                  Future.delayed(Duration.zero, () {
                    if (context.mounted) {
                      // 完全重建API设置
                      _rebuildApiSettings();
                    }
                  });
                  
                  Navigator.of(context).pop();
                }
              } catch (e) {
                // 处理删除过程中的错误
                print("删除API时发生错误: $e");
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除API失败: $e')),
                  );
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      ),
    );
  }
} 