import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/models/message.dart';
import 'package:zenx/models/chat_session.dart';
import 'package:zenx/states/assistant_provider.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/api/title_generator_service.dart';
import 'package:flutter/material.dart';
import 'package:zenx/utils/storage_utils.dart';

// 当前会话ID
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

// 当前会话标题
final currentSessionTitleProvider = StateProvider<String>((ref) => '新对话');

// 当前会话消息列表
final currentMessagesProvider = StateProvider<List<Message>>((ref) => []);

// 左侧抽屉选中的标签页索引
final drawerSelectedTabProvider = StateProvider<int>((ref) => 0);

// 会话列表 - 使用StateNotifierProvider来管理
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, List<ChatSession>>((ref) {
  return ChatSessionsNotifier();
});

// 会话管理类 - 负责会话的持久化存储
class ChatSessionsNotifier extends StateNotifier<List<ChatSession>> {
  ChatSessionsNotifier() : super([]) {
    _loadSessionsFromStorage();
  }
  
  // 从存储加载会话
  Future<void> _loadSessionsFromStorage() async {
    try {
      final sessions = await StorageUtils.loadChatSessions();
      if (sessions.isNotEmpty) {
        state = sessions;
      }
    } catch (e) {
      debugPrint('加载会话失败: $e');
    }
  }
  
  // 保存会话到存储
  Future<void> _saveSessionsToStorage() async {
    try {
      await StorageUtils.saveChatSessions(state);
    } catch (e) {
      debugPrint('保存会话失败: $e');
    }
  }
  
  // 添加或更新会话
  void addOrUpdateSession(ChatSession session) {
    final existingIndex = state.indexWhere((s) => s.id == session.id);
    
    if (existingIndex >= 0) {
      // 更新现有会话
      state = [
        ...state.sublist(0, existingIndex),
        session,
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      // 添加新会话
      state = [...state, session];
    }
    
    // 保存到存储
    _saveSessionsToStorage();
  }
  
  // 删除会话
  void deleteSession(String sessionId) {
    state = state.where((session) => session.id != sessionId).toList();
    // 保存到存储
    _saveSessionsToStorage();
  }
  
  // 清空所有会话
  void clearAllSessions() {
    state = [];
    // 保存到存储
    _saveSessionsToStorage();
  }
}

// 创建新会话
void createNewSession(WidgetRef ref) {
  final currentAssistant = ref.read(currentAssistantProvider);
  
  // 设置新会话标题
  ref.read(currentSessionTitleProvider.notifier).state = '新对话';
  
  // 清空当前消息
  ref.read(currentMessagesProvider.notifier).state = [];
  
  // 设置当前会话ID为null（表示新会话）
  ref.read(currentSessionIdProvider.notifier).state = null;
  
  // 移除助手欢迎消息
  // addAssistantWelcomeMessage(ref, currentAssistant.name, currentAssistant.description);
}

// 添加消息
void addMessage(WidgetRef ref, Message message) {
  final currentMessages = ref.read(currentMessagesProvider);
  ref.read(currentMessagesProvider.notifier).state = [...currentMessages, message];
  
  // 检查是否需要生成标题
  final shouldGenerateTitle = ref.read(titleGenerationApiEnabledProvider) && 
                             ref.read(currentSessionIdProvider) == null && 
                             currentMessages.length >= 1;
  
  if (shouldGenerateTitle && !message.isUser) {
    // 在助手回复后生成标题
    _generateTitleForCurrentChat(ref);
  }
  
  // 如果有会话ID，自动保存会话
  final currentSessionId = ref.read(currentSessionIdProvider);
  if (currentSessionId != null) {
    saveCurrentSession(ref);
  }
}

// 使用标题生成API生成标题
Future<void> _generateTitleForCurrentChat(WidgetRef ref) async {
  try {
    final messages = ref.read(currentMessagesProvider);
    
    // 确保有足够的消息生成标题（至少一对对话）
    if (messages.length < 2) return;
    
    // 获取标题生成API的设置
    final settings = ref.read(settingsProvider);
    final isEnabled = settings.titleGenerationApiEnabled;
    final apiKey = settings.titleGenerationApiKey;
    final apiUrl = settings.titleGenerationApiUrl;
    final apiModel = settings.titleGenerationApiModel;
    
    // 如果功能未启用或没有API密钥，则不生成标题
    if (!isEnabled || apiKey == null || apiKey.isEmpty) return;
    
    // 创建标题生成服务
    final titleGenerator = TitleGeneratorService(
      apiKey: apiKey,
      baseUrl: apiUrl ?? "https://api.openai.com/v1",
      model: apiModel ?? "gpt-3.5-turbo",
    );
    
    // 生成标题
    final title = await titleGenerator.generateTitle(messages);
    
    // 更新会话标题
    if (title.isNotEmpty) {
      ref.read(currentSessionTitleProvider.notifier).state = title;
      debugPrint('已生成会话标题: $title');
      
      // 自动保存会话
      saveCurrentSession(ref);
    }
  } catch (e) {
    debugPrint('标题生成错误: $e');
    // 错误处理时不做任何操作，保持默认标题
  }
}

// 添加助手欢迎消息
void addAssistantWelcomeMessage(WidgetRef ref, String assistantName, String assistantDescription) {
  final welcomeMessage = Message(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    content: '您好，我是$assistantName，$assistantDescription',
    isUser: false,
    timestamp: DateTime.now(),
  );
  
  addMessage(ref, welcomeMessage);
}

// 保存当前会话
void saveCurrentSession(WidgetRef ref) {
  final currentSessionId = ref.read(currentSessionIdProvider);
  final currentSessionTitle = ref.read(currentSessionTitleProvider);
  final currentMessages = ref.read(currentMessagesProvider);
  final currentAssistant = ref.read(currentAssistantProvider);
  
  // 如果没有消息，不保存
  if (currentMessages.isEmpty) return;
  
  // 创建新会话或更新现有会话
  final sessionToSave = ChatSession(
    id: currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: currentSessionTitle,
    createdAt: DateTime.now(),
    lastUpdatedAt: DateTime.now(),
    assistantId: currentAssistant.id,
    messages: currentMessages,
  );
  
  // 使用notifier方法保存会话
  ref.read(chatSessionsProvider.notifier).addOrUpdateSession(sessionToSave);
  
  // 如果是新会话，更新当前会话ID
  if (currentSessionId == null) {
    ref.read(currentSessionIdProvider.notifier).state = sessionToSave.id;
  }
}

// 加载会话
void loadSession(WidgetRef ref, String sessionId) {
  final allSessions = ref.read(chatSessionsProvider);
  final sessionToLoad = allSessions.firstWhere((session) => session.id == sessionId);
  
  // 设置当前会话信息
  ref.read(currentSessionIdProvider.notifier).state = sessionId;
  ref.read(currentSessionTitleProvider.notifier).state = sessionToLoad.title;
  ref.read(currentMessagesProvider.notifier).state = sessionToLoad.messages;
  
  // 如果助手ID与当前不符，则切换助手
  final currentAssistant = ref.read(currentAssistantProvider);
  if (currentAssistant.id != sessionToLoad.assistantId) {
    // 查找助手的索引并设置
    final assistants = ref.read(assistantsProvider);
    final assistantIndex = assistants.indexWhere((a) => a.id == sessionToLoad.assistantId);
    if (assistantIndex >= 0) {
      ref.read(selectedAssistantIndexProvider.notifier).state = assistantIndex;
    }
  }
}

// 正在输入的状态
final isTypingProvider = StateProvider<bool>((ref) => false); 