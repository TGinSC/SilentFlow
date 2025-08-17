import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../providers/team_pool_provider.dart';
import '../../widgets/task_creation_dialog.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({
    super.key,
    required this.task,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  List<Task> _childTasks = [];
  Map<String, int> _completionStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTaskDetails();
  }

  Future<void> _loadTaskDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final childTasks = await TaskService.getChildTasks(widget.task.id);
      final stats = await TaskService.getTaskCompletionStats(widget.task.id);

      setState(() {
        _childTasks = childTasks;
        _completionStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载任务详情失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.title),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTask,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'status',
                child: Text('更改状态'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('删除任务'),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  // 任务基本信息卡片
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildTaskInfoCard(),
                  ),

                  // 完成统计卡片
                  if (_completionStats.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildCompletionStats(),
                    ),

                  // 子任务列表
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildChildTasksList(),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addChildTask,
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskInfoCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和状态
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.task.description != null)
                    Text(
                      widget.task.description!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
            _buildStatusChip(widget.task.status),
          ],
        ),

        const SizedBox(height: 20),

        // 任务属性
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _buildInfoItem(
              Icons.flag,
              '优先级',
              widget.task.priority.displayName,
              _getPriorityColor(widget.task.priority),
            ),
            _buildInfoItem(
              Icons.access_time,
              '预估时间',
              '${widget.task.estimatedMinutes}分钟',
              Colors.blue,
            ),
            _buildInfoItem(
              Icons.schedule,
              '层级',
              _getTaskLevelText(widget.task.level),
              Colors.purple,
            ),
            if (widget.task.expectedAt != null)
              _buildInfoItem(
                Icons.event,
                '预期完成',
                _formatDate(widget.task.expectedAt!),
                Colors.orange,
              ),
          ],
        ),

        // 标签
        if (widget.task.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.task.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      labelStyle: const TextStyle(color: Colors.blue),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionStats() {
    final total = _completionStats['total'] ?? 0;
    final completed = _completionStats['completed'] ?? 0;
    final inProgress = _completionStats['inProgress'] ?? 0;
    final pending = _completionStats['pending'] ?? 0;
    final blocked = _completionStats['blocked'] ?? 0;

    final completionRate = total > 0 ? (completed / total * 100).toInt() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '完成进度',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Text(
              '$completionRate%',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF48BB78),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 进度条
        LinearProgressIndicator(
          value: total > 0 ? completed / total : 0,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF48BB78)),
        ),
        const SizedBox(height: 16),

        // 统计数字
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('总计', total, Colors.grey),
            _buildStatItem('已完成', completed, const Color(0xFF48BB78)),
            _buildStatItem('进行中', inProgress, const Color(0xFF4299E1)),
            _buildStatItem('待处理', pending, const Color(0xFFED8936)),
            if (blocked > 0)
              _buildStatItem('受阻', blocked, const Color(0xFFE53E3E)),
          ],
        ),
      ],
    );
  }

  Widget _buildChildTasksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '子任务 (${_childTasks.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              if (_childTasks.isNotEmpty)
                TextButton.icon(
                  onPressed: _addChildTask,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('添加'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _childTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无子任务',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _addChildTask,
                        icon: const Icon(Icons.add),
                        label: const Text('添加子任务'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: _childTasks.length,
                  itemBuilder: (context, index) {
                    return _buildChildTaskItem(_childTasks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChildTaskItem(Task childTask) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        onTap: () => _openChildTaskDetail(childTask),
        leading: Icon(
          _getStatusIcon(childTask.status),
          color: _getStatusColor(childTask.status),
        ),
        title: Text(
          childTask.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (childTask.description != null)
              Text(
                childTask.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${childTask.estimatedMinutes}分钟',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.flag,
                    size: 14, color: _getPriorityColor(childTask.priority)),
                const SizedBox(width: 4),
                Text(
                  childTask.priority.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildStatusChip(childTask.status),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Chip(
      label: Text(
        _getStatusText(status),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: _getStatusColor(status).withOpacity(0.1),
      labelStyle: TextStyle(color: _getStatusColor(status)),
      side: BorderSide(
        color: _getStatusColor(status).withOpacity(0.3),
      ),
    );
  }

  Widget _buildInfoItem(
      IconData icon, String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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

  // 辅助方法
  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return '待处理';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.blocked:
        return '受阻';
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.blocked:
        return Icons.block;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return const Color(0xFFED8936);
      case TaskStatus.inProgress:
        return const Color(0xFF4299E1);
      case TaskStatus.completed:
        return const Color(0xFF48BB78);
      case TaskStatus.blocked:
        return const Color(0xFFE53E3E);
    }
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
        return Colors.red[800]!;
    }
  }

  String _getTaskLevelText(TaskLevel level) {
    switch (level) {
      case TaskLevel.project:
        return '项目';
      case TaskLevel.task:
        return '任务';
      case TaskLevel.taskPoint:
        return '任务点';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // 事件处理方法
  void _editTask() {
    // TODO: 实现任务编辑功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务编辑功能开发中')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'status':
        _showStatusChangeDialog();
        break;
      case 'delete':
        _showDeleteConfirmDialog();
        break;
    }
  }

  void _showStatusChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更改任务状态'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TaskStatus.values.map((status) {
            return ListTile(
              leading: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              title: Text(_getStatusText(status)),
              onTap: () async {
                Navigator.pop(context);
                await _updateTaskStatus(status);
              },
            );
          }).toList(),
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

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务 "${widget.task.title}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteTask();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskStatus(TaskStatus newStatus) async {
    try {
      final result = await TaskService.updateTaskStatus(
        teamId: widget.task.poolId,
        taskId: widget.task.id,
        status: newStatus,
      );

      if (result != null) {
        setState(() {
          // 更新本地任务状态
        });
        _loadTaskDetails(); // 重新加载数据
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务状态已更新')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('更新失败: $e')),
      );
    }
  }

  Future<void> _deleteTask() async {
    try {
      final success = await TaskService.deleteTask(widget.task.id);
      if (success) {
        Navigator.pop(context, true); // 返回true表示任务已删除
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('任务已删除')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e')),
      );
    }
  }

  Future<void> _addChildTask() async {
    final teamPoolProvider = context.read<TeamPoolProvider>();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TaskCreationDialog(
        team: teamPoolProvider.currentTeam,
        parentTask: widget.task,
      ),
    );

    if (result == true) {
      _loadTaskDetails(); // 重新加载任务详情
    }
  }

  void _openChildTaskDetail(Task childTask) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: childTask),
      ),
    ).then((result) {
      if (result == true) {
        _loadTaskDetails(); // 如果子任务被修改或删除，重新加载
      }
    });
  }
}
