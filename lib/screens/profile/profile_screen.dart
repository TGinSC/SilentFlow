import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
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
    final projectTemplates = [
      {
        'name': '软件开发项目',
        'description': '完整的软件开发流程，适合多人协作开发',
        'icon': Icons.code,
        'color': Colors.blue,
        'estimatedDays': '10-15天',
        'teamSize': '3-6人',
        'templateId': 'template_software_dev',
      },
      {
        'name': '协作写作项目',
        'description': '多人协作完成文档或创作项目，包含大纲设计、内容编写、审核修改',
        'icon': Icons.edit_note,
        'color': Colors.indigo,
        'estimatedDays': '5-8天',
        'teamSize': '2-5人',
        'templateId': 'template_collaborative_writing',
      },
      {
        'name': '学术论文协作',
        'description': '团队合作完成学术论文，包含文献综述、研究设计、数据分析',
        'icon': Icons.school,
        'color': Colors.deepPurple,
        'estimatedDays': '15-20天',
        'teamSize': '2-4人',
        'templateId': 'template_academic_paper',
      },
      {
        'name': '商业提案协作',
        'description': '团队合作完成商业提案，包含市场分析、财务规划、风险评估',
        'icon': Icons.business_center,
        'color': Colors.green,
        'estimatedDays': '8-12天',
        'teamSize': '3-6人',
        'templateId': 'template_business_proposal',
      },
      {
        'name': '技术文档协作',
        'description': '团队协作编写技术文档，包含需求分析、架构设计、API文档',
        'icon': Icons.description,
        'color': Colors.orange,
        'estimatedDays': '10-15天',
        'teamSize': '3-5人',
        'templateId': 'template_tech_documentation',
      },
      {
        'name': '研究项目',
        'description': '学术或商业研究，包含文献调研和数据分析',
        'icon': Icons.science,
        'color': Colors.teal,
        'estimatedDays': '7-12天',
        'teamSize': '2-4人',
        'templateId': 'template_research',
      },
      {
        'name': '营销活动',
        'description': '完整的营销推广活动策划和执行',
        'icon': Icons.campaign,
        'color': Colors.pink,
        'estimatedDays': '5-8天',
        'teamSize': '2-5人',
        'templateId': 'template_marketing',
      },
      {
        'name': '设计项目',
        'description': '产品设计或UI/UX设计项目',
        'icon': Icons.design_services,
        'color': Colors.purple,
        'estimatedDays': '5-10天',
        'teamSize': '2-5人',
        'templateId': 'template_design',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 对话框标题
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '创建合作项目',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '选择一个项目模板快速开始团队协作',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              // 项目模板列表
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: projectTemplates.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final template = projectTemplates[index];
                    return Card(
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.of(context).pop();
                          _createProjectFromTemplate(context, template);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: (template['color'] as Color)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  template['icon'] as IconData,
                                  color: template['color'] as Color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      template['name'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      template['description'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          template['estimatedDays'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.group,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          template['teamSize'] as String,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 自定义项目按钮
              Container(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _createCustomProject(context);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('创建自定义项目'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createProjectFromTemplate(
      BuildContext context, Map<String, dynamic> template) {
    // 导航到团队标签页并显示创建团队对话框
    Navigator.of(context).pushReplacementNamed('/main',
        arguments: {'tab': 1, 'action': 'create_team', 'template': template});
  }

  void _createCustomProject(BuildContext context) {
    // 导航到团队标签页并显示自定义团队创建
    Navigator.of(context).pushReplacementNamed('/main',
        arguments: {'tab': 1, 'action': 'create_custom_team'});
  }
}
