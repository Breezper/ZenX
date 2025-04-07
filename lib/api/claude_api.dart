import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/models/api_config.dart';

/// Claude API实现
class ClaudeAPI extends BaseChatAPI {
  // Claude API默认基础URL
  static const String defaultBaseUrl = 'https://api.anthropic.com';
  
  @override
  String get vendorName => 'Claude';
  
  @override
  Color get brandColor => const Color(0xFF5436DA); // Claude品牌紫色
  
  @override
  List<String> get supportedModels => [
    'claude-3-opus-20240229',
    'claude-3-sonnet-20240229',
    'claude-3-haiku-20240307',
    'claude-2.1',
    'claude-2.0',
    'claude-instant-1.2',
  ];
  
  @override
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    final dio = Dio();
    
    // 设置请求头
    dio.options.headers['x-api-key'] = config.apiKey; // Claude使用x-api-key作为头部
    dio.options.headers['anthropic-version'] = '2023-06-01'; // Claude API版本
    dio.options.headers['Content-Type'] = 'application/json';
    
    // 准备消息列表
    List<Map<String, dynamic>> messages = [];
    
    // 找出系统消息（如果有）
    String? systemMessage;
    for (final msg in history.messages) {
      if (msg.metadata != null && msg.metadata!['role'] == 'system') {
        systemMessage = msg.content;
        break;
      }
    }
    
    // 添加历史消息（不包括系统消息）
    for (final msg in history.messages) {
      if (msg.metadata == null || msg.metadata!['role'] != 'system') {
        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }
    
    // 添加当前消息
    messages.add({
      'role': 'user',
      'content': message,
    });
    
    // 准备请求体
    final Map<String, dynamic> requestBody = {
      'model': config.model,
      'messages': messages,
      'stream': true,
      'temperature': 0.7,
      'max_tokens': 4000,
    };
    
    // 如果有系统消息，添加到请求中
    if (systemMessage != null) {
      requestBody['system'] = systemMessage;
    }
    
    final streamController = StreamController<String>();
    
    try {
      // 使用提供的baseUrl或默认基础URL
      final baseUrl = config.baseUrl.isEmpty ? defaultBaseUrl : config.baseUrl;
      
      print("发送请求到Claude API: $baseUrl/v1/messages");
      print("请求体: ${jsonEncode(requestBody)}");
      
      final response = await dio.post(
        '$baseUrl/v1/messages',
        data: requestBody,
        options: Options(
          responseType: ResponseType.stream,
        ),
      );
      
      // 获取响应流
      final responseStream = response.data.stream as Stream<List<int>>;
      
      // 用于辅助处理UTF-8编码的转换器
      final utf8Decoder = Utf8Decoder();
      
      // 缓存接收到的消息片段
      String fullContent = '';
      String buffer = '';
      
      // 处理流式响应
      responseStream.listen(
        (List<int> chunk) {
          try {
            // 使用UTF-8解码器处理字节数据
            final chunkString = utf8Decoder.convert(chunk);
            print("接收到Claude流式响应片段: $chunkString");
            
            // 添加到缓冲区
            buffer += chunkString;
            
            // 处理缓冲区中的数据行
            while (buffer.contains('\n')) {
              final lineEnd = buffer.indexOf('\n');
              String line = buffer.substring(0, lineEnd).trim();
              buffer = buffer.substring(lineEnd + 1);
              
              // 跳过空行和data: [DONE]
              if (line.isEmpty || line == 'data: [DONE]') {
                continue;
              }
              
              // 移除 "data: " 前缀
              if (line.startsWith('data: ')) {
                line = line.substring(6);
                
                try {
                  // 解析JSON
                  final Map<String, dynamic> data = jsonDecode(line);
                  
                  if (data.containsKey('type') && data['type'] == 'content_block_delta') {
                    if (data.containsKey('delta') && 
                        data['delta'] is Map && 
                        data['delta'].containsKey('text')) {
                      final textDelta = data['delta']['text'] ?? '';
                      
                      if (textDelta.isNotEmpty) {
                        // 添加到完整内容中
                        fullContent += textDelta;
                        // 发送完整内容
                        streamController.add(textDelta);
                      }
                    }
                  }
                } catch (e) {
                  print("解析Claude流式响应失败: $e, 原始数据: $line");
                }
              }
            }
          } catch (e) {
            print("处理Claude流式响应片段出错: $e");
          }
        },
        onDone: () {
          print("Claude流式响应完成，完整内容: $fullContent");
          if (!streamController.isClosed) {
            streamController.close();
          }
        },
        onError: (e) {
          print("Claude流式响应出错: $e");
          if (!streamController.isClosed) {
            streamController.addError('Claude流式响应出错: $e');
            streamController.close();
          }
        },
        cancelOnError: true,
      );
      
      return StreamedResponse(textStream: streamController.stream);
    } catch (e) {
      final errorMsg = '发送消息到Claude API失败: $e';
      print(errorMsg);
      streamController.addError(errorMsg);
      streamController.close();
      return StreamedResponse(textStream: streamController.stream);
    }
  }
  
  @override
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      return false;
    }
    
    try {
      final dio = Dio();
      dio.options.headers['x-api-key'] = apiKey;
      dio.options.headers['anthropic-version'] = '2023-06-01';
      
      // Claude API没有直接的模型列表端点，我们尝试发送一个极短的消息来验证
      final response = await dio.post(
        '$defaultBaseUrl/v1/messages',
        data: {
          'model': 'claude-3-haiku-20240307',
          'messages': [{'role': 'user', 'content': 'Hi'}],
          'max_tokens': 1,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('验证Claude API密钥失败: $e');
      return false;
    }
  }
} 