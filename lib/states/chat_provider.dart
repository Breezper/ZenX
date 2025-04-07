import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/models/message.dart';
import 'package:zenx/models/chat_session.dart';
import 'package:zenx/states/assistant_provider.dart';

// 当前会话ID
final currentSessionIdProvider = StateProvider<String?>((ref) => null);

// 当前会话标题
final currentSessionTitleProvider = StateProvider<String>((ref) => '新对话');

// 当前会话消息列表
final currentMessagesProvider = StateProvider<List<Message>>((ref) => []);

// 左侧抽屉选中的标签页索引
final drawerSelectedTabProvider = StateProvider<int>((ref) => 0);

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
  
  // 获取当前所有会话
  final allSessions = ref.read(chatSessionsProvider);
  
  if (currentSessionId == null) {
    // 添加新会话
    ref.read(chatSessionsProvider.notifier).state = [...allSessions, sessionToSave];
    // 更新当前会话ID
    ref.read(currentSessionIdProvider.notifier).state = sessionToSave.id;
  } else {
    // 更新现有会话
    ref.read(chatSessionsProvider.notifier).state = allSessions.map((session) => 
      session.id == currentSessionId ? sessionToSave : session
    ).toList();
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