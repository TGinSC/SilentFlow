import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/team_pool_provider.dart';
import '../../services/task_service.dart';
import '../../widgets/task_creation_dialog.dart';
import '../workflow/workflow_screen.dart';
import 'task_detail_screen.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasks = [];
  List<Task> _myTasks = [];
  List<Task> _availableTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  TaskStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 🆕 立即加载任务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();

      // 监听团队池变化，自动刷新任务
      final teamPoolProvider = context.read<TeamPoolProvider>();
      teamPoolProvider.addListener(_onTeamPoolChanged);
    });
  }

  @override
  void dispose() {
    // 🆕 移除监听器
    final teamPoolProvider = context.read<TeamPoolProvider>();
    teamPoolProvider.removeListener(_onTeamPoolChanged);
    _tabController.dispose();
    super.dispose();
  }

  // 🆕 团队池变化处理
  void _onTeamPoolChanged() {
    print('TaskBoardScreen: 团队池发生变化，重新加载任务');
    // 🔧 减少延迟时间，更快响应变化
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _loadTasks();
      }
    });
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final teamPoolProvider = context.read<TeamPoolProvider>();
      final userId = appProvider.currentUser?.id;

      if (userId == null) {
        print('TaskBoardScreen: 用户ID为空，无法加载任务');
        setState(() {
          _tasks = [];
          _myTasks = [];
          _availableTasks = [];
          _isLoading = false;
        });
        return;
      }

      print('TaskBoardScreen: 开始加载用户 $userId 的任务');
      print('TaskBoardScreen: 当前团队池数量: ${teamPoolProvider.teamPools.length}');

      // 🔧 修复：确保先获取用户的团队列表
      final userTeams = teamPoolProvider.teamPools
          .where((team) =>
              team.memberIds.contains(userId) || team.leaderId == userId)
          .toList();

      print('TaskBoardScreen: 用户参与的团队数量: ${userTeams.length}');
      for (var team in userTeams) {
        print('TaskBoardScreen: 团队 - ID: ${team.id}, 名称: ${team.name}');
      }

      _tasks = [];

      // 🔧 增强：并行加载所有团队的任务，提高效率
      final taskLoadFutures = userTeams.map((team) async {
        try {
          print('TaskBoardScreen: 加载团队 ${team.id} (${team.name}) 的任务');
          final teamTasks = await TaskService.getTeamTasks(team.id);
          print('TaskBoardScreen: 团队 ${team.id} 加载到 ${teamTasks.length} 个任务');
          return teamTasks;
        } catch (e) {
          print('TaskBoardScreen: 加载团队 ${team.id} 的任务失败: $e');
          return <Task>[];
        }
      }).toList();

      // 等待所有团队任务加载完成
      final allTeamTasks = await Future.wait(taskLoadFutures);

      // 合并所有团队的任务
      for (final teamTasks in allTeamTasks) {
        _tasks.addAll(teamTasks);
      }

      print('TaskBoardScreen: 总共加载了 ${_tasks.length} 个任务');

      // 🔧 优化：任务分类逻辑
      _myTasks = _tasks
          .where((task) =>
              task.assignedUsers.contains(userId) || task.assigneeId == userId)
          .toList();

      _availableTasks = _tasks
          .where((task) =>
              task.status == TaskStatus.pending &&
              !task.assignedUsers.contains(userId) &&
              task.assigneeId != userId)
          .toList();

      print('TaskBoardScreen: 我的任务: ${_myTasks.length} 个');
      print('TaskBoardScreen: 可认领任务: ${_availableTasks.length} 个');

      setState(() {});
    } catch (e) {
      print('TaskBoardScreen: 加载任务异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载任务失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Task> _getFilteredTasks(List<Task> tasks) {
    var filtered = tasks;

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((task) =>
              task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (task.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false) ||
              task.tags.any((tag) =>
                  tag.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }

    // 状态过滤
    if (_filterStatus != null) {
      filtered =
          filtered.where((task) => task.status == _filterStatus).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 使用Consumer监听团队池变化
    return Consumer<TeamPoolProvider>(
      builder: (context, teamPoolProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('任务面板'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.assignment_ind), text: '我的任务'),
                Tab(icon: Icon(Icons.assignment), text: '可认领'),
                Tab(icon: Icon(Icons.dashboard), text: '全部任务'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_tree),
                tooltip: '工作流图',
                onPressed: () => _navigateToWorkflowGraph(),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadTasks,
              ),
              // 🔧 修改显示逻辑：显示更详细的调试信息
              if (teamPoolProvider.teamPools.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${teamPoolProvider.teamPools.length}团',
                        style: const TextStyle(fontSize: 11),
                      ),
                      Text(
                        '${_tasks.length}任务',
                        style: const TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // 搜索和筛选栏
              _buildSearchAndFilter(),

              // 任务列表
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildHierarchicalTaskList(
                              _getFilteredTasks(_myTasks), true),
                          _buildHierarchicalTaskList(
                              _getFilteredTasks(_availableTasks), false),
                          _buildHierarchicalTaskList(
                              _getFilteredTasks(_tasks), false),
                        ],
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showCreateTaskDialog(),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // 搜索框
          TextField(
            decoration: InputDecoration(
              hintText: '搜索任务...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor:
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // 状态筛选和快速工具
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: _filterStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('待处理'),
                        selected: _filterStatus == TaskStatus.pending,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus =
                                selected ? TaskStatus.pending : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('进行中'),
                        selected: _filterStatus == TaskStatus.inProgress,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus =
                                selected ? TaskStatus.inProgress : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('已完成'),
                        selected: _filterStatus == TaskStatus.completed,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus =
                                selected ? TaskStatus.completed : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('被阻塞'),
                        selected: _filterStatus == TaskStatus.blocked,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus =
                                selected ? TaskStatus.blocked : null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 工作流图快速访问按钮
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _navigateToWorkflowGraph,
                  icon: const Icon(Icons.account_tree),
                  color: const Color(0xFF667eea),
                  tooltip: '查看工作流图',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHierarchicalTaskList(List<Task> tasks, bool isMyTasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              isMyTasks ? '暂无分配的任务' : '暂无可认领的任务',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    // 按层级组织任务
    final projects = tasks.where((t) => t.level == TaskLevel.project).toList();
    final regularTasks = tasks
        .where((t) => t.level == TaskLevel.task && t.parentTaskId == null)
        .toList();
    final taskPoints =
        tasks.where((t) => t.level == TaskLevel.taskPoint).toList();

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 显示项目级任务
          if (projects.isNotEmpty) ...[
            _buildSectionHeader('项目 (${projects.length})'),
            ...projects.map((project) => _buildProjectCard(project, isMyTasks)),
            const SizedBox(height: 16),
          ],

          // 显示独立任务（不属于任何项目的任务）
          if (regularTasks.isNotEmpty) ...[
            _buildSectionHeader('独立任务 (${regularTasks.length})'),
            ...regularTasks.map((task) => _buildTaskCard(task, isMyTasks)),
            const SizedBox(height: 16),
          ],

          // 显示孤立的任务点（如果有的话）
          if (taskPoints
              .any((tp) => !tasks.any((t) => t.id == tp.parentTaskId))) ...[
            _buildSectionHeader('其他任务点'),
            ...taskPoints
                .where((tp) => !tasks.any((t) => t.id == tp.parentTaskId))
                .map(
                    (task) => _buildTaskCard(task, isMyTasks, isSubTask: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.label, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const Expanded(child: Divider(indent: 16)),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Task project, bool isMyTask) {
    final colorScheme = Theme.of(context).colorScheme;

    // 查找属于这个项目的子任务
    final projectSubTasks =
        _tasks.where((t) => t.parentTaskId == project.id).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // 项目主体
            _buildTaskCard(project, isMyTask, isInProjectCard: true),

            // 项目的子任务
            if (projectSubTasks.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
                child: Text(
                  '子任务 (${projectSubTasks.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              ...projectSubTasks.map((subTask) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildTaskCard(subTask, isMyTask, isSubTask: true),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isMyTask,
      {bool isInProjectCard = false, bool isSubTask = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isProject = task.level == TaskLevel.project;

    // 根据层级确定样式
    Color? borderColor;
    double elevation = 1;
    EdgeInsets margin = const EdgeInsets.only(bottom: 12);
    IconData leadingIcon;
    Color leadingIconColor;

    if (isProject && !isInProjectCard) {
      borderColor = colorScheme.primary;
      elevation = 4;
      leadingIcon = Icons.folder;
      leadingIconColor = colorScheme.primary;
    } else if (isSubTask) {
      leadingIcon = Icons.subdirectory_arrow_right;
      leadingIconColor = colorScheme.tertiary;
      margin = const EdgeInsets.only(bottom: 8, left: 8, right: 8);
    } else {
      leadingIcon = Icons.assignment;
      leadingIconColor = colorScheme.secondary;
    }

    return Container(
      margin: margin,
      child: Card(
        elevation: elevation,
        child: Container(
          decoration: borderColor != null && !isInProjectCard
              ? BoxDecoration(
                  border: Border.all(color: borderColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: ListTile(
            contentPadding: EdgeInsets.all(isSubTask ? 12 : 16),
            leading: Icon(leadingIcon,
                color: leadingIconColor, size: isSubTask ? 20 : 24),
            title: Row(
              children: [
                if (isProject && !isInProjectCard)
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                if (isProject && !isInProjectCard) const SizedBox(width: 4),
                if (isSubTask)
                  const Icon(Icons.arrow_right, color: Colors.grey, size: 16),
                if (isSubTask) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: isProject
                          ? FontWeight.w700
                          : isSubTask
                              ? FontWeight.w500
                              : FontWeight.bold,
                      fontSize: isProject
                          ? 16
                          : isSubTask
                              ? 13
                              : 14,
                      color: isProject
                          ? colorScheme.primary
                          : isSubTask
                              ? colorScheme.tertiary
                              : null,
                    ),
                  ),
                ),
                if (!isInProjectCard) _buildLevelChip(task.level),
                if (!isInProjectCard) const SizedBox(width: 8),
                _buildStatusChip(task.status),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (task.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description!,
                    maxLines: isProject
                        ? 3
                        : isSubTask
                            ? 1
                            : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: isSubTask ? 12 : 14),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${task.estimatedMinutes}分钟',
                        style: TextStyle(fontSize: isSubTask ? 11 : 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.flag,
                        size: 14, color: _getPriorityColor(task.priority)),
                    const SizedBox(width: 4),
                    Text(task.priority.displayName,
                        style: TextStyle(fontSize: isSubTask ? 11 : 12)),
                  ],
                ),
              ],
            ),
            trailing: isMyTask
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handleTaskAction(task, value),
                    itemBuilder: (context) => [
                      if (task.level == TaskLevel.project)
                        const PopupMenuItem(
                            value: 'create_subtask', child: Text('创建子任务')),
                      if (task.status == TaskStatus.pending)
                        const PopupMenuItem(
                            value: 'start', child: Text('开始任务')),
                      if (task.status == TaskStatus.inProgress)
                        const PopupMenuItem(
                            value: 'complete', child: Text('完成任务')),
                      if (task.status == TaskStatus.inProgress)
                        const PopupMenuItem(
                            value: 'block', child: Text('标记阻塞')),
                      const PopupMenuItem(
                          value: 'details', child: Text('查看详情')),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.assignment_turned_in),
                    onPressed: () => _claimTask(task),
                  ),
            onTap: () => _showTaskDetails(task),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(TaskLevel level) {
    final colorScheme = Theme.of(context).colorScheme;

    Color chipColor;
    String chipText;
    IconData chipIcon;

    switch (level) {
      case TaskLevel.project:
        chipColor = colorScheme.primary;
        chipText = '项目';
        chipIcon = Icons.folder;
        break;
      case TaskLevel.task:
        chipColor = colorScheme.secondary;
        chipText = '任务';
        chipIcon = Icons.assignment;
        break;
      case TaskLevel.taskPoint:
        chipColor = colorScheme.tertiary;
        chipText = '任务点';
        chipIcon = Icons.task_alt;
        break;
    }

    return Chip(
      avatar: Icon(chipIcon, size: 16, color: Colors.white),
      label: Text(
        chipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case TaskStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        icon = Icons.play_arrow;
        break;
      case TaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case TaskStatus.blocked:
        color = Colors.red;
        icon = Icons.block;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.urgent:
        return Colors.red;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.low:
        return Colors.green;
    }
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
        return '被阻塞';
    }
  }

  void _handleTaskAction(Task task, String action) {
    switch (action) {
      case 'create_subtask':
        _createSubTask(task);
        break;
      case 'start':
        _startTask(task);
        break;
      case 'complete':
        _completeTask(task);
        break;
      case 'block':
        _blockTask(task);
        break;
      case 'details':
        _showTaskDetails(task);
        break;
    }
  }

  Future<void> _createSubTask(Task parentTask) async {
    final teamPoolProvider = context.read<TeamPoolProvider>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreationDialog(
        team: teamPoolProvider.currentTeam,
        parentTask: parentTask,
      ),
    );

    if (result == true) {
      _loadTasks(); // 重新加载任务列表
    }
  }

  Future<void> _startTask(Task task) async {
    try {
      await TaskService.updateTaskStatus(
        teamId: task.poolId,
        taskId: task.id,
        status: TaskStatus.inProgress,
      );
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已开始')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始任务失败: $e')),
        );
      }
    }
  }

  Future<void> _completeTask(Task task) async {
    try {
      await TaskService.updateTaskStatus(
        teamId: task.poolId,
        taskId: task.id,
        status: TaskStatus.completed,
      );
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已完成')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('完成任务失败: $e')),
        );
      }
    }
  }

  Future<void> _blockTask(Task task) async {
    try {
      await TaskService.updateTaskStatus(
        teamId: task.poolId,
        taskId: task.id,
        status: TaskStatus.blocked,
      );
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已标记为阻塞')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('阻塞任务失败: $e')),
        );
      }
    }
  }

  Future<void> _claimTask(Task task) async {
    final appProvider = context.read<AppProvider>();
    final userId = appProvider.currentUser?.id;

    if (userId == null) return;

    try {
      await TaskService.updateTaskStatus(
        teamId: task.poolId,
        taskId: task.id,
        status: TaskStatus.inProgress,
        assigneeId: userId,
      );
      _loadTasks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已认领')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('认领任务失败: $e')),
        );
      }
    }
  }

  void _showTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    ).then((result) {
      if (result == true) {
        _loadTasks(); // 如果任务被修改或删除，重新加载任务列表
      }
    });
  }

  Future<void> _showCreateTaskDialog() async {
    final teamPoolProvider = context.read<TeamPoolProvider>();

    // 🔧 确保有可用的团队
    if (teamPoolProvider.teamPools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先创建或加入团队，然后再创建任务'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreationDialog(
        team: teamPoolProvider.currentTeam ?? teamPoolProvider.teamPools.first,
      ),
    );

    if (result == true) {
      print('TaskBoardScreen: 任务创建成功，重新加载任务列表');
      _loadTasks();
    }
  }

  void _navigateToWorkflowGraph() {
    final teamPoolProvider = context.read<TeamPoolProvider>();

    if (teamPoolProvider.teamPools.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('您还没有加入任何团队，请先创建或加入团队'),
          backgroundColor: Color(0xFFED8936),
        ),
      );
      return;
    }

    // 🔧 选择当前团队或第一个可用团队
    final selectedTeam =
        teamPoolProvider.currentTeam ?? teamPoolProvider.teamPools.first;

    print('TaskBoardScreen: 导航到工作流图，团队: ${selectedTeam.name}');

    // 直接导航到工作流页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkflowScreen(
          teamId: selectedTeam.id,
          teamName: selectedTeam.name,
        ),
      ),
    );
  }
}
