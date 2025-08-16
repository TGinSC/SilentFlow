import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../models/subtask_model.dart';
import '../../providers/app_provider.dart';
import '../../services/task_service.dart';

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
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final userId = appProvider.currentUser?.id;

      if (userId != null) {
        // 加载所有任务
        _tasks = await TaskService.getAllTasks();

        // 分类任务
        _myTasks = _tasks
            .where((task) =>
                task.assignedUsers.contains(userId) ||
                task.assigneeId == userId)
            .toList();

        _availableTasks = _tasks
            .where((task) =>
                task.status == TaskStatus.pending &&
                !task.assignedUsers.contains(userId) &&
                task.assigneeId != userId)
            .toList();

        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载任务失败: $e')),
      );
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
    final colorScheme = Theme.of(context).colorScheme;

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
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索和筛选栏
          _buildSearchAndFilter(colorScheme),

          // 任务列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(_getFilteredTasks(_myTasks), true),
                      _buildTaskList(_getFilteredTasks(_availableTasks), false),
                      _buildTaskList(_getFilteredTasks(_tasks), false),
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
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
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
              fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),

          // 状态筛选
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('全部'),
                  selected: _filterStatus == null,
                  onSelected: (selected) {
                    setState(() {
                      _filterStatus = selected ? null : _filterStatus;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...TaskStatus.values.map((status) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getStatusText(status)),
                        selected: _filterStatus == status,
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = selected ? status : null;
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, bool isMyTasks) {
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

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _buildTaskCard(task, isMyTasks);
        },
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isMyTask) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // 任务主体
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),

                // 任务信息行
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${task.estimatedMinutes}分钟'),
                    const SizedBox(width: 16),
                    Icon(Icons.flag,
                        size: 16, color: _getPriorityColor(task.priority)),
                    const SizedBox(width: 4),
                    Text(task.priority.displayName),
                    const SizedBox(width: 16),
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(task.difficulty.displayName),
                  ],
                ),

                // 进度条
                if (task.subTasks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: task.progress,
                          backgroundColor: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${(task.progress * 100).toInt()}%'),
                    ],
                  ),
                ],

                // 标签
                if (task.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: task.tags
                        .take(3)
                        .map((tag) => Chip(
                              label: Text(tag),
                              labelStyle: const TextStyle(fontSize: 12),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
            trailing: isMyTask
                ? PopupMenuButton<String>(
                    onSelected: (value) => _handleTaskAction(task, value),
                    itemBuilder: (context) => [
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

          // 子任务预览
          if (task.subTasks.isNotEmpty) _buildSubTasksPreview(task),
        ],
      ),
    );
  }

  Widget _buildSubTasksPreview(Task task) {
    final completedSubTasks = task.subTasks
        .where((st) => st.status == SubTaskStatus.completed)
        .length;
    final totalSubTasks = task.subTasks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '子任务 ($completedSubTasks/$totalSubTasks)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _showTaskDetails(task),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 显示前3个子任务
          ...task.subTasks.take(3).map((subTask) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      subTask.status == SubTaskStatus.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: subTask.status == SubTaskStatus.completed
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subTask.title,
                        style: TextStyle(
                          decoration: subTask.status == SubTaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (subTask.assignedUserId != null)
                      const Icon(Icons.person, size: 16),
                  ],
                ),
              )),
        ],
      ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
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

  Future<void> _startTask(Task task) async {
    try {
      await TaskService.updateTaskStatus(
        teamId: task.poolId,
        taskId: task.id,
        status: TaskStatus.inProgress,
      );
      _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务已开始')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('开始任务失败: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务已完成')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('完成任务失败: $e')),
      );
    }
  }

  Future<void> _blockTask(Task task) async {
    // 显示阻塞原因对话框
    BlockReason? reason = await _showBlockReasonDialog();
    if (reason != null) {
      try {
        await TaskService.blockTask(
          teamId: task.poolId,
          taskId: task.id,
          blockReason: reason,
        );
        _loadTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已标记为阻塞')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('标记阻塞失败: $e')),
        );
      }
    }
  }

  Future<void> _claimTask(Task task) async {
    try {
      final userId = context.read<AppProvider>().currentUser?.id;
      if (userId != null) {
        // 认领任务实际上是更新任务状态并分配给用户
        await TaskService.updateTaskStatus(
          teamId: task.poolId,
          taskId: task.id,
          status: TaskStatus.inProgress,
          assigneeId: userId,
        );
        _loadTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已认领')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('认领任务失败: $e')),
      );
    }
  }

  void _showTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    ).then((_) => _loadTasks());
  }

  Future<BlockReason?> _showBlockReasonDialog() async {
    BlockReason? selectedReason;
    return showDialog<BlockReason>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择阻塞原因'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BlockReason.values
              .map((reason) => RadioListTile<BlockReason>(
                    title: Text(_getBlockReasonText(reason)),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      selectedReason = value;
                      Navigator.pop(context, selectedReason);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  String _getBlockReasonText(BlockReason reason) {
    switch (reason) {
      case BlockReason.lackOfTools:
        return '缺少工具';
      case BlockReason.needHelp:
        return '需要帮助';
      case BlockReason.timeConflict:
        return '时间冲突';
      case BlockReason.other:
        return '其他原因';
    }
  }

  void _showCreateTaskDialog() {
    // TODO: 实现创建任务对话框
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建任务功能开发中...')),
    );
  }
}

// 任务详情页面
class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 任务基本信息
            _buildTaskHeader(),
            const SizedBox(height: 24),

            // 任务描述
            if (_task.description != null) ...[
              _buildSectionTitle('任务描述'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_task.description!),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 子任务列表
            if (_task.subTasks.isNotEmpty) ...[
              _buildSectionTitle('子任务'),
              _buildSubTasksList(),
              const SizedBox(height: 24),
            ],

            // 任务统计
            _buildTaskStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(_task.status),
              ],
            ),
            const SizedBox(height: 16),

            // 任务信息网格
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: [
                _buildInfoTile(
                    '预计时间', '${_task.estimatedMinutes}分钟', Icons.schedule),
                _buildInfoTile('优先级', _task.priority.displayName, Icons.flag),
                _buildInfoTile('难度', _task.difficulty.displayName, Icons.star),
                _buildInfoTile('奖励', '${_task.baseReward.toInt()}分',
                    Icons.monetization_on),
              ],
            ),

            // 进度条
            if (_task.subTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('完成进度: '),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _task.progress,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(_task.progress * 100).toInt()}%'),
                ],
              ),
            ],

            // 标签
            if (_task.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _task.tags
                    .map((tag) => Chip(
                          label: Text(tag),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubTasksList() {
    return Card(
      child: Column(
        children: [
          // 子任务统计
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSubTaskStat(
                    '总数', _task.subTasks.length.toString(), Icons.list),
                _buildSubTaskStat(
                    '已完成',
                    _task.subTasks
                        .where((st) => st.status == SubTaskStatus.completed)
                        .length
                        .toString(),
                    Icons.check_circle),
                _buildSubTaskStat(
                    '进行中',
                    _task.subTasks
                        .where((st) => st.status == SubTaskStatus.inProgress)
                        .length
                        .toString(),
                    Icons.play_arrow),
              ],
            ),
          ),

          // 子任务列表
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _task.subTasks.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final subTask = _task.subTasks[index];
              return _buildSubTaskTile(subTask);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubTaskStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
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

  Widget _buildSubTaskTile(SubTask subTask) {
    Color statusColor = _getSubTaskStatusColor(subTask.status);

    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(
        _getSubTaskStatusIcon(subTask.status),
        color: statusColor,
      ),
      title: Text(
        subTask.title,
        style: TextStyle(
          decoration: subTask.status == SubTaskStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subTask.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subTask.description),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('预期: ${_formatDate(subTask.expectedAt)}'),
              const SizedBox(width: 16),
              if (subTask.assignedUserId != null) ...[
                Icon(Icons.person, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('已分配'),
              ],
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              subTask.status.displayName,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '权重: ${subTask.weight}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
      onTap: () => _handleSubTaskTap(subTask),
    );
  }

  Color _getSubTaskStatusColor(SubTaskStatus status) {
    switch (status) {
      case SubTaskStatus.pending:
        return Colors.orange;
      case SubTaskStatus.inProgress:
        return Colors.blue;
      case SubTaskStatus.completed:
        return Colors.green;
      case SubTaskStatus.blocked:
        return Colors.red;
      case SubTaskStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getSubTaskStatusIcon(SubTaskStatus status) {
    switch (status) {
      case SubTaskStatus.pending:
        return Icons.radio_button_unchecked;
      case SubTaskStatus.inProgress:
        return Icons.play_circle;
      case SubTaskStatus.completed:
        return Icons.check_circle;
      case SubTaskStatus.blocked:
        return Icons.block;
      case SubTaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Widget _buildTaskStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '任务统计',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              children: [
                _buildStatTile('实际用时', '${_task.statistics.actualMinutes}分钟'),
                _buildStatTile(
                    '贡献分数', '${_task.statistics.contributionScore.toInt()}'),
                _buildStatTile(
                    '默契分数', '${_task.statistics.tacitScore.toInt()}'),
                _buildStatTile(
                    '协作事件', '${_task.statistics.collaborationEvents}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case TaskStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        text = '待处理';
        break;
      case TaskStatus.inProgress:
        color = Colors.blue;
        icon = Icons.play_arrow;
        text = '进行中';
        break;
      case TaskStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = '已完成';
        break;
      case TaskStatus.blocked:
        color = Colors.red;
        icon = Icons.block;
        text = '被阻塞';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubTaskTap(SubTask subTask) {
    // 显示子任务操作菜单
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('查看详情'),
            onTap: () {
              Navigator.pop(context);
              _showSubTaskDetails(subTask);
            },
          ),
          if (subTask.status == SubTaskStatus.pending)
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('开始子任务'),
              onTap: () {
                Navigator.pop(context);
                _updateSubTaskStatus(subTask, SubTaskStatus.inProgress);
              },
            ),
          if (subTask.status == SubTaskStatus.inProgress)
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('完成子任务'),
              onTap: () {
                Navigator.pop(context);
                _updateSubTaskStatus(subTask, SubTaskStatus.completed);
              },
            ),
          if (subTask.status == SubTaskStatus.inProgress)
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('标记阻塞'),
              onTap: () {
                Navigator.pop(context);
                _updateSubTaskStatus(subTask, SubTaskStatus.blocked);
              },
            ),
        ],
      ),
    );
  }

  void _showSubTaskDetails(SubTask subTask) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(subTask.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subTask.description.isNotEmpty) ...[
              Text(subTask.description),
              const SizedBox(height: 16),
            ],
            Text('状态: ${subTask.status.displayName}'),
            Text('权重: ${subTask.weight}'),
            Text('优先级: ${subTask.priority}'),
            Text('预期完成: ${_formatDate(subTask.expectedAt)}'),
            if (subTask.completedAt != null)
              Text('实际完成: ${_formatDate(subTask.completedAt!)}'),
            if (subTask.assignedUserId != null)
              Text('分配给: ${subTask.assignedUserId}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _updateSubTaskStatus(SubTask subTask, SubTaskStatus newStatus) {
    // TODO: 实现更新子任务状态的API调用
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('子任务状态更新为: ${newStatus.displayName}')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
