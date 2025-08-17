// 前端任务管理服务
// 封装后端API调用，支持贡献值和默契度计算
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import 'item_service.dart';
import 'scoring_service.dart';
import 'storage_service.dart';

class TaskService {
  /// 获取任务详情，包含评分计算
  static Future<Task?> getTask(String itemId) async {
    try {
      // 调用原始API获取基础任务信息
      Map<String, dynamic>? itemData = await ItemService.getItemInfo(itemId);

      if (itemData != null) {
        return _convertBackendItemToTask(itemData);
      }
      return null;
    } catch (e) {
      print('获取任务详情失败: $e');
      return null;
    }
  }

  /// 获取所有任务列表（包含测试数据和存储的任务）
  static Future<List<Task>> getAllTasks() async {
    try {
      // 获取存储的任务
      final storedTasks = await _getStoredTasks();

      // 如果没有存储的任务，返回测试数据
      if (storedTasks.isEmpty) {
        final testTasks = _createTestTasks();
        // 保存测试任务到存储
        await _saveTasksToStorage(testTasks);
        return testTasks;
      }

      return storedTasks;
    } catch (e) {
      print('获取任务列表失败: $e');
      return [];
    }
  }

  /// 创建测试任务数据
  static List<Task> _createTestTasks() {
    final now = DateTime.now();

    return [
      Task(
        id: 'task_001',
        poolId: 'pool_001',
        projectId: 'demo-project-001', // 添加项目ID
        title: '开发用户登录模块',
        description: '实现用户登录、注册和密码找回功能，包括前端UI和后端API',
        estimatedMinutes: 120,
        expectedAt: now.add(const Duration(days: 2)),
        dueDate: now.add(const Duration(days: 3)), // 添加截止日期
        status: TaskStatus.pending,
        createdAt: now.subtract(const Duration(hours: 2)),
        statistics: const TaskStatistics(),
        priority: TaskPriority.high,
        baseReward: 25.0,
        tags: ['前端开发', 'UI设计', '用户体验'],
        requiredSkills: ['Flutter', 'UI设计'],
        difficulty: TaskDifficulty.medium,
        maxAssignees: 2,
        subTasks: [
          SubTask(
            id: 'subtask_001_1',
            taskId: 'task_001',
            title: '设计登录界面',
            description: '使用Material Design设计登录页面',
            createdAt: now,
            expectedAt: now.add(const Duration(hours: 24)),
            priority: 3,
            weight: 1.5,
            status: SubTaskStatus.pending,
          ),
          SubTask(
            id: 'subtask_001_2',
            taskId: 'task_001',
            title: '实现登录API',
            description: '实现用户登录的后端API接口',
            createdAt: now,
            expectedAt: now.add(const Duration(hours: 36)),
            priority: 4,
            weight: 2.0,
            status: SubTaskStatus.pending,
          ),
          SubTask(
            id: 'subtask_001_3',
            taskId: 'task_001',
            title: '添加表单验证',
            description: '前端表单验证和错误处理',
            createdAt: now,
            expectedAt: now.add(const Duration(hours: 48)),
            priority: 2,
            weight: 1.0,
            status: SubTaskStatus.pending,
          ),
        ],
      ),
      Task(
        id: 'task_002',
        poolId: 'pool_001',
        title: '优化数据库性能',
        description: '分析和优化数据库查询性能，添加必要的索引',
        estimatedMinutes: 180,
        expectedAt: now.add(const Duration(days: 3)),
        status: TaskStatus.inProgress,
        assigneeId: 'test_user_001',
        assignedUsers: ['test_user_001'],
        startedAt: now.subtract(const Duration(hours: 4)),
        createdAt: now.subtract(const Duration(days: 1)),
        statistics: const TaskStatistics(actualMinutes: 60),
        priority: TaskPriority.medium,
        baseReward: 30.0,
        tags: ['后端开发', '数据库', '性能优化'],
        requiredSkills: ['数据库', '性能调优'],
        difficulty: TaskDifficulty.hard,
        maxAssignees: 1,
        subTasks: [
          SubTask(
            id: 'subtask_002_1',
            taskId: 'task_002',
            title: '分析慢查询',
            description: '使用数据库日志分析慢查询语句',
            createdAt: now.subtract(const Duration(days: 1)),
            expectedAt: now.add(const Duration(hours: 12)),
            priority: 5,
            weight: 2.0,
            status: SubTaskStatus.completed,
            assignedUserId: 'test_user_001',
            completedAt: now.subtract(const Duration(hours: 2)),
          ),
          SubTask(
            id: 'subtask_002_2',
            taskId: 'task_002',
            title: '创建索引',
            description: '为频繁查询的字段创建合适的索引',
            createdAt: now.subtract(const Duration(days: 1)),
            expectedAt: now.add(const Duration(hours: 24)),
            priority: 4,
            weight: 1.5,
            status: SubTaskStatus.inProgress,
            assignedUserId: 'test_user_001',
          ),
          SubTask(
            id: 'subtask_002_3',
            taskId: 'task_002',
            title: '性能测试',
            description: '测试优化后的查询性能',
            createdAt: now.subtract(const Duration(days: 1)),
            expectedAt: now.add(const Duration(hours: 36)),
            priority: 3,
            weight: 1.0,
            status: SubTaskStatus.pending,
          ),
        ],
      ),
      Task(
        id: 'task_003',
        poolId: 'pool_002',
        title: '编写API文档',
        description: '为所有后端API接口编写详细的技术文档',
        estimatedMinutes: 90,
        expectedAt: now.add(const Duration(days: 1)),
        status: TaskStatus.completed,
        assigneeId: 'test_user_002',
        assignedUsers: ['test_user_002'],
        startedAt: now.subtract(const Duration(hours: 8)),
        completedAt: now.subtract(const Duration(hours: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        statistics: const TaskStatistics(
          actualMinutes: 75,
          contributionScore: 85.0,
          tacitScore: 92.0,
        ),
        priority: TaskPriority.low,
        baseReward: 15.0,
        tags: ['文档', '技术写作'],
        requiredSkills: ['技术写作'],
        difficulty: TaskDifficulty.easy,
        maxAssignees: 1,
        subTasks: [
          SubTask(
            id: 'subtask_003_1',
            taskId: 'task_003',
            title: '用户相关API文档',
            description: '编写用户注册、登录、信息管理相关API文档',
            createdAt: now.subtract(const Duration(days: 2)),
            expectedAt: now.subtract(const Duration(hours: 4)),
            priority: 3,
            weight: 1.5,
            status: SubTaskStatus.completed,
            assignedUserId: 'test_user_002',
            completedAt: now.subtract(const Duration(hours: 6)),
          ),
          SubTask(
            id: 'subtask_003_2',
            taskId: 'task_003',
            title: '任务相关API文档',
            description: '编写任务管理相关API文档',
            createdAt: now.subtract(const Duration(days: 2)),
            expectedAt: now.subtract(const Duration(hours: 2)),
            priority: 3,
            weight: 1.5,
            status: SubTaskStatus.completed,
            assignedUserId: 'test_user_002',
            completedAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      Task(
        id: 'task_004',
        poolId: 'pool_001',
        title: '移动端适配优化',
        description: '优化应用在不同屏幕尺寸下的显示效果',
        estimatedMinutes: 150,
        expectedAt: now.add(const Duration(days: 4)),
        status: TaskStatus.blocked,
        assigneeId: 'test_user_003',
        assignedUsers: ['test_user_003'],
        startedAt: now.subtract(const Duration(hours: 12)),
        blockReason: BlockReason.needHelp,
        blockNote: '需要UI设计师配合提供不同尺寸的设计稿',
        createdAt: now.subtract(const Duration(hours: 18)),
        statistics: const TaskStatistics(actualMinutes: 45),
        priority: TaskPriority.urgent,
        baseReward: 20.0,
        tags: ['移动开发', '响应式设计'],
        requiredSkills: ['Flutter', 'UI适配'],
        difficulty: TaskDifficulty.medium,
        maxAssignees: 1,
        subTasks: [
          SubTask(
            id: 'subtask_004_1',
            taskId: 'task_004',
            title: '分析屏幕适配问题',
            description: '测试应用在不同设备上的显示问题',
            createdAt: now.subtract(const Duration(hours: 18)),
            expectedAt: now.add(const Duration(hours: 6)),
            priority: 4,
            weight: 1.0,
            status: SubTaskStatus.completed,
            assignedUserId: 'test_user_003',
            completedAt: now.subtract(const Duration(hours: 10)),
          ),
          SubTask(
            id: 'subtask_004_2',
            taskId: 'task_004',
            title: '等待设计稿',
            description: '等待UI设计师提供适配设计稿',
            createdAt: now.subtract(const Duration(hours: 18)),
            expectedAt: now.add(const Duration(hours: 12)),
            priority: 5,
            weight: 2.0,
            status: SubTaskStatus.blocked,
            assignedUserId: 'test_user_003',
          ),
        ],
      ),
      Task(
        id: 'task_005',
        poolId: 'pool_002',
        title: '单元测试覆盖',
        description: '为核心业务逻辑添加单元测试，提高代码质量',
        estimatedMinutes: 240,
        expectedAt: now.add(const Duration(days: 5)),
        status: TaskStatus.pending,
        createdAt: now.subtract(const Duration(hours: 6)),
        statistics: const TaskStatistics(),
        priority: TaskPriority.medium,
        baseReward: 35.0,
        tags: ['测试', '质量保证', '自动化'],
        requiredSkills: ['单元测试', 'Flutter测试'],
        difficulty: TaskDifficulty.hard,
        isTeamTask: true,
        maxAssignees: 3,
        subTasks: [],
      ),
    ];
  }

  /// 创建任务
  static Future<Task?> createTask({
    required String teamId,
    required String title,
    String? description,
    int estimatedMinutes = 30,
    DateTime? expectedAt,
    TaskPriority priority = TaskPriority.medium,
    List<String> assignedUsers = const [],
    List<String> tags = const [],
    double baseReward = 10.0,
    String? parentTaskId, // 新增：父任务ID
    TaskLevel level = TaskLevel.task, // 新增：任务层级
  }) async {
    try {
      // 生成任务ID
      final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';

      // 创建带有层级信息的任务对象
      final task = Task(
        id: taskId,
        poolId: teamId,
        title: title,
        description: description,
        estimatedMinutes: estimatedMinutes,
        expectedAt: expectedAt ??
            DateTime.now().add(Duration(minutes: estimatedMinutes)),
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
        statistics: const TaskStatistics(),
        priority: priority,
        baseReward: baseReward,
        tags: tags,
        assignedUsers: assignedUsers,
        level: level, // 设置任务层级
        parentTaskId: parentTaskId, // 设置父任务ID
        childTaskIds: const [],
      );

      // 保存到本地存储
      await _addTaskToStorage(task);

      // 尝试调用后端API（可选）
      try {
        await ItemService.createItem(
          teamId: teamId,
          content: title + (description != null ? '\n$description' : ''),
          score: baseReward.toInt(),
          shouldBeCompletedBy: (expectedAt ??
                  DateTime.now().add(Duration(minutes: estimatedMinutes)))
              .millisecondsSinceEpoch,
        );
      } catch (e) {
        print('后端API调用失败，任务仅保存在本地: $e');
      }

      // 如果有父任务，更新父任务的子任务列表
      if (parentTaskId != null) {
        await _addChildTaskToParent(parentTaskId, taskId);
      }

      return task;
    } catch (e) {
      print('创建任务失败: $e');
      return null;
    }
  }

  /// 更新任务状态
  static Future<Task?> updateTaskStatus({
    required String teamId,
    required String taskId,
    required TaskStatus status,
    String? assigneeId,
    DateTime? startedAt,
    DateTime? completedAt,
    BlockReason? blockReason,
    String? blockNote,
  }) async {
    try {
      // 从存储中获取现有任务
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex == -1) {
        print('任务不存在: $taskId');
        return null;
      }

      final originalTask = storedTasks[taskIndex];

      // 更新任务状态
      final updatedTask = originalTask.copyWith(
        status: status,
        assigneeId: assigneeId,
        startedAt: startedAt,
        completedAt: completedAt,
        blockReason: blockReason,
        blockNote: blockNote,
      );

      // 更新存储
      storedTasks[taskIndex] = updatedTask;
      await _saveTasksToStorage(storedTasks);

      // 尝试更新后端（可选）
      try {
        if (status == TaskStatus.completed) {
          await ItemService.completeItem(
            teamId: teamId,
            itemId: int.tryParse(taskId) ?? 0,
            completedBy:
                assigneeId != null ? (int.tryParse(assigneeId) ?? 0) : 0,
          );
        } else {
          await ItemService.updateItem(
            teamId: teamId,
            itemId: int.tryParse(taskId) ?? 0,
          );
        }
      } catch (e) {
        print('后端更新失败，任务状态仅在本地更新: $e');
      }

      return updatedTask;
    } catch (e) {
      print('更新任务状态失败: $e');
      return null;
    }
  }

  /// 完成任务并计算奖励
  static Future<Map<String, dynamic>?> completeTask({
    required String teamId,
    required String taskId,
    required String userId,
    String? completionNote,
    List<String>? completedSubTasks,
  }) async {
    try {
      // 完成后端任务
      bool success = await ItemService.completeItem(
        teamId: teamId,
        itemId: int.parse(taskId),
        completedBy: int.parse(userId),
      );

      if (success) {
        Task? completedTask = await getTask(taskId);

        if (completedTask != null) {
          // 计算奖励和贡献值
          TaskReward reward = completedTask.calculateReward();
          double userContribution =
              ScoringService.calculateTaskContribution(completedTask, userId);

          // 应用时间奖惩
          double adjustedContribution = userContribution;
          if (completedTask.expectedAt != null &&
              completedTask.completedAt != null) {
            if (completedTask.completedAt!
                .isBefore(completedTask.expectedAt!)) {
              adjustedContribution = ScoringService.applyEarlyBonus(
                originalScore: userContribution,
                expectedTime: completedTask.expectedAt!,
                actualTime: completedTask.completedAt!,
              );
            } else if (completedTask.completedAt!
                .isAfter(completedTask.expectedAt!)) {
              adjustedContribution = ScoringService.applyTimelinePenalty(
                originalScore: userContribution,
                expectedTime: completedTask.expectedAt!,
                actualTime: completedTask.completedAt!,
              );
            }
          }

          return {
            'task': completedTask,
            'reward': reward,
            'userContribution': userContribution,
            'adjustedContribution': adjustedContribution,
            'isEarly': completedTask.isEarlyCompletion,
            'isOverdue': completedTask.isOverdue,
            'timeDeviation': completedTask.timeDeviation,
            'completionNote': completionNote,
          };
        }
      }
      return null;
    } catch (e) {
      print('完成任务异常: $e');
      return null;
    }
  }

  /// 开始任务
  static Future<Task?> startTask({
    required String teamId,
    required String taskId,
    required String userId,
  }) async {
    return await updateTaskStatus(
      teamId: teamId,
      taskId: taskId,
      status: TaskStatus.inProgress,
      assigneeId: userId,
      startedAt: DateTime.now(),
    );
  }

  /// 阻塞任务
  static Future<Task?> blockTask({
    required String teamId,
    required String taskId,
    required BlockReason blockReason,
    String? blockNote,
  }) async {
    return await updateTaskStatus(
      teamId: teamId,
      taskId: taskId,
      status: TaskStatus.blocked,
      blockReason: blockReason,
      blockNote: blockNote,
    );
  }

  /// 删除任务
  static Future<bool> deleteTask(String taskId) async {
    try {
      return await ItemService.deleteItem(taskId);
    } catch (e) {
      print('删除任务失败: $e');
      return false;
    }
  }

  /// 创建子任务
  static Future<SubTask?> createSubTask({
    required String parentTaskId,
    required String title,
    String? description,
    String? assigneeId,
    double weight = 1.0,
    int estimatedMinutes = 30,
  }) async {
    // 由于后端可能不直接支持子任务，在前端本地管理
    String subTaskId = DateTime.now().millisecondsSinceEpoch.toString();
    return SubTask(
      id: subTaskId,
      taskId: parentTaskId,
      title: title,
      description: description ?? '',
      assignedUserId: assigneeId,
      weight: weight,
      status: SubTaskStatus.pending,
      createdAt: DateTime.now(),
      expectedAt: DateTime.now().add(Duration(minutes: estimatedMinutes)),
    );
  }

  /// 完成子任务
  static Future<SubTask?> completeSubTask({
    required String subTaskId,
    required String parentTaskId,
    String? completionNote,
  }) async {
    // 前端本地管理子任务状态
    // 实际应用中可能需要持久化到本地存储
    return SubTask(
      id: subTaskId,
      taskId: parentTaskId,
      title: '已完成的子任务',
      status: SubTaskStatus.completed,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      expectedAt: DateTime.now(),
    );
  }

  /// 获取用户的活跃任务
  static Future<List<Task>> getUserActiveTasks(String userId) async {
    try {
      // 这里需要根据实际后端API设计
      // 可能需要通过团队获取任务，然后筛选用户相关的任务
      List<Task> allTasks = await getAllTasks();
      return allTasks
          .where((task) =>
              (task.assignedUsers.contains(userId) ||
                  task.assigneeId == userId) &&
              task.status != TaskStatus.completed)
          .toList();
    } catch (e) {
      print('获取用户活跃任务失败: $e');
      return [];
    }
  }

  /// 获取用户的完成任务统计
  static Future<Map<String, dynamic>> getUserTaskStats(String userId) async {
    try {
      List<Task> allTasks = await getAllTasks();
      List<Task> userTasks = allTasks
          .where((task) =>
              task.assignedUsers.contains(userId) || task.assigneeId == userId)
          .toList();

      int completedTasks =
          userTasks.where((task) => task.status == TaskStatus.completed).length;
      int activeTasks =
          userTasks.where((task) => task.status != TaskStatus.completed).length;
      double totalContribution = userTasks
          .map((task) => ScoringService.calculateTaskContribution(task, userId))
          .fold(0.0, (sum, score) => sum + score);

      return {
        'totalTasks': userTasks.length,
        'completedTasks': completedTasks,
        'activeTasks': activeTasks,
        'totalContribution': totalContribution,
        'averageContribution':
            userTasks.isNotEmpty ? totalContribution / userTasks.length : 0.0,
        'onTimeCompletions': userTasks
            .where((task) =>
                task.status == TaskStatus.completed &&
                    task.completedAt != null &&
                    task.expectedAt != null &&
                    task.completedAt!.isBefore(task.expectedAt!) ||
                task.completedAt!.isAtSameMomentAs(task.expectedAt!))
            .length,
      };
    } catch (e) {
      print('获取用户任务统计失败: $e');
      return {
        'totalTasks': 0,
        'completedTasks': 0,
        'activeTasks': 0,
        'totalContribution': 0.0,
        'averageContribution': 0.0,
        'onTimeCompletions': 0,
      };
    }
  }

  // ==================== 私有辅助方法 ====================

  /// 将后端item数据转换为前端Task模型
  static Task _convertBackendItemToTask(Map<String, dynamic> itemData) {
    // 解析后端数据结构
    int itemId = itemData['itemUID'] ?? itemData['id'] ?? 0;
    String content = itemData['content'] ?? '未命名任务';
    int score = itemData['score'] ?? 10;
    int shouldBeCompletedBy = itemData['shouldBeCompletedBy'] ?? 0;
    int? beCompletedBy = itemData['beCompletedBy'];
    bool isComplete = itemData['isComplete'] ?? false;

    // 解析标题和描述
    List<String> contentParts = content.split('\n');
    String title = contentParts.first;
    String? description =
        contentParts.length > 1 ? contentParts.sublist(1).join('\n') : null;

    // 转换时间戳
    DateTime? expectedAt = shouldBeCompletedBy > 0
        ? DateTime.fromMillisecondsSinceEpoch(shouldBeCompletedBy)
        : null;

    DateTime? completedAt = isComplete
        ? DateTime.now() // 后端可能没有具体完成时间，使用当前时间
        : null;

    return Task(
      id: itemId.toString(),
      poolId: itemData['teamUID']?.toString() ?? '',
      title: title,
      description: description,
      estimatedMinutes: _estimateMinutesFromScore(score),
      expectedAt: expectedAt,
      status: isComplete ? TaskStatus.completed : TaskStatus.pending,
      assigneeId: beCompletedBy?.toString(),
      createdAt: DateTime.now(), // 后端可能没有创建时间
      completedAt: completedAt,
      baseReward: score.toDouble(),
      statistics: TaskStatistics(
        actualMinutes: isComplete ? _estimateMinutesFromScore(score) : 0,
        tacitScoreContribution: 0,
        interactions: [],
        contributionScore: 0.0,
        tacitScore: 0.0,
        collaborationEvents: 0,
      ),
      keyNodes: [],
      subTasks: [],
      priority: _priorityFromScore(score),
      assignedUsers: beCompletedBy != null ? [beCompletedBy.toString()] : [],
      tags: [],
    );
  }

  /// 从分数估算预期分钟数
  static int _estimateMinutesFromScore(int score) {
    // 简单映射：分数越高，预期时间越长
    if (score <= 5) return 30;
    if (score <= 10) return 60;
    if (score <= 20) return 120;
    return 180;
  }

  /// 从分数确定任务优先级
  static TaskPriority _priorityFromScore(int score) {
    if (score <= 5) return TaskPriority.low;
    if (score <= 15) return TaskPriority.medium;
    if (score <= 25) return TaskPriority.high;
    return TaskPriority.urgent;
  }

  /// 根据用户ID获取用户的任务
  static Future<List<Task>> getTasksByUserId(String userId) async {
    try {
      // 获取所有任务，然后筛选出该用户的任务
      final allTasks = await getAllTasks();
      return allTasks
          .where((task) =>
              task.assigneeId == userId || task.assignedUsers.contains(userId))
          .toList();
    } catch (e) {
      print('获取用户任务失败: $e');
      return [];
    }
  }

  /// 获取可认领的任务（未分配给任何人的任务）
  static Future<List<Task>> getAvailableTasks() async {
    try {
      final allTasks = await getAllTasks();
      return allTasks
          .where((task) =>
              task.status == TaskStatus.pending &&
              task.assigneeId == null &&
              task.assignedUsers.isEmpty)
          .toList();
    } catch (e) {
      print('获取可认领任务失败: $e');
      return [];
    }
  }

  /// 将子任务添加到父任务的子任务列表中
  static Future<void> _addChildTaskToParent(
      String parentTaskId, String childTaskId) async {
    try {
      // 这里应该实现更新父任务的子任务列表的逻辑
      // 由于目前的架构限制，我们先简单记录这个关系
      // 在实际项目中，这应该更新数据库或存储系统
      print('子任务 $childTaskId 已添加到父任务 $parentTaskId');
    } catch (e) {
      print('添加子任务到父任务失败: $e');
    }
  }

  /// 获取指定团队的所有任务（不包括主项目）
  static Future<List<Task>> getTeamTasks(String teamId) async {
    try {
      // 获取所有任务并筛选出指定团队的任务
      final allTasks = await getAllTasks();
      return allTasks
          .where((task) =>
              task.poolId == teamId &&
              task.level != TaskLevel.project) // 排除主项目，主项目单独处理
          .toList();
    } catch (e) {
      print('获取团队任务失败: $e');
      return [];
    }
  }

  /// 获取指定任务的子任务列表
  static Future<List<Task>> getChildTasks(String parentTaskId) async {
    try {
      final allTasks = await getAllTasks();
      return allTasks
          .where((task) => task.parentTaskId == parentTaskId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // 按创建时间排序
    } catch (e) {
      print('获取子任务失败: $e');
      return [];
    }
  }

  /// 获取任务的完成统计信息
  static Future<Map<String, int>> getTaskCompletionStats(String taskId) async {
    try {
      final childTasks = await getChildTasks(taskId);

      if (childTasks.isEmpty) {
        // 如果没有子任务，返回当前任务的状态
        final task = await getTaskById(taskId);
        if (task != null) {
          return {
            'total': 1,
            'completed': task.status == TaskStatus.completed ? 1 : 0,
            'inProgress': task.status == TaskStatus.inProgress ? 1 : 0,
            'pending': task.status == TaskStatus.pending ? 1 : 0,
            'blocked': task.status == TaskStatus.blocked ? 1 : 0,
          };
        }
        return {
          'total': 0,
          'completed': 0,
          'inProgress': 0,
          'pending': 0,
          'blocked': 0
        };
      }

      int total = childTasks.length;
      int completed = childTasks
          .where((task) => task.status == TaskStatus.completed)
          .length;
      int inProgress = childTasks
          .where((task) => task.status == TaskStatus.inProgress)
          .length;
      int pending =
          childTasks.where((task) => task.status == TaskStatus.pending).length;
      int blocked =
          childTasks.where((task) => task.status == TaskStatus.blocked).length;

      return {
        'total': total,
        'completed': completed,
        'inProgress': inProgress,
        'pending': pending,
        'blocked': blocked,
      };
    } catch (e) {
      print('获取任务完成统计失败: $e');
      return {
        'total': 0,
        'completed': 0,
        'inProgress': 0,
        'pending': 0,
        'blocked': 0
      };
    }
  }

  /// 根据任务ID获取单个任务
  static Future<Task?> getTaskById(String taskId) async {
    try {
      final allTasks = await getAllTasks();
      return allTasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      print('获取任务失败: $e');
      return null;
    }
  }

  /// 从存储中获取任务列表
  static Future<List<Task>> _getStoredTasks() async {
    try {
      final storageService = StorageService();
      final taskDataList = await storageService.getData('tasks');
      if (taskDataList == null) return [];

      if (taskDataList is List) {
        return taskDataList
            .map((taskData) => Task.fromJson(taskData as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('从存储获取任务失败: $e');
      return [];
    }
  }

  /// 保存任务列表到存储
  static Future<void> _saveTasksToStorage(List<Task> tasks) async {
    try {
      final storageService = StorageService();
      final taskDataList = tasks.map((task) => task.toJson()).toList();
      await storageService.saveData('tasks', taskDataList);
    } catch (e) {
      print('保存任务到存储失败: $e');
    }
  }

  /// 添加新任务到存储
  static Future<void> _addTaskToStorage(Task task) async {
    try {
      final storedTasks = await _getStoredTasks();
      storedTasks.add(task);
      await _saveTasksToStorage(storedTasks);
    } catch (e) {
      print('添加任务到存储失败: $e');
    }
  }

  // ======================== 工作流相关方法 ========================

  /// 更新任务工作流状态
  static Future<void> updateTaskWorkflowStatus(
      String taskId, WorkflowStatus status) async {
    try {
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = storedTasks[taskIndex];
        final updatedTask = Task(
          id: task.id,
          poolId: task.poolId,
          title: task.title,
          description: task.description,
          estimatedMinutes: task.estimatedMinutes,
          expectedAt: task.expectedAt,
          status: task.status,
          assigneeId: task.assigneeId,
          startedAt: task.startedAt,
          completedAt: task.completedAt,
          blockReason: task.blockReason,
          blockNote: task.blockNote,
          createdAt: task.createdAt,
          statistics: task.statistics,
          keyNodes: task.keyNodes,
          subTasks: task.subTasks,
          priority: task.priority,
          baseReward: task.baseReward,
          assignedUsers: task.assignedUsers,
          tags: task.tags,
          requiredSkills: task.requiredSkills,
          createdBy: task.createdBy,
          difficulty: task.difficulty,
          milestones: task.milestones,
          isTeamTask: task.isTeamTask,
          maxAssignees: task.maxAssignees,
          level: task.level,
          parentTaskId: task.parentTaskId,
          childTaskIds: task.childTaskIds,
          fromTemplate: task.fromTemplate,
          creationMethod: task.creationMethod,
          templateParams: task.templateParams,
          prerequisiteTasks: task.prerequisiteTasks,
          dependentTasks: task.dependentTasks,
          workflowStatus: status, // 更新工作流状态
          submissions: task.submissions,
          reviewStatus: task.reviewStatus,
          reviewerId: task.reviewerId,
          reviewComment: task.reviewComment,
          reviewedAt: task.reviewedAt,
          taskPoints: task.taskPoints,
        );

        storedTasks[taskIndex] = updatedTask;
        await _saveTasksToStorage(storedTasks);
      }
    } catch (e) {
      print('更新任务工作流状态失败: $e');
    }
  }

  /// 添加任务前置依赖
  static Future<void> addTaskPrerequisite(
      String taskId, String prerequisiteTaskId) async {
    try {
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = storedTasks[taskIndex];
        final updatedPrerequisites = [...task.prerequisiteTasks];
        if (!updatedPrerequisites.contains(prerequisiteTaskId)) {
          updatedPrerequisites.add(prerequisiteTaskId);
        }

        final updatedTask = Task(
          id: task.id,
          poolId: task.poolId,
          title: task.title,
          description: task.description,
          estimatedMinutes: task.estimatedMinutes,
          expectedAt: task.expectedAt,
          status: task.status,
          assigneeId: task.assigneeId,
          startedAt: task.startedAt,
          completedAt: task.completedAt,
          blockReason: task.blockReason,
          blockNote: task.blockNote,
          createdAt: task.createdAt,
          statistics: task.statistics,
          keyNodes: task.keyNodes,
          subTasks: task.subTasks,
          priority: task.priority,
          baseReward: task.baseReward,
          assignedUsers: task.assignedUsers,
          tags: task.tags,
          requiredSkills: task.requiredSkills,
          createdBy: task.createdBy,
          difficulty: task.difficulty,
          milestones: task.milestones,
          isTeamTask: task.isTeamTask,
          maxAssignees: task.maxAssignees,
          level: task.level,
          parentTaskId: task.parentTaskId,
          childTaskIds: task.childTaskIds,
          fromTemplate: task.fromTemplate,
          creationMethod: task.creationMethod,
          templateParams: task.templateParams,
          prerequisiteTasks: updatedPrerequisites,
          dependentTasks: task.dependentTasks,
          workflowStatus: task.workflowStatus,
          submissions: task.submissions,
          reviewStatus: task.reviewStatus,
          reviewerId: task.reviewerId,
          reviewComment: task.reviewComment,
          reviewedAt: task.reviewedAt,
          taskPoints: task.taskPoints,
        );

        storedTasks[taskIndex] = updatedTask;
        await _saveTasksToStorage(storedTasks);
      }
    } catch (e) {
      print('添加任务前置依赖失败: $e');
    }
  }

  /// 添加任务后置依赖
  static Future<void> addTaskDependent(
      String taskId, String dependentTaskId) async {
    try {
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = storedTasks[taskIndex];
        final updatedDependents = [...task.dependentTasks];
        if (!updatedDependents.contains(dependentTaskId)) {
          updatedDependents.add(dependentTaskId);
        }

        final updatedTask = Task(
          id: task.id,
          poolId: task.poolId,
          title: task.title,
          description: task.description,
          estimatedMinutes: task.estimatedMinutes,
          expectedAt: task.expectedAt,
          status: task.status,
          assigneeId: task.assigneeId,
          startedAt: task.startedAt,
          completedAt: task.completedAt,
          blockReason: task.blockReason,
          blockNote: task.blockNote,
          createdAt: task.createdAt,
          statistics: task.statistics,
          keyNodes: task.keyNodes,
          subTasks: task.subTasks,
          priority: task.priority,
          baseReward: task.baseReward,
          assignedUsers: task.assignedUsers,
          tags: task.tags,
          requiredSkills: task.requiredSkills,
          createdBy: task.createdBy,
          difficulty: task.difficulty,
          milestones: task.milestones,
          isTeamTask: task.isTeamTask,
          maxAssignees: task.maxAssignees,
          level: task.level,
          parentTaskId: task.parentTaskId,
          childTaskIds: task.childTaskIds,
          fromTemplate: task.fromTemplate,
          creationMethod: task.creationMethod,
          templateParams: task.templateParams,
          prerequisiteTasks: task.prerequisiteTasks,
          dependentTasks: updatedDependents,
          workflowStatus: task.workflowStatus,
          submissions: task.submissions,
          reviewStatus: task.reviewStatus,
          reviewerId: task.reviewerId,
          reviewComment: task.reviewComment,
          reviewedAt: task.reviewedAt,
          taskPoints: task.taskPoints,
        );

        storedTasks[taskIndex] = updatedTask;
        await _saveTasksToStorage(storedTasks);
      }
    } catch (e) {
      print('添加任务后置依赖失败: $e');
    }
  }

  /// 更新任务审核状态
  static Future<void> updateTaskReviewStatus(
      String taskId, TaskReviewStatus status) async {
    try {
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = storedTasks[taskIndex];
        final updatedTask = Task(
          id: task.id,
          poolId: task.poolId,
          title: task.title,
          description: task.description,
          estimatedMinutes: task.estimatedMinutes,
          expectedAt: task.expectedAt,
          status: task.status,
          assigneeId: task.assigneeId,
          startedAt: task.startedAt,
          completedAt: task.completedAt,
          blockReason: task.blockReason,
          blockNote: task.blockNote,
          createdAt: task.createdAt,
          statistics: task.statistics,
          keyNodes: task.keyNodes,
          subTasks: task.subTasks,
          priority: task.priority,
          baseReward: task.baseReward,
          assignedUsers: task.assignedUsers,
          tags: task.tags,
          requiredSkills: task.requiredSkills,
          createdBy: task.createdBy,
          difficulty: task.difficulty,
          milestones: task.milestones,
          isTeamTask: task.isTeamTask,
          maxAssignees: task.maxAssignees,
          level: task.level,
          parentTaskId: task.parentTaskId,
          childTaskIds: task.childTaskIds,
          fromTemplate: task.fromTemplate,
          creationMethod: task.creationMethod,
          templateParams: task.templateParams,
          prerequisiteTasks: task.prerequisiteTasks,
          dependentTasks: task.dependentTasks,
          workflowStatus: task.workflowStatus,
          submissions: task.submissions,
          reviewStatus: status, // 更新审核状态
          reviewerId: task.reviewerId,
          reviewComment: task.reviewComment,
          reviewedAt: task.reviewedAt,
          taskPoints: task.taskPoints,
        );

        storedTasks[taskIndex] = updatedTask;
        await _saveTasksToStorage(storedTasks);
      }
    } catch (e) {
      print('更新任务审核状态失败: $e');
    }
  }

  /// 添加任务提交记录
  static Future<void> addTaskSubmission(
      String taskId, TaskSubmission submission) async {
    try {
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = storedTasks[taskIndex];
        final updatedSubmissions = [...task.submissions, submission];

        final updatedTask = Task(
          id: task.id,
          poolId: task.poolId,
          title: task.title,
          description: task.description,
          estimatedMinutes: task.estimatedMinutes,
          expectedAt: task.expectedAt,
          status: task.status,
          assigneeId: task.assigneeId,
          startedAt: task.startedAt,
          completedAt: task.completedAt,
          blockReason: task.blockReason,
          blockNote: task.blockNote,
          createdAt: task.createdAt,
          statistics: task.statistics,
          keyNodes: task.keyNodes,
          subTasks: task.subTasks,
          priority: task.priority,
          baseReward: task.baseReward,
          assignedUsers: task.assignedUsers,
          tags: task.tags,
          requiredSkills: task.requiredSkills,
          createdBy: task.createdBy,
          difficulty: task.difficulty,
          milestones: task.milestones,
          isTeamTask: task.isTeamTask,
          maxAssignees: task.maxAssignees,
          level: task.level,
          parentTaskId: task.parentTaskId,
          childTaskIds: task.childTaskIds,
          fromTemplate: task.fromTemplate,
          creationMethod: task.creationMethod,
          templateParams: task.templateParams,
          prerequisiteTasks: task.prerequisiteTasks,
          dependentTasks: task.dependentTasks,
          workflowStatus: task.workflowStatus,
          submissions: updatedSubmissions,
          reviewStatus: task.reviewStatus,
          reviewerId: task.reviewerId,
          reviewComment: task.reviewComment,
          reviewedAt: task.reviewedAt,
          taskPoints: task.taskPoints,
        );

        storedTasks[taskIndex] = updatedTask;
        await _saveTasksToStorage(storedTasks);
      }
    } catch (e) {
      print('添加任务提交记录失败: $e');
    }
  }

  /// 获取任务提交记录
  static Future<TaskSubmission?> getTaskSubmission(String submissionId) async {
    try {
      final storedTasks = await _getStoredTasks();

      for (final task in storedTasks) {
        for (final submission in task.submissions) {
          if (submission.id == submissionId) {
            return submission;
          }
        }
      }

      return null;
    } catch (e) {
      print('获取任务提交记录失败: $e');
      return null;
    }
  }

  /// 获取任务的所有提交记录
  static Future<List<TaskSubmission>> getTaskSubmissions(String taskId) async {
    try {
      final task = await getTaskById(taskId);
      return task?.submissions ?? [];
    } catch (e) {
      print('获取任务提交记录列表失败: $e');
      return [];
    }
  }

  /// 更新任务提交状态
  static Future<void> updateTaskSubmissionStatus({
    required String submissionId,
    required TaskSubmissionStatus status,
    String? reviewComment,
    String? reviewerId,
  }) async {
    try {
      final storedTasks = await _getStoredTasks();
      bool found = false;

      for (int taskIndex = 0; taskIndex < storedTasks.length; taskIndex++) {
        final task = storedTasks[taskIndex];
        final updatedSubmissions = <TaskSubmission>[];

        for (final submission in task.submissions) {
          if (submission.id == submissionId) {
            found = true;
            // 创建更新后的提交记录
            final updatedSubmission = TaskSubmission(
              id: submission.id,
              taskId: submission.taskId,
              submitterId: submission.submitterId,
              submitterName: submission.submitterName,
              submittedAt: submission.submittedAt,
              content: submission.content,
              attachments: submission.attachments,
              type: submission.type,
              status: status,
              reviewComment: reviewComment ?? submission.reviewComment,
              reviewedAt: DateTime.now(),
              reviewerId: reviewerId ?? submission.reviewerId,
            );
            updatedSubmissions.add(updatedSubmission);
          } else {
            updatedSubmissions.add(submission);
          }
        }

        if (found) {
          final updatedTask = Task(
            id: task.id,
            poolId: task.poolId,
            title: task.title,
            description: task.description,
            estimatedMinutes: task.estimatedMinutes,
            expectedAt: task.expectedAt,
            status: task.status,
            assigneeId: task.assigneeId,
            startedAt: task.startedAt,
            completedAt: task.completedAt,
            blockReason: task.blockReason,
            blockNote: task.blockNote,
            createdAt: task.createdAt,
            statistics: task.statistics,
            keyNodes: task.keyNodes,
            subTasks: task.subTasks,
            priority: task.priority,
            baseReward: task.baseReward,
            assignedUsers: task.assignedUsers,
            tags: task.tags,
            requiredSkills: task.requiredSkills,
            createdBy: task.createdBy,
            difficulty: task.difficulty,
            milestones: task.milestones,
            isTeamTask: task.isTeamTask,
            maxAssignees: task.maxAssignees,
            level: task.level,
            parentTaskId: task.parentTaskId,
            childTaskIds: task.childTaskIds,
            fromTemplate: task.fromTemplate,
            creationMethod: task.creationMethod,
            templateParams: task.templateParams,
            prerequisiteTasks: task.prerequisiteTasks,
            dependentTasks: task.dependentTasks,
            workflowStatus: task.workflowStatus,
            submissions: updatedSubmissions,
            reviewStatus: task.reviewStatus,
            reviewerId: task.reviewerId,
            reviewComment: task.reviewComment,
            reviewedAt: task.reviewedAt,
            taskPoints: task.taskPoints,
          );

          storedTasks[taskIndex] = updatedTask;
          await _saveTasksToStorage(storedTasks);
          break;
        }
      }
    } catch (e) {
      print('更新任务提交状态失败: $e');
    }
  }

  /// 添加任务点
  static Future<void> addTaskPoint(String taskId, TaskPoint taskPoint) async {
    try {
      final storedTasks = await _getStoredTasks();
      final taskIndex = storedTasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = storedTasks[taskIndex];
        final updatedTaskPoints = [...task.taskPoints, taskPoint];

        final updatedTask = Task(
          id: task.id,
          poolId: task.poolId,
          title: task.title,
          description: task.description,
          estimatedMinutes: task.estimatedMinutes,
          expectedAt: task.expectedAt,
          status: task.status,
          assigneeId: task.assigneeId,
          startedAt: task.startedAt,
          completedAt: task.completedAt,
          blockReason: task.blockReason,
          blockNote: task.blockNote,
          createdAt: task.createdAt,
          statistics: task.statistics,
          keyNodes: task.keyNodes,
          subTasks: task.subTasks,
          priority: task.priority,
          baseReward: task.baseReward,
          assignedUsers: task.assignedUsers,
          tags: task.tags,
          requiredSkills: task.requiredSkills,
          createdBy: task.createdBy,
          difficulty: task.difficulty,
          milestones: task.milestones,
          isTeamTask: task.isTeamTask,
          maxAssignees: task.maxAssignees,
          level: task.level,
          parentTaskId: task.parentTaskId,
          childTaskIds: task.childTaskIds,
          fromTemplate: task.fromTemplate,
          creationMethod: task.creationMethod,
          templateParams: task.templateParams,
          prerequisiteTasks: task.prerequisiteTasks,
          dependentTasks: task.dependentTasks,
          workflowStatus: task.workflowStatus,
          submissions: task.submissions,
          reviewStatus: task.reviewStatus,
          reviewerId: task.reviewerId,
          reviewComment: task.reviewComment,
          reviewedAt: task.reviewedAt,
          taskPoints: updatedTaskPoints,
        );

        storedTasks[taskIndex] = updatedTask;
        await _saveTasksToStorage(storedTasks);
      }
    } catch (e) {
      print('添加任务点失败: $e');
    }
  }

  /// 更新任务点状态
  static Future<bool> updateTaskPointStatus(
      String taskPointId, TaskPointStatus status) async {
    try {
      final storedTasks = await _getStoredTasks();

      for (int taskIndex = 0; taskIndex < storedTasks.length; taskIndex++) {
        final task = storedTasks[taskIndex];
        final updatedTaskPoints = <TaskPoint>[];
        bool found = false;

        for (final taskPoint in task.taskPoints) {
          if (taskPoint.id == taskPointId) {
            found = true;
            final updatedTaskPoint = TaskPoint(
              id: taskPoint.id,
              taskId: taskPoint.taskId,
              title: taskPoint.title,
              description: taskPoint.description,
              estimatedMinutes: taskPoint.estimatedMinutes,
              status: status,
              assigneeId: taskPoint.assigneeId,
              completedAt: status == TaskPointStatus.completed
                  ? DateTime.now()
                  : taskPoint.completedAt,
              createdAt: taskPoint.createdAt,
              order: taskPoint.order,
              isRequired: taskPoint.isRequired,
              weight: taskPoint.weight,
            );
            updatedTaskPoints.add(updatedTaskPoint);
          } else {
            updatedTaskPoints.add(taskPoint);
          }
        }

        if (found) {
          final updatedTask = Task(
            id: task.id,
            poolId: task.poolId,
            title: task.title,
            description: task.description,
            estimatedMinutes: task.estimatedMinutes,
            expectedAt: task.expectedAt,
            status: task.status,
            assigneeId: task.assigneeId,
            startedAt: task.startedAt,
            completedAt: task.completedAt,
            blockReason: task.blockReason,
            blockNote: task.blockNote,
            createdAt: task.createdAt,
            statistics: task.statistics,
            keyNodes: task.keyNodes,
            subTasks: task.subTasks,
            priority: task.priority,
            baseReward: task.baseReward,
            assignedUsers: task.assignedUsers,
            tags: task.tags,
            requiredSkills: task.requiredSkills,
            createdBy: task.createdBy,
            difficulty: task.difficulty,
            milestones: task.milestones,
            isTeamTask: task.isTeamTask,
            maxAssignees: task.maxAssignees,
            level: task.level,
            parentTaskId: task.parentTaskId,
            childTaskIds: task.childTaskIds,
            fromTemplate: task.fromTemplate,
            creationMethod: task.creationMethod,
            templateParams: task.templateParams,
            prerequisiteTasks: task.prerequisiteTasks,
            dependentTasks: task.dependentTasks,
            workflowStatus: task.workflowStatus,
            submissions: task.submissions,
            reviewStatus: task.reviewStatus,
            reviewerId: task.reviewerId,
            reviewComment: task.reviewComment,
            reviewedAt: task.reviewedAt,
            taskPoints: updatedTaskPoints,
          );

          storedTasks[taskIndex] = updatedTask;
          await _saveTasksToStorage(storedTasks);
          return true;
        }
      }

      return false;
    } catch (e) {
      print('更新任务点状态失败: $e');
      return false;
    }
  }

  // 获取项目任务列表
  static Future<List<Task>> getProjectTasks(String projectId) async {
    try {
      // 暂时返回模拟数据，实际应该调用后端API
      await Future.delayed(const Duration(milliseconds: 500));

      final now = DateTime.now();

      return [
        Task(
          id: 'task_demo_001',
          poolId: 'pool_001',
          projectId: projectId,
          title: '系统架构设计',
          description: '设计整体系统架构，包括前端、后端和数据库结构',
          status: TaskStatus.completed,
          createdAt: now.subtract(const Duration(days: 10)),
          statistics: const TaskStatistics(),
          priority: TaskPriority.high,
          baseReward: 40.0,
          expectedAt: now.subtract(const Duration(days: 5)),
          dueDate: now.subtract(const Duration(days: 3)),
          tags: ['架构', '设计'],
          requiredSkills: ['系统设计'],
          difficulty: TaskDifficulty.hard,
          maxAssignees: 1,
        ),
        Task(
          id: 'task_demo_002',
          poolId: 'pool_001',
          projectId: projectId,
          title: '数据库设计',
          description: '设计数据库表结构和关系',
          status: TaskStatus.inProgress,
          createdAt: now.subtract(const Duration(days: 8)),
          statistics: const TaskStatistics(),
          priority: TaskPriority.high,
          baseReward: 30.0,
          expectedAt: now.add(const Duration(days: 2)),
          dueDate: now.add(const Duration(days: 3)),
          tags: ['数据库', '设计'],
          requiredSkills: ['SQL', '数据建模'],
          difficulty: TaskDifficulty.medium,
          maxAssignees: 2,
        ),
        Task(
          id: 'task_demo_003',
          poolId: 'pool_001',
          projectId: projectId,
          title: '前端页面开发',
          description: '开发主要的前端页面和组件',
          status: TaskStatus.pending,
          createdAt: now.subtract(const Duration(days: 5)),
          statistics: const TaskStatistics(),
          priority: TaskPriority.medium,
          baseReward: 35.0,
          expectedAt: now.add(const Duration(days: 7)),
          dueDate: now.add(const Duration(days: 10)),
          tags: ['前端', 'UI'],
          requiredSkills: ['Flutter', 'Dart'],
          difficulty: TaskDifficulty.medium,
          maxAssignees: 3,
        ),
      ];
    } catch (e) {
      throw Exception('获取项目任务失败: $e');
    }
  }
}
