import 'package:flutter/material.dart';
import 'package:zenx/utils/constants.dart';

class ContextLengthSlider extends StatelessWidget {
  final int contextLength;
  final Function(int) onContextLengthChanged;

  const ContextLengthSlider({
    Key? key,
    required this.contextLength,
    required this.onContextLengthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert contextLength to slider value
    double sliderValue;
    if (contextLength == -1) {
      sliderValue = 20.0; // Unlimited position
    } else if (contextLength == 0) {
      sliderValue = 0.0;
    } else if (contextLength == 5) {
      sliderValue = 5.0;
    } else if (contextLength == 10) {
      sliderValue = 10.0;
    } else if (contextLength == 15) {
      sliderValue = 15.0;
    } else {
      // Non-standard value, convert to nearest valid value
      sliderValue = 20.0; // Default to unlimited
      
      // Update state after UI renders
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onContextLengthChanged(-1); // Default to unlimited
      });
    }
    
    // Display label
    final String contextLabel = contextLength == -1 ? "无限制" : "${contextLength.toString()}条";
    
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTheme.dividerDark
                  : AppTheme.dividerLight,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("保留消息数量:"),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      contextLabel,
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: sliderValue,
                min: 0,
                max: 20,
                divisions: 4,
                label: contextLabel,
                onChanged: (double value) {
                  int newContextLength;
                  if (value >= 20) {
                    newContextLength = -1; // Unlimited
                  } else {
                    // 5 positions: 0, 5, 10, 15, unlimited
                    if (value < 2.5) {
                      newContextLength = 0;
                    } else if (value < 7.5) {
                      newContextLength = 5;
                    } else if (value < 12.5) {
                      newContextLength = 10;
                    } else {
                      newContextLength = 15;
                    }
                  }
                  onContextLengthChanged(newContextLength);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("0条", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("5条", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("10条", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("15条", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text("无限制", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 4),
        Text(
          "设置保留在上下文中的历史消息数量，0条表示不保留历史消息，无限制表示保留所有历史消息",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
} 