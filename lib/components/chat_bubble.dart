import 'package:flutter/material.dart';
import 'package:zenx/models/message.dart';
import 'package:zenx/utils/constants.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  
  const ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 根据消息类型设置气泡样式
    final alignment = message.isUser 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start;
    
    // 根据主题和消息类型确定气泡颜色
    final bubbleColor = message.isUser
        ? (isDarkMode ? AppTheme.userBubbleDark : AppTheme.userBubbleLight)
        : (isDarkMode ? AppTheme.openAIBubbleDark : AppTheme.openAIBubbleLight);
    
    // 根据发送者确定文本颜色
    final textColor = message.isUser
        ? (isDarkMode ? Colors.white : Colors.black)
        : (Colors.white);
    
    // 根据发送者确定气泡形状
    final borderRadius = message.isUser
        ? BorderRadius.only(
            topLeft: Radius.circular(AppTheme.bubbleRadius),
            topRight: Radius.circular(AppTheme.bubbleRadius),
            bottomLeft: Radius.circular(AppTheme.bubbleRadius),
            bottomRight: Radius.circular(4.0),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(4.0),
            topRight: Radius.circular(AppTheme.bubbleRadius),
            bottomLeft: Radius.circular(AppTheme.bubbleRadius),
            bottomRight: Radius.circular(AppTheme.bubbleRadius),
          );
    
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.defaultPadding,
        vertical: AppTheme.smallPadding / 2,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
            ),
            padding: EdgeInsets.all(AppTheme.smallPadding),
            child: message.isLoading
                ? _buildLoadingIndicator()
                : _buildMessageContent(textColor),
          ),
          SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: AppTheme.captionTextStyle.copyWith(
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
  
  Widget _buildMessageContent(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.bubbleRadius - 4),
            child: Image.network(
              message.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SizedBox(height: 8),
        ],
        SelectableText(
          message.content,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
} 