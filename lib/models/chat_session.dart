import 'package:zenx/models/message.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final List<Message> messages;
  final String assistantId;
  
  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.assistantId,
    DateTime? lastUpdatedAt,
    this.messages = const [],
  }) : this.lastUpdatedAt = lastUpdatedAt ?? createdAt;
} 