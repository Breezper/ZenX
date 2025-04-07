import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/api/api_service.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/states/models_provider.dart';

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
              '注意: API密钥将安全加密存储在您的设备上，不会上传到任何服务器。通常需要在基础URL末尾手动加上/v1',
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