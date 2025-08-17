import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../widgets/team_creation_dialog.dart';
import 'profile_detail_screen.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser;

        return Scaffold(
          appBar: AppBar(
            title: const Text('我的'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: user == null
              ? _buildNotLoggedIn(context)
              : _buildProfile(context, user),
        );
      },
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '请先登录',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '登录后查看您的个人资料',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('立即登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile(BuildContext context, User user) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 用户头像和基本信息
          _buildUserHeader(context, user, colorScheme),
          const SizedBox(height: 24),

          // 统计信息卡片
          _buildStatsCard(context, user, colorScheme),
          const SizedBox(height: 16),

          // 功能菜单列表
          _buildMenuList(context, user, colorScheme),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
      BuildContext context, User user, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 头像
            CircleAvatar(
              radius: 40,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // 用户名
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),

            // ID和创建时间
            Text(
              'ID: ${user.id}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            if (user.profile.bio != null) ...[
              const SizedBox(height: 8),
              Text(
                user.profile.bio!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
      BuildContext context, User user, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '我的统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.task_alt,
                    '已完成任务',
                    '${user.stats.completedTasks}',
                    colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.groups,
                    '团队参与',
                    '${user.stats.joinedPools}',
                    colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.star,
                    '贡献值',
                    '${user.stats.contributionScore.toInt()}',
                    colorScheme.tertiary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    Icons.favorite,
                    '默契度',
                    '${user.stats.averageTacitScore.toInt()}',
                    Colors.pink,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String label,
      String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildMenuList(
      BuildContext context, User user, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          _buildMenuItem(
            context,
            Icons.person_outline,
            '个人详情',
            '查看和管理个人资料',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileDetailScreen(
                    userId: user.id,
                    user: user,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            Icons.edit_outlined,
            '编辑资料',
            '修改个人信息和技能',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileEditScreen(
                    userId: user.id,
                    currentUser: user,
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            Icons.dashboard_outlined,
            '我的任务',
            '查看正在进行的任务',
            () {
              // TODO: 导航到任务页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中...')),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            Icons.add_task_outlined,
            '创建合作项目',
            '基于模板快速创建团队项目',
            () {
              _showCreateProjectDialog(context);
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            Icons.groups_outlined,
            '我的团队',
            '管理参与的团队和项目',
            () {
              // 导航到团队标签页
              Navigator.of(context).pushReplacementNamed('/main', arguments: 1);
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            Icons.settings_outlined,
            '设置',
            '应用设置和偏好',
            () {
              // TODO: 导航到设置页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('功能开发中...')),
              );
            },
          ),
          const Divider(height: 1),
          _buildMenuItem(
            context,
            Icons.logout,
            '退出登录',
            '安全退出应用',
            () {
              _showLogoutDialog(context);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: isDestructive ? TextStyle(color: Colors.red) : null,
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AppProvider>().logout();
            },
            child: const Text(
              '退出',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog(BuildContext context) {
    // 使用增强的团队创建对话框
    showDialog(
      context: context,
      builder: (context) => const TeamCreationDialog(
        isCustomCreation: false,
      ),
    );
  }
}
