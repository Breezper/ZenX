import 'package:flutter/material.dart';
import 'package:zenx/components/assistant_item.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/models/chat_session.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/screens/settings_screen.dart';

class LeftDrawer extends StatefulWidget {
  const LeftDrawer({Key? key}) : super(key: key);

  @override
  _LeftDrawerState createState() => _LeftDrawerState();
}

class _LeftDrawerState extends State<LeftDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedAssistantIndex = 0;
  
  // 临时数据 - 后续会从状态管理中获取
  final List<Assistant> _assistants = [
    Assistant(
      id: '1',
      name: '通用助手',
      description: '可以回答各种问题',
      systemPrompt: '你是ZenX的AI助手，可以回答用户的各种问题。',
      iconPath: 'icons/assistant.png', // 稍后添加
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
      iconPath: 'icons/code.png', // 稍后添加
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
      iconPath: 'icons/write.png', // 稍后添加
      modelConfig: ApiModelConfig(
        apiProvider: 'gemini',
        modelName: 'gemini-pro',
      ),
    ),
  ];
  
  // 临时数据 - 历史会话
  final List<ChatSession> _chatSessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final drawerWidth = AppTheme.getDrawerWidth(context);
    
    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        child: Column(
          children: [
            Container(
              color: isDarkMode 
                  ? AppTheme.drawerDarkBackground 
                  : AppTheme.drawerBackground,
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: '助手'),
                      Tab(text: '历史记录'),
                    ],
                    labelColor: AppTheme.primaryBlue,
                    unselectedLabelColor: AppTheme.neutralGray,
                    indicatorColor: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAssistantsTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistantsTab() {
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.smallPadding),
      itemCount: _assistants.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.listItemSpacing),
          child: AssistantItem(
            assistant: _assistants[index],
            isSelected: index == _selectedAssistantIndex,
            onTap: () {
              setState(() {
                _selectedAssistantIndex = index;
              });
              // TODO: 通知上层切换助手
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_chatSessions.isEmpty) {
      return Center(
        child: Text(
          '没有历史会话',
          style: AppTheme.bodyTextStyle.copyWith(
            color: AppTheme.neutralGray,
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.smallPadding),
      itemCount: _chatSessions.length,
      itemBuilder: (context, index) {
        final session = _chatSessions[index];
        return ListTile(
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(session.lastUpdatedAt),
            style: AppTheme.captionTextStyle,
          ),
          onTap: () {
            // TODO: 加载历史会话
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.dividerDark
                : AppTheme.dividerLight,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.settings),
        title: Text('设置'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }
} 