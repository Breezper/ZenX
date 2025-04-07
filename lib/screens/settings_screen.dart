import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/api/api_service.dart';
import 'package:zenx/states/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    // Convert apiKeys to ApiConfig objects
    final Map<String, ApiConfig?> apiConfigs = {
      'OpenAI': settings.apiKeys.containsKey('openai') 
          ? ApiConfig(
              provider: 'openai',
              apiKey: settings.apiKeys['openai']!,
              baseUrl: 'https://api.openai.com/v1',
            )
          : null,
      'Claude': settings.apiKeys.containsKey('claude')
          ? ApiConfig(
              provider: 'claude',
              apiKey: settings.apiKeys['claude']!,
              baseUrl: 'https://api.anthropic.com/v1',
            )
          : null,
      'Gemini': settings.apiKeys.containsKey('gemini')
          ? ApiConfig(
              provider: 'gemini',
              apiKey: settings.apiKeys['gemini']!,
              baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
            )
          : null,
      'OpenAI兼容': settings.apiKeys.containsKey('openai_compatible')
          ? ApiConfig(
              provider: settings.apiKeys['openai_compatible_model'] ?? 'gpt-3.5-turbo',
              apiKey: settings.apiKeys['openai_compatible']!,
              baseUrl: settings.apiKeys['openai_compatible_url'] ?? 'http://localhost:8000',
            )
          : null,
    };

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
    
    // Debug log
    print("构建API配置项，显示名称: $apiDisplayNames");
    print("API可见性: $apiVisibility");
    
    return apiConfigs.entries.map((entry) {
      final provider = entry.key;
      final config = entry.value;
      
      // 标准化提供商键名以匹配存储的键名
      String providerKey;
      if (provider.toLowerCase() == 'openai兼容') {
        providerKey = 'openai_compatible';
      } else {
        providerKey = provider.toLowerCase();
      }
      
      // 获取显示名称 - 先检查完整匹配，再检查不同格式，最后使用默认值
      String displayName;
      if (apiDisplayNames.containsKey(providerKey)) {
        displayName = apiDisplayNames[providerKey]!;
      } else if (providerKey == 'openai_compatible' && apiDisplayNames.containsKey('openai-compatible')) {
        displayName = apiDisplayNames['openai-compatible']!;
      } else {
        displayName = provider;
      }
      
      // Debug log
      print("处理API提供商: $provider, 标准化键: $providerKey, 显示名称: $displayName");
      
      // 获取可见性
      final isVisible = providerKey == 'openai_compatible' ? 
                      (apiVisibility[providerKey] ?? apiVisibility['openai-compatible'] ?? true) : 
                      (apiVisibility[providerKey] ?? true);
      
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
          trailing: Icon(Icons.chevron_right),
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
    // Debug logs
    print("打开API配置对话框: $provider");
    if (config != null) {
      print("配置信息: API密钥长度: ${config.apiKey.length}, 基础URL: ${config.baseUrl}");
    }
    
    // Standardize the provider name for OpenAI compatible APIs
    String displayProvider = provider;
    
    // 打开API配置页面
    showDialog(
      context: context,
      builder: (context) => ApiConfigDialog(
        provider: displayProvider,
        config: config,
        onSave: (newConfig) {
          // No need to call settings provider again - it's handled in the dialog
        },
      ),
    );
  }
  
  void _addNewApi(BuildContext context) {
    // 打开添加新API页面
    // 实现待完善
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('添加新API功能将在后续版本实现')),
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
  
  @override
  void initState() {
    super.initState();
    
    // Get settings
    final settings = ref.read(settingsProvider);
    String providerKey = widget.provider.toLowerCase();
    
    // Handle provider key standardization for OpenAI compatible API
    if (providerKey == 'openai兼容') {
      providerKey = 'openai_compatible';
    }
    
    // Debug log
    print('初始化API配置对话框，提供商: ${widget.provider}，标准化键: $providerKey');
    print('API显示名称: ${settings.apiDisplayNames}');
    
    // Get the saved display name for this provider
    String? savedDisplayName;
    
    // Check for display name under both naming conventions for OpenAI compatible
    if (providerKey == 'openai_compatible') {
      savedDisplayName = settings.apiDisplayNames['openai_compatible'] ?? 
                       settings.apiDisplayNames['openai-compatible'];
      print('找到的OpenAI兼容API显示名称: $savedDisplayName');
    } else {
      savedDisplayName = settings.apiDisplayNames[providerKey];
    }
    
    // Initialize controllers
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
    _baseUrlController = TextEditingController(
      text: widget.config?.baseUrl ?? _getDefaultBaseUrl(),
    );
    _modelController = TextEditingController(
      text: widget.config?.provider ?? '',
    );
    _displayNameController = TextEditingController(
      // Only use default display name if no saved name exists
      text: savedDisplayName ?? _getDefaultDisplayName(),
    );
    
    // Get the visibility status
    if (providerKey == 'openai_compatible') {
      _isVisible = settings.apiVisibility['openai_compatible'] ?? 
                 settings.apiVisibility['openai-compatible'] ?? 
                 true;
    } else {
      _isVisible = settings.apiVisibility[providerKey] ?? true;
    }
    
    // 如果是已配置的OpenAI兼容API，尝试获取模型列表
    if (providerKey == 'openai_compatible' && widget.config != null) {
      _fetchModels();
    }
  }

  String _getDefaultBaseUrl() {
    switch (widget.provider.toLowerCase()) {
      case 'openai':
        return 'https://api.openai.com/v1';
      case 'claude':
        return 'https://api.anthropic.com/v1';
      case 'gemini':
        return 'https://generativelanguage.googleapis.com/v1beta';
      case 'openai兼容':
        return 'http://localhost:8000';
      default:
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
                hintText: '默认${widget.provider}基础URL',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
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
    final isOpenAICompatible = widget.provider.toLowerCase() == 'openai兼容';
    
    // Standardize provider key
    String providerKey = widget.provider.toLowerCase();
    if (isOpenAICompatible) {
      providerKey = 'openai_compatible';
    }
    
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
        // 对于其他API，直接验证密钥
        isValid = await _apiService.validateApiKey(
          providerKey,
          apiKey,
        );
      }
      
      if (isValid) {
        if (isOpenAICompatible) {
          // Log before saving to help debug
          print('保存OpenAI兼容API配置:');
          print('- 提供商: $providerKey');
          print('- 显示名称: $displayName');
          print('- 是否可见: $_isVisible');
          
          // For OpenAI-compatible API, save with additional metadata
          ref.read(settingsProvider.notifier).setApiConfig(
            providerKey,
            apiKey,
            baseUrl: baseUrl,
            model: modelName,
            displayName: displayName,
            isVisible: _isVisible,
          );
        } else {
          // For other APIs, save with all settings
          ref.read(settingsProvider.notifier).setApiConfig(
            providerKey,
            apiKey,
            displayName: displayName,
            isVisible: _isVisible,
          );
        }
        
        final newConfig = ApiConfig(
          provider: isOpenAICompatible ? modelName : providerKey,
          apiKey: apiKey,
          baseUrl: baseUrl,
          headers: {},
        );
        
        widget.onSave(newConfig);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _validationError = 'API验证失败，请检查密钥和URL';
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() {
        _validationError = '验证出错: ${e.toString()}';
        _isValidating = false;
      });
    }
  }
} 