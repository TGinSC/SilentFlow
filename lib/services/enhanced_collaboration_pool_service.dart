import '../models/collaboration_pool_model.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import 'task_assignment_service.dart';

// 增强的协作池管理服务（修复版）
class EnhancedCollaborationPoolService {
  /// 创建智能协作池
  static Future<bool> createSmartCollaborationPool({
    required String leaderId,
    required String poolName,
    required String description,
    PoolSettings? customSettings,
  }) async {
    try {
      // 验证队长权限 (简化实现)
      // 在实际应用中，这里应该调用 UserService.getUser(leaderId);

      // 创建协作池设置
      // PoolSettings settings = customSettings ?? const PoolSettings(...);

      // 这里应该调用后端API创建协作池
      // await ApiService.post('/pools', {...});

      return true;
    } catch (e) {
      print('创建智能协作池失败: $e');
      return false;
    }
  }

  /// 智能成员邀请和加入审批
  static Future<bool> approvePoolJoinRequest({
    required String requesterId,
    required String poolId,
    String? approvalNote,
  }) async {
    try {
      // 验证用户是否为队长
      CollaborationPool? pool = await getPool(poolId);
      if (pool == null || pool.leaderId != requesterId) {
        return false;
      }

      // 检查池容量
      if (pool.memberIds.length >= pool.settings.maxPoolSize) {
        throw Exception('协作池已满');
      }

      // 获取申请者信息 (简化实现)
      // 在实际应用中，这里应该调用 UserService.getUser(requesterId);

      // 批准加入
      // 这里应该调用后端API更新协作池
      // await ApiService.put('/pools/$poolId/members', {...});

      return true;
    } catch (e) {
      print('审批加入申请失败: $e');
      return false;
    }
  }

  /// 智能任务分配
  static Future<TaskAssignmentResult> assignTaskToMembers({
    required String taskId,
    required List<String> assigneeIds,
    required String leaderId,
    String? assignmentNote,
  }) async {
    try {
      // 获取任务信息 (简化实现)
      // 在实际应用中，这里应该调用 TaskService.getTask(taskId);

      return TaskAssignmentResult(
        success: true,
        message: '任务分配成功',
        assignedUsers: assigneeIds,
      );
    } catch (e) {
      print('智能任务分配失败: $e');
      return TaskAssignmentResult(
        success: false,
        message: '任务分配失败: $e',
        assignedUsers: [],
      );
    }
  }

  /// 获取队长管理仪表板
  static Future<LeaderDashboardData?> getLeaderDashboard(
    String poolId,
    String leaderId,
  ) async {
    try {
      // 验证权限
      CollaborationPool? pool = await getPool(poolId);
      if (pool == null || pool.leaderId != leaderId) {
        throw Exception('权限不足');
      }

      // 获取池中所有任务 (简化实现)
      // 在实际应用中，这里应该调用 TaskService.getTasksByPool(poolId);
      List<Task> allTasks = [];

      // 获取所有成员信息 (简化实现)
      // 在实际应用中，这里应该从数据库获取用户信息
      List<User> members = [];

      return LeaderDashboardData(
        poolOverview: PoolOverview(
          totalMembers: members.length,
          activeTasks:
              allTasks.where((t) => t.status == TaskStatus.inProgress).length,
          completedTasks:
              allTasks.where((t) => t.status == TaskStatus.completed).length,
          averageTacitScore: 78.5,
          teamEfficiency: 0.85,
          upcomingDeadlines: allTasks
              .where((t) =>
                  t.expectedAt != null &&
                  t.expectedAt!.difference(DateTime.now()).inDays <= 3)
              .length,
        ),
        memberPerformance: members
            .map((member) => MemberPerformance(
                  userId: member.id,
                  userName: member.name,
                  contributionScore: 75.0,
                  completedTasks: allTasks
                      .where((t) =>
                          t.assigneeId == member.id &&
                          t.status == TaskStatus.completed)
                      .length,
                  tacitScores: {
                    'communication': 75.0,
                    'collaboration': 80.0,
                    'reliability': 85.0,
                  },
                  workloadBalance: 0.8,
                  skillUtilization: 0.75,
                  preferredTaskTypes: ['development', 'design'],
                  averageTaskCompletionTime: const Duration(days: 3),
                ))
            .toList(),
        taskAnalytics: TaskAnalytics(
          tasksByStatus: {
            TaskStatus.completed:
                allTasks.where((t) => t.status == TaskStatus.completed).length,
            TaskStatus.inProgress:
                allTasks.where((t) => t.status == TaskStatus.inProgress).length,
            TaskStatus.pending:
                allTasks.where((t) => t.status == TaskStatus.pending).length,
          },
          tasksByDifficulty: {
            TaskDifficulty.easy: allTasks
                .where((t) => t.difficulty == TaskDifficulty.easy)
                .length,
            TaskDifficulty.medium: allTasks
                .where((t) => t.difficulty == TaskDifficulty.medium)
                .length,
            TaskDifficulty.hard: allTasks
                .where((t) => t.difficulty == TaskDifficulty.hard)
                .length,
          },
          averageCompletionTime: const Duration(days: 3),
          bottlenecks: ['资源不足', '依赖任务延迟'],
          upcomingDeadlines: allTasks
              .where((t) =>
                  t.expectedAt != null &&
                  t.expectedAt!.difference(DateTime.now()).inDays <= 7)
              .map((t) => TaskDeadlineInfo(
                    taskId: t.id,
                    taskTitle: t.title,
                    deadline: t.expectedAt!,
                    assigneeId: t.assigneeId,
                    priority: t.priority,
                  ))
              .toList(),
        ),
        recommendations: _getLeaderRecommendations(pool, allTasks, members),
      );
    } catch (e) {
      print('获取仪表板数据失败：$e');
      return null;
    }
  }

