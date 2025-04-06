import 'package:flutter/material.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/utils/constants.dart';

class RightSettingsDrawer extends StatefulWidget {
  final Assistant? currentAssistant;
  final Function(Assistant)? onAssistantUpdated;
  
  const RightSettingsDrawer({
    Key? key,
    this.currentAssistant,
    this.onAssistantUpdated,
  }) : super(key: key);

  @override
  _RightSettingsDrawerState createState() => _RightSettingsDrawerState();
}

class _RightSettingsDrawerState extends State<RightSettingsDrawer> {
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
    _initializeValues();
  }
  
  @override
  void didUpdateWidget(RightSettingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAssistant != oldWidget.currentAssistant) {
      _initializeValues();
    }
  }
  
  void _initializeValues() {
    if (widget.currentAssistant != null) {
      _systemPromptController = TextEditingController(
        text: widget.currentAssistant!.systemPrompt,
      );
      _selectedApiProvider = widget.currentAssistant!.modelConfig.apiProvider;
      _selectedModel = widget.currentAssistant!.modelConfig.modelName;
      _contextLength = widget.currentAssistant!.modelConfig.contextLength;
      _streamingEnabled = widget.currentAssistant!.modelConfig.streamingEnabled;
    } else {
      _systemPromptController = TextEditingController();
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
    
    if (widget.currentAssistant == null) {
      return SizedBox(
        width: drawerWidth,
        child: Drawer(
          child: Center(
            child: Text('请先选择一个助手'),
          ),
        ),
      );
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
                '${widget.currentAssistant!.name}设置',
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
          value: contextOptions.contains(_contextLength) 
              ? _contextLength 
              : 4000,
          items: contextOptions.map((length) {
            return DropdownMenuItem<int>(
              value: length,
              child: Text('$length 字符'),
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
      title: Text('流式输出'),
      subtitle: Text('启用打字机效果'),
      value: _streamingEnabled,
      activeColor: AppTheme.primaryBlue,
      onChanged: (value) {
        setState(() {
          _streamingEnabled = value;
        });
      },
    );
  }
  
  Widget _buildApplyButton() {
    return Container(
      width: double.infinity,
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
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          ),
        ),
        onPressed: _applySettings,
        child: Text(
          '应用设置',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  void _applySettings() {
    if (widget.onAssistantUpdated != null && widget.currentAssistant != null) {
      final updatedAssistant = Assistant(
        id: widget.currentAssistant!.id,
        name: widget.currentAssistant!.name,
        description: widget.currentAssistant!.description,
        systemPrompt: _systemPromptController.text,
        iconPath: widget.currentAssistant!.iconPath,
        chatSessions: widget.currentAssistant!.chatSessions,
        modelConfig: ApiModelConfig(
          apiProvider: _selectedApiProvider,
          modelName: _selectedModel,
          contextLength: _contextLength,
          streamingEnabled: _streamingEnabled,
        ),
      );
      
      widget.onAssistantUpdated!(updatedAssistant);
    }
    
    Navigator.pop(context);
  }
} 