import 'package:flutter/material.dart';
import 'package:zenx/utils/constants.dart';

class SettingsWarning extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const SettingsWarning({
    Key? key,
    required this.message,
    this.icon = Icons.warning_amber_rounded,
    this.color = Colors.orange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color.withOpacity(0.8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsInfo extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const SettingsInfo({
    Key? key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color = AppTheme.primaryBlue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            Icon(icon, color: color),
            SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
      ),
    );
  }
} 