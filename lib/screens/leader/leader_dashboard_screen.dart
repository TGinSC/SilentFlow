import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/task_model.dart';
import '../../models/collaboration_pool_model.dart';
import '../../services/enhanced_collaboration_pool_service.dart';

// 队长管理面板
// 提供智能任务分配、成员管理、进度监控等功能
class LeaderDashboardScreen extends StatefulWidget {
  final User currentUser;
  final String poolId;

  const LeaderDashboardScreen({
    Key? key,
    required this.currentUser,
    required this.poolId,
  }) : super(key: key);

  @override
  State<LeaderDashboardScreen> createState() => _LeaderDashboardScreenState();
}

class _LeaderDashboardScreenState extends State<LeaderDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  CollaborationPool? _pool;
  List<User> _members = [];
  List<Task> _tasks = [];
  LeaderDashboardData? _dashboardData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载协作池信息
      await _loadPoolInfo();
      // 加载仪表板数据
      await _loadLeaderDashboard();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPoolInfo() async {
    // 这里应该从API获取协作池和成员信息
    // final pool = await CollaborationPoolService.getPool(widget.poolId);
    // final members = await UserService.getPoolMembers(widget.poolId);
    // final tasks = await TaskService.getPoolTasks(widget.poolId);

    // 模拟数据
    setState(() {
      _pool = CollaborationPool(
        id: widget.poolId,
        name: '移动应用开发项目',
        description: '开发一款协作管理应用',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        createdBy: widget.currentUser.id,
        progress: const PoolProgress(
            completedTasks: 8,
            totalTasks: 15,
            inProgressTasks: 5,
            averageProgress: 0.75),
        settings: const PoolSettings(),
        statistics: const PoolStatistics(),
        leaderId: widget.currentUser.id,
        memberRoles: {
          widget.currentUser.id: MemberRole.leader,
          'user_2': MemberRole.member,
          'user_3': MemberRole.member,
        },
      );

      _members = [
        widget.currentUser,
        User(
          id: 'user_2',
          name: '张三',
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          stats: const UserStats(
            completedTasks: 12,
            contributionScore: 85.0,
            averageTacitScore: 78.0,
          ),
          profile: UserProfile(
            bio: 'Flutter开发工程师',
            role: '前端开发',
            skills: [
              UserSkill(name: 'Flutter开发', level: 4, experienceYears: 2),
              UserSkill(name: 'Dart编程', level: 4, experienceYears: 2),
              UserSkill(name: 'UI设计', level: 3, experienceYears: 1),
            ],
            interests: ['移动开发', '用户界面'],
            workStyle: const WorkStyle(
              communicationStyle: '直接',
              workPace: '快速',
              preferredCollaborationMode: '团队',
              stressHandling: '良好',
              feedbackStyle: '建设性',
            ),
            availability: const AvailabilityInfo(),
            preferredTaskTypes: ['开发任务', '设计任务'],
            contact: const ContactInfo(),
          ),
        ),
        User(
          id: 'user_3',
          name: '李四',
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          stats: const UserStats(
            completedTasks: 8,
            contributionScore: 72.0,
            averageTacitScore: 82.0,
          ),
          profile: UserProfile(
            bio: '后端开发专家',
            role: '后端开发',
            skills: [
              UserSkill(name: '后端开发', level: 5, experienceYears: 3),
              UserSkill(name: 'API设计', level: 4, experienceYears: 2),
              UserSkill(name: '数据库设计', level: 4, experienceYears: 3),
            ],
            interests: ['后端架构', '数据库优化'],
            workStyle: const WorkStyle(
              communicationStyle: '详细',
              workPace: '稳定',
              preferredCollaborationMode: '独立',
              stressHandling: '优秀',
              feedbackStyle: '技术性',
            ),
            availability: const AvailabilityInfo(),
            preferredTaskTypes: ['开发任务', '架构任务'],
            contact: const ContactInfo(),
          ),
        ),
      ];

      _tasks = [
        Task(
          id: 'task_1',
          poolId: widget.poolId,
          title: '用户界面重构',
          description: '重构主界面布局，提升用户体验',
          status: TaskStatus.inProgress,
          assigneeId: 'user_2',
          priority: TaskPriority.high,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          expectedAt: DateTime.now().add(const Duration(days: 2)),
          difficulty: TaskDifficulty.medium,
          estimatedMinutes: 1200,
          requiredSkills: ['Flutter开发', 'UI设计'],
          statistics: const TaskStatistics(),
          createdBy: widget.currentUser.id,
        ),
        Task(
          id: 'task_2',
          poolId: widget.poolId,
          title: 'API接口优化',
          description: '优化现有API接口性能',
          status: TaskStatus.pending,
          priority: TaskPriority.medium,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          expectedAt: DateTime.now().add(const Duration(days: 5)),
          difficulty: TaskDifficulty.hard,
          estimatedMinutes: 1800,
          requiredSkills: ['后端开发', 'API设计'],
          statistics: const TaskStatistics(),
          createdBy: widget.currentUser.id,
        ),
      ];
    });
  }

  Future<void> _loadLeaderDashboard() async {
    if (_pool == null) return;

    try {
      _dashboardData =
          await EnhancedCollaborationPoolService.getLeaderDashboard(
        widget.poolId,
        widget.currentUser.id,
      );
    } catch (e) {
      print('获取仪表板数据失败：$e');
      // 创建模拟数据
      _dashboardData = LeaderDashboardData(
        poolOverview: PoolOverview(
          totalMembers: _members.length,
          activeTasks:
              _tasks.where((t) => t.status == TaskStatus.inProgress).length,
          completedTasks:
              _tasks.where((t) => t.status == TaskStatus.completed).length,
          averageTacitScore: 78.5,
          teamEfficiency: 0.85,
          upcomingDeadlines: _tasks
              .where((t) =>
                  t.expectedAt != null &&
                  t.expectedAt!.difference(DateTime.now()).inDays <= 3)
              .length,
        ),
        memberPerformance: _members
            .map((member) => MemberPerformance(
                  userId: member.id,
                  userName: member.name,
                  contributionScore: member.stats.contributionScore,
                  completedTasks: member.stats.completedTasks,
                  tacitScores: {
                    for (var otherId in _members
                        .where((m) => m.id != member.id)
                        .map((m) => m.id))
                      otherId: 75.0 + (member.id.hashCode % 20),
                  },
                  workloadBalance: 0.7 + (member.id.hashCode % 30) / 100,
                  skillUtilization: 0.6 + (member.id.hashCode % 40) / 100,
                  preferredTaskTypes: member.profile.preferredTaskTypes,
                  averageTaskCompletionTime:
                      Duration(minutes: 120 + (member.id.hashCode % 180)),
                ))
            .toList(),
        taskAnalytics: TaskAnalytics(
          tasksByStatus: {
            TaskStatus.pending:
                _tasks.where((t) => t.status == TaskStatus.pending).length,
            TaskStatus.inProgress:
                _tasks.where((t) => t.status == TaskStatus.inProgress).length,
            TaskStatus.completed:
                _tasks.where((t) => t.status == TaskStatus.completed).length,
            TaskStatus.blocked:
                _tasks.where((t) => t.status == TaskStatus.blocked).length,
          },
          tasksByDifficulty: {
            TaskDifficulty.easy:
                _tasks.where((t) => t.difficulty == TaskDifficulty.easy).length,
            TaskDifficulty.medium: _tasks
                .where((t) => t.difficulty == TaskDifficulty.medium)
                .length,
            TaskDifficulty.hard:
                _tasks.where((t) => t.difficulty == TaskDifficulty.hard).length,
            TaskDifficulty.expert: _tasks
                .where((t) => t.difficulty == TaskDifficulty.expert)
                .length,
          },
          averageCompletionTime: const Duration(hours: 18),
          bottlenecks: ['UI设计资源紧张', '后端接口依赖'],
          upcomingDeadlines: _tasks
              .where((t) =>
                  t.expectedAt != null && t.expectedAt!.isAfter(DateTime.now()))
              .map((t) => TaskDeadlineInfo(
                    taskId: t.id,
                    taskTitle: t.title,
                    assigneeId: t.assigneeId,
                    deadline: t.expectedAt!,
                    priority: t.priority,
                  ))
              .toList(),
        ),
        recommendations: [
          '建议将UI设计任务分配给张三，匹配度最高',
          '李四的后端技能可以应用到API优化任务',
          '团队默契度良好，可以考虑增加协作任务',
        ],
      );

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pool?.name ?? '队长管理面板'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: '总览'),
            Tab(icon: Icon(Icons.people), text: '成员'),
            Tab(icon: Icon(Icons.assignment), text: '任务'),
            Tab(icon: Icon(Icons.analytics), text: '分析'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dashboardData == null
              ? const Center(child: Text('加载数据失败'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildMembersTab(),
                    _buildTasksTab(),
                    _buildAnalyticsTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: _createNewTask,
              child: const Icon(Icons.add),
              tooltip: '创建新任务',
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    final data = _dashboardData!;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCards(data.poolOverview),
            const SizedBox(height: 24),
            _buildRecommendationsCard(data.recommendations),
            const SizedBox(height: 24),
            _buildQuickActionsCard(),
            const SizedBox(height: 24),
            _buildUpcomingDeadlinesCard(data.taskAnalytics.upcomingDeadlines),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(PoolOverview overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '项目概览',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildOverviewCard(
                '团队成员', '${overview.totalMembers}人', Icons.people, Colors.blue),
            _buildOverviewCard('进行中', '${overview.activeTasks}个',
                Icons.play_arrow, Colors.orange),
            _buildOverviewCard('已完成', '${overview.completedTasks}个',
                Icons.check_circle, Colors.green),
            _buildOverviewCard('即将到期', '${overview.upcomingDeadlines}个',
                Icons.schedule, Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildProgressCard(
                '团队默契度',
                overview.averageTacitScore / 100,
                '${overview.averageTacitScore.toInt()}%',
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProgressCard(
                '团队效率',
                overview.teamEfficiency,
                '${(overview.teamEfficiency * 100).toInt()}%',
                Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
      String title, double progress, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '智能推荐',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_right, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: [
                _buildQuickActionButton(
                    '智能分配', Icons.auto_awesome, _showSmartAssignment),
                _buildQuickActionButton('创建任务', Icons.add_task, _createNewTask),
                _buildQuickActionButton(
                    '团队分析', Icons.analytics, () => _tabController.animateTo(3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String title, IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color:
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingDeadlinesCard(List<TaskDeadlineInfo> deadlines) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  '即将到期的任务',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (deadlines.isEmpty)
              const Text('暂无即将到期的任务')
            else
              ...deadlines
                  .take(3)
                  .map((deadline) => _buildDeadlineItem(deadline)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineItem(TaskDeadlineInfo deadline) {
    final daysLeft = deadline.deadline.difference(DateTime.now()).inDays;
    final color = daysLeft <= 1
        ? Colors.red
        : daysLeft <= 3
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.taskTitle,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '还有 ${daysLeft}天 • ${deadline.assigneeId != null ? '已分配' : '待分配'}',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '团队成员',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._members.map(_buildMemberCard),
        ],
      ),
    );
  }

  Widget _buildMemberCard(User member) {
    final performance = _dashboardData?.memberPerformance
        .firstWhere((p) => p.userId == member.id,
            orElse: () => MemberPerformance(
                  userId: member.id,
                  userName: member.name,
                  contributionScore: member.stats.contributionScore,
                  completedTasks: member.stats.completedTasks,
                  tacitScores: {},
                  workloadBalance: 0.8,
                  skillUtilization: 0.7,
                  preferredTaskTypes: member.profile.preferredTaskTypes,
                  averageTaskCompletionTime: const Duration(hours: 20),
                ));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  child: Text(member.name[0]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 8),
                          if (_pool?.memberRoles[member.id] ==
                              MemberRole.leader)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '队长',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black),
                              ),
                            ),
                        ],
                      ),
                      if (member.profile.role != null)
                        Text(
                          member.profile.role!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.assignment),
                  onPressed: () => _assignTaskToMember(member),
                  tooltip: '分配任务',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 成员统计
            Row(
              children: [
                Expanded(
                  child: _buildMemberStat(
                    '完成任务',
                    '${performance?.completedTasks ?? 0}',
                    Icons.task_alt,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildMemberStat(
                    '贡献值',
                    '${(performance?.contributionScore ?? 0).toInt()}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
                Expanded(
                  child: _buildMemberStat(
                    '工作负载',
                    '${((performance?.workloadBalance ?? 0) * 100).toInt()}%',
                    Icons.work,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 技能展示
            if (member.profile.skills.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '核心技能',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: member.profile.skills
                    .take(4)
                    .map((skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            skill.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberStat(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '任务管理',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ..._tasks.map(_buildTaskCard),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final assignee = _members.firstWhere(
      (m) => m.id == task.assigneeId,
      orElse: () => User(
        id: '',
        name: '未分配',
        createdAt: DateTime.now(),
        stats: const UserStats(),
        profile: UserProfile(
          workStyle: const WorkStyle(
            communicationStyle: '平衡',
            workPace: '稳定',
            preferredCollaborationMode: '混合',
            stressHandling: '正常',
            feedbackStyle: '建设性',
          ),
          availability: const AvailabilityInfo(),
          contact: const ContactInfo(),
        ),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _buildTaskStatusChip(task.status),
              ],
            ),
            const SizedBox(height: 8),
            if (task.description != null)
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  assignee.name,
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.schedule, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${(task.estimatedMinutes / 60).toStringAsFixed(1)}h',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.bar_chart, size: 16),
                const SizedBox(width: 4),
                Text(
                  task.difficulty.displayName,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _editTask(task),
                    child: const Text('编辑'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: task.status == TaskStatus.pending
                        ? () => _reassignTask(task)
                        : null,
                    child: const Text('重新分配'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusChip(TaskStatus status) {
    Color color;
    String text;

    switch (status) {
      case TaskStatus.pending:
        color = Colors.grey;
        text = '待处理';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        text = '进行中';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = '已完成';
        break;
      case TaskStatus.blocked:
        color = Colors.red;
        text = '已阻塞';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final analytics = _dashboardData?.taskAnalytics;
    if (analytics == null) return const Center(child: Text('暂无分析数据'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '数据分析',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // 任务状态分布
          _buildAnalyticsCard(
            '任务状态分布',
            _buildTaskStatusChart(analytics.tasksByStatus),
          ),

          const SizedBox(height: 16),

          // 任务难度分布
          _buildAnalyticsCard(
            '任务难度分布',
            _buildTaskDifficultyChart(analytics.tasksByDifficulty),
          ),

          const SizedBox(height: 16),

          // 瓶颈分析
          _buildAnalyticsCard(
            '项目瓶颈',
            Column(
              children: analytics.bottlenecks
                  .map((bottleneck) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(bottleneck)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusChart(Map<TaskStatus, int> statusData) {
    final total = statusData.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const Text('暂无数据');

    return Column(
      children: statusData.entries.map((entry) {
        final percentage = (entry.value / total * 100).round();
        final statusText = _getStatusText(entry.key);
        final color = _getStatusColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(statusText),
              ),
              Text('${entry.value} ($percentage%)'),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskDifficultyChart(Map<TaskDifficulty, int> difficultyData) {
    final total = difficultyData.values.fold(0, (sum, count) => sum + count);
    if (total == 0) return const Text('暂无数据');

    return Column(
      children: difficultyData.entries.map((entry) {
        final percentage = (entry.value / total * 100).round();
        final difficultyText = entry.key.displayName;
        final color = _getDifficultyColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(difficultyText),
              ),
              Text('${entry.value} ($percentage%)'),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待处理';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.blocked:
        return '已阻塞';
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.blocked:
        return Colors.red;
    }
  }

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green;
      case TaskDifficulty.medium:
        return Colors.orange;
      case TaskDifficulty.hard:
        return Colors.red;
      case TaskDifficulty.expert:
        return Colors.purple;
    }
  }

  void _showSmartAssignment() async {
    // 获取智能分配建议
    final suggestions =
        await EnhancedCollaborationPoolService.getSmartAssignmentSuggestions(
      widget.poolId,
      widget.currentUser.id,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => SmartAssignmentDialog(
        suggestions: suggestions,
        members: _members,
        onAssign: (taskId, userId) => _assignTaskToUser(taskId, userId),
      ),
    );
  }

  void _createNewTask() {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        poolId: widget.poolId,
        createdBy: widget.currentUser.id,
        onTaskCreated: (task) {
          setState(() {
            _tasks.add(task);
          });
        },
      ),
    );
  }

  void _assignTaskToMember(User member) {
    final availableTasks = _tasks
        .where((t) => t.status == TaskStatus.pending && t.assigneeId == null)
        .toList();

    if (availableTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无可分配的任务')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AssignTaskDialog(
        member: member,
        availableTasks: availableTasks,
        onAssign: (taskId) => _assignTaskToUser(taskId, member.id),
      ),
    );
  }

  void _assignTaskToUser(String taskId, String userId) async {
    try {
      // 这里应该调用API分配任务
      // await TaskService.assignTask(taskId, userId);

      setState(() {
        final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
        if (taskIndex != -1) {
          _tasks[taskIndex] = _tasks[taskIndex].copyWith(
            assigneeId: userId,
            status: TaskStatus.inProgress,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务分配成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('任务分配失败：$e')),
      );
    }
  }

  void _editTask(Task task) {
    // 实现编辑任务功能
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑任务'),
        content: const Text('编辑任务功能即将上线'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _reassignTask(Task task) {
    final availableMembers =
        _members.where((m) => m.id != task.assigneeId).toList();

    showDialog(
      context: context,
      builder: (context) => ReassignTaskDialog(
        task: task,
        availableMembers: availableMembers,
        onReassign: (newUserId) => _assignTaskToUser(task.id, newUserId),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// 智能分配对话框
class SmartAssignmentDialog extends StatelessWidget {
  final List<SmartAssignmentSuggestion> suggestions;
  final List<User> members;
  final Function(String taskId, String userId) onAssign;

  const SmartAssignmentDialog({
    Key? key,
    required this.suggestions,
    required this.members,
    required this.onAssign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('智能任务分配'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: suggestions.isEmpty
            ? const Center(child: Text('暂无分配建议'))
            : ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = suggestions[index];
                  final member = members.firstWhere(
                    (m) => m.id == suggestion.userId,
                    orElse: () => User(
                      id: suggestion.userId,
                      name: '未知用户',
                      createdAt: DateTime.now(),
                      stats: const UserStats(),
                      profile: UserProfile(
                        workStyle: const WorkStyle(
                          communicationStyle: '平衡',
                          workPace: '稳定',
                          preferredCollaborationMode: '混合',
                          stressHandling: '正常',
                          feedbackStyle: '建设性',
                        ),
                        availability: const AvailabilityInfo(),
                        contact: const ContactInfo(),
                      ),
                    ),
                  );

                  return Card(
                    child: ListTile(
                      title: Text(suggestion.taskTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('推荐给：${member.name}'),
                          Text('匹配度：${(suggestion.matchScore * 100).toInt()}%'),
                          Text('原因：${suggestion.reason}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          onAssign(suggestion.taskId, suggestion.userId);
                          Navigator.of(context).pop();
                        },
                        child: const Text('分配'),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

// 创建任务对话框
class CreateTaskDialog extends StatefulWidget {
  final String poolId;
  final String createdBy;
  final Function(Task) onTaskCreated;

  const CreateTaskDialog({
    Key? key,
    required this.poolId,
    required this.createdBy,
    required this.onTaskCreated,
  }) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskDifficulty _difficulty = TaskDifficulty.medium;
  TaskPriority _priority = TaskPriority.medium;
  int _estimatedMinutes = 480;
  List<String> _requiredSkills = [];
  DateTime? _expectedAt;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('创建新任务'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '任务标题'),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return '请输入任务标题';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '任务描述'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskDifficulty>(
                value: _difficulty,
                decoration: const InputDecoration(labelText: '任务难度'),
                items: TaskDifficulty.values
                    .map((difficulty) => DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty.displayName),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _difficulty = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: '优先级'),
                items: TaskPriority.values
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(_getPriorityText(priority)),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('创建'),
        ),
      ],
    );
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return '紧急';
      case TaskPriority.high:
        return '高';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.low:
        return '低';
    }
  }

  void _createTask() {
    if (!_formKey.currentState!.validate()) return;

    final task = Task(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      poolId: widget.poolId,
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      difficulty: _difficulty,
      priority: _priority,
      estimatedMinutes: _estimatedMinutes,
      requiredSkills: _requiredSkills,
      createdAt: DateTime.now(),
      expectedAt: _expectedAt,
      statistics: const TaskStatistics(),
      createdBy: widget.createdBy,
    );

    widget.onTaskCreated(task);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// 分配任务对话框
class AssignTaskDialog extends StatelessWidget {
  final User member;
  final List<Task> availableTasks;
  final Function(String taskId) onAssign;

  const AssignTaskDialog({
    Key? key,
    required this.member,
    required this.availableTasks,
    required this.onAssign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('为 ${member.name} 分配任务'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: availableTasks.length,
          itemBuilder: (context, index) {
            final task = availableTasks[index];

            return ListTile(
              title: Text(task.title),
              subtitle: Text(task.difficulty.displayName),
              trailing: ElevatedButton(
                onPressed: () {
                  onAssign(task.id);
                  Navigator.of(context).pop();
                },
                child: const Text('分配'),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}

// 重新分配任务对话框
class ReassignTaskDialog extends StatelessWidget {
  final Task task;
  final List<User> availableMembers;
  final Function(String userId) onReassign;

  const ReassignTaskDialog({
    Key? key,
    required this.task,
    required this.availableMembers,
    required this.onReassign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('重新分配：${task.title}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: availableMembers.length,
          itemBuilder: (context, index) {
            final member = availableMembers[index];

            return ListTile(
              leading: CircleAvatar(
                child: Text(member.name[0]),
              ),
              title: Text(member.name),
              subtitle: Text(member.profile.role ?? ''),
              trailing: ElevatedButton(
                onPressed: () {
                  onReassign(member.id);
                  Navigator.of(context).pop();
                },
                child: const Text('分配'),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
      ],
    );
  }
}
