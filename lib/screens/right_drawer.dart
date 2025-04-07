import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/states/assistant_provider.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/api/openai_compatible_api.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/states/models_provider.dart';

class RightSettingsDrawer extends ConsumerStatefulWidget {
  const RightSettingsDrawer({Key? key}) : super(key: key);

  @override
  ConsumerState<RightSettingsDrawer> createState() => _RightSettingsDrawerState();
}

class _RightSettingsDrawerState extends ConsumerState<RightSettingsDrawer> {
  late TextEditingController _systemPromptController;
  String _selectedApiProvider = 'openai';
  String _selectedModel = 'gpt-4o';
  int _contextLength = 4000;
  bool _streamingEnabled = true;
  String _apiKeyName = 'openai';
  String _urlKeyName = 'openai_url';
  
  final Map<String, List<String>> _defaultModelOptions = {
    'openai': ['gpt-4o', 'gpt-4', 'gpt-3.5-turbo'],
    'anthropic': ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'],
    'gemini': ['gemini-pro', 'gemini-ultra'],
    'openai-compatible': ['custom-model'], // 默认选项，会被API获取的模型替换
  };
  
  @override
  void initState() {
    super.initState();
    // 直接在initState中初始化控制器
    _systemPromptController = TextEditingController();
    // 在控制器初始化后再调用后续方法
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeValues();
    });
  }
  
  @override
  void didUpdateWidget(RightSettingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当Provider的值改变时，更新控制器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeValues();
    });
  }
  
  void _initializeValues() {
    // 从Provider获取当前助手信息
    final currentAssistant = ref.read(currentAssistantProvider);
    
    // 直接更新文本，无需检查是否为null
    if (_systemPromptController.text != currentAssistant.systemPrompt) {
      _systemPromptController.text = currentAssistant.systemPrompt;
    }
    
    setState(() {
      _selectedApiProvider = currentAssistant.modelConfig.apiProvider;
      _selectedModel = currentAssistant.modelConfig.modelName;
      _contextLength = currentAssistant.modelConfig.contextLength;
      _streamingEnabled = currentAssistant.modelConfig.streamingEnabled;
    });
    
    // 如果选择的是OpenAI兼容API，触发模型获取
    _fetchCustomModelsIfNeeded();
  }
  
  // 根据需要获取自定义模型
  void _fetchCustomModelsIfNeeded() {
    final apiKeys = ref.read(apiKeysProvider);
    
    // 检查是否有OpenAI兼容API配置
    if (_selectedApiProvider == 'openai-compatible') {
      // 检查可能的键名
      final hasApiKey = apiKeys.containsKey('openai-compatible') || apiKeys.containsKey('openai_compatible');
      final hasBaseUrl = apiKeys.containsKey('openai-compatible_url') || 
                        apiKeys.containsKey('openai_compatible_url') ||
                        apiKeys.containsKey('openai-compatible-url') ||
                        apiKeys.containsKey('openai_compatible-url');
      
      if (hasApiKey && hasBaseUrl) {
        // 通过全局提供者获取模型
        ref.read(apiModelsProvider.notifier).fetchModelsForProvider('openai-compatible');
      }
    }
  }
  
  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final drawerWidth = AppTheme.getDrawerWidth(context);
    
    // 从Provider获取当前助手
    final currentAssistant = ref.watch(currentAssistantProvider);
    // 获取API keys
    final apiKeys = ref.watch(apiKeysProvider);
    
    // DEBUG: 打印API配置信息
    print("==== API Keys Debug ====");
    apiKeys.forEach((key, value) {
      print("Key: $key | Value: ${value.isNotEmpty ? '已设置' : '空'}");
    });
    print("选中的提供商: $_selectedApiProvider");
    print("=======================");
    
    // 更新键名映射
    _apiKeyName = _selectedApiProvider;
    _urlKeyName = '${_selectedApiProvider}_url';
    
    // 特殊处理OpenAI兼容API的键名
    if (_selectedApiProvider == 'openai-compatible') {
      // 检查可能的键名变体 
      if (!apiKeys.containsKey('openai-compatible') && apiKeys.containsKey('openai_compatible')) {
        _apiKeyName = 'openai_compatible';
      }
      if (!apiKeys.containsKey('openai-compatible_url') && apiKeys.containsKey('openai_compatible_url')) {
        _urlKeyName = 'openai_compatible_url';
      }
    }
    
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: Column(
          children: [
            Container(
              color: isDarkMode
                  ? AppTheme.drawerDarkBackground
                  : AppTheme.drawerBackground,
              padding: EdgeInsets.fromLTRB(
                AppTheme.defaultPadding,
                MediaQuery.of(context).padding.top + AppTheme.smallPadding,
                AppTheme.defaultPadding,
                AppTheme.smallPadding,
              ),
              child: Text(
                '${currentAssistant.name}设置',
                style: AppTheme.headerTextStyle,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppTheme.defaultPadding),
                children: [
                  _buildSectionTitle('系统提示词'),
                  SizedBox(height: 8),
                  _buildSystemPromptField(),
                  SizedBox(height: 16),
                  
                  _buildSectionTitle('模型选择'),
                  SizedBox(height: 8),
                  _buildProviderDropdown(),
                  // 检查是否配置了API Key (使用类变量)
                  if (!apiKeys.containsKey(_apiKeyName) || apiKeys[_apiKeyName]?.isEmpty == true)
                    _buildApiKeyWarning(),
                  // OpenAI兼容API需要base URL (使用类变量)
                  if (_selectedApiProvider == 'openai-compatible' && 
                      (!apiKeys.containsKey(_urlKeyName) || apiKeys[_urlKeyName]?.isEmpty == true))
                    _buildBaseUrlWarning(),
                  SizedBox(height: 8),
                  _buildModelDropdown(),
                  SizedBox(height: 16),
                  
                  _buildSectionTitle('上下文长度'),
                  SizedBox(height: 8),
                  _buildContextLengthDropdown(),
                  SizedBox(height: 16),
                  
                  _buildStreamingToggle(),
                  // 使用全局流式响应设置
                  _buildGlobalStreamingSetting(),
                ],
              ),
            ),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.titleTextStyle,
    );
  }
  
  Widget _buildSystemPromptField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.dividerDark
              : AppTheme.dividerLight,
        ),
      ),
      child: TextField(
        controller: _systemPromptController,
        maxLines: 5,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
          hintText: '输入系统提示词，定义助手的行为...',
        ),
      ),
    );
  }
  
  Widget _buildApiKeyWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '未配置${_apiKeyName.toUpperCase()}的API密钥，请在应用设置中添加',
                style: TextStyle(color: Colors.orange[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBaseUrlWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '未配置OpenAI兼容API的基础URL，请在应用设置中添加',
                style: TextStyle(color: Colors.orange[800]),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProviderDropdown() {
    // 获取有API密钥的提供商
    final apiKeys = ref.watch(apiKeysProvider);
    
    // 添加OpenAI兼容API到选项中
    final List<String> providers = [..._defaultModelOptions.keys];
    
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
          value: providers.contains(_selectedApiProvider) ? _selectedApiProvider : providers.first,
          items: providers.map((provider) {
            bool hasKey = apiKeys.containsKey(provider) && apiKeys[provider]?.isNotEmpty == true;
            // OpenAI兼容API还需要检查URL
            if (provider == 'openai-compatible') {
              hasKey = hasKey && apiKeys.containsKey('openai-compatible_url') && 
                      apiKeys['openai-compatible_url']?.isNotEmpty == true;
            }
            
            String displayName = provider.toUpperCase();
            if (provider == 'openai-compatible') {
              displayName = 'OPENAI兼容API';
            }
            
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
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedApiProvider = value;
                
                // 如果是OpenAI兼容API，尝试获取模型列表
                if (value == 'openai-compatible') {
                  _fetchCustomModelsIfNeeded();
                }
                
                // 选择默认模型
                final defaultModels = _defaultModelOptions[value] ?? [];
                if (defaultModels.isNotEmpty) {
                  _selectedModel = defaultModels.first;
                }
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildModelDropdown() {
    // 根据选择的提供商获取模型列表
    List<String> models = [];
    bool isLoading = false;
    
    // 获取全局缓存的模型列表
    if (_selectedApiProvider == 'openai-compatible') {
      models = ref.watch(providerModelsProvider('openai-compatible'));
      isLoading = ref.watch(isLoadingModelsProvider('openai-compatible'));
      
      // 如果没有获取到模型，使用默认列表
      if (models.isEmpty && !isLoading) {
        models = _defaultModelOptions['openai-compatible'] ?? [];
      }
    } else {
      models = _defaultModelOptions[_selectedApiProvider] ?? [];
    }
    
    // 检查自定义模型
    final apiKeys = ref.watch(apiKeysProvider);
    final customModelKey = '${_selectedApiProvider}_model';
    if (apiKeys.containsKey(customModelKey) && apiKeys[customModelKey]?.isNotEmpty == true) {
      final customModel = apiKeys[customModelKey]!;
      if (!models.contains(customModel)) {
        models.add(customModel);
      }
    }
    
    // 如果没有模型选项，添加一个默认选项
    if (models.isEmpty) {
      models = ['custom-model'];
    }
    
    // 如果当前选择的模型不在列表中，默认选择第一个
    if (!models.contains(_selectedModel) && models.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedModel = models.first;
        });
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
              value: models.contains(_selectedModel) ? _selectedModel : models.first,
              items: models.map((model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: isLoading ? null : (value) {
                if (value != null) {
                  setState(() {
                    _selectedModel = value;
                  });
                }
              },
            ),
          ),
        ),
        // 加载指示器
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
  
  Widget _buildContextLengthDropdown() {
    final contextOptions = [2000, 4000, 8000, 16000, 32000];
    
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
        child: DropdownButton<int>(
          isExpanded: true,
          value: _contextLength,
          items: contextOptions.map((length) {
            return DropdownMenuItem<int>(
              value: length,
              child: Text('$length tokens'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _contextLength = value;
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildStreamingToggle() {
    return SwitchListTile(
      title: Text('流式响应'),
      subtitle: Text('实时显示AI回复'),
      value: _streamingEnabled,
      activeColor: AppTheme.primaryBlue,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _streamingEnabled = value;
        });
      },
    );
  }
  
  Widget _buildGlobalStreamingSetting() {
    // 获取全局流式响应设置
    final globalStreaming = ref.watch(streamingResponsesProvider);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.dividerDark
                : AppTheme.dividerLight,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Expanded(
              child: Text('全局流式响应设置: ${globalStreaming ? "已启用" : "已禁用"}'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildApplyButton() {
    return Container(
      padding: EdgeInsets.all(AppTheme.defaultPadding),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.dividerDark
                : AppTheme.dividerLight,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _applySettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            ),
          ),
          child: Text('应用设置'),
        ),
      ),
    );
  }
  
  void _applySettings() {
    // 获取当前助手
    final currentAssistant = ref.read(currentAssistantProvider);
    final assistants = ref.read(assistantsProvider);
    final selectedIndex = ref.read(selectedAssistantIndexProvider);
    final apiKeys = ref.read(apiKeysProvider);
    
    // 检查是否有API密钥
    final hasApiKey = apiKeys.containsKey(_apiKeyName) && 
                     apiKeys[_apiKeyName]?.isNotEmpty == true;
    
    // OpenAI兼容API还需要检查URL
    final needsBaseUrl = _selectedApiProvider == 'openai-compatible';
    final hasBaseUrl = !needsBaseUrl || (apiKeys.containsKey(_urlKeyName) && 
                      apiKeys[_urlKeyName]?.isNotEmpty == true);
    
    if (!hasApiKey) {
      // 提示用户添加API密钥
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先在设置中添加${_apiKeyName.toUpperCase()}的API密钥'),
          action: SnackBarAction(
            label: '前往设置',
            onPressed: () {
              Navigator.of(context).pop(); // 关闭抽屉
              // 导航到设置页面 - 你需要根据你的应用添加设置页面的导航逻辑
              // Navigator.of(context).pushNamed('/settings');
            },
          ),
        ),
      );
      return;
    }
    
    if (!hasBaseUrl) {
      // 提示用户添加基础URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先在设置中添加OpenAI兼容API的基础URL'),
          action: SnackBarAction(
            label: '前往设置',
            onPressed: () {
              Navigator.of(context).pop(); // 关闭抽屉
              // 导航到设置页面
              // Navigator.of(context).pushNamed('/settings');
            },
          ),
        ),
      );
      return;
    }
    
    // 创建更新后的助手对象
    final updatedAssistant = Assistant(
      id: currentAssistant.id,
      name: currentAssistant.name,
      description: currentAssistant.description,
      systemPrompt: _systemPromptController.text,
      iconPath: currentAssistant.iconPath,
      modelConfig: ApiModelConfig(
        apiProvider: _selectedApiProvider,
        modelName: _selectedModel,
        contextLength: _contextLength,
        streamingEnabled: _streamingEnabled,
      ),
    );
    
    // 更新助手列表
    final updatedAssistants = assistants.map((assistant) => 
      assistant.id == updatedAssistant.id ? updatedAssistant : assistant
    ).toList();
    
    // 更新状态
    ref.read(assistantsProvider.notifier).state = updatedAssistants;
    
    // 提示并关闭抽屉
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('设置已应用')),
    );
    Navigator.of(context).pop();
  }
} 