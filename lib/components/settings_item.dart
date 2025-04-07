import 'package:flutter/material.dart';
import 'package:zenx/utils/constants.dart';

/// 设置页面通用卡片项
class SettingsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;

  const SettingsCard({
    Key? key,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.dividerDark
              : AppTheme.dividerLight,
        ),
      ),
      child: child,
    );
  }
}

/// 设置页API配置项
class ApiConfigItem extends StatelessWidget {
  final String displayName;
  final bool isConfigured;
  final bool isVisible;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ApiConfigItem({
    Key? key,
    required this.displayName,
    required this.isConfigured,
    this.isVisible = true,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: ListTile(
        title: Row(
          children: [
            Text(displayName),
            SizedBox(width: 8),
            isConfigured
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
            if (!isVisible)
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
        subtitle: isConfigured ? Text('API密钥: ******') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: onDelete,
                tooltip: '删除API',
              ),
            Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// 设置页导出选项
class ExportOptionItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const ExportOptionItem({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

/// 设置页开关项
class ToggleSettingItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const ToggleSettingItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryBlue,
      ),
    );
  }
}

/// 设置页主题选择项
class ThemeOptionItem extends StatelessWidget {
  final ThemeMode mode;
  final IconData icon;
  final String label;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onTap;

  const ThemeOptionItem({
    Key? key,
    required this.mode,
    required this.icon,
    required this.label,
    required this.currentThemeMode,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentThemeMode == mode;
    
    return InkWell(
      onTap: () => onTap(mode),
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
}

/// 设置页节标题
class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: AppTheme.titleTextStyle,
      ),
    );
  }
} 