  /// 智能推荐任务分配
  static Future<List<SmartAssignmentSuggestion>> getSmartAssignmentSuggestions(
    String leaderId,
    String poolId,
  ) async {
    try {
      // 验证权限
      CollaborationPool? pool = await getPool(poolId);
      if (pool == null || pool.leaderId != leaderId) {
        return [];
      }

      // 获取未分配的任务 (简化实现)
      // 在实际应用中，这里应该调用 TaskService.getUnassignedTasks(poolId);
      List<Task> unassignedTasks = [];

      // 获取可用成员 (简化实现)
      // 在实际应用中，这里应该从数据库获取用户信息
      List<User> availableMembers = [];

      List<SmartAssignmentSuggestion> suggestions = [];

      for (Task task in unassignedTasks) {
        TaskAssignmentRecommendation recommendation =
            TaskAssignmentService.recommendTaskAssignment(
          task,
          availableMembers,
          pool,
        );

        if (recommendation.recommendedAssignments.isNotEmpty) {
          suggestions.add(SmartAssignmentSuggestion(
            taskId: task.id,
            taskTitle: task.title,
            taskDifficulty: task.difficulty.displayName,
            userId: recommendation.recommendedAssignments.isNotEmpty
                ? recommendation.recommendedAssignments.first.userId
                : '',
            matchScore: recommendation.recommendedAssignments.isNotEmpty
                ? recommendation.recommendedAssignments.first.matchScore
                : 0.0,
            recommendedAssignees: recommendation.recommendedAssignments
                .map((match) => match.userId)
                .toList(),
            confidence: recommendation.confidence,
            reason: recommendation.assignmentStrategy,
            reasoning: recommendation.assignmentStrategy,
            benefits: _generateAssignmentBenefits(task, recommendation),
            potentialRisks: _identifyAssignmentRisks(task, recommendation),
          ));
        }
      }

      return suggestions;
    } catch (e) {
      print('获取智能分配建议失败: $e');
      return [];
    }
  }

  /// 设置任务里程碑
  static Future<bool> setTaskMilestones(
    String taskId,
    String leaderId,
    List<TaskMilestone> milestones,
  ) async {
    try {
      // 获取任务 (简化实现)
      // 在实际应用中，这里应该调用 TaskService.getTask(taskId);

      // 简化实现，直接返回成功
      return true;
    } catch (e) {
      print('设置任务里程碑失败: $e');
      return false;
    }
  }

  // ==================== 私有辅助方法 ====================

  static Future<CollaborationPool?> getPool(String poolId) async {
    // 这里应该调用后端API获取协作池信息
    // 暂时返回模拟数据
    return null;
  }

  static List<String> _getLeaderRecommendations(
    CollaborationPool pool,
    List<Task> tasks,
    List<User> members,
  ) {
    List<String> recommendations = [];

    // 基于当前状况生成建议
    if (tasks.isEmpty) {
      recommendations.add('建议创建一些任务开始协作');
    } else {
      recommendations.add('团队运行良好，继续保持');
    }

    return recommendations;
  }

  static List<String> _generateAssignmentBenefits(
    Task task,
    TaskAssignmentRecommendation recommendation,
  ) {
    return [
      '技能匹配度高',
      '工作负载均衡',
      '提升协作效率',
    ];
  }

  static List<String> _identifyAssignmentRisks(
    Task task,
    TaskAssignmentRecommendation recommendation,
  ) {
    return [
      '可能存在时间冲突',
      '需要额外的沟通协调',
    ];
  }
}

// ==================== 数据模型类 ====================

// 任务分配结果
class TaskAssignmentResult {
  final bool success;
  final String message;
  final List<String> assignedUsers;
  final TaskAssignmentRecommendation? recommendation;

  const TaskAssignmentResult({
    required this.success,
    required this.message,
    required this.assignedUsers,
    this.recommendation,
  });
}

// 队长仪表板数据
class LeaderDashboardData {
  final PoolOverview poolOverview;
  final List<MemberPerformance> memberPerformance;
  final TaskAnalytics taskAnalytics;
  final List<String> recommendations;

  const LeaderDashboardData({
    required this.poolOverview,
    required this.memberPerformance,
    required this.taskAnalytics,
    required this.recommendations,
  });
}

// 协作池概览
class PoolOverview {
  final int totalMembers;
  final int activeTasks;
  final int completedTasks;
  final double averageTacitScore;
  final double teamEfficiency;
  final int upcomingDeadlines;

  const PoolOverview({
    required this.totalMembers,
    required this.activeTasks,
    required this.completedTasks,
    required this.averageTacitScore,
    required this.teamEfficiency,
    required this.upcomingDeadlines,
  });
}

// 成员表现数据
class MemberPerformance {
  final String userId;
  final String userName;
  final double contributionScore;
  final int completedTasks;
  final Map<String, double> tacitScores;
  final double workloadBalance;
  final double skillUtilization;
  final List<String> preferredTaskTypes;
  final Duration averageTaskCompletionTime;

  const MemberPerformance({
    required this.userId,
    required this.userName,
    required this.contributionScore,
    required this.completedTasks,
    required this.tacitScores,
    required this.workloadBalance,
    required this.skillUtilization,
    required this.preferredTaskTypes,
    required this.averageTaskCompletionTime,
  });
}

// 任务分析数据
class TaskAnalytics {
  final Map<TaskStatus, int> tasksByStatus;
  final Map<TaskDifficulty, int> tasksByDifficulty;
  final Duration averageCompletionTime;
  final List<String> bottlenecks;
  final List<TaskDeadlineInfo> upcomingDeadlines;

  const TaskAnalytics({
    required this.tasksByStatus,
    required this.tasksByDifficulty,
    required this.averageCompletionTime,
    required this.bottlenecks,
    required this.upcomingDeadlines,
  });
}

// 任务截止信息
class TaskDeadlineInfo {
  final String taskId;
  final String taskTitle;
  final String? assigneeId;
  final DateTime deadline;
  final TaskPriority priority;

  const TaskDeadlineInfo({
    required this.taskId,
    required this.taskTitle,
    this.assigneeId,
    required this.deadline,
    required this.priority,
  });
}

// 智能分配建议
class SmartAssignmentSuggestion {
  final String taskId;
  final String taskTitle;
  final String taskDifficulty;
  final String userId; // 推荐的用户ID
  final double matchScore; // 匹配分数
  final List<String> recommendedAssignees;
  final double confidence;
  final String reason; // 推荐原因
  final String reasoning;
  final List<String> benefits;
  final List<String> potentialRisks;

  const SmartAssignmentSuggestion({
    required this.taskId,
    required this.taskTitle,
    required this.taskDifficulty,
    required this.userId,
    required this.matchScore,
    required this.recommendedAssignees,
    required this.confidence,
    required this.reason,
    required this.reasoning,
    required this.benefits,
    required this.potentialRisks,
  });
}
