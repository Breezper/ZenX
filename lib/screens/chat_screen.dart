import 'package:flutter/material.dart';
import 'package:zenx/components/chat_bubble.dart';
import 'package:zenx/components/message_input.dart';
import 'package:zenx/components/typing_indicator.dart';
import 'package:zenx/models/message.dart';
import 'package:zenx/utils/constants.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    // 可以在这里加载之前的消息或显示欢迎消息
    _addWelcomeMessage();
  }
  
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '您好，我是ZenX AI助手，有什么可以帮您的？',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    });
  }
  
  void _handleSendMessage(String text) {
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
    // 模拟AI回复
    Future.delayed(Duration(seconds: 1), () {
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '这是一个模拟回复。实际项目中，这里会调用API获取回复内容。',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });
      
      // 自动滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
    
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }
  
  void _toggleFunctionPanel() {
    // TODO: 实现功能面板（如图片上传等）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('功能面板待实现')),
    );
  }
  
  final ScrollController _scrollController = ScrollController();
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(),
        ),
        MessageInput(
          onSendMessage: _handleSendMessage,
          onToggleFunctionPanel: _toggleFunctionPanel,
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.neutralGray,
          ),
          SizedBox(height: 16),
          Text(
            '开始新的对话',
            style: AppTheme.titleTextStyle.copyWith(
              color: AppTheme.neutralGray,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '输入消息开始与AI助手对话',
            style: AppTheme.bodyTextStyle.copyWith(
              color: AppTheme.neutralGray,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: AppTheme.smallPadding),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppTheme.defaultPadding,
              right: AppTheme.defaultPadding,
              bottom: AppTheme.smallPadding,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TypingIndicator(),
            ),
          );
        }
        
        return ChatBubble(message: _messages[index]);
      },
    );
  }
} 