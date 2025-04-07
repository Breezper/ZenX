import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zenx/api/base_chat_api.dart';
import 'package:zenx/models/api_config.dart';

/// OpenAI兼容API实现
/// 支持任何遵循OpenAI API规范的服务商，如Azure OpenAI, Local AI, LMStudio, Custom API等
class OpenAICompatibleAPI extends BaseChatAPI {
  final List<String> _cachedModels = [];
  final Dio _dio = Dio();
  
  @override
  String get vendorName => 'OpenAI兼容';
  
  @override
  Color get brandColor => const Color(0xFF6B46C1); // 紫色，区别于官方OpenAI

  @override
  List<String> get supportedModels {
    // 如果未获取到模型，返回默认模型列表
    if (_cachedModels.isEmpty) {
      return ['gpt-3.5-turbo', 'gpt-4', 'custom-model'];
    }
    return _cachedModels;
  }
  
  /// 确保baseUrl正确包含/v1路径
  String _normalizeBaseUrl(String url) {
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    if (!url.endsWith('/v1')) {
      return '$url/v1';
    }
    
    return url;
  }
  
  /// 获取可用模型列表
  Future<List<String>> fetchModels(ApiConfig config) async {
    try {
      final normalizedBaseUrl = _normalizeBaseUrl(config.baseUrl);
      _dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
      
      // Add timeout to avoid hanging
      _dio.options.connectTimeout = const Duration(seconds: 10);
      _dio.options.receiveTimeout = const Duration(seconds: 10);
      
      print('Fetching models from: $normalizedBaseUrl/models');
      
      final response = await _dio.get(
        '$normalizedBaseUrl/models',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        print('Models fetched successfully');
        try {
          if (response.data is Map && response.data.containsKey('data')) {
            final List<dynamic> models = response.data['data'];
            
            if (models.isEmpty) {
              print('API returned empty models list');
              return supportedModels;
            }
            
            final List<String> modelIds = models
                .map<String>((model) => model['id'].toString())
                .toList();
            
            print('Found ${modelIds.length} models: ${modelIds.join(', ')}');
            
            // 缓存获取到的模型列表
            _cachedModels.clear();
            _cachedModels.addAll(modelIds);
            
            return modelIds;
          } else {
            print('Unexpected response format: ${response.data}');
          }
        } catch (parseError) {
          print('Error parsing models response: $parseError');
          print('Response data: ${response.data}');
        }
      } else {
        print('Failed to fetch models, status: ${response.statusCode}');
        print('Response data: ${response.data}');
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    
    return supportedModels;
  }

  @override
  Future<StreamedResponse> sendMessage({
    required String message,
    required MessageHistory history,
    required ApiConfig config,
  }) async {
    final normalizedBaseUrl = _normalizeBaseUrl(config.baseUrl);
    
    // 设置请求头
    _dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
    _dio.options.headers['Content-Type'] = 'application/json';
    
    // 添加用户自定义headers
    if (config.headers.isNotEmpty) {
      config.headers.forEach((key, value) {
        _dio.options.headers[key] = value;
      });
    }
    
    final List<Map<String, dynamic>> messages = [];
    
    // 添加历史消息
    for (final msg in history.messages) {
      // 检查是否是系统提示词消息
      if (msg.metadata != null && msg.metadata!['role'] == 'system') {
        messages.add({
          'role': 'system',
          'content': msg.content,
        });
      } else {
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
    
    try {
      final response = await _dio.post(
        '$normalizedBaseUrl/chat/completions',
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
            if (line.isEmpty) continue;
            
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
          streamController.addError('连接API出错: $error');
          streamController.close();
        },
      );
      
      return StreamedResponse(textStream: streamController.stream);
    } catch (e) {
      // 创建错误流
      final errorStreamController = StreamController<String>();
      errorStreamController.addError('API请求失败: $e');
      errorStreamController.close();
      
      return StreamedResponse(textStream: errorStreamController.stream);
    }
  }
  
  @override
  Future<bool> validateApiKey(String apiKey) async {
    try {
      _dio.options.headers['Authorization'] = 'Bearer $apiKey';
      
      // We can't validate with just an API key since we also need a base URL
      // So we'll use a default URL for basic validation
      final response = await _dio.get('https://api.openai.com/v1/models');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // 覆盖验证方法，使用完整的配置进行验证
  Future<bool> validateConfig(ApiConfig config) async {
    try {
      final normalizedBaseUrl = _normalizeBaseUrl(config.baseUrl);
      _dio.options.headers['Authorization'] = 'Bearer ${config.apiKey}';
      
      // Add timeout to avoid hanging
      _dio.options.connectTimeout = const Duration(seconds: 10);
      _dio.options.receiveTimeout = const Duration(seconds: 10);
      
      print('Validating API at: $normalizedBaseUrl/models');
      
      final response = await _dio.get(
        '$normalizedBaseUrl/models',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode == 200) {
        print('API validation successful');
        // 顺便获取模型列表
        await fetchModels(config);
        return true;
      } else {
        print('API validation failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API validation error: $e');
      return false;
    }
  }
} 