import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/states/assistant_provider.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/api/openai_compatible_api.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/states/models_provider.dart';
import 'package:zenx/utils/api_utils.dart';

// Import components
import 'package:zenx/components/api_provider_dropdown.dart';
import 'package:zenx/components/model_dropdown.dart';
import 'package:zenx/components/context_length_slider.dart';
import 'package:zenx/components/settings_warning.dart';
import 'package:zenx/components/system_prompt_field.dart';

class RightSettingsDrawer extends ConsumerStatefulWidget {
  const RightSettingsDrawer({Key? key}) : super(key: key);

  @override
  ConsumerState<RightSettingsDrawer> createState() => _RightSettingsDrawerState();
}

class _RightSettingsDrawerState extends ConsumerState<RightSettingsDrawer> {
  late TextEditingController _systemPromptController;
  String _selectedApiProvider = 'openai';
  String _selectedModel = 'gpt-4o';
  int _contextLength = -1; // -1 means unlimited
  bool _streamingEnabled = true;
  String _apiKeyName = 'openai';
  String _urlKeyName = 'openai_url';
  
  // Flag to ensure models are only fetched once
  bool _modelsInitialized = false;
  // Flag to avoid system prompt reset
  bool _valuesInitialized = false;
  
  // Default model options for each provider
  final Map<String, List<String>> _defaultModelOptions = {
    'openai': ['gpt-4o', 'gpt-4', 'gpt-3.5-turbo'],
    'anthropic': ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'],
    'gemini': ['gemini-pro', 'gemini-ultra'],
    'openai-compatible': ['custom-model'], // Default, will be replaced with API fetched models
  };
  
  @override
  void initState() {
    super.initState();
    // Initialize controller directly in initState
    _systemPromptController = TextEditingController();
    // Call subsequent methods after controller initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeValues();
      _valuesInitialized = true;
    });
  }
  
  @override
  void didUpdateWidget(RightSettingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when Provider values change (only when necessary)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_valuesInitialized) {
        _initializeValues();
        _valuesInitialized = true;
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // When Provider dependencies change, only get key info without reinitializing all values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Only update UI
      setState(() {});
    });
  }
  
  void _initializeValues() {
    if (!mounted) return;
    
    // Get current assistant info from Provider
    final currentAssistant = ref.read(currentAssistantProvider);
    final apiKeys = ref.read(apiKeysProvider);
    
    print("初始化右侧抽屉值 - 助手: ${currentAssistant.name}, 系统提示词: ${currentAssistant.systemPrompt}");
    
    // Update text directly, no need to check if null
    if (_systemPromptController.text != currentAssistant.systemPrompt) {
      _systemPromptController.text = currentAssistant.systemPrompt;
    }
    
    // Check apiProvider format, handle naming inconsistencies
    String apiProvider = currentAssistant.modelConfig.apiProvider;
    
    // Standardize API provider naming
    if (apiProvider == 'openai-compatible' || apiProvider == 'openai_compatible') {
      apiProvider = apiKeys.containsKey('openai_compatible') ? 'openai_compatible' : 'openai-compatible';
    }
    
    // Convert context length, from old token count to new message count
    int contextLength = currentAssistant.modelConfig.contextLength;
    // Handle conversion from old token values to new message count
    if (contextLength > 100) { // If value is greater than 100, assume it's old token count
      contextLength = -1; // Default to unlimited
    }
    
    setState(() {
      _selectedApiProvider = apiProvider;
      _selectedModel = currentAssistant.modelConfig.modelName;
      _contextLength = contextLength;
      _streamingEnabled = currentAssistant.modelConfig.streamingEnabled;
    });
    
    // If OpenAI compatible API is selected and models not yet initialized, trigger model fetch
    if (!_modelsInitialized) {
      _fetchCustomModelsIfNeeded();
      _modelsInitialized = true;
    }
  }
  
  // Fetch custom models if needed - only once
  void _fetchCustomModelsIfNeeded() {
    ApiUtils.fetchModelsForProviderIfNeeded(_selectedApiProvider, ref);
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
    
    // Get current assistant from Provider
    final currentAssistant = ref.watch(currentAssistantProvider);
    // Get API keys
    final apiKeys = ref.watch(apiKeysProvider);
    // Get API display names
    final apiDisplayNames = ref.watch(apiDisplayNamesProvider);
    // Get visible API providers
    final visibleProviders = ref.watch(visibleApiProvidersProvider);
    
    // DEBUG: Print API config info
    print("==== API Keys Debug ====");
    apiKeys.forEach((key, value) {
      print("Key: $key | Value: ${value.isNotEmpty ? '已设置' : '空'}");
    });
    print("选中的提供商: $_selectedApiProvider");
    print("=======================");
    
    // Update key name mappings
    _apiKeyName = ApiUtils.getApiKeyName(_selectedApiProvider);
    _urlKeyName = ApiUtils.getUrlKeyName(_selectedApiProvider);
    
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
                  SystemPromptField(controller: _systemPromptController),
                  SizedBox(height: 16),
                  
                  _buildSectionTitle('模型选择'),
                  SizedBox(height: 8),
                  ApiProviderDropdown(
                    selectedProvider: _selectedApiProvider,
                    onProviderChanged: (value) {
                      setState(() {
                        _selectedApiProvider = value;
                        
                        // Update key names
                        _apiKeyName = ApiUtils.getApiKeyName(value);
                        _urlKeyName = ApiUtils.getUrlKeyName(value);
                        
                        // Select default model
                        final defaultModels = _defaultModelOptions[value] ?? [];
                        if (defaultModels.isNotEmpty) {
                          _selectedModel = defaultModels.first;
                        }
                      });
                    },
                    onFetchModels: _fetchCustomModelsIfNeeded,
                  ),
                  // Check if API Key is configured
                  if (!apiKeys.containsKey(_apiKeyName) || apiKeys[_apiKeyName]?.isEmpty == true)
                    SettingsWarning(
                      message: '未配置${_apiKeyName.toUpperCase()}的API密钥，请在应用设置中添加',
                    ),
                  // OpenAI compatible API needs base URL
                  if (_selectedApiProvider == 'openai-compatible' && 
                      (!apiKeys.containsKey(_urlKeyName) || apiKeys[_urlKeyName]?.isEmpty == true))
                    SettingsWarning(
                      message: '未配置OpenAI兼容API的基础URL，请在应用设置中添加',
                    ),
                  SizedBox(height: 8),
                  ModelDropdown(
                    selectedProvider: _selectedApiProvider,
                    selectedModel: _selectedModel,
                    onModelChanged: (value) {
                      setState(() {
                        _selectedModel = value;
                      });
                    },
                    defaultModelOptions: _defaultModelOptions,
                  ),
                  SizedBox(height: 16),
                  
                  _buildSectionTitle('保留对话消息数量'),
                  SizedBox(height: 8),
                  ContextLengthSlider(
                    contextLength: _contextLength,
                    onContextLengthChanged: (value) {
                      setState(() {
                        _contextLength = value;
                      });
                    },
                  ),
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
    // Get current assistant
    final currentAssistant = ref.read(currentAssistantProvider);
    final assistants = ref.read(assistantsProvider);
    final selectedIndex = ref.read(selectedAssistantIndexProvider);
    final apiKeys = ref.read(apiKeysProvider);
    
    // Check if API key exists
    final hasApiKey = apiKeys.containsKey(_apiKeyName) && 
                     apiKeys[_apiKeyName]?.isNotEmpty == true;
    
    // OpenAI compatible API also needs URL
    final needsBaseUrl = _selectedApiProvider == 'openai-compatible';
    final hasBaseUrl = !needsBaseUrl || (apiKeys.containsKey(_urlKeyName) && 
                      apiKeys[_urlKeyName]?.isNotEmpty == true);
    
    if (!hasApiKey) {
      // Prompt user to add API key
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先在设置中添加${_apiKeyName.toUpperCase()}的API密钥'),
          action: SnackBarAction(
            label: '前往设置',
            onPressed: () {
              Navigator.of(context).pop(); // Close drawer
              // Navigate to settings page - add your navigation logic here
              // Navigator.of(context).pushNamed('/settings');
            },
          ),
        ),
      );
      return;
    }
    
    if (!hasBaseUrl) {
      // Prompt user to add base URL
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先在设置中添加OpenAI兼容API的基础URL'),
          action: SnackBarAction(
            label: '前往设置',
            onPressed: () {
              Navigator.of(context).pop(); // Close drawer
              // Navigate to settings page
              // Navigator.of(context).pushNamed('/settings');
            },
          ),
        ),
      );
      return;
    }
    
    // Create updated assistant object
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
    
    // Use correct notifier method to update assistant
    ref.read(assistantNotifierProvider.notifier).updateAssistant(updatedAssistant);
    
    // Print confirmation that system prompt is updated
    print("助手系统提示词已更新: ${_systemPromptController.text}");
    
    // Show message and close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('设置已应用')),
    );
    Navigator.of(context).pop();
  }
} 