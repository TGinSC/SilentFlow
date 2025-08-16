import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/team_pool_provider.dart';
import 'screens/main_tab_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/api_service.dart';

void main() {
  // 初始化API服务
  ApiService.initialize();

  runApp(const SilentFlowApp());
}

class SilentFlowApp extends StatelessWidget {
  const SilentFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => TeamPoolProvider()),
      ],
      child: MaterialApp(
        title: '静默协作',
        theme: ThemeData(
          // 静默协作主题 - 使用冷静的蓝紫色调
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // 卡片主题
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          // 应用栏主题
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.indigo[700],
          ),
        ),
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// 应用初始化器 - 根据登录状态决定显示哪个页面
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // 延迟初始化，先显示登录页面
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 显示启动页面2秒
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });

      // 异步初始化应用状态
      context.read<AppProvider>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果正在初始化，显示启动页面
    if (_isInitializing) {
      return const SplashScreen();
    }

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // 根据登录状态决定显示登录页面还是主页面
        if (appProvider.isLoggedIn) {
          return const MainTabScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

// 启动页面
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[300]!,
              Colors.indigo[600]!,
              Colors.purple[600]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 80,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '静默协作',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '用技术连接人心，以数据驱动效率',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
