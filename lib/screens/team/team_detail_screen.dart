import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_pool_model.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/user_service.dart';
import '../../services/task_service.dart';
import '../../widgets/task_creation_dialog.dart';

class TeamDetailScreen extends StatefulWidget {
  final TeamPool team;

  const TeamDetailScreen({
    super.key,
    required this.team,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<User> _teamMembers = [];
  List<Task> _teamTasks = [];
  Task? _teamProject; // 团队项目（总任务）
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 增加到4个Tab
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 加载团队成员信息
      await _loadTeamMembers();

      // 加载团队任务（包括项目）
      await _loadTeamTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载团队数据失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTeamMembers() async {
    _teamMembers = [];
    for (final memberId in widget.team.memberIds) {
      final member = await UserService.getUserProfile(memberId);
      if (member != null) {
        _teamMembers.add(member);
      }
    }
  }

  Future<void> _loadTeamTasks() async {
    // 获取所有团队任务
    final allTasks = await TaskService.getAllTasks();
    _teamTasks =
        allTasks.where((task) => task.poolId == widget.team.id).toList();

    // 找到团队项目（Level.project的任务）
    _teamProject = _teamTasks.firstWhere(
      (task) => task.level == TaskLevel.project,
      orElse: () => Task(
        id: 'default_project_${widget.team.id}',
        poolId: widget.team.id,
        title: widget.team.name,
        description: widget.team.description,
        estimatedMinutes: 2400, // 默认40小时
        expectedAt: DateTime.now().add(const Duration(days: 30)),
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        statistics: const TaskStatistics(),
        priority: TaskPriority.high,
        baseReward: 100.0,
        level: TaskLevel.project,
        tags: widget.team.tags,
        assignedUsers: widget.team.memberIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航栏
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.team.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.team.teamType.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildTeamActions(),
                  ],
                ),
              ),

              // Tab栏
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: Colors.white,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: '概览'),
                    Tab(text: '项目'),
                    Tab(text: '成员'),
                    Tab(text: '任务'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 内容区域
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildProjectTab(),
                            _buildMembersTab(),
                            _buildTasksTab(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamActions() {
    final appProvider = context.read<AppProvider>();
    final currentUserId = appProvider.currentUser?.id;
    final isLeader = widget.team.leaderId == currentUserId;
    final isMember = widget.team.memberIds.contains(currentUserId);

    return PopupMenuButton<String>(
      onSelected: _handleAction,
      icon: const Icon(Icons.more_vert, color: Colors.white),
      itemBuilder: (context) => [
        if (isLeader) ...[
          const PopupMenuItem(value: 'edit', child: Text('编辑团队')),
          const PopupMenuItem(value: 'manage_members', child: Text('管理成员')),
          const PopupMenuItem(value: 'team_settings', child: Text('团队设置')),
        ],
        if (isMember && !isLeader)
          const PopupMenuItem(value: 'leave_team', child: Text('退出团队')),
        const PopupMenuItem(value: 'share', child: Text('分享团队')),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 团队统计卡片
          _buildTeamStatsCard(),
          const SizedBox(height: 16),

          // 项目概览卡片
          if (_teamProject != null) _buildProjectOverviewCard(),
          if (_teamProject != null) const SizedBox(height: 16),

          // 团队描述
          _buildDescriptionCard(),
          const SizedBox(height: 16),

          // 团队标签
          if (widget.team.tags.isNotEmpty) _buildTagsCard(),

          const SizedBox(height: 16),

          // 最近动态
          _buildRecentActivitiesCard(),
        ],
      ),
    );
  }

  Widget _buildProjectTab() {
    if (_teamProject == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无项目',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createTeamProject,
              icon: const Icon(Icons.add),
              label: const Text('创建团队项目'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 项目基本信息
          _buildProjectInfoCard(),
          const SizedBox(height: 16),

          // 项目进度
          _buildProjectProgressCard(),
          const SizedBox(height: 16),

          // 项目成员分工
          _buildProjectAssignmentsCard(),
          const SizedBox(height: 16),

          // 项目里程碑
          _buildProjectMilestonesCard(),
        ],
      ),
    );
  }

  Widget _buildTeamStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '团队统计',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.people,
                    '成员数',
                    '${widget.team.memberIds.length}/${widget.team.maxMembers}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.task_alt,
                    '任务',
                    widget.team.statistics.totalTasksCompleted.toString(),
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.check_circle,
                    '完成率',
                    '${(widget.team.statistics.onTimeCompletionRate * 100).toInt()}%',
                    Colors.purple,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.trending_up,
                    '效率',
                    '${(widget.team.statistics.teamEfficiency * 100).toInt()}%',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildProjectOverviewCard() {
    if (_teamProject == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '团队项目',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildStatusChip(_teamProject!.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _teamProject!.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            if (_teamProject!.description != null) ...[
              const SizedBox(height: 4),
              Text(
                _teamProject!.description!,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${_teamProject!.estimatedMinutes}分钟'),
                const SizedBox(width: 16),
                Icon(Icons.flag,
                    size: 16, color: _getPriorityColor(_teamProject!.priority)),
                const SizedBox(width: 4),
                Text(_teamProject!.priority.displayName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '团队描述',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.team.description.isNotEmpty
                  ? widget.team.description
                  : '暂无描述',
              style: TextStyle(
                color: widget.team.description.isNotEmpty
                    ? Colors.black87
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '团队标签',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.team.tags
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamMembers.length,
      itemBuilder: (context, index) {
        final member = _teamMembers[index];
        final role = widget.team.memberRoles[member.id] ?? MemberRole.member;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.displayName),
                if (member.profile.skills.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: member.profile.skills
                        .take(3)
                        .map(
                          (skill) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              skill.name,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.blue),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
            trailing: _buildMemberActions(member, role),
          ),
        );
      },
    );
  }

  Widget _buildMemberActions(User member, MemberRole role) {
    final appProvider = context.read<AppProvider>();
    final currentUserId = appProvider.currentUser?.id;
    final isLeader = widget.team.leaderId == currentUserId;

    if (!isLeader || member.id == currentUserId) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      onSelected: (value) => _handleMemberAction(member, value),
      itemBuilder: (context) => [
        if (role != MemberRole.coLeader)
          const PopupMenuItem(value: 'promote', child: Text('提升为副队长')),
        if (role == MemberRole.coLeader)
          const PopupMenuItem(value: 'demote', child: Text('取消副队长')),
        const PopupMenuItem(value: 'remove', child: Text('移除成员')),
      ],
    );
  }

  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '团队任务',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _createNewTask,
                icon: const Icon(Icons.add),
                label: const Text('创建任务'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_teamProject != null) ...[
            // 团队项目卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.folder,
                            color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _teamProject!.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: const Text('团队项目'),
                          backgroundColor: Theme.of(context).primaryColor,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    if (_teamProject!.description != null) ...[
                      const SizedBox(height: 8),
                      Text(_teamProject!.description!),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatusChip(_teamProject!.status),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _createSubTask(_teamProject!),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('创建子任务'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            '暂无其他任务',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        color = Colors.orange;
        text = '待处理';
        icon = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        text = '进行中';
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        text = '已完成';
        icon = Icons.check_circle;
        break;
      case TaskStatus.blocked:
        color = Colors.red;
        text = '被阻塞';
        icon = Icons.block;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.grey;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  void _handleAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action功能即将上线')),
    );
  }

  void _handleMemberAction(User member, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('对${member.name}的$action功能即将上线')),
    );
  }

  void _createNewTask() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreationDialog(
        team: widget.team,
      ),
    );

    if (result == true) {
      _loadTeamData();
    }
  }

  void _createSubTask(Task parentTask) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreationDialog(
        team: widget.team,
        parentTask: parentTask,
      ),
    );

    if (result == true) {
      _loadTeamData();
    }
  }

  void _createTeamProject() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreationDialog(
        team: widget.team,
      ),
    );

    if (result == true) {
      _loadTeamData();
    }
  }

  Widget _buildRecentActivitiesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '最近动态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 这里之后可以添加实际的活动数据
            const Center(
              child: Text(
                '暂无最近动态',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfoCard() {
    if (_teamProject == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目信息',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('项目名称', _teamProject!.title),
            if (_teamProject!.description != null)
              _buildInfoRow('项目描述', _teamProject!.description!),
            _buildInfoRow('预估时间', '${_teamProject!.estimatedMinutes}分钟'),
            _buildInfoRow('优先级', _teamProject!.priority.displayName),
            _buildInfoRow('状态', _teamProject!.status.displayName),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目进度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 这里之后可以添加进度条和统计信息
            const Center(
              child: Text(
                '进度统计功能开发中',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectAssignmentsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '成员分工',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '成员分工功能开发中',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectMilestonesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '项目里程碑',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '里程碑功能开发中',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
