import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenx/screens/chat_screen.dart';
import 'package:zenx/screens/left_drawer.dart';
import 'package:zenx/screens/right_drawer.dart';
import 'package:zenx/utils/constants.dart';
import 'package:zenx/states/settings_provider.dart';
import 'package:zenx/states/assistant_provider.dart';
import 'package:zenx/states/chat_provider.dart';

void main() {
  runApp(
    // Enable Riverpod for the entire app
    const ProviderScope(
      child: ZenXApp(),
    ),
  );
}

class ZenXApp extends ConsumerWidget {
  const ZenXApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get theme mode from settings provider
    final themeMode = ref.watch(themeModeProvider);
    
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
      themeMode: themeMode, // Use theme mode from settings
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  @override
  void initState() {
    super.initState();
    // 初始化欢迎消息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentAssistant = ref.read(currentAssistantProvider);
      addAssistantWelcomeMessage(
        ref, 
        currentAssistant.name, 
        currentAssistant.description
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // 使用Provider获取当前会话标题和助手
    final currentSessionTitle = ref.watch(currentSessionTitleProvider);
    final currentAssistant = ref.watch(currentAssistantProvider);
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Column(
          children: [
            Text(currentSessionTitle),
            Text(
              currentAssistant.name,
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
            onPressed: () => createNewSession(ref),
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
}
