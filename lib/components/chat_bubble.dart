import 'package:flutter/material.dart';
import 'package:zenx/models/message.dart';
import 'package:zenx/utils/constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatefulWidget {
  final Message message;
  
  const ChatBubble({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<int> _dotsAnimation;
  
  @override
  void initState() {
    super.initState();
    // 只有在AI消息且内容为空时才初始化动画
    if (!widget.message.isUser && widget.message.content.isEmpty) {
      _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500),
      )..repeat();
      
      _dotsAnimation = IntTween(begin: 0, end: 3).animate(_animationController);
    } else {
      // 创建默认控制器但不启动它
      _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 1000));
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // 根据消息类型设置气泡样式
    final alignment = widget.message.isUser 
        ? CrossAxisAlignment.end 
        : CrossAxisAlignment.start;
    
    // 根据主题和消息类型确定气泡颜色
    final bubbleColor = widget.message.isUser
        ? (isDarkMode ? AppTheme.userBubbleDark : AppTheme.userBubbleLight)
        : (isDarkMode ? AppTheme.openAIBubbleDark : AppTheme.openAIBubbleLight);
    
    // 根据发送者确定文本颜色
    final textColor = widget.message.isUser
        ? (isDarkMode ? Colors.white : Colors.black)
        : (Colors.white);
    
    // 根据发送者确定气泡形状
    final borderRadius = widget.message.isUser
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
            child: widget.message.isLoading
                ? _buildLoadingIndicator()
                : _buildMessageContent(textColor),
          ),
          SizedBox(height: 4),
          Text(
            _formatTime(widget.message.timestamp),
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
    // 检查是否是AI的空消息
    final isAIEmptyMessage = !widget.message.isUser && widget.message.content.isEmpty;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.message.imageUrl != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.bubbleRadius - 4),
            child: Image.network(
              widget.message.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SizedBox(height: 8),
        ],
        isAIEmptyMessage
            ? _buildThinkingAnimation(textColor)
            : MarkdownBody(
                data: widget.message.content,
                selectable: true,
                softLineBreak: true,
                styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                  h1: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  code: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontFamily: 'monospace',
                    backgroundColor: isDarkMode ? Colors.black38 : Colors.grey.shade200,
                  ),
                  codeblockPadding: EdgeInsets.all(8),
                  codeblockDecoration: BoxDecoration(
                    color: isDarkMode ? Colors.black38 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  blockquote: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquotePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                        width: 4.0,
                      ),
                    ),
                  ),
                  listBullet: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                  listIndent: 24,
                  listBulletPadding: EdgeInsets.only(right: 4),
                  tableBorder: TableBorder.all(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    width: 1,
                  ),
                  tableHead: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  tableBody: TextStyle(
                    color: textColor,
                    fontSize: 15,
                  ),
                  a: TextStyle(
                    color: Colors.blue,
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
      ],
    );
  }
  
  Widget _buildThinkingAnimation(Color textColor) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        String dots = '';
        for (int i = 0; i < _dotsAnimation.value; i++) {
          dots += '.';
        }
        return Text(
          '正在思考$dots',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
          ),
        );
      },
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
} 