import 'package:flutter/material.dart';
import 'package:zenx/utils/constants.dart';

class SystemPromptField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const SystemPromptField({
    Key? key,
    required this.controller,
    this.hintText = '输入系统提示词，定义助手的行为...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        controller: controller,
        maxLines: 5,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
          hintText: hintText,
        ),
      ),
    );
  }
} 