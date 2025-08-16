import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/team_pool_provider.dart';
import 'home/home_screen.dart';
import 'team/team_pool_screen.dart';
import 'tasks/task_board_screen.dart';
import 'profile/profile_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const TeamPoolScreen(),
      const TaskBoardScreen(),
      const ProfileScreen(),
    ];

    // 初始化团队池数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      if (appProvider.currentUser != null) {
        context.read<TeamPoolProvider>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 1.0],
            colors: [
              Colors.indigo[50]!,
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            indicatorColor: Colors.indigo[100],
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.dashboard_outlined,
                  color: _selectedIndex == 0
                      ? Colors.indigo[700]
                      : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.dashboard,
                  color: Colors.indigo[700],
                ),
                label: '首页',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.groups_outlined,
                  color: _selectedIndex == 1
                      ? Colors.indigo[700]
                      : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.groups,
                  color: Colors.indigo[700],
                ),
                label: '团队池',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.task_outlined,
                  color: _selectedIndex == 2
                      ? Colors.indigo[700]
                      : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.task,
                  color: Colors.indigo[700],
                ),
                label: '任务面板',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: _selectedIndex == 3
                      ? Colors.indigo[700]
                      : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.person,
                  color: Colors.indigo[700],
                ),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
