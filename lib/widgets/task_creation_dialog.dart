import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../models/task_template_model.dart';
import '../models/team_pool_model.dart';
import '../providers/app_provider.dart';
import '../services/task_service.dart';

class TaskCreationDialog extends StatefulWidget {
  final TeamPool? team;
  final Task? parentTask; // 父任务，用于创建子任务

  const TaskCreationDialog({
    super.key,
    this.team,
    this.parentTask,
  });

  @override
  State<TaskCreationDialog> createState() => _TaskCreationDialogState();
}

class _TaskCreationDialogState extends State<TaskCreationDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  TaskTemplate? _selectedTemplate;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  int _estimatedHours = 1;
  List<String> _tags = [];
  List<String> _assignedUsers = [];
  String _newTag = '';
  bool _isLoading = false;

  // 所有可用的任务模板
  List<TaskTemplate> _availableTemplates = [];

  @override
  void initState() {
    super.initState();
    // 如果是创建子任务，只显示自定义tab；否则显示两个tab
    final tabCount = widget.parentTask != null ? 1 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
    _loadTaskTemplates();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadTaskTemplates() {
    try {
      _availableTemplates = DefaultTaskTemplates.all;
      setState(() {});
    } catch (e) {
      print('Error loading task templates: $e');
      _availableTemplates = [];
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            // 只有创建主任务时才显示 TabBar
            if (widget.parentTask == null) _buildTabBar(),
            Flexible(
              child: widget.parentTask != null
                  ? _buildCustomTab() // 创建子任务时直接显示自定义表单
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTemplateTab(),
                        _buildCustomTab(),
                      ],
                    ),
            ),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue[400]!,
            Colors.blue[600]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.add_task,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.parentTask == null ? '创建新任务' : '创建子任务',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.parentTask == null
                      ? '选择模板或自定义任务'
                      : '在"${widget.parentTask!.title}"下创建子任务',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.blue[600],
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: '使用模板'),
          Tab(text: '自定义任务'),
        ],
      ),
    );
  }

  Widget _buildTemplateTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择任务模板',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _availableTemplates.isEmpty
                ? const Center(
                    child: Text(
                      '暂无可用模板',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // 📱 根据屏幕尺寸和对话框宽度动态调整网格布局
                      final availableWidth = constraints.maxWidth;
                      final screenWidth = MediaQuery.of(context).size.width;
                      final isMobile =
                          availableWidth < 500 || screenWidth < 600;

                      // 根据可用宽度计算列数
                      int crossAxisCount;
                      double aspectRatio;

                      if (isMobile || availableWidth < 400) {
                        // 移动端或窄屏：单列布局
                        crossAxisCount = 1;
                        aspectRatio = 3.2; // 更宽的比例适应单列
                      } else if (availableWidth < 600) {
                        // 中等屏幕：单列但稍窄的比例
                        crossAxisCount = 1;
                        aspectRatio = 2.5;
                      } else {
                        // 大屏幕：双列布局
                        crossAxisCount = 2;
                        aspectRatio = 1.4;
                      }

                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: _availableTemplates.length,
                        itemBuilder: (context, index) {
                          final template = _availableTemplates[index];
                          return _buildTemplateCard(template);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(TaskTemplate template) {
    final isSelected = _selectedTemplate?.id == template.id;

    // 📱 移动端适配：根据屏幕尺寸调整卡片布局
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedTemplate?.id == template.id) {
            _selectedTemplate = null;
            _titleController.clear();
            _descriptionController.clear();
          } else {
            _selectedTemplate = template;
            _titleController.text = template.name;
            _descriptionController.text = template.description;
            _priority = template.priority;
            _estimatedHours =
                (template.estimatedMinutes / 60).round().clamp(1, 40);
            _tags = List.from(template.tags);
          }
        });
      },
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.blue[300]! : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行 - 确保不溢出
            Row(
              children: [
                Icon(
                  Icons.task_alt,
                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  size: isMobile ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    template.name,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.blue[600] : Colors.black87,
                    ),
                    maxLines: 1, // 📱 限制为单行，防止溢出
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 描述 - 自适应高度
            Flexible(
              child: Text(
                template.description,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.grey[600],
                ),
                maxLines: isMobile ? 2 : 3, // 📱 移动端减少行数
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 底部信息区域
            const Spacer(),

            // 类别和时长行
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.category,
                    style: TextStyle(
                      fontSize: isMobile ? 9 : 10,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(template.estimatedMinutes / 60).round()}h',
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.blue[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // 标签区域 - 使用 Wrap 确保不溢出
            SizedBox(
              height: isMobile ? 20 : 24, // 固定高度防止布局跳动
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: template.tags
                      .take(isMobile ? 2 : 3)
                      .map((tag) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 4 : 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: isMobile ? 8 : 9,
                                color: Colors.blue[600],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTab() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskBasicInfo(),
            const SizedBox(height: 24),
            _buildTaskSettings(),
            const SizedBox(height: 24),
            _buildTaskAssignment(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本信息',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: '任务标题',
            hintText: '输入任务标题',
            prefixIcon: const Icon(Icons.title),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入任务标题';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: '任务描述',
            hintText: '详细描述任务内容和要求',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          maxLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入任务描述';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTaskSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('优先级',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskPriority>(
                    value: _priority,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    onChanged: (TaskPriority? value) {
                      if (value != null) {
                        setState(() {
                          _priority = value;
                        });
                      }
                    },
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Row(
                          children: [
                            Icon(
                              Icons.flag,
                              color: _getPriorityColor(priority),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(_getPriorityText(priority)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('预估工时',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _estimatedHours.toDouble(),
                          min: 1,
                          max: 40,
                          divisions: 39,
                          label: '${_estimatedHours}h',
                          onChanged: (double value) {
                            setState(() {
                              _estimatedHours = value.round();
                            });
                          },
                        ),
                      ),
                      Text(
                        '${_estimatedHours}h',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('截止日期', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDueDate(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 12),
                Text(
                  _dueDate != null
                      ? '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}'
                      : '选择截止日期（可选）',
                  style: TextStyle(
                    color: _dueDate != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildTagsSection(),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('标签', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                )),
            ActionChip(
              label: const Text('添加标签'),
              avatar: const Icon(Icons.add, size: 16),
              onPressed: () => _showAddTagDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTaskAssignment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '任务分配',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (widget.team != null) ...[
          const Text('分配给团队成员', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...widget.team!.allMemberIds.map((memberId) {
            final isAssigned = _assignedUsers.contains(memberId);
            return CheckboxListTile(
              title: Text('成员 $memberId'), // TODO: 显示真实用户名
              value: isAssigned,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _assignedUsers.add(memberId);
                  } else {
                    _assignedUsers.remove(memberId);
                  }
                });
              },
            );
          }),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '未选择团队，任务将创建为个人任务',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('创建任务'),
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
        return Colors.deepPurple;
    }
  }

  String _getPriorityText(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _showAddTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(
          onChanged: (value) => _newTag = value,
          decoration: const InputDecoration(
            hintText: '输入标签名称',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty && !_tags.contains(value.trim())) {
              setState(() {
                _tags.add(value.trim());
              });
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (_newTag.trim().isNotEmpty &&
                  !_tags.contains(_newTag.trim())) {
                setState(() {
                  _tags.add(_newTag.trim());
                });
                Navigator.of(context).pop();
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _createTask() async {
    if (_tabController.index == 1 && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final userId = appProvider.currentUser?.id;

      if (userId == null) {
        throw Exception('用户未登录');
      }

      final teamId = widget.team?.id ?? 'personal';
      final estimatedMinutes = (_estimatedHours * 60).round();

      // 确定任务层级
      TaskLevel taskLevel = TaskLevel.task;
      String? parentTaskId;

      if (widget.parentTask != null) {
        parentTaskId = widget.parentTask!.id;
        // 如果父任务是项目级，子任务是任务级；如果父任务是任务级，子任务是任务点级
        taskLevel = widget.parentTask!.level == TaskLevel.project
            ? TaskLevel.task
            : TaskLevel.taskPoint;
      }

      print(
          '创建任务: 团队ID=$teamId, 标题=${_titleController.text.trim()}, 层级=$taskLevel');

      final task = await TaskService.createTask(
        teamId: teamId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        estimatedMinutes: estimatedMinutes,
        expectedAt: _dueDate,
        priority: _priority,
        assignedUsers: _assignedUsers,
        tags: _tags,
        baseReward: estimatedMinutes / 30.0 * 10.0, // 基于估算时间计算奖励
        parentTaskId: parentTaskId,
        level: taskLevel,
      );

      if (task != null) {
        print('任务创建成功: ${task.id}');
        Navigator.of(context).pop(true); // 返回 true 表示创建成功
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${taskLevel == TaskLevel.taskPoint ? "任务点" : "任务"} "${task.title}" 创建成功'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('创建任务失败 - 任务对象为null');
      }
    } catch (e) {
      print('创建任务异常: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('创建任务失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
