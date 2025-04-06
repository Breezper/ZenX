import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/models/api_config.dart';

/// OpenAI API实现
class OpenAIAPI extends BaseChatAPI {
  @override
  String get vendorName => 'OpenAI';
  
  @override
  Color get brandColor => const Color(0xFF10A37F); // OpenAI绿色
  
  @override
  List<String> get supportedModels => [
    'gpt-4o',
    'gpt-4-turbo',
    'gpt-3.5-turbo',
  ];
  
  @override
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    final dio = Dio();
    
    // 设置请求头
    dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
    dio.options.headers['Content-Type'] = 'application/json';
    
    final List<Map<String, dynamic>> messages = [];
    
    // 添加历史消息
    for (final msg in history.messages) {
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      });
    }
    
    // 添加当前消息
    messages.add({
      'role': 'user',
      'content': message,
    });
    
    try {
      final response = await dio.post(
        '${config.baseUrl}/chat/completions',
        data: {
          'model': config.model,
          'messages': messages,
          'stream': true,
          'temperature': 0.7,
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );
      
      // 处理流式响应
      final streamController = StreamController<String>();
      
      response.data.stream.listen(
        (data) {
          final String text = utf8.decode(data);
          final List<String> lines = text.split('\n');
          
          for (var line in lines) {
            if (line.startsWith('data: ') && line != 'data: [DONE]') {
              final jsonData = line.substring(6);
              try {
                final Map<String, dynamic> json = jsonDecode(jsonData);
                final choice = json['choices'][0];
                final content = choice['delta']['content'];
                if (content != null) {
                  streamController.add(content);
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          }
        },
        onDone: () {
          streamController.close();
        },
        onError: (error) {
          streamController.addError(error);
          streamController.close();
        },
      );
      
      return StreamedResponse(textStream: streamController.stream);
    } catch (e) {
      // 创建错误流
      final errorStreamController = StreamController<String>();
      errorStreamController.addError(e);
      errorStreamController.close();
      
      return StreamedResponse(textStream: errorStreamController.stream);
    }
  }
  
  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $apiKey';
      
      final response = await dio.get('https://api.openai.com/v1/models');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 