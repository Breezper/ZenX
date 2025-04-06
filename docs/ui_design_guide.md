# ZenX UI设计指南

## 一、设计理念

ZenX采用**SwiftUI风格**设计语言，追求以下设计目标：
- **简洁美观**：干净的界面，无冗余元素
- **自然流畅**：自然的动效和过渡
- **功能直观**：用户无需学习即可使用
- **跨平台统一**：在iOS和Android上保持一致体验

## 二、配色方案

### 主色板
```
主品牌蓝：#0A84FF (SwiftUI蓝)
辅助绿色：#30D158 (成功状态)
警告红色：#FF453A (错误状态)
中性灰色：#8E8E93 (次要文本)
```

### 明暗模式色彩
| 用途 | 亮色模式 | 暗色模式 |
|------|---------|---------|
| 背景色 | #F2F2F7 | #1C1C1E |
| 次级背景 | #FFFFFF | #2C2C2E |
| 主文本 | #000000 | #FFFFFF |
| 次要文本 | #8E8E93 | #8E8E93 |
| 分割线 | #C6C6C8 | #38383A |
| 抽屉背景 | #F9F9F9 | #2C2C2E |

### 消息气泡颜色
| 角色 | 亮色模式 | 暗色模式 |
|------|---------|---------|
| 用户消息 | #E9E9EB | #3C3C3E |
| AI回复(OpenAI) | #147EFB | #0A84FF |
| AI回复(Claude) | #5A45FF | #6E56FF |
| AI回复(Gemini) | #1E88E5 | #42A5F5 |

## 三、字体系统

### 字体家族
- iOS: SF Pro
- Android: Roboto (自动适配)

### 字号规范
```
大标题：20pt, 粗体
标题：17pt, 半粗体
正文：15pt, 常规
小文本：13pt, 常规
次要文本：13pt, 常规
```

### 行高设置
- 单行文本：1.2倍行高
- 多行文本：1.5倍行高

## 四、组件规范

### 圆角半径
```
卡片/面板：12px
按钮：8px
输入框：8px
消息气泡：13px (用户) / 13px (AI，左上角为直角)
抽屉边缘：0px (直角)
```

### 间距规范
```
页面边距：16px
组件间距：12px
内部填充：12px
列表项间距：8px
抽屉宽度：屏幕宽度的80%
```

### 阴影样式
```dart
// 浮动卡片阴影
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.1),
    spreadRadius: 0,
    blurRadius: 10,
    offset: Offset(0, 2),
  ),
],

// 抽屉阴影
drawerShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.15),
    spreadRadius: 0,
    blurRadius: 10,
    offset: Offset(0, 0),
  ),
],
```

## 五、动效指南

### 过渡动画
- 页面切换：水平滑动，300ms，缓动曲线
- 弹出对话框：缩放+淡入，250ms
- 列表项动画：轻微上移+淡入，交错进行
- 抽屉开关：水平滑动，200ms，缓出曲线

### 反馈动效
- 按钮点击：缩放至95%，迅速恢复
- 加载动画：使用CupertinoActivityIndicator
- 下拉刷新：使用原生风格指示器

### 抽屉手势
```dart
// 抽屉手势实现
GestureDetector(
  onHorizontalDragEnd: (details) {
    if (details.primaryVelocity! > 0) {
      // 向右滑动，打开左抽屉
      _scaffoldKey.currentState!.openDrawer();
    } else if (details.primaryVelocity! < 0) {
      // 向左滑动，打开右抽屉
      _scaffoldKey.currentState!.openEndDrawer();
    }
  },
  child: mainContent,
)
```

## 六、主要页面布局

### 1. 主聊天界面
```
┌─────────────────────────────────────────┐
│ ☰           新对话                   +  │
│             通用助手                     │
├─────────────────────────────────────────┤
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│               消息列表区域              │
│                                         │
│                                         │
│                                         │
│             开始新的对话                │
│        输入消息开始与AI助手对话         │
│                                         │
├─────────────────────────────────────────┤
│  输入信息                          +    │
└─────────────────────────────────────────┘
```

### 2. 左侧抽屉 - 助手选择
```
┌─────────────────────────────┐
│ [助手]          [历史记录]   │
├─────────────────────────────┤
│                             │
│ ○ 通用助手                  │
│                             │
│ ○ 编程专家                  │
│                             │
│ ○ 写作助手                  │
│                             │
│ ○ 数学导师                  │
│                             │
│                             │
│                             │
│                             │
│                             │
│                             │
├─────────────────────────────┤
│           设置              │
└─────────────────────────────┘
```

### 3. 右侧抽屉 - 助手设置
```
┌─────────────────────────────┐
│ 通用助手设置                 │
├─────────────────────────────┤
│                             │
│ 系统提示词                   │
│ [                          ]│
│ [                          ]│
│                             │
│ 模型选择                     │
│ [GPT-4o                 ▼  ]│
│                             │
│ 上下文长度                   │
│ [4000                   ▼  ]│
│                             │
│ ☑ 流式输出                  │
│                             │
├─────────────────────────────┤
│         应用设置             │
└─────────────────────────────┘
```

### 4. 设置界面
```
┌─────────────────────────────┐
│ ←   设置                    │
├─────────────────────────────┤
│                             │
│ API配置                     │
│  ├─ OpenAI                  │
│  │   [API密钥: ***]         │
│  ├─ Claude                  │
│  │   [未设置]               │
│  └─ + 添加新API             │
│                             │
│ 导出备份                     │
│  ├─ 导出对话                │
│  └─ 导出设置                │
│                             │
│ 应用主题                     │
│  ○ 跟随系统  ○ 浅色  ○ 深色  │
│                             │
└─────────────────────────────┘
```

## 七、UI交互规范

### 1. 抽屉交互
- **左侧抽屉**：从屏幕左侧向右滑动打开，或点击左上角菜单按钮
- **右侧抽屉**：从屏幕右侧向左滑动打开
- **关闭抽屉**：点击抽屉外区域，或向抽屉开启的反方向滑动

### 2. 助手选择
- 在左侧抽屉的助手选项卡中点击助手图标或名称
- 选择后自动关闭抽屉，主页面标题更新为对应助手名称

### 3. 新建对话
- 点击右上角"+"按钮创建新对话
- 新对话默认使用当前选中的助手

### 4. 历史记录浏览
- 在左侧抽屉切换到历史记录标签
- 点击历史记录项加载对应对话

### 5. 输入框交互
- 点击输入框底部"+"按钮展开功能面板
- 功能面板包含图片上传等功能
- 按回车键发送消息

## 八、具体组件实现

### 1. 抽屉实现
```dart
class MainScaffold extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Column(
          children: [
            Text('新对话'),
            Text('通用助手', style: TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // 创建新对话
            },
          ),
        ],
      ),
      drawer: LeftDrawer(),
      endDrawer: RightSettingsDrawer(),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _scaffoldKey.currentState!.openDrawer();
          } else if (details.primaryVelocity! < 0) {
            _scaffoldKey.currentState!.openEndDrawer();
          }
        },
        child: ChatScreen(),
      ),
    );
  }
}
```

### 2. 输入栏实现
```dart
class MessageInputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '输入信息',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: AppTheme.primaryBlue,
            child: IconButton(
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                // 打开功能面板
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 九、响应式设计

### 屏幕适配策略
- 手机: 左右抽屉默认隐藏，通过手势或按钮展开
- 平板: 在横屏模式下可考虑常驻左侧抽屉

### 抽屉宽度策略
- 手机: 抽屉宽度为屏幕宽度的80%
- 平板: 抽屉宽度固定为320dp

### 自适应布局
```dart
// 自适应抽屉宽度
double getDrawerWidth(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth > 600) {
    return 320.0; // 平板固定宽度
  } else {
    return screenWidth * 0.8; // 手机屏幕比例
  }
}
```

## 十、设计资源

### 设计常量配置类
```dart
class AppTheme {
  // 颜色
  static const primaryBlue = Color(0xFF0A84FF);
  static const successGreen = Color(0xFF30D158);
  static const errorRed = Color(0xFFFF453A);
  
  // 亮色模式背景色
  static const lightBackground = Color(0xFFF2F2F7);
  static const darkBackground = Color(0xFF1C1C1E);
  static const drawerBackground = Color(0xFFF9F9F9);
  static const drawerDarkBackground = Color(0xFF2C2C2E);
  
  // 文本样式
  static const headerTextStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
  );
  
  static const titleTextStyle = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
  );
  
  static const bodyTextStyle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.normal,
  );
  
  static const captionTextStyle = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.normal,
    color: Color(0xFF8E8E93),
  );
  
  // 内边距
  static const defaultPadding = 16.0;
  static const smallPadding = 12.0;
  
  // 圆角
  static const defaultRadius = 12.0;
  static const buttonRadius = 8.0;
  static const bubbleRadius = 13.0;
  static const inputRadius = 24.0;
}
``` 