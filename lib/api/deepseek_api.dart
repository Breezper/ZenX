import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/models/api_config.dart';

/// DeepSeek API实现 - 预设配置
class DeepSeekAPI extends BaseChatAPI {
  // DeepSeek预设模型列表
  static const List<String> defaultModels = [
    'deepseek-chat',
    'deepseek-coder',
    'deepseek-lite',
    'deepseek-llm-67b-chat',
    'deepseek-coder-33b-instruct'
  ];

  // DeepSeek品牌颜色
  static const Color defaultBrandColor = Color(0xFF0066CC);
  
  @override
  String get vendorName => 'DeepSeek';
  
  @override
  Color get brandColor => DeepSeekAPI.defaultBrandColor;
  
  @override
  List<String> get supportedModels => DeepSeekAPI.defaultModels;
  
  @override
  Future<bool> validateApiKey(String apiKey) async {
    print("DeepSeekAPI.validateApiKey - 密钥长度: ${apiKey.length}");
    
    if (apiKey.isEmpty) {
      print("DeepSeekAPI.validateApiKey - 密钥为空，验证失败");
      return false;
    }
    
    // 简化验证，密钥不为空则视为有效
    print("DeepSeekAPI.validateApiKey - 验证成功 (简化验证逻辑)");
    return true;
  }
  
  @override
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    final streamController = StreamController<String>();
    
    try {
      // 准备请求体数据
      final requestBody = prepareRequestBody(message, history, config);
      
      print("发送请求到 DeepSeek API: ${config.baseUrl}/chat/completions");
      print("请求体: ${requestBody.toString()}");
      
      // 使用Dio处理流式响应
      final dio = Dio();
      
      // 使用responseType: ResponseType.stream来处理流式响应
      final response = await dio.post(
        '${config.baseUrl}/chat/completions',
        data: requestBody,
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
            ...config.headers,
          },
          responseType: ResponseType.stream, // 设置响应类型为流
        ),
      );
      
      print("开始接收流式响应");
      
      // 获取响应流
      final responseStream = response.data.stream as Stream<List<int>>;
      
      // 用于辅助处理UTF-8编码的转换器
      final utf8Decoder = Utf8Decoder();
      
      // 缓存接收到的消息片段
      String buffer = '';
      
      // 处理流式响应
      responseStream.listen(
        (List<int> chunk) {
          try {
            // 使用UTF-8解码器处理字节数据
            final chunkString = utf8Decoder.convert(chunk);
            print("接收到流式响应片段 (UTF-8解码后): $chunkString");
            
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
                  
                  // 处理DeepSeek格式
                  if (data.containsKey('choices') && 
                      data['choices'] is List && 
                      data['choices'].isNotEmpty) {
                    
                    final choice = data['choices'][0];
                    String content = '';
                    
                    // 处理增量消息
                    if (choice.containsKey('delta') && 
                        choice['delta'] is Map && 
                        choice['delta'].containsKey('content')) {
                      content = choice['delta']['content'] ?? '';
                    }
                    // 处理完整消息
                    else if (choice.containsKey('message') && 
                             choice['message'] is Map && 
                             choice['message'].containsKey('content')) {
                      content = choice['message']['content'] ?? '';
                    }
                    
                    if (content.isNotEmpty) {
                      // 只发送增量部分，不累积
                      print("发送DeepSeek增量更新: $content");
                      streamController.add(content);
                    }
                  }
                } catch (e) {
                  print("解析流式响应失败: $e, 原始数据: $line");
                }
              }
            }
          } catch (e) {
            print("处理流式响应片段出错: $e");
          }
        },
        onDone: () {
          print("流式响应完成");
          if (!streamController.isClosed) {
            streamController.close();
          }
        },
        onError: (e) {
          print("流式响应出错: $e");
          if (!streamController.isClosed) {
            streamController.addError('流式响应出错: $e');
            streamController.close();
          }
        },
        cancelOnError: true,
      );
      
      return StreamedResponse(textStream: streamController.stream);
    } catch (e) {
      final errorMsg = '发送消息到 DeepSeek API失败: $e';
      print(errorMsg);
      streamController.addError(errorMsg);
      streamController.close();
      return StreamedResponse(textStream: streamController.stream);
    }
  }
  
  // 准备DeepSeek API请求主体
  Map<String, dynamic> prepareRequestBody(
    String message, 
    MessageHistory history,
    ApiConfig config,
  ) {
    // 转换历史消息为OpenAI兼容格式
    final messages = history.messages.map((msg) {
      // 检查是否是系统提示词消息
      if (msg.metadata != null && msg.metadata!['role'] == 'system') {
        return {
          'role': 'system',
          'content': msg.content,
        };
      } else {
        return {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        };
      }
    }).toList();
    
    // 添加当前消息
    messages.add({
      'role': 'user',
      'content': message,
    });
    
    // 获取正确的模型名称
    String modelName = 'deepseek-chat'; // 默认模型
    
    // 检查是否有存储在config.model中的模型名称
    if (config.model?.isNotEmpty == true) {
      modelName = config.model!;
    }
    
    // 返回请求体，带有DeepSeek特定参数
    return {
      'model': modelName,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
      'stream': true, // 启用流式响应
      'top_p': 0.8,  // DeepSeek特定参数
    };
  }
  
  // 获取DeepSeek API支持的模型列表
  Future<List<String>> fetchModels(ApiConfig config) async {
    print("获取DeepSeek API支持的模型列表");
    try {
      // 尝试使用models端点获取模型列表
      final response = await Dio().get(
        '${config.baseUrl}/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            ...config.headers,
          },
        ),
      );
      
      if (response.statusCode == 200) {
        print("DeepSeek API返回模型列表: ${response.data}");
        
        final Map<String, dynamic> data = response.data;
        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> models = data['data'];
          final modelList = models.map((model) => model['id'].toString()).toList();
          
          if (modelList.isNotEmpty) {
            return modelList;
          }
        }
      }
      
    } catch (e) {
      print('获取DeepSeek模型列表失败: $e');
    }
    
    // 返回预设模型列表
    return DeepSeekAPI.defaultModels;
  }
  
  // 验证DeepSeek API配置
  Future<bool> validateConfig(ApiConfig config) async {
    try {
      print("验证DeepSeek API配置: baseUrl=${config.baseUrl}");
      
      // 尝试获取模型列表
      final response = await Dio().get(
        '${config.baseUrl}/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
            ...config.headers,
          },
        ),
      );
      
      final bool isValid = response.statusCode == 200;
      print("DeepSeek API验证结果: $isValid, 状态码: ${response.statusCode}");
      
      if (isValid) {
        try {
          // 记录支持的模型
          final data = response.data;
          print("DeepSeek API支持的模型: ${data.toString()}");
        } catch (e) {
          // 忽略打印错误
        }
      }
      
      return isValid;
    } catch (e) {
      print('验证DeepSeek API配置失败: $e');
      // 即使验证失败，也允许通过，因为有些服务器可能没有models端点或有限制
      print("DeepSeek API验证失败，但仍允许使用");
      return true;
    }
  }
} 