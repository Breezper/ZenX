import 'package:flutter/material.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/models/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;

  // 临时数据 - 后续会从状态管理中获取
  final Map<String, ApiConfig?> _apiConfigs = {
    'OpenAI': ApiConfig(
      provider: 'openai',
      apiKey: '**********',
      baseUrl: 'https://api.openai.com/v1',
    ),
    'Claude': null,
    'Gemini': null,
  };

  @override
  Widget build(BuildContext context) {
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
          ..._buildApiConfigItems(),
          _buildAddApiButton(),
          
          SizedBox(height: 32),
          _buildSectionHeader('导出备份'),
          _buildExportOption('导出对话', Icons.chat_bubble_outline, _exportConversations),
          _buildExportOption('导出设置', Icons.settings_outlined, _exportSettings),
          
          SizedBox(height: 32),
          _buildSectionHeader('应用主题'),
          _buildThemeSelector(),
          
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

  List<Widget> _buildApiConfigItems() {
    return _apiConfigs.entries.map((entry) {
      final provider = entry.key;
      final config = entry.value;
      
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
              Text(provider),
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
            ],
          ),
          subtitle: config != null
              ? Text('API密钥: ******')
              : null,
          trailing: Icon(Icons.chevron_right),
          onTap: () => _configureApi(provider, config),
        ),
      );
    }).toList();
  }
  
  Widget _buildAddApiButton() {
    return TextButton.icon(
      icon: Icon(Icons.add),
      label: Text('添加新API'),
      onPressed: _addNewApi,
      style: TextButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
  
  Widget _buildExportOption(String title, IconData icon, VoidCallback onTap) {
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
  
  Widget _buildThemeSelector() {
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
            _buildThemeOption(ThemeMode.system, Icons.brightness_auto, '跟随系统'),
            _buildThemeOption(ThemeMode.light, Icons.light_mode, '浅色'),
            _buildThemeOption(ThemeMode.dark, Icons.dark_mode, '深色'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(ThemeMode mode, IconData icon, String label) {
    final isSelected = _themeMode == mode;
    
    return InkWell(
      onTap: () => _changeTheme(mode),
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
  
  void _configureApi(String provider, ApiConfig? config) {
    // 打开API配置页面
    showDialog(
      context: context,
      builder: (context) => ApiConfigDialog(
        provider: provider,
        config: config,
        onSave: (newConfig) {
          setState(() {
            _apiConfigs[provider] = newConfig;
          });
        },
      ),
    );
  }
  
  void _addNewApi() {
    // 打开添加新API页面
    // 实现待完善
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('添加新API功能将在后续版本实现')),
    );
  }
  
  void _exportConversations() {
    // 导出对话功能
    // 实现待完善
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出对话功能将在后续版本实现')),
    );
  }
  
  void _exportSettings() {
    // 导出设置功能
    // 实现待完善
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('导出设置功能将在后续版本实现')),
    );
  }
  
  void _changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    // 在实际应用中，这里需要通过状态管理保存主题设置
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('主题设置功能将在后续版本完全实现')),
    );
  }
}

// API配置对话框
class ApiConfigDialog extends StatefulWidget {
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
  _ApiConfigDialogState createState() => _ApiConfigDialogState();
}

class _ApiConfigDialogState extends State<ApiConfigDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _baseUrlController;
  
  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(
      text: widget.config?.apiKey ?? '',
    );
    _baseUrlController = TextEditingController(
      text: widget.config?.baseUrl ?? _getDefaultBaseUrl(),
    );
  }
  
  String _getDefaultBaseUrl() {
    switch (widget.provider.toLowerCase()) {
      case 'openai':
        return 'https://api.openai.com/v1';
      case 'claude':
        return 'https://api.anthropic.com/v1';
      case 'gemini':
        return 'https://generativelanguage.googleapis.com/v1beta';
      default:
        return '';
    }
  }
  
  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.provider} 配置'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        ElevatedButton(
          child: Text('保存'),
          onPressed: () {
            final newConfig = ApiConfig(
              provider: widget.provider.toLowerCase(),
              apiKey: _apiKeyController.text,
              baseUrl: _baseUrlController.text,
              headers: {},
            );
            widget.onSave(newConfig);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
} 