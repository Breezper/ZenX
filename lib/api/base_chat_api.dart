import 'package:flutter/material.dart';
import 'package:zenx/models/api_config.dart';

/// 流式响应包装类
class StreamedResponse {
  final Stream<String> textStream;
  final Stream<Map<String, dynamic>>? metadataStream;
  
  StreamedResponse({
    required this.textStream,
    this.metadataStream,
  });
}

/// 消息历史记录类
class MessageHistory {
  final List<ChatMessage> messages;
  
  MessageHistory({this.messages = const []});
}

/// 聊天消息类
class ChatMessage {
  final String content;
  final bool isUser;
  final Map<String, dynamic>? metadata;
  
  ChatMessage({
    required this.content,
    required this.isUser,
    this.metadata,
  });
}

/// 基础聊天API抽象类，所有API实现都必须继承此类
abstract class BaseChatAPI {
  /// 发送消息并返回流式响应
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  });
  
  /// 获取服务商名称
  String get vendorName;
  
  /// 获取品牌颜色
  Color get brandColor;
  
  /// 获取支持的模型列表
  List<String> get supportedModels;
  
  /// 检查API配置是否有效
  Future<bool> validateApiKey(String apiKey);
} 