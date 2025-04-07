import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/api/api_service.dart';
import 'package:zenx/api/custom_api.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/states/models_provider.dart';

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
          _buildSectionHeader('API配置'),
          ..._buildApiConfigItems(context, ref, apiConfigs),
          _buildAddApiButton(context),
          
          SizedBox(height: 32),
          _buildSectionHeader('导出备份'),
          _buildExportOption(context, '导出对话', Icons.chat_bubble_outline, () => _exportConversations(context)),
          _buildExportOption(context, '导出设置', Icons.settings_outlined, () => _exportSettings(context)),
          
          SizedBox(height: 32),
          _buildSectionHeader('应用主题'),
          _buildThemeSelector(context, ref, settings.themeMode),
          
          SizedBox(height: 32),
          _buildSectionHeader('其他设置'),
          _buildToggleOption(
            context, 
            '流式响应', 
            '实时显示AI回复内容', 
            settings.enableStreamingResponses,
            (value) => ref.read(settingsProvider.notifier).toggleStreamingResponses(value),
          ),
          _buildToggleOption(
            context, 
            '声音效果', 
            '启用提示音效', 
            settings.enableSoundEffects,
            (value) => ref.read(settingsProvider.notifier).toggleSoundEffects(value),
          ),
          _buildToggleOption(
            context, 
            '触感反馈', 
            '启用轻微振动', 
            settings.enableHapticFeedback,
            (value) => ref.read(settingsProvider.notifier).toggleHapticFeedback(value),
          ),
          
          SizedBox(height: 32),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTheme.titleTextStyle,
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
      
      // 获取显示名称
      String displayName = provider; // Default to the key in the map
      
      // 获取可见性
      final isVisible = apiVisibility[providerKey] ?? true;
      
      // Debug providerKey mapping
      print("API项目 - 显示名称: $provider, 提供商键名: $providerKey, 可见性: $isVisible");
      
      return Card(
        margin: EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
          side: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.dividerDark
                : AppTheme.dividerLight,
          ),
        ),
        child: ListTile(
          title: Row(
            children: [
              Text(displayName),
              SizedBox(width: 8),
              config != null
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '已配置',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.successGreen,
                        ),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralGray.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '未设置',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.neutralGray,
                        ),
                      ),
                    ),
              if (isVisible == false)
                Container(
                  margin: EdgeInsets.only(left: 4),
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '隐藏',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
          subtitle: config != null
              ? Text('API密钥: ******')
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 不允许删除默认API提供商
              if (!['OpenAI', 'Claude', 'Gemini', 'OpenAI兼容'].contains(provider))
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                  onPressed: () => _confirmDeleteApi(context, ref, providerKey, displayName),
                  tooltip: '删除API',
                ),
              Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _configureApi(context, ref, provider, config),
        ),
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
  
  Widget _buildExportOption(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.dividerDark
              : AppTheme.dividerLight,
        ),
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
  
  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeMode currentThemeMode) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.dividerDark
              : AppTheme.dividerLight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildThemeOption(context, ref, ThemeMode.system, Icons.brightness_auto, '跟随系统', currentThemeMode),
            _buildThemeOption(context, ref, ThemeMode.light, Icons.light_mode, '浅色', currentThemeMode),
            _buildThemeOption(context, ref, ThemeMode.dark, Icons.dark_mode, '深色', currentThemeMode),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(BuildContext context, WidgetRef ref, ThemeMode mode, IconData icon, String label, ThemeMode currentThemeMode) {
    final isSelected = currentThemeMode == mode;
    
    return InkWell(
      onTap: () => _changeTheme(context, ref, mode),
      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryBlue : null,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryBlue : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToggleOption(
    BuildContext context, 
    String title, 
    String subtitle, 
    bool value, 
    Function(bool) onChanged
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.dividerDark
              : AppTheme.dividerLight,
        ),
      ),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
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

// API配置对话框
class ApiConfigDialog extends ConsumerStatefulWidget {
  final String provider;
  final ApiConfig? config;
  final Function(ApiConfig) onSave;
  
  const ApiConfigDialog({
    Key? key,
    required this.provider,
    this.config,
    required this.onSave,
  }) : super(key: key);
  
  @override
  ConsumerState<ApiConfigDialog> createState() => _ApiConfigDialogState();
}

class _ApiConfigDialogState extends ConsumerState<ApiConfigDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  late TextEditingController _modelController;
  late TextEditingController _displayNameController;
  bool _isValidating = false;
  bool _isVisible = true;
  String? _validationError;
  List<String> _availableModels = [];
  final ApiService _apiService = ApiService();
  
  // 标准化提供商名称
  String _standardizeProviderName(String provider) {
    if (provider.toLowerCase() == 'openai兼容') {
      return 'openai_compatible';
    }
    return provider.toLowerCase();
  }
  
  @override
  void initState() {
    super.initState();
    
    // Get settings
    final settings = ref.read(settingsProvider);
    
    // 标准化提供商键名
    String providerKey = widget.provider.toLowerCase();
    
    // Debug log
    print('初始化API配置对话框，提供商: ${widget.provider}，标准化键: $providerKey');
    print('API显示名称: ${settings.apiDisplayNames}');
    
    // Get the saved display name for this provider
    String? savedDisplayName = settings.apiDisplayNames[providerKey];
    
    // Get the saved baseURL from settings if config doesn't have it
    String baseUrl = '';
    if (widget.config != null && widget.config!.baseUrl.isNotEmpty) {
      baseUrl = widget.config!.baseUrl;
      print('从config获取基础URL: $baseUrl');
    } else {
      // Try to get from settings
      final urlKey = '${providerKey}_url';
      baseUrl = settings.apiKeys[urlKey] ?? _getDefaultBaseUrl();
      print('从settings获取基础URL，键名: $urlKey, 值: $baseUrl');
    }
    
    // Initialize controllers
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
    _baseUrlController = TextEditingController(
      text: baseUrl,
    );
    _modelController = TextEditingController(
      text: widget.config?.provider ?? '',
    );
    _displayNameController = TextEditingController(
      // Use saved display name, or default display name if none exists
      text: savedDisplayName ?? _getDefaultDisplayName(),
    );
    
    // Get the visibility status
    _isVisible = settings.apiVisibility[providerKey] ?? true;
    
    // Log what we're initializing with
    print('初始化控制器 - 显示名称: ${_displayNameController.text}, 可见性: $_isVisible, API密钥长度: ${_apiKeyController.text.length}, 基础URL: ${_baseUrlController.text}');
    
    // 如果是已配置的OpenAI兼容API，尝试获取模型列表
    if (providerKey == 'openai_compatible' && widget.config != null) {
      _fetchModels();
    }
  }
  
  String _getDefaultBaseUrl() {
    // Use default based on provider
    switch (widget.provider.toLowerCase()) {
      case 'openai':
        return 'https://api.openai.com/v1';
      case 'claude':
        return 'https://api.anthropic.com/v1';
      case 'gemini':
        return 'https://generativelanguage.googleapis.com/v1beta';
      case 'openai_compatible':
        return 'http://localhost:8000';
      default:
        // For custom APIs, no default base URL
        return '';
    }
  }
  
  String _getDefaultDisplayName() {
    // Default display name is the capitalized provider name
    final providerName = widget.provider;
    switch (providerName.toLowerCase()) {
      case 'openai':
        return 'OpenAI';
      case 'claude':
        return 'Claude';
      case 'gemini':
        return 'Gemini';
      case 'openai兼容':
        return 'OpenAI兼容';
      default:
        return providerName.toUpperCase();
    }
  }
  
  Future<void> _fetchModels() async {
    if (widget.provider.toLowerCase() != 'openai兼容') return;
    
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    
    if (apiKey.isEmpty || baseUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先填写API密钥和基础URL')),
      );
      return;
    }
    
    setState(() {
      _isValidating = true;
      _validationError = null;
    });
    
    try {
      final config = ApiConfig(
        provider: 'openai_compatible',
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      
      final models = await _apiService.fetchCompatibleApiModels(config);
      
      if (models.isEmpty) {
        throw Exception('无法获取模型列表，请检查API地址和密钥');
      }
      
      setState(() {
        _availableModels = models;
        _isValidating = false;
      });
      
      // 如果获取到模型，设置默认选中第一个
      if (_availableModels.isNotEmpty && _modelController.text.isEmpty) {
        _modelController.text = _availableModels.first;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功获取${models.length}个模型')),
      );
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = '获取模型失败: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取模型失败: ${e.toString()}')),
      );
    }
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final bool isOpenAICompatible = widget.provider.toLowerCase() == 'openai兼容';
    
    // Use the display name for the dialog title
    final String dialogTitle = _displayNameController.text.isNotEmpty ? 
                             _displayNameController.text : 
                             widget.provider;
    
    return AlertDialog(
      title: Text('$dialogTitle 配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('显示名称', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
            SizedBox(height: 8),
            TextField(
              controller: _displayNameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
                hintText: '输入API显示名称',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('在右侧抽屉显示'),
              subtitle: Text('控制该API是否显示在右侧模型选择抽屉中'),
              value: _isVisible,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryBlue,
              onChanged: (value) {
                setState(() {
                  _isVisible = value;
                });
              },
            ),
            
            Divider(),
            
            Text('API密钥', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
            SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
                hintText: '输入${widget.provider} API密钥',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                errorText: _validationError,
              ),
              obscureText: true,
            ),
            
            SizedBox(height: 16),
            Text('基础URL', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
            SizedBox(height: 8),
            TextField(
              controller: _baseUrlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                ),
                hintText: '输入API基础URL，例如 https://api.example.com',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                // 立即更新baseUrl，帮助调试
                print("基础URL输入: $value");
              },
            ),
            
            if (isOpenAICompatible && _availableModels.isNotEmpty) ...[
              SizedBox(height: 16),
              Text('选择模型', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                hint: Text('选择模型'),
                value: _modelController.text.isNotEmpty && _availableModels.contains(_modelController.text) 
                    ? _modelController.text 
                    : null,
                items: _availableModels.map((model) {
                  return DropdownMenuItem<String>(
                    value: model,
                    child: Text(model, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _modelController.text = value;
                    });
                  }
                },
              ),
            ],
            
            if (isOpenAICompatible && _availableModels.isEmpty) ...[
              SizedBox(height: 16),
              Text('模型', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
              SizedBox(height: 8),
              TextField(
                controller: _modelController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                  hintText: '输入模型名称',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
            
            SizedBox(height: 16),
            Text(
              '注意: API密钥将安全加密存储在您的设备上，不会上传到任何服务器。',
              style: AppTheme.captionTextStyle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (isOpenAICompatible && _availableModels.isEmpty)
          TextButton(
            child: Text('获取模型'),
            onPressed: _fetchModels,
          ),
        if (_isValidating)
          CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          )
        else
          ElevatedButton(
            child: Text('保存'),
            onPressed: _validateAndSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
          ),
      ],
    );
  }
  
  Future<void> _validateAndSave() async {
    final apiKey = _apiKeyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    final displayName = _displayNameController.text.trim();
    
    // 标准化提供商键名
    String providerKey = _standardizeProviderName(widget.provider);
    final isOpenAICompatible = providerKey == 'openai_compatible';
    
    // Get the model name for OpenAI compatible API
    String modelName = _modelController.text.trim();
    
    if (apiKey.isEmpty) {
      setState(() {
        _validationError = 'API密钥不能为空';
      });
      return;
    }
    
    if (isOpenAICompatible && baseUrl.isEmpty) {
      setState(() {
        _validationError = '基础URL不能为空';
      });
      return;
    }
    
    if (displayName.isEmpty) {
      setState(() {
        _validationError = '显示名称不能为空';
      });
      return;
    }
    
    // For OpenAI compatible, ensure we have a model selected
    if (isOpenAICompatible && modelName.isEmpty) {
      if (_availableModels.isNotEmpty) {
        // Default to first model if available
        modelName = _availableModels.first;
        _modelController.text = modelName;
      } else {
        setState(() {
          _validationError = '请先获取模型列表或手动输入模型名称';
        });
        return;
      }
    }
    
    setState(() {
      _isValidating = true;
      _validationError = null;
    });
    
    try {
      bool isValid = false;
      
      if (isOpenAICompatible) {
        // 对于OpenAI兼容API，需要验证完整配置
        final config = ApiConfig(
          provider: 'openai_compatible',
          apiKey: apiKey,
          baseUrl: baseUrl,
        );
        
        isValid = await _apiService.validateCompatibleApiConfig(config);
      } else {
        // 确保自定义API已注册
        if (!['openai', 'claude', 'gemini', 'openai_compatible', 'openai-compatible'].contains(providerKey)) {
          // 这是一个自定义API，先注册它
          print("在验证前注册自定义API: $providerKey, 显示名称: $displayName");
          _apiService.createCustomApi(providerKey, displayName);
          
          // 对于自定义API，如果有baseUrl，使用完整配置进行验证
          if (baseUrl.isNotEmpty) {
            print("使用完整配置验证自定义API: $providerKey, baseUrl: $baseUrl");
            final config = ApiConfig(
              provider: providerKey,
              apiKey: apiKey,
              baseUrl: baseUrl,
            );
            
            isValid = await _apiService.validateCustomApiConfig(config);
          } else {
            // 如果baseUrl为空，只验证API密钥
            isValid = await _apiService.validateApiKey(
              providerKey,
              apiKey,
            );
          }
        } else {
          // 对于标准API，直接验证密钥
          isValid = await _apiService.validateApiKey(
            providerKey,
            apiKey,
          );
        }
      }
      
      if (!mounted) return; // Check if widget is still mounted
      
      if (isValid) {
        // 保存前获取ref的引用
        final settingsNotifier = ref.read(settingsProvider.notifier);
        final currentConfig = ApiConfig(
          provider: isOpenAICompatible ? modelName : providerKey,
          apiKey: apiKey,
          baseUrl: baseUrl,
          headers: {},
        );
        
        // 关闭对话框先
        Navigator.of(context).pop();
        
        try {
          if (isOpenAICompatible) {
            // Log before saving to help debug
            print('保存OpenAI兼容API配置:');
            print('- 提供商: $providerKey');
            print('- 显示名称: $displayName');
            print('- 是否可见: $_isVisible');
            
            // For OpenAI-compatible API, save with additional metadata
            await settingsNotifier.setApiConfig(
              providerKey,
              apiKey,
              baseUrl: baseUrl,
              model: modelName,
              displayName: displayName,
              isVisible: _isVisible,
            );
            
            // 获取模型列表并更新
            final modelsNotifier = ref.read(apiModelsProvider.notifier);
            modelsNotifier.fetchModelsForProvider(providerKey);
          } else {
            // Log before saving to help debug custom API
            print('保存自定义API配置:');
            print('- 提供商: $providerKey');
            print('- 显示名称: $displayName');
            print('- 基础URL: $baseUrl');
            print('- 是否可见: $_isVisible');
            
            // For other APIs, save with all settings
            await settingsNotifier.setApiConfig(
              providerKey,
              apiKey,
              baseUrl: baseUrl, // Add the baseUrl for custom APIs
              displayName: displayName,
              isVisible: _isVisible,
            );
            
            // 为自定义API获取模型列表
            if (!['openai', 'claude', 'gemini'].contains(providerKey)) {
              final modelsNotifier = ref.read(apiModelsProvider.notifier);
              modelsNotifier.fetchModelsForProvider(providerKey);
            }
          }
          
          // 强制刷新UI
          ref.invalidate(settingsProvider);
          
          // 调用保存回调
          widget.onSave(currentConfig);
        } catch (e) {
          print("保存API配置时出错: $e");
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存配置失败: $e')),
            );
          }
        }
      } else {
        if (mounted) { // Check if widget is still mounted
          setState(() {
            _validationError = 'API验证失败，请检查密钥和URL';
            _isValidating = false;
          });
        }
      }
    } catch (e) {
      if (mounted) { // Check if widget is still mounted
        setState(() {
          _validationError = '验证出错: ${e.toString()}';
          _isValidating = false;
        });
      }
    }
  }
}

// 添加新API对话框
class AddNewApiDialog extends ConsumerStatefulWidget {
  final Function(String providerKey, String displayName) onAdd;
  
  const AddNewApiDialog({
    Key? key,
    required this.onAdd,
  }) : super(key: key);
  
  @override
  ConsumerState<AddNewApiDialog> createState() => _AddNewApiDialogState();
}

class _AddNewApiDialogState extends ConsumerState<AddNewApiDialog> {
  final TextEditingController _providerKeyController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  String? _error;
  
  // 获取API服务实例
  final ApiService _apiService = ApiService();
  
  @override
  void dispose() {
    _providerKeyController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('添加新API'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('API标识符', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
          SizedBox(height: 8),
          TextField(
            controller: _providerKeyController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
              hintText: '输入API标识符 (如 ollama)',
              errorText: _error,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (_) {
              if (_error != null) {
                setState(() {
                  _error = null;
                });
              }
            },
          ),
          
          SizedBox(height: 16),
          Text('显示名称', style: AppTheme.titleTextStyle.copyWith(fontSize: 14)),
          SizedBox(height: 8),
          TextField(
            controller: _displayNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
              hintText: '输入显示名称 (如 Ollama)',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          
          SizedBox(height: 16),
          Text(
            '添加新API后，您可以配置API密钥、基础URL和其他参数。',
            style: AppTheme.captionTextStyle,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('取消'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('添加'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
          ),
          onPressed: () async {
            final providerKey = _providerKeyController.text.trim().toLowerCase();
            String displayName = _displayNameController.text.trim();
            
            // 验证
            if (providerKey.isEmpty) {
              setState(() {
                _error = 'API标识符不能为空';
              });
              return;
            }
            
            // 如果显示名称为空，使用标识符首字母大写
            if (displayName.isEmpty) {
              displayName = providerKey[0].toUpperCase() + providerKey.substring(1);
            }
            
            // 检查是否已存在
            final settings = ref.read(settingsProvider);
            if (settings.apiKeys.containsKey(providerKey)) {
              setState(() {
                _error = '此API标识符已存在';
              });
              return;
            }
            
            try {
              // 创建自定义API实现
              _apiService.createCustomApi(providerKey, displayName);
              
              // 保存设置前获取ref的引用，以避免后续可能的挂载问题
              final currentRef = ref;
              
              // 关闭当前对话框，避免在对话框关闭后访问setState
              Navigator.of(context).pop();
              
              // 保存到设置
              await currentRef.read(settingsProvider.notifier).setApiDisplayName(providerKey, displayName);
              await currentRef.read(settingsProvider.notifier).setApiVisibility(providerKey, true);
              
              // 强制刷新UI
              currentRef.invalidate(settingsProvider);
              
              // 打开配置对话框
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) => ApiConfigDialog(
                    provider: providerKey,
                    config: null,
                    onSave: (_) {},
                  ),
                );
              }
              
              // 将回调延迟到这里执行
              widget.onAdd(providerKey, displayName);
            } catch (e) {
              print("添加API时出错: $e");
              if (mounted) {
                setState(() {
                  _error = '添加API失败: $e';
                });
              }
            }
          },
        ),
      ],
    );
  }
} 