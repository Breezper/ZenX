import 'package:zenx/models/chat_session.dart';

class Assistant {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final String iconPath;
  final List<ChatSession> chatSessions;
  final ApiModelConfig modelConfig;
  
  Assistant({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    required this.iconPath,
    required this.modelConfig,
    this.chatSessions = const [],
  });
}

class ApiModelConfig {
  final String apiProvider; // e.g., "openai", "anthropic"
  final String modelName;   // e.g., "gpt-4o", "claude-3-opus"
  final int contextLength;
  final bool streamingEnabled;
  final Map<String, dynamic> additionalParams;
  
  ApiModelConfig({
    required this.apiProvider,
    required this.modelName,
    this.contextLength = 4000,
    this.streamingEnabled = true,
    this.additionalParams = const {},
  });
} 