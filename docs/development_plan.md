# ZenX AI聊天应用开发计划

## 一、项目概述

**项目名称：** ZenX  
**项目类型：** 多模型AI聊天应用  
**设计风格：** SwiftUI风格（简洁、流畅、现代）  
**目标平台：** iOS/Android（Flutter跨平台）  
**开发模式：** AI辅助零基础开发  

## 二、功能需求

### 核心功能
- 支持与多家AI服务商API进行对话（OpenAI、Gemini、Claude等）
- 左侧抽屉选择不同AI角色（通用助手、编程专家等）
- 右侧抽屉配置当前角色的模型和参数
- 消息历史管理和分类
- SwiftUI风格的用户界面
- 支持API密钥配置和管理
- 图片上传等媒体能力支持

### 优先级功能矩阵
| 功能 | 优先级 | 难度 |
|------|--------|------|
| 基础聊天界面与双抽屉结构 | P0 | 中 |
| 助手角色选择 | P0 | 低 |
| OpenAI集成 | P0 | 中 |
| 历史会话管理 | P1 | 中 |
| 多API支持 | P1 | 高 |
| 设置与配置界面 | P1 | 低 |
| 图片上传功能 | P2 | 中 |
| 对话导出 | P2 | 低 |

## 三、技术架构

### 项目结构
```
📦 ZenX
├── 📂 lib
│   ├── 📂 components        # 可复用UI组件
│   │   ├── chat_bubble.dart  # 消息气泡
│   │   ├── message_input.dart # 消息输入栏
│   │   ├── assistant_item.dart # 助手选择项
│   │   └── typing_indicator.dart # 打字动画效果
│   ├── 📂 api              # API接口层
│   │   ├── base_chat_api.dart # 抽象接口
│   │   ├── openai_api.dart 
│   │   ├── gemini_api.dart
│   │   └── claude_api.dart
│   ├── 📂 models          # 数据模型
│   │   ├── message.dart    # 消息对象
│   │   ├── assistant.dart  # 助手角色对象
│   │   ├── chat_session.dart # 聊天会话对象
│   │   └── api_config.dart # API配置项
│   ├── 📂 states          # 状态管理
│   │   ├── chat_provider.dart # 聊天状态管理
│   │   ├── assistant_provider.dart # 助手角色状态管理
│   │   └── settings_provider.dart # 用户设置
│   ├── 📂 screens         # 页面层
│   │   ├── chat_screen.dart # 主聊天界面
│   │   ├── left_drawer.dart # 左侧抽屉（助手选择和历史）
│   │   ├── right_drawer.dart # 右侧抽屉（模型设置）
│   │   └── settings_screen.dart # 设置界面
│   └── 📂 utils           # 工具类
│       ├── constants.dart  # 设计常量
│       ├── api_utils.dart  # API通用工具
│       └── storage_utils.dart # 本地存储工具
```

### 核心技术选型
- **前端框架：** Flutter（最新稳定版）
- **状态管理：** Riverpod（易于组合和测试）
- **网络请求：** Dio（支持请求拦截和流式响应）
- **本地存储：** Hive/SQLite（轻量级键值对存储）
- **安全存储：** flutter_secure_storage（API密钥加密存储）

### 核心数据模型

#### 助手角色模型
```dart
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
```

#### 对话会话模型
```dart
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
    this.lastUpdatedAt,
    this.messages = const [],
  });
}
```

## 四、UI/UX设计规范

### 配色方案
- **主色调：** #0A84FF（SwiftUI蓝）
- **次要色：** #30D158（成功绿）/ #FF453A（错误红）
- **背景色：** #F2F2F7（浅灰）/ #1C1C1E（深色模式）
- **气泡色：** #E9E9EB（用户）/ #147EFB（AI回复）

### 导航结构
- 主聊天界面（带双抽屉结构）
- 设置界面（API配置、导出、主题）

## 五、开发路线图

### 第一阶段：基础框架（估计1周）
1. 项目初始化与依赖配置
2. 双抽屉布局结构实现
3. 基础UI组件开发（消息气泡、输入框）
4. 状态管理设置（Riverpod初始化）
5. 助手角色选择UI实现

### 第二阶段：核心功能（估计1周）
1. OpenAI API基础集成
2. 消息流处理机制
3. 助手角色管理系统
4. 聊天会话创建与切换
5. API密钥安全管理

### 第三阶段：完善功能（估计2周）
1. 多API厂商支持
2. 历史会话管理完善
3. 图片上传功能实现
4. 设置界面与功能完善
5. 性能优化与测试

## 六、零基础AI辅助开发方法

### AI指令模板库
```
# 双抽屉布局模板
请创建一个带左右抽屉的主界面骨架，左侧抽屉用于选择助手和历史，右侧抽屉用于模型设置。
主界面中间是聊天区域。要求使用SwiftUI风格设计。

# 助手选择组件模板
请创建一个助手选择组件，用于在左侧抽屉中展示和选择不同的AI助手角色。
支持显示助手图标、名称，支持点击选择功能。
```

### 开发工作流
1. **分解任务：** 将大功能拆分为小组件和独立功能
2. **AI生成代码：** 使用模板指令生成组件代码
3. **组合与测试：** 复制代码到项目中，运行测试
4. **迭代优化：** 基于测试结果提供反馈，让AI优化

## 七、核心组件开发顺序

1. **主界面双抽屉结构**
   - 主聊天界面框架
   - 左侧抽屉框架
   - 右侧抽屉框架
   - 手势控制机制

2. **左侧抽屉组件**
   - 助手/历史标签切换
   - 助手列表项
   - 历史记录列表项

3. **右侧抽屉组件**
   - 模型参数设置
   - 系统提示词编辑
   - 应用按钮

4. **消息组件**
   - 消息气泡
   - 消息输入栏
   - 功能面板（图片上传等）

5. **设置界面**
   - API密钥管理
   - 导出功能
   - 主题设置

## 八、预期风险与解决方案

| 风险 | 可能性 | 影响 | 解决方案 |
|------|--------|------|----------|
| 手势冲突 | 高 | 中 | 精细控制手势识别范围和优先级 |
| API限流 | 高 | 中 | 实现重试机制和用户友好错误提示 |
| 状态管理复杂性 | 中 | 高 | 严格分层，使用Riverpod简化状态流 |
| 流式响应处理 | 中 | 高 | 使用Stream Builder和适当缓冲机制 |
| 安全存储问题 | 低 | 高 | 使用flutter_secure_storage并添加额外加密层 |

## 九、项目需求变更流程

1. 明确新需求
2. 评估对现有架构的影响
3. 在不破坏现有功能的前提下集成
4. 针对新功能编写AI指令
5. 验证并集成新代码

## 十、版本发布计划

**v0.1** - 双抽屉框架与基础聊天功能  
**v0.2** - 助手角色系统与OpenAI集成  
**v0.3** - 多API支持与设置功能  
**v0.4** - 图片上传与历史管理完善  
**v1.0** - 完整功能集与UI优化  

## 附录：关键依赖

```yaml
dependencies:
  flutter: ">=3.0.0"
  cupertino_icons: ^1.0.5
  riverpod: ^2.3.0
  flutter_riverpod: ^2.3.0
  dio: ^5.0.0
  hive: ^2.2.3
  flutter_secure_storage: ^8.0.0
  flutter_markdown: ^0.6.14
  shared_preferences: ^2.1.1
  image_picker: ^0.8.7
``` 