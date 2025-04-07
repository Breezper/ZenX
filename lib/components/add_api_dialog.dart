import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/api/api_service.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/components/api_config_dialog.dart';

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