import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/states/assistant_provider.dart';

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
  
  final Map<String, List<String>> _modelOptions = {
    'openai': ['gpt-4o', 'gpt-4', 'gpt-3.5-turbo'],
    'anthropic': ['claude-3-opus', 'claude-3-sonnet', 'claude-3-haiku'],
    'gemini': ['gemini-pro', 'gemini-ultra'],
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
                  SizedBox(height: 8),
                  _buildModelDropdown(),
                  SizedBox(height: 16),
                  
                  _buildSectionTitle('上下文长度'),
                  SizedBox(height: 8),
                  _buildContextLengthDropdown(),
                  SizedBox(height: 16),
                  
                  _buildStreamingToggle(),
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
  
  Widget _buildProviderDropdown() {
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
          value: _selectedApiProvider,
          items: _modelOptions.keys.map((provider) {
            return DropdownMenuItem<String>(
              value: provider,
              child: Text(provider.toUpperCase()),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedApiProvider = value;
                _selectedModel = _modelOptions[value]!.first;
              });
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildModelDropdown() {
    final models = _modelOptions[_selectedApiProvider] ?? [];
    
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
          value: models.contains(_selectedModel) ? _selectedModel : models.first,
          items: models.map((model) {
            return DropdownMenuItem<String>(
              value: model,
              child: Text(model),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedModel = value;
              });
            }
          },
        ),
      ),
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