import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'package:zenx/models/chat_session.dart';
import 'package:zenx/models/message.dart';

/// 存储工具类，负责应用的持久化存储
class StorageUtils {
  static bool _initialized = false;
  static const String _chatSessionsBoxName = 'chat_sessions';
  
  /// 初始化Hive存储
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // 初始化Hive for Flutter
      await Hive.initFlutter();
      
      // 打开存储盒子
      await Hive.openBox<String>(_chatSessionsBoxName);
      
      _initialized = true;
      debugPrint('Hive存储初始化成功');
    } catch (e) {
      debugPrint('Hive存储初始化失败: $e');
      rethrow;
    }
  }
  
  /// 保存会话列表
  static Future<void> saveChatSessions(List<ChatSession> sessions) async {
    if (!_initialized) await initialize();
    
    try {
      final box = Hive.box<String>(_chatSessionsBoxName);
      
      // 将会话列表转换为JSON字符串列表
      final sessionsJson = sessions.map((session) => _sessionToJson(session)).toList();
      
      // 保存到Hive
      await box.put('all_sessions', jsonEncode(sessionsJson));
      debugPrint('保存了 ${sessions.length} 个会话');
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
  }
  
  /// 加载所有会话
  static Future<List<ChatSession>> loadChatSessions() async {
    if (!_initialized) await initialize();
    
    try {
      final box = Hive.box<String>(_chatSessionsBoxName);
      final jsonString = box.get('all_sessions');
      
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('没有发现保存的会话');
        return [];
      }
      
      // 解析JSON
      final List<dynamic> sessionsJson = jsonDecode(jsonString);
      final sessions = sessionsJson.map((json) => _sessionFromJson(json)).toList();
      
      debugPrint('加载了 ${sessions.length} 个会话');
      return sessions;
    } catch (e) {
      debugPrint('加载会话失败: $e');
      return [];
    }
  }
  
  /// 将ChatSession转换为JSON
  static Map<String, dynamic> _sessionToJson(ChatSession session) {
    return {
      'id': session.id,
      'title': session.title,
      'createdAt': session.createdAt.millisecondsSinceEpoch,
      'lastUpdatedAt': session.lastUpdatedAt.millisecondsSinceEpoch,
      'assistantId': session.assistantId,
      'messages': session.messages.map((msg) => _messageToJson(msg)).toList(),
    };
  }
  
  /// 从JSON创建ChatSession
  static ChatSession _sessionFromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(json['lastUpdatedAt']),
      assistantId: json['assistantId'],
      messages: (json['messages'] as List)
          .map((msgJson) => _messageFromJson(msgJson))
          .toList(),
    );
  }
  
  /// 将Message转换为JSON
  static Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'content': message.content,
      'isUser': message.isUser,
      'timestamp': message.timestamp.millisecondsSinceEpoch,
    };
  }
  
  /// 从JSON创建Message
  static Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }
} 