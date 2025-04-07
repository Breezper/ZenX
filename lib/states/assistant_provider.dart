import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/models/chat_session.dart';
import 'package:zenx/utils/storage_utils.dart';
import 'package:flutter/material.dart';
import 'package:zenx/states/chat_provider.dart';

// 默认助手列表初始数据
final defaultAssistants = [
  Assistant(
    id: '1',
    name: '通用助手',
    description: '可以回答各种问题',
    systemPrompt: '你是ZenX的AI助手，可以回答用户的各种问题。',
    iconPath: 'icons/assistant.png',
    modelConfig: ApiModelConfig(
      apiProvider: 'openai',
      modelName: 'gpt-4o',
    ),
  ),
  Assistant(
    id: '2',
    name: '编程专家',
    description: '帮助解决编程问题',
    systemPrompt: '你是编程领域专家，精通多种编程语言和框架，可以回答编程相关问题。',
    iconPath: 'icons/code.png',
    modelConfig: ApiModelConfig(
      apiProvider: 'openai',
      modelName: 'gpt-4o',
    ),
  ),
  Assistant(
    id: '3',
    name: '写作助手',
    description: '帮助创作和改进文章',
    systemPrompt: '你是写作助手，可以帮助用户创作、修改和改进各类文章。',
    iconPath: 'icons/write.png',
    modelConfig: ApiModelConfig(
      apiProvider: 'gemini',
      modelName: 'gemini-pro',
    ),
  ),
];

// 默认助手列表
final assistantsProvider = StateProvider<List<Assistant>>((ref) {
  return defaultAssistants;
});

// 当前选中的助手索引
final selectedAssistantIndexProvider = StateProvider<int>((ref) => 0);

// 当前选中的助手
final currentAssistantProvider = Provider<Assistant>((ref) {
  final assistants = ref.watch(assistantNotifierProvider);
  final selectedIndex = ref.watch(selectedAssistantIndexProvider);
  
  if (selectedIndex >= assistants.length) {
    debugPrint("警告: 选择的助手索引 ($selectedIndex) 超出了助手列表范围 (${assistants.length})");
    return assistants.isNotEmpty ? assistants.first : Assistant(
      id: 'default',
      name: '默认助手',
      description: '默认助手',
      systemPrompt: '你是一个AI助手',
      iconPath: 'icons/assistant.png',
      modelConfig: ApiModelConfig(
        apiProvider: 'openai',
        modelName: 'gpt-3.5-turbo',
      ),
    );
  }
  
  return assistants[selectedIndex];
});

// 更新助手设置
class AssistantNotifier extends StateNotifier<List<Assistant>> {
  AssistantNotifier() : super(defaultAssistants) {
    debugPrint("AssistantNotifier初始化，默认助手数量: ${defaultAssistants.length}");
    _loadAssistantsFromStorage();
  }
  
  // 从存储加载助手
  Future<void> _loadAssistantsFromStorage() async {
    try {
      final assistants = await StorageUtils.loadAssistants();
      if (assistants.isNotEmpty) {
        state = assistants;
        debugPrint("从存储中加载了 ${assistants.length} 个助手");
      } else {
        // 如果没有保存的助手，保存默认助手
        _saveAssistantsToStorage();
        debugPrint("未找到保存的助手，使用默认助手");
      }
    } catch (e) {
      debugPrint('加载助手失败: $e');
    }
  }
  
  // 保存助手到存储
  Future<void> _saveAssistantsToStorage() async {
    try {
      await StorageUtils.saveAssistants(state);
      debugPrint("已保存 ${state.length} 个助手到存储");
    } catch (e) {
      debugPrint('保存助手失败: $e');
    }
  }
  
  void updateAssistant(Assistant updatedAssistant) {
    debugPrint("更新助手: ${updatedAssistant.name}, 系统提示词: ${updatedAssistant.systemPrompt}");
    state = state.map((assistant) => 
      assistant.id == updatedAssistant.id ? updatedAssistant : assistant
    ).toList();
    
    // 保存更新后的助手到存储
    _saveAssistantsToStorage();
  }
  
  void addAssistant(Assistant newAssistant) {
    state = [...state, newAssistant];
    // 保存到存储
    _saveAssistantsToStorage();
  }
  
  void removeAssistant(String assistantId) {
    state = state.where((assistant) => assistant.id != assistantId).toList();
    // 保存到存储
    _saveAssistantsToStorage();
  }
}

final assistantNotifierProvider = StateNotifierProvider<AssistantNotifier, List<Assistant>>((ref) {
  return AssistantNotifier();
});

// 获取特定助手的会话
final assistantSessionsProvider = Provider.family<List<ChatSession>, String>((ref, assistantId) {
  final sessions = ref.watch(chatSessionsProvider);
  return sessions.where((session) => session.assistantId == assistantId).toList();
}); 