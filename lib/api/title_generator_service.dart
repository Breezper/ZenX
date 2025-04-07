import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/models/message.dart';

/// Title Generator Service for chat sessions
class TitleGeneratorService {
  final Dio _dio = Dio();
  final String apiKey;
  final String baseUrl;
  final String model;
  
  TitleGeneratorService({
    required this.apiKey,
    required this.baseUrl,
    this.model = 'gpt-3.5-turbo',
  });

  /// Generate a title based on chat messages
  Future<String> generateTitle(List<Message> messages) async {
    try {
      if (messages.length < 2) {
        return '新对话';
      }

      // Format messages for the API request
      final formattedMessages = messages.take(3).map((msg) => {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      }).toList();

      // Build request
      final Map<String, dynamic> request = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': '你是一个标题生成助手。请为以下对话生成一个简短、有描述性的标题（不超过15个字）。标题应该反映对话的主题和内容，不要包含"对话"、"聊天"等词语。直接返回标题文本，不要有任何前缀或额外解释。'
          },
        ],
        'temperature': 0.7,
        'max_tokens': 30,
      };
      
      // Add the message contents
      request['messages'].addAll(formattedMessages);

      // Debug log
      debugPrint('正在生成标题，API URL: $baseUrl, 模型: $model');
      
      // Make the API call
      final response = await _dio.post(
        '$baseUrl/chat/completions',
        data: request,
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final String title = response.data['choices'][0]['message']['content'];
        return title.trim();
      }
      
      return '新对话 ${DateTime.now().hour}:${DateTime.now().minute}';
    } catch (e) {
      debugPrint('标题生成错误: $e');
      return '新对话 ${DateTime.now().hour}:${DateTime.now().minute}';
    }
  }
  
  /// 获取可用的模型列表
  /// 从API提供商获取可用的模型
  static Future<List<String>> fetchAvailableModels(String baseUrl, String apiKey) async {
    try {
      debugPrint('正在获取模型列表，API URL: $baseUrl');
      final dio = Dio();
      
      // 尝试获取模型列表
      final response = await dio.get(
        '$baseUrl/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> models = response.data['data'];
        // 过滤出适合聊天的模型（通常包含"gpt"或"chat"关键字）
        final chatModels = models
            .where((model) => 
                model['id'] != null && 
                (model['id'].toString().contains('gpt') || 
                model['id'].toString().contains('chat') ||
                model['id'].toString().contains('claude') ||
                model['id'].toString().contains('-3')))
            .map((model) => model['id'].toString())
            .toList();
        
        // 对结果进行排序
        chatModels.sort();
        
        debugPrint('找到${chatModels.length}个可用的聊天模型');
        return chatModels;
      }
      
      // 如果API调用成功但未返回预期结构，返回默认模型
      return ['gpt-3.5-turbo', 'gpt-4'];
    } catch (e) {
      debugPrint('获取模型列表时出错: $e');
      // 出错时返回常见模型作为默认值
      return ['gpt-3.5-turbo', 'gpt-4'];
    }
  }
} 