import 'package:flutter/material.dart';
import 'package:zenx/screens/chat_screen.dart';
import 'package:zenx/screens/left_drawer.dart';
import 'package:zenx/screens/right_drawer.dart';
import 'package:zenx/utils/constants.dart';

void main() {
  runApp(const ZenXApp());
}

class ZenXApp extends StatelessWidget {
  const ZenXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZenX AI聊天',
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: AppTheme.primaryBlue,
          background: AppTheme.lightBackground,
          surface: AppTheme.lightCardBackground,
        ),
        scaffoldBackgroundColor: AppTheme.lightBackground,
        appBarTheme: AppBarTheme(
          elevation: 0.5,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: AppTheme.primaryBlue,
          background: AppTheme.darkBackground,
          surface: AppTheme.darkCardBackground,
        ),
        scaffoldBackgroundColor: AppTheme.darkBackground,
        appBarTheme: AppBarTheme(
          elevation: 0.5,
          backgroundColor: AppTheme.darkCardBackground,
          centerTitle: true,
        ),
      ),
      themeMode: ThemeMode.system, // 根据系统设置切换明暗主题
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentAssistantName = '通用助手';
  String _currentSessionTitle = '新对话';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Column(
          children: [
            Text(_currentSessionTitle),
            Text(
              _currentAssistantName,
              style: AppTheme.captionTextStyle,
            ),
          ],
        ),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createNewChat,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => _scaffoldKey.currentState!.openEndDrawer(),
          ),
        ],
      ),
      drawer: LeftDrawer(),
      endDrawer: RightSettingsDrawer(),
      body: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalDrag,
        child: ChatScreen(),
      ),
    );
  }
  
  void _handleHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity! > 0) {
      // 向右滑动，打开左抽屉
      _scaffoldKey.currentState!.openDrawer();
    } else if (details.primaryVelocity! < 0) {
      // 向左滑动，打开右抽屉
      _scaffoldKey.currentState!.openEndDrawer();
    }
  }
  
  void _createNewChat() {
    setState(() {
      _currentSessionTitle = '新对话';
    });
    
    // TODO: 重置聊天记录
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已创建新对话')),
    );
  }
}
