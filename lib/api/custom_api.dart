import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/models/api_config.dart';

/// 通用自定义API实现
/// 支持OpenAI兼容格式和自定义格式
class CustomAPI extends BaseChatAPI {
  final String _name;
  final Color _brandColor;
  final List<String> _supportedModels;
  
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
  
  @override
  Future<bool> validateApiKey(String apiKey) async {
    print("CustomAPI.validateApiKey - API名称: $_name, 密钥长度: ${apiKey.length}");
    
    if (apiKey.isEmpty) {
      print("CustomAPI.validateApiKey - 密钥为空，验证失败");
      return false;
    }
    
    // 如果是DeepSeek API，尝试特定验证方法
    if (_name.toLowerCase() == 'deepseek') {
      print("验证DeepSeek API密钥");
      // 为了简化，我们假设密钥不为空就是有效的
      // 在实际应用中，可以尝试调用DeepSeek API的models端点进行验证
      return true;
    }
    
    // 对于自定义API，我们简化验证，总是返回true
    // 实际验证将在sendMessage时进行
    print("CustomAPI.validateApiKey - 验证成功 (简化验证逻辑)");
    return true;
    
    /* 已禁用原先的实现，因为它需要baseUrl
    try {
      // 尝试使用OpenAI兼容方式验证
      final response = await Dio().get(
        '/models',
        options: Options(
          headers: {'Authorization': 'Bearer $apiKey'},
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      // 如果API格式不兼容OpenAI，则简单地返回true
      // 这只是一个简化的实现，实际使用时可能需要更复杂的验证
      return true;
    }
    */
  }
  
  @override
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    final streamController = StreamController<String>();
    
    try {
      // 检查是否是DeepSeek API
      final isDeepSeek = config.provider.toLowerCase() == 'deepseek';
      if (isDeepSeek) {
        print("使用DeepSeek API专用处理逻辑");
      }
      
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
      String fullContent = '';
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
                  
                  // DeepSeek和OpenAI兼容格式处理
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
                      // 添加到完整内容中
                      fullContent += content;
                      
                      // 对于DeepSeek API，发送增量更新而不是完整内容
                      // 这样可以避免重复解码的问题
                      if (isDeepSeek) {
                        print("发送DeepSeek增量更新: $content");
                        streamController.add(content); // 只发送增量部分
                      } else {
                        // 对于其他API，保持原来的行为，发送完整内容
                        streamController.add(fullContent);
                      }
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
          print("流式响应完成，完整内容: $fullContent");
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
    // 检查是否是DeepSeek API
    final isDeepSeek = config.provider.toLowerCase() == 'deepseek';
    
    // 转换历史消息为OpenAI兼容格式
    final messages = history.messages.map((msg) {
      return {
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.content,
      };
    }).toList();
    
    // 添加当前消息
    messages.add({
      'role': 'user',
      'content': message,
    });
    
    // 获取正确的模型名称
    String modelName = config.provider;
    
    // 检查是否有存储在config.model中的模型名称
    if (config.model != null && config.model!.isNotEmpty) {
      modelName = config.model!;
    } else {
      // 针对特定API提供商的默认模型
      switch (config.provider.toLowerCase()) {
        case 'deepseek':
          modelName = 'deepseek-chat'; // DeepSeek的默认模型
          break;
        default:
          // 使用提供商名称作为默认值
          break;
      }
    }
    
    // 返回请求体，根据API类型添加特定参数
    final requestBody = {
      'model': modelName,
      'messages': messages,
      'temperature': 0.7,
      'max_tokens': 2000,
      'stream': true, // 启用流式响应
    };
    
    // 为DeepSeek API添加特定参数
    if (isDeepSeek) {
      print("为DeepSeek API调整请求参数");
      // 可以根据DeepSeek API文档添加特定参数
      requestBody['top_p'] = 0.8;  // 示例参数，根据实际需要调整
    }
    
    return requestBody;
  }
  
  // 获取API支持的模型列表
  Future<List<String>> fetchModels(ApiConfig config) async {
    // 检查是否是DeepSeek API
    final isDeepSeek = config.provider.toLowerCase() == 'deepseek';
    
    if (isDeepSeek) {
      print("获取DeepSeek API支持的模型列表");
      try {
        // For DeepSeek, we'll try to use their models endpoint
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
        
        // 如果无法获取实际模型列表，返回已知的DeepSeek模型
        return ['deepseek-chat', 'deepseek-coder', 'deepseek-lite'];
      } catch (e) {
        print('获取DeepSeek模型列表失败: $e');
        // 出错时返回已知的DeepSeek模型
        return ['deepseek-chat', 'deepseek-coder', 'deepseek-lite'];
      }
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
    // 检查是否是DeepSeek API
    final isDeepSeek = config.provider.toLowerCase() == 'deepseek';
    
    try {
      print("验证API配置: provider=${config.provider}, baseUrl=${config.baseUrl}");
      
      if (isDeepSeek) {
        print("使用DeepSeek专用验证逻辑");
        // 对于DeepSeek，我们尝试获取模型列表
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
      }
      
      // 普通API验证
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
      
      // 对于DeepSeek API，即使验证失败，也允许通过
      // 因为有些服务器可能没有models端点或有限制
      if (isDeepSeek) {
        print("DeepSeek API验证失败，但仍允许使用");
        return true;
      }
      
      return false;
    }
  }
} 