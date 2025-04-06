import 'package:flutter/material.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/utils/constants.dart';

class AssistantItem extends StatelessWidget {
  final Assistant assistant;
  final bool isSelected;
  final VoidCallback onTap;
  
  const AssistantItem({
    Key? key,
    required this.assistant,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isSelected
        ? (isDarkMode ? Colors.grey[800] : Colors.grey[200])
        : Colors.transparent;
    
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.smallPadding),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: assistant.iconPath.startsWith('assets')
                      ? Image.asset(
                          assistant.iconPath,
                          width: 24,
                          height: 24,
                        )
                      : Icon(Icons.smart_toy, color: AppTheme.primaryBlue),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assistant.name,
                      style: AppTheme.titleTextStyle.copyWith(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      assistant.description,
                      style: AppTheme.captionTextStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 