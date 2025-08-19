import '../models/task_model.dart';
import 'task_service.dart';

class WorkflowService {
  /// 检查任务是否可以开始（前置任务已完成）
  static Future<bool> canStartTask(String taskId) async {
    final task = await TaskService.getTaskById(taskId);
    if (task == null) return false;

    // 如果没有前置任务，可以直接开始
    if (task.prerequisiteTasks.isEmpty) return true;

    // 检查所有前置任务是否已完成
    for (final prerequisiteId in task.prerequisiteTasks) {
      final prerequisiteTask = await TaskService.getTaskById(prerequisiteId);
      if (prerequisiteTask == null ||
          prerequisiteTask.status != TaskStatus.completed) {
        return false;
      }
    }

    return true;
  }

  /// 更新任务的工作流状态
  static Future<void> updateWorkflowStatus(String taskId) async {
    final task = await TaskService.getTaskById(taskId);
    if (task == null) return;

    WorkflowStatus newStatus;

    if (task.status == TaskStatus.completed) {
      newStatus = WorkflowStatus.completed;
    } else if (task.status == TaskStatus.blocked) {
      newStatus = WorkflowStatus.blocked;
    } else if (task.reviewStatus == TaskReviewStatus.pending &&
        task.status == TaskStatus.inProgress) {
      newStatus = WorkflowStatus.reviewing;
    } else if (await canStartTask(taskId)) {
      if (task.status == TaskStatus.inProgress) {
        newStatus = WorkflowStatus.inProgress;
      } else {
        newStatus = WorkflowStatus.ready;
      }
    } else {
      newStatus = WorkflowStatus.waiting;
    }

    // 更新工作流状态
    await TaskService.updateTaskWorkflowStatus(taskId, newStatus);

    // 更新依赖此任务的后置任务状态
    await _updateDependentTasksStatus(taskId);
  }

  /// 更新依赖任务的状态
  static Future<void> _updateDependentTasksStatus(
      String completedTaskId) async {
    final completedTask = await TaskService.getTaskById(completedTaskId);
    if (completedTask == null) return;

    // 更新所有依赖此任务的后置任务
    for (final dependentTaskId in completedTask.dependentTasks) {
      await updateWorkflowStatus(dependentTaskId);
    }
  }

  /// 获取任务的工作流图数据
  static Future<Map<String, dynamic>> getWorkflowGraph(String teamId) async {
    try {
      final tasks = await TaskService.getTeamTasks(teamId);
      final projectTasks =
          tasks.where((task) => task.level == TaskLevel.task).toList();

      List<Map<String, dynamic>> nodes = [];
      List<Map<String, dynamic>> edges = [];

      // 创建节点
      for (final task in projectTasks) {
        nodes.add({
          'id': task.id,
          'title': task.title,
          'status': task.status.name,
          'workflowStatus': task.workflowStatus.name,
          'progress': await _calculateTaskProgress(task.id),
          'assignees': task.assignedUsers,
          'level': task.level.name,
        });
      }

      // 创建边（连接线）
      for (final task in projectTasks) {
        for (final dependentTaskId in task.dependentTasks) {
          edges.add({
            'source': task.id,
            'target': dependentTaskId,
            'type': 'dependency',
          });
        }
      }

      return {
        'nodes': nodes,
        'edges': edges,
        'layout': 'dagre', // 有向无环图布局
      };
    } catch (e) {
      print('WorkflowService.getWorkflowGraph: 错误 - $e');
      return {
        'nodes': <Map<String, dynamic>>[],
        'edges': <Map<String, dynamic>>[],
        'layout': 'dagre',
      };
    }
  }

  /// 计算任务进度
  static Future<double> _calculateTaskProgress(String taskId) async {
    final task = await TaskService.getTaskById(taskId);
    if (task == null) return 0.0;

    if (task.level == TaskLevel.taskPoint) {
      // 任务点级别，直接返回完成状态
      return task.status == TaskStatus.completed ? 1.0 : 0.0;
    } else if (task.level == TaskLevel.task) {
      // 任务级别，基于任务点计算进度
      if (task.taskPoints.isEmpty) {
        // 没有任务点，基于状态计算
        switch (task.status) {
          case TaskStatus.pending:
            return 0.0;
          case TaskStatus.inProgress:
            return 0.5;
          case TaskStatus.completed:
            return 1.0;
          case TaskStatus.blocked:
            return 0.3; // 假设被阻塞时有一些进度
        }
      }

      // 基于任务点计算进度
      final totalWeight =
          task.taskPoints.fold<double>(0.0, (sum, point) => sum + point.weight);
      final completedWeight = task.taskPoints
          .where((point) => point.status == TaskPointStatus.completed)
          .fold<double>(0.0, (sum, point) => sum + point.weight);

      return totalWeight > 0 ? completedWeight / totalWeight : 0.0;
    }

    return 0.0;
  }

  /// 添加任务依赖关系
  static Future<bool> addTaskDependency(
      String taskId, String prerequisiteTaskId) async {
    final task = await TaskService.getTaskById(taskId);
    final prerequisiteTask = await TaskService.getTaskById(prerequisiteTaskId);

    if (task == null || prerequisiteTask == null) return false;

    // 检查是否会产生循环依赖
    if (await _wouldCreateCycle(taskId, prerequisiteTaskId)) {
      return false;
    }

    // 添加依赖关系
    await TaskService.addTaskPrerequisite(taskId, prerequisiteTaskId);
    await TaskService.addTaskDependent(prerequisiteTaskId, taskId);

    // 更新工作流状态
    await updateWorkflowStatus(taskId);

    return true;
  }

  /// 检查是否会产生循环依赖
  static Future<bool> _wouldCreateCycle(
      String taskId, String prerequisiteTaskId) async {
    // 简单的循环检测：检查prerequisiteTask是否依赖于taskId
    final prerequisiteTask = await TaskService.getTaskById(prerequisiteTaskId);
    if (prerequisiteTask == null) return false;

    return prerequisiteTask.prerequisiteTasks.contains(taskId) ||
        await _hasTransitiveDependency(prerequisiteTaskId, taskId);
  }

  /// 检查传递依赖
  static Future<bool> _hasTransitiveDependency(
      String fromTaskId, String toTaskId) async {
    final fromTask = await TaskService.getTaskById(fromTaskId);
    if (fromTask == null) return false;

    for (final depId in fromTask.dependentTasks) {
      if (depId == toTaskId) return true;
      if (await _hasTransitiveDependency(depId, toTaskId)) return true;
    }

    return false;
  }

  /// 提交任务
  static Future<TaskSubmission?> submitTask({
    required String taskId,
    required String submitterId,
    required String submitterName,
    required String content,
    List<String> attachments = const [],
    TaskSubmissionType type = TaskSubmissionType.completion,
  }) async {
    final task = await TaskService.getTaskById(taskId);
    if (task == null) return null;

    final submission = TaskSubmission(
      id: 'submission_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      submitterId: submitterId,
      submitterName: submitterName,
      submittedAt: DateTime.now(),
      content: content,
      attachments: attachments,
      type: type,
      status: TaskSubmissionStatus.submitted,
    );

    // 保存提交记录
    await TaskService.addTaskSubmission(taskId, submission);

    // 如果是完成提交，更新任务状态为审核中
    if (type == TaskSubmissionType.completion) {
      await TaskService.updateTaskStatus(
        teamId: task.poolId,
        taskId: taskId,
        status: TaskStatus.inProgress,
      );
      await TaskService.updateTaskReviewStatus(
          taskId, TaskReviewStatus.pending);
    }

    // 更新工作流状态
    await updateWorkflowStatus(taskId);

    return submission;
  }

  /// 审核任务提交
  static Future<bool> reviewTaskSubmission({
    required String submissionId,
    required String reviewerId,
    required TaskSubmissionStatus decision,
    String? reviewComment,
  }) async {
    final submission = await TaskService.getTaskSubmission(submissionId);
    if (submission == null) return false;

    final task = await TaskService.getTaskById(submission.taskId);
    if (task == null) return false;

    // 更新提交状态
    await TaskService.updateTaskSubmissionStatus(
      submissionId: submissionId,
      status: decision,
      reviewComment: reviewComment,
      reviewerId: reviewerId,
    );

    // 根据审核结果更新任务状态
    TaskStatus newTaskStatus;
    TaskReviewStatus newReviewStatus;

    switch (decision) {
      case TaskSubmissionStatus.approved:
        newTaskStatus = TaskStatus.completed;
        newReviewStatus = TaskReviewStatus.approved;
        break;
      case TaskSubmissionStatus.rejected:
        newTaskStatus = TaskStatus.pending;
        newReviewStatus = TaskReviewStatus.rejected;
        break;
      case TaskSubmissionStatus.needsRevision:
        newTaskStatus = TaskStatus.inProgress;
        newReviewStatus = TaskReviewStatus.needsRevision;
        break;
      default:
        return false;
    }

    await TaskService.updateTaskStatus(
      teamId: task.poolId,
      taskId: submission.taskId,
      status: newTaskStatus,
    );

    await TaskService.updateTaskReviewStatus(
        submission.taskId, newReviewStatus);

    // 更新工作流状态
    await updateWorkflowStatus(submission.taskId);

    return true;
  }

  /// 获取任务的提交历史
  static Future<List<TaskSubmission>> getTaskSubmissions(String taskId) async {
    return await TaskService.getTaskSubmissions(taskId);
  }

  /// 创建任务点
  static Future<TaskPoint?> createTaskPoint({
    required String taskId,
    required String title,
    String? description,
    int estimatedMinutes = 30,
    String? assigneeId,
    int order = 0,
    bool isRequired = true,
    double weight = 1.0,
  }) async {
    final task = await TaskService.getTaskById(taskId);
    if (task == null || task.level != TaskLevel.task) return null;

    final taskPoint = TaskPoint(
      id: 'point_${DateTime.now().millisecondsSinceEpoch}',
      taskId: taskId,
      title: title,
      description: description,
      estimatedMinutes: estimatedMinutes,
      assigneeId: assigneeId,
      createdAt: DateTime.now(),
      order: order,
      isRequired: isRequired,
      weight: weight,
    );

    await TaskService.addTaskPoint(taskId, taskPoint);

    return taskPoint;
  }

  /// 更新任务点状态
  static Future<bool> updateTaskPointStatus(
      String taskPointId, TaskPointStatus status) async {
    return await TaskService.updateTaskPointStatus(taskPointId, status);
  }

  /// 获取任务的所有任务点
  static Future<List<TaskPoint>> getTaskPoints(String taskId) async {
    final task = await TaskService.getTaskById(taskId);
    if (task == null) return [];

    return task.taskPoints;
  }
}
