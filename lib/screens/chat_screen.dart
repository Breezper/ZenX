import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/components/chat_bubble.dart';
import 'package:zenx/components/message_input.dart';
import 'package:zenx/components/typing_indicator.dart';
import 'package:zenx/models/message.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/api/api_service.dart';
import 'package:zenx/models/api_config.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/states/assistant_provider.dart';
import 'package:zenx/states/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  ApiConfig _getActiveApiConfig() {
    // 从Provider获取当前助手
    final currentAssistant = ref.read(currentAssistantProvider);
    final modelConfig = currentAssistant.modelConfig;
    final settings = ref.read(settingsProvider);
    final apiKeys = settings.apiKeys;
    
    String provider = modelConfig.apiProvider;
    
    // 处理API key名称的变体
    String apiKeyName = provider;
    String urlKeyName = '${provider}_url';
    
    // 特殊处理OpenAI兼容API的键名
    if (provider == 'openai-compatible') {
      // 检查可能的键名变体 
      if (!apiKeys.containsKey('openai-compatible') && apiKeys.containsKey('openai_compatible')) {
        apiKeyName = 'openai_compatible';
      }
      if (!apiKeys.containsKey('openai-compatible_url') && apiKeys.containsKey('openai_compatible_url')) {
        urlKeyName = 'openai_compatible_url';
      }
    }
    
    String apiKey = apiKeys[apiKeyName] ?? '';
    String baseUrl = apiKeys[urlKeyName] ?? 'https://api.openai.com/v1';
    String model = modelConfig.modelName;
    
    final headers = {'Content-Type': 'application/json'};
    
    // DEBUG: 打印API配置信息
    print("==== Chat API Config Debug ====");
    print("Provider: $provider | API Key Name: $apiKeyName | URL Key Name: $urlKeyName");
    print("API Key: ${apiKey.isNotEmpty ? '已设置' : '空'} | Base URL: ${baseUrl != 'https://api.openai.com/v1' ? '已设置' : '默认'}");
    print("Model: $model");
    print("============================");
    
    return ApiConfig(
      provider: provider,
      apiKey: apiKey,
      baseUrl: baseUrl,
      model: model,
      headers: headers,
    );
  }
  
  MessageHistory _buildMessageHistory() {
    // 从Provider获取当前消息
    final currentMessages = ref.read(currentMessagesProvider);
    
    final history = <ChatMessage>[];
    for (final message in currentMessages) {
      history.add(
        ChatMessage(
          content: message.content,
          isUser: message.isUser,
        ),
      );
    }
    return MessageHistory(messages: history);
  }
  
  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    // 添加用户消息
    addMessage(ref, userMessage);
    
    // 设置输入状态
    ref.read(isTypingProvider.notifier).state = true;
    
    // 自动滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // 获取API配置
    final apiConfig = _getActiveApiConfig();
    final enableStreaming = ref.read(streamingResponsesProvider);
    
    if (apiConfig.apiKey.isEmpty) {
      // 还没有配置API
      ref.read(isTypingProvider.notifier).state = false;
      
      // 添加错误提示
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '请先在设置中配置AI提供商的API密钥。',
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(ref, errorMessage);
      return;
    }
    
    try {
      // 创建一个空的AI回复消息
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      // 添加到消息列表
      addMessage(ref, aiMessage);
      
      // 发送请求到API
      final response = await _apiService.sendMessage(
        message: text,
        history: _buildMessageHistory(),
        config: apiConfig,
      );
      
      // 处理流式响应
      String fullContent = '';
      response.textStream.listen(
        (chunk) {
          fullContent += chunk;
          if (enableStreaming) {
            // 如果启用了流式响应，则实时更新UI
            final messages = ref.read(currentMessagesProvider);
            final index = messages.indexWhere((m) => m.id == aiMessage.id);
            
            if (index != -1) {
              final updatedMessages = [...messages];
              updatedMessages[index] = messages[index].copyWith(content: fullContent);
              ref.read(currentMessagesProvider.notifier).state = updatedMessages;
            }
          }
        },
        onDone: () {
          // 先确保消息内容已更新
          final messages = ref.read(currentMessagesProvider);
          final index = messages.indexWhere((m) => m.id == aiMessage.id);
          
          if (index != -1) {
            // 如果没有启用流式响应或需要最终更新
            final updatedMessages = [...messages];
            updatedMessages[index] = messages[index].copyWith(content: fullContent);
            ref.read(currentMessagesProvider.notifier).state = updatedMessages;
            
            // 延迟一帧后再关闭输入状态，确保UI已更新
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 设置输入完成状态
              ref.read(isTypingProvider.notifier).state = false;
              
              // 自动保存会话
              saveCurrentSession(ref);
              
              // 自动滚动到底部
              _scrollToBottom();
            });
          } else {
            // 如果找不到消息，直接关闭状态
            ref.read(isTypingProvider.notifier).state = false;
          }
        },
        onError: (error) {
          ref.read(isTypingProvider.notifier).state = false;
          
          final messages = ref.read(currentMessagesProvider);
          final index = messages.indexWhere((m) => m.id == aiMessage.id);
          
          if (index != -1) {
            final updatedMessages = [...messages];
            updatedMessages[index] = messages[index].copyWith(
              content: '发生错误: $error',
            );
            ref.read(currentMessagesProvider.notifier).state = updatedMessages;
          }
        },
      );
    } catch (e) {
      ref.read(isTypingProvider.notifier).state = false;
      
      // 添加错误消息
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '发生错误: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(ref, errorMessage);
    }
  }
  
  void _toggleFunctionPanel() {
    // TODO: 实现功能面板（如图片上传等）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('功能面板待实现')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // 从Provider获取消息列表和输入状态
    final messages = ref.watch(currentMessagesProvider);
    final isTyping = ref.watch(isTypingProvider);
    
    return Column(
      children: [
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : _buildMessageList(messages, isTyping),
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
  
  Widget _buildMessageList(List<Message> messages, bool isTyping) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: AppTheme.smallPadding),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: messages[index]);
      },
    );
  }
  
  // 检查是否已有空的AI消息（表示正在响应中）
  bool _hasEmptyAIMessage(List<Message> messages) {
    return messages.any((message) => !message.isUser && message.content.isEmpty);
  }
} 