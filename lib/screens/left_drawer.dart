import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/components/assistant_item.dart';
import 'package:zenx/models/assistant.dart';
import 'package:zenx/models/chat_session.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/screens/settings_screen.dart';
import 'package:zenx/states/assistant_provider.dart';
import 'package:zenx/states/chat_provider.dart';

class LeftDrawer extends ConsumerStatefulWidget {
  const LeftDrawer({Key? key}) : super(key: key);

  @override
  ConsumerState<LeftDrawer> createState() => _LeftDrawerState();
}

class _LeftDrawerState extends ConsumerState<LeftDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // 使用保存的抽屉标签索引初始化TabController
    final savedTabIndex = ref.read(drawerSelectedTabProvider);
    _tabController = TabController(length: 2, vsync: this, initialIndex: savedTabIndex);
    
    // 监听标签切换，保存当前选中的标签索引
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging || _tabController.index != ref.read(drawerSelectedTabProvider)) {
      ref.read(drawerSelectedTabProvider.notifier).state = _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
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
    // 使用Provider获取助手列表和当前选中索引
    final assistants = ref.watch(assistantsProvider);
    final selectedIndex = ref.watch(selectedAssistantIndexProvider);
    
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.smallPadding),
      itemCount: assistants.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: AppTheme.listItemSpacing),
          child: AssistantItem(
            assistant: assistants[index],
            isSelected: index == selectedIndex,
            onTap: () {
              // 更新选中的助手索引
              ref.read(selectedAssistantIndexProvider.notifier).state = index;
              
              // 如果是新对话，更新会话标题
              final currentTitle = ref.read(currentSessionTitleProvider);
              if (currentTitle == '新对话') {
                ref.read(currentSessionTitleProvider.notifier).state = 
                    '${assistants[index].name}的对话';
              }
              
              // 清空现有消息，不再添加欢迎消息
              ref.read(currentMessagesProvider.notifier).state = [];
              
              // 自动切换到历史标签
              _tabController.animateTo(1);
              
              // 更新抽屉标签状态为历史标签
              ref.read(drawerSelectedTabProvider.notifier).state = 1;
              
              // 不再立即关闭抽屉，让用户查看助手历史记录
              // Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    // 使用Provider获取当前选中的助手
    final currentAssistant = ref.watch(currentAssistantProvider);
    
    // 获取当前助手的会话
    final assistantSessions = ref.watch(
      assistantSessionsProvider(currentAssistant.id)
    );
    
    if (assistantSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '没有${currentAssistant.name}的历史会话',
              style: AppTheme.bodyTextStyle.copyWith(
                color: AppTheme.neutralGray,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('开始新对话'),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(AppTheme.smallPadding),
      itemCount: assistantSessions.length,
      itemBuilder: (context, index) {
        final session = assistantSessions[index];
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
            // 加载历史会话
            loadSession(ref, session.id);
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