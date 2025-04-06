import 'package:flutter/material.dart';

class AppTheme {
  // 颜色
  static const primaryBlue = Color(0xFF0A84FF);
  static const successGreen = Color(0xFF30D158);
  static const errorRed = Color(0xFFFF453A);
  static const neutralGray = Color(0xFF8E8E93);
  
  // 背景色
  static const lightBackground = Color(0xFFF2F2F7);
  static const darkBackground = Color(0xFF1C1C1E);
  static const lightCardBackground = Color(0xFFFFFFFF);
  static const darkCardBackground = Color(0xFF2C2C2E);
  static const drawerBackground = Color(0xFFF9F9F9);
  static const drawerDarkBackground = Color(0xFF2C2C2E);
  
  // 消息气泡颜色
  static const userBubbleLight = Color(0xFFE9E9EB);
  static const userBubbleDark = Color(0xFF3C3C3E);
  static const openAIBubbleLight = Color(0xFF147EFB);
  static const openAIBubbleDark = Color(0xFF0A84FF);
  static const claudeBubbleLight = Color(0xFF5A45FF);
  static const claudeBubbleDark = Color(0xFF6E56FF);
  static const geminiBubbleLight = Color(0xFF1E88E5);
  static const geminiBubbleDark = Color(0xFF42A5F5);
  
  // 分割线颜色
  static const dividerLight = Color(0xFFC6C6C8);
  static const dividerDark = Color(0xFF38383A);
  
  // 文本样式
  static const headerTextStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );
  
  static const titleTextStyle = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
  );
  
  static const bodyTextStyle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.normal,
  );
  
  static const captionTextStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF8E8E93),
  );
  
  // 内边距
  static const defaultPadding = 16.0;
  static const smallPadding = 12.0;
  static const listItemSpacing = 8.0;
  
  // 圆角
  static const defaultRadius = 12.0;
  static const buttonRadius = 8.0;
  static const bubbleRadius = 13.0;
  static const inputRadius = 24.0;
  
  // 抽屉宽度
  static double getDrawerWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) {
      return 320.0; // 平板固定宽度
    } else {
      return screenWidth * 0.8; // 手机屏幕比例
    }
  }
}

// 通用阴影样式
class AppShadows {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      spreadRadius: 0,
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> drawerShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      spreadRadius: 0,
      blurRadius: 10,
      offset: Offset(0, 0),
    ),
  ];
}

// 动画持续时间常量
class AppAnimations {
  static const Duration drawerAnimationDuration = Duration(milliseconds: 200);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration feedbackAnimationDuration = Duration(milliseconds: 100);
} 