# ZenX API集成方案

## 1. 概述

ZenX支持多种AI服务提供商的API集成，包括：

- OpenAI (ChatGPT)
- Claude (Anthropic)
- Gemini (Google)
- OpenAI兼容API
- 自定义API提供商

本文档详细介绍各API的集成方案、验证方式和数据流。

## 2. API架构设计

### 2.1 核心类

- `BaseChatAPI`: 所有API实现的抽象基类
- `ApiService`: 管理和提供各种API实现的服务类
- `ApiConfig`: API配置数据模型
- `SettingsProvider`: 存储和管理API配置的状态提供者
- `ApiUtils`: 提供API名称标准化和配置验证的工具类
- `ModelsProvider`: 管理和缓存各提供商的模型列表

### 2.2 API组件化设计

API集成在UI层采用了组件化设计，主要包括：

- `ApiProviderDropdown`: API提供商选择组件
- `ModelDropdown`: 模型选择组件
- `SettingsWarning`: API配置问题警告组件

这些组件通过状态提供者与后端API服务连接：

```
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│               │       │               │       │               │
│ API UI组件     │ ────> │ 状态提供者     │ ────> │  ApiService   │
│               │       │               │       │               │
└───────────────┘       └───────────────┘       └───────────────┘
```

### 2.3 API数据流

```
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│               │       │               │       │               │
│ 设置界面/对话框 │ ────> │SettingsProvider│ ────> │  ApiService   │
│               │       │               │       │               │
└───────────────┘       └───────────────┘       └───────────────┘
                                                       │
                                                       │
                                                       ▼
┌───────────────┐       ┌───────────────┐       ┌───────────────┐
│               │       │               │       │               │
│  聊天界面      │ <──── │  BaseChatAPI   │ <──── │ API具体实现类  │
│               │       │ 实现类         │       │               │
└───────────────┘       └───────────────┘       └───────────────┘
```

## 3. 已支持的API服务商

### 3.1 OpenAI

- **基本URL**: https://api.openai.com/v1
- **支持模型**: gpt-3.5-turbo, gpt-4, gpt-4o等
- **验证方式**: 通过GET /models验证API密钥

### 3.2 Claude

- **基本URL**: https://api.anthropic.com/v1
- **支持模型**: claude-3-opus, claude-3-sonnet等
- **验证方式**: 通过API密钥验证请求

### 3.3 Gemini

- **基本URL**: https://generativelanguage.googleapis.com/v1beta
- **支持模型**: gemini-pro, gemini-pro-vision等
- **验证方式**: 通过API密钥验证

### 3.4 OpenAI兼容API

- **基本URL**: 用户自定义（默认为http://localhost:8000）
- **支持模型**: 从API服务获取或用户设置
- **验证方式**: 与OpenAI兼容的/models端点验证

## 4. 自定义API支持

### 4.1 API工具类

`ApiUtils`类提供了以下核心功能：

```dart
class ApiUtils {
  // 标准化API提供商名称（处理命名不一致问题）
  static String standardizeProviderName(String provider);
  
  // 获取正确的API密钥名称
  static String getApiKeyName(String provider);
  
  // 获取正确的API URL键名
  static String getUrlKeyName(String provider);
  
  // 验证API配置的有效性
  static bool hasValidApiConfig(String provider, Map<String, String> apiKeys);
  
  // 智能获取模型列表（仅在必要时）
  static void fetchModelsForProviderIfNeeded(String provider, WidgetRef ref);
}
```

API工具类解决的主要问题：
- 处理不同API命名格式的不一致性（如 openai-compatible 和 openai_compatible）
- 简化跨平台API键名管理
- 集中式API配置验证
- 优化模型获取，避免不必要的API调用

### 4.2 添加自定义API

用户可以通过以下步骤添加自定义API：

1. 在设置界面点击"添加新API"
2. 输入API标识符和显示名称
3. 设置API密钥和基础URL
4. 对于OpenAI兼容API，可选择获取可用模型

### 4.3 自定义API实现

`CustomAPI`类提供了通用的实现，支持：

- 标准的OpenAI兼容格式
- 简化的聊天消息格式
- 灵活的请求/响应处理

### 4.4 自定义API注册

1. 应用启动时，通过`StartupService`初始化所有自定义API
2. 每个自定义API都会被注册到`ApiService`
3. 注册的API可以与内置API一样被调用和使用

### 4.5 自定义API数据存储

- API密钥通过`flutter_secure_storage`安全存储
- API配置保存在`SettingsProvider`中
- 显示名称和可见性设置也保存在`SettingsProvider`中

## 5. API调用流程

### 5.1 标准调用过程

```dart
// 获取API配置
final config = ApiConfig(
  provider: 'openai',  // 或自定义API的标识符
  apiKey: 'sk-...',
  baseUrl: 'https://...',
);

// 获取API服务
final apiService = ApiService();

// 发送消息
final response = await apiService.sendMessage(
  message: '你好，AI助手',
  history: MessageHistory(...),
  config: config,
);

// 处理流式响应
response.textStream.listen((text) {
  // 处理文本块
});
```

### 5.2 错误处理

API调用可能遇到以下错误：

- API密钥无效
- 网络连接问题
- 服务器错误
- 超出速率限制

每种错误都会有适当的处理和用户友好的提示。

## 6. 未来扩展计划

- 支持更多API提供商（例如Baidu ERNIE）
- 添加API使用统计功能
- 实现更丰富的API参数设置
- 增加API速率限制保护
- 支持流式传输的自定义实现 