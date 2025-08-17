import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/team_pool_provider.dart';
import '../widgets/team_creation_dialog.dart';
import 'home/home_screen.dart';
import 'team/team_pool_screen.dart';
import 'tasks/task_board_screen.dart';
import 'workflow/workflow_screen.dart';
import 'profile/profile_screen.dart';

class MainTabScreen extends StatefulWidget {
  final Object? arguments;

  const MainTabScreen({super.key, this.arguments});

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
      const WorkflowScreen(),
      const ProfileScreen(),
    ];

    // 处理导航参数
    _handleNavigationArguments();

    // 初始化团队池数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProvider = context.read<AppProvider>();
      if (appProvider.currentUser != null) {
        context.read<TeamPoolProvider>().initialize();
      }
    });
  }

  void _handleNavigationArguments() {
    if (widget.arguments != null) {
      if (widget.arguments is int) {
        // 简单的标签索引
        _selectedIndex = widget.arguments as int;
      } else if (widget.arguments is Map<String, dynamic>) {
        // 复杂的参数对象
        final args = widget.arguments as Map<String, dynamic>;

        // 设置标签索引
        if (args.containsKey('tab')) {
          _selectedIndex = args['tab'] as int;
        }

        // 处理操作
        if (args.containsKey('action')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleAction(args);
          });
        }
      }
    }
  }

  void _handleAction(Map<String, dynamic> args) {
    final action = args['action'] as String;

    switch (action) {
      case 'create_team':
        final template = args['template'] as Map<String, dynamic>?;
        _showCreateTeamDialog(initialTemplate: template);
        break;
      case 'create_custom_team':
        _showCreateTeamDialog(isCustomCreation: true);
        break;
    }
  }

  void _showCreateTeamDialog({
    Map<String, dynamic>? initialTemplate,
    bool isCustomCreation = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => TeamCreationDialog(
        initialTemplate: initialTemplate,
        isCustomCreation: isCustomCreation,
      ),
    );
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
                  Icons.account_tree_outlined,
                  color: _selectedIndex == 3
                      ? Colors.indigo[700]
                      : Colors.grey[600],
                ),
                selectedIcon: Icon(
                  Icons.account_tree,
                  color: Colors.indigo[700],
                ),
                label: '工作流图',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: _selectedIndex == 4
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
