import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/api/deepseek_api.dart';
import 'package:zenx/models/api_config.dart';

/// 通用自定义API实现
/// 支持OpenAI兼容格式和自定义格式
class CustomAPI extends BaseChatAPI {
  final String _name;
  final Color _brandColor;
  final List<String> _supportedModels;
  late final DeepSeekAPI _deepSeekAPI = DeepSeekAPI();
  
  CustomAPI({
    required String name,
    Color? brandColor,
    List<String>? supportedModels,
  }) : 
    _name = name,
    _brandColor = brandColor ?? Colors.grey,
    _supportedModels = supportedModels ?? [];
  
  @override
  String get vendorName => _name;
  
  @override
  Color get brandColor => _brandColor;
  
  @override
  List<String> get supportedModels => _supportedModels;
  
  /// 检查是否是DeepSeek API
  bool _isDeepSeek(String provider) {
    return provider.toLowerCase() == 'deepseek' || _name.toLowerCase() == 'deepseek';
  }
  
  @override
  Future<bool> validateApiKey(String apiKey) async {
    print("CustomAPI.validateApiKey - API名称: $_name, 密钥长度: ${apiKey.length}");
    
    if (apiKey.isEmpty) {
      print("CustomAPI.validateApiKey - 密钥为空，验证失败");
      return false;
    }
    
    // 如果是DeepSeek API，使用专用实现
    if (_isDeepSeek(_name)) {
      return _deepSeekAPI.validateApiKey(apiKey);
    }
    
    // 对于自定义API，我们简化验证，总是返回true
    // 实际验证将在sendMessage时进行
    print("CustomAPI.validateApiKey - 验证成功 (简化验证逻辑)");
    return true;
  }
  
  @override
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    // 如果是DeepSeek API，使用专用实现
    if (_isDeepSeek(config.provider)) {
      return _deepSeekAPI.sendMessage(message: message, history: history, config: config);
    }
    
    final streamController = StreamController<String>();
    
    try {
      // 准备请求体数据
      final requestBody = _prepareRequestBody(message, history, config);
      
      print("发送请求到 ${config.provider} API: ${config.baseUrl}/chat/completions");
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
                  
                  // OpenAI兼容格式处理
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
                      // 只发送增量部分，不累积内容
                      print("发送增量更新: $content");
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
      final errorMsg = '发送消息到 ${config.provider} API失败: $e';
      print(errorMsg);
      streamController.addError(errorMsg);
      streamController.close();
      return StreamedResponse(textStream: streamController.stream);
    }
  }
  
  // 准备API请求主体
  Map<String, dynamic> _prepareRequestBody(
    String message, 
    MessageHistory history,
    ApiConfig config,
  ) {
    // 如果是DeepSeek API，使用专用实现
    if (_isDeepSeek(config.provider)) {
      return _deepSeekAPI.prepareRequestBody(message, history, config);
    }
    
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
    String modelName = config.provider;
    
    // 检查是否有存储在config.model中的模型名称
    if (config.model != null && config.model.isNotEmpty) {
      modelName = config.model;
    }
    
    // 返回请求体
    return {
      'model': modelName,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
      'stream': true, // 启用流式响应
    };
  }
  
  // 获取API支持的模型列表
  Future<List<String>> fetchModels(ApiConfig config) async {
    // 如果是DeepSeek API，使用专用实现
    if (_isDeepSeek(config.provider)) {
      return _deepSeekAPI.fetchModels(config);
    }
    
    // 非DeepSeek API的处理逻辑
    try {
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
        final Map<String, dynamic> data = response.data;
        
        if (data.containsKey('data') && data['data'] is List) {
          final List<dynamic> models = data['data'];
          final modelList = models.map((model) => model['id'].toString()).toList();
          
          if (modelList.isNotEmpty) {
            return modelList;
          }
        }
      }
      
      // 如果无法获取模型列表或列表为空，返回默认模型
      return ['custom-model'];
    } catch (e) {
      print('获取模型列表失败: $e');
      // 出错时也返回默认模型
      return ['custom-model'];
    }
  }
  
  // 验证API配置
  Future<bool> validateConfig(ApiConfig config) async {
    // 如果是DeepSeek API，使用专用实现
    if (_isDeepSeek(config.provider)) {
      return _deepSeekAPI.validateConfig(config);
    }
    
    // 普通API验证
    try {
      print("验证API配置: provider=${config.provider}, baseUrl=${config.baseUrl}");
      
      final response = await Dio().get(
        '${config.baseUrl}/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            ...config.headers,
          },
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('验证API配置失败: $e');
      return false;
    }
  }
} 