// 评分系统使用示例
// 展示如何在前端应用中使用贡献值和默契度计算系统

import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/collaboration_pool_model.dart';
import '../services/scoring_service.dart';
import '../services/collaboration_scoring_manager.dart';

class ScoringSystemExample {
  /// 示例：计算用户在协作池中的综合表现
  static Future<Map<String, dynamic>> calculateUserPerformance({
    required String userId,
    required CollaborationPool pool,
    required List<User> allUsers,
  }) async {
    // 1. 计算用户的贡献值
    double userContribution =
        CollaborationScoringManager.calculateUserPoolContribution(
      userId,
      pool,
    );

    // 2. 计算用户的平均默契度
    double averageTacitScore =
        CollaborationScoringManager.calculateUserAverageTacitScore(
      userId,
      pool,
    );

    // 3. 计算用户的评分趋势
    List<Task> userTasks = pool.tasks
        .where((task) => task.assignedUsers.contains(userId))
        .toList();

    User? user = allUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => User(
        id: userId,
        name: '未知用户',
        createdAt: DateTime.now(),
        stats: const UserStats(),
        profile: const UserProfile(
          workStyle: WorkStyle(
            communicationStyle: 'direct',
            workPace: 'stable',
            preferredCollaborationMode: 'team',
            workingHours: ['9:00-18:00'],
            stressHandling: 'normal',
            feedbackStyle: 'constructive',
          ),
          availability: AvailabilityInfo(
            weeklySchedule: {
              'Monday': ['9:00-18:00']
            },
            timezone: 'UTC+8',
            maxHoursPerWeek: 40,
            busyPeriods: [],
          ),
          contact: ContactInfo(
            email: 'unknown@example.com',
            phone: '',
          ),
        ),
      ),
    );

    Map<String, double> trends = ScoringService.calculateScoreTrends(
      user: user,
      userTasks: userTasks,
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
    );

    // 4. 应用动态奖惩机制示例
    double adjustedContribution = userContribution;
    for (Task task in userTasks) {
      if (task.status == TaskStatus.completed &&
          task.expectedAt != null &&
          task.completedAt != null) {
        // 应用时间奖惩
        if (task.completedAt!.isBefore(task.expectedAt!)) {
          // 提前完成奖励
          adjustedContribution = ScoringService.applyEarlyBonus(
            originalScore: adjustedContribution,
            expectedTime: task.expectedAt!,
            actualTime: task.completedAt!,
          );
        } else if (task.completedAt!.isAfter(task.expectedAt!)) {
          // 超时惩罚
          adjustedContribution = ScoringService.applyTimelinePenalty(
            originalScore: adjustedContribution,
            expectedTime: task.expectedAt!,
            actualTime: task.completedAt!,
          );
        }
      }
    }

    return {
      'userId': userId,
      'originalContribution': userContribution,
      'adjustedContribution': adjustedContribution,
      'averageTacitScore': averageTacitScore,
      'trends': trends,
      'performanceLevel':
          _getPerformanceLevel(adjustedContribution, averageTacitScore),
      'recommendations':
          _generateRecommendations(adjustedContribution, averageTacitScore),
    };
  }

  /// 示例：生成团队协作分析报告
  static Future<Map<String, dynamic>> generateTeamAnalysis({
    required CollaborationPool pool,
    required List<User> allUsers,
  }) async {
    // 1. 生成协作池报告
    CollaborationReport report = CollaborationScoringManager.generatePoolReport(
      pool,
      allUsers,
    );

    // 2. 获取协作推荐
    List<CollaborationRecommendation> recommendations =
        CollaborationScoringManager.recommendCollaborations(pool, 5);

    // 3. 计算团队整体默契度
    double teamTacitScore = ScoringService.calculateTeamTacitScore(
      teamTasks: pool.tasks,
      teamMembers:
          allUsers.where((user) => pool.memberIds.contains(user.id)).toList(),
      periodStart: DateTime.now().subtract(const Duration(days: 30)),
      periodEnd: DateTime.now(),
    );

    // 4. 分析团队效率趋势
    Map<String, dynamic> efficiencyTrends =
        _calculateTeamEfficiencyTrends(pool.tasks);

    return {
      'poolInfo': {
        'id': pool.id,
        'name': pool.name,
        'memberCount': pool.memberIds.length,
        'taskCount': pool.tasks.length,
      },
      'overallPerformance': {
        'teamTacitScore': teamTacitScore,
        'completionRate': report.taskCompletionRate,
        'onTimeRate': report.onTimeCompletionRate,
        'averageTaskTime': report.averageTaskTime,
      },
      'memberPerformance': report.userReports
          .map((userReport) => {
                'userId': userReport.userId,
                'userName': userReport.userName,
                'contribution': userReport.contribution,
                'tacitScore': userReport.averageTacitScore,
                'performanceLevel': userReport.performanceLevel,
                'completedTasks': userReport.completedTasks,
                'onTimeRate': userReport.onTimeRate,
                'earlyCompletionRate': userReport.earlyCompletionRate,
              })
          .toList(),
      'collaborationRecommendations': recommendations
          .map((rec) => {
                'member1': rec.member1Id,
                'member2': rec.member2Id,
                'tacitScore': rec.tacitScore,
                'expectedEfficiency': rec.expectedEfficiency,
                'recommendationLevel': rec.recommendationLevel,
                'reason': rec.recommendationReason,
              })
          .toList(),
      'trends': efficiencyTrends,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 示例：实时更新任务完成后的评分
  static Future<Map<String, dynamic>> updateScoresOnTaskCompletion({
    required Task completedTask,
    required CollaborationPool pool,
    required List<User> allUsers,
  }) async {
    Map<String, dynamic> updates = {};

    // 1. 为所有参与的用户计算贡献值增加
    for (String userId in completedTask.assignedUsers) {
      double taskContribution = ScoringService.calculateTaskContribution(
        completedTask,
        userId,
      );

      // 应用时间奖惩
      double adjustedContribution = taskContribution;
      if (completedTask.expectedAt != null &&
          completedTask.completedAt != null) {
        if (completedTask.completedAt!.isBefore(completedTask.expectedAt!)) {
          adjustedContribution = ScoringService.applyEarlyBonus(
            originalScore: taskContribution,
            expectedTime: completedTask.expectedAt!,
            actualTime: completedTask.completedAt!,
          );
        } else if (completedTask.completedAt!
            .isAfter(completedTask.expectedAt!)) {
          adjustedContribution = ScoringService.applyTimelinePenalty(
            originalScore: taskContribution,
            expectedTime: completedTask.expectedAt!,
            actualTime: completedTask.completedAt!,
          );
        }
      }

      updates['user_$userId'] = {
        'baseContribution': taskContribution,
        'adjustedContribution': adjustedContribution,
        'bonusOrPenalty': adjustedContribution - taskContribution,
      };
    }

    // 2. 更新成员间默契度（如果是多人任务）
    if (completedTask.assignedUsers.length > 1) {
      for (int i = 0; i < completedTask.assignedUsers.length; i++) {
        for (int j = i + 1; j < completedTask.assignedUsers.length; j++) {
          String user1 = completedTask.assignedUsers[i];
          String user2 = completedTask.assignedUsers[j];

          // 找到这两个用户的历史协作任务
          List<Task> sharedTasks = pool.tasks
              .where((task) =>
                  task.assignedUsers.contains(user1) &&
                  task.assignedUsers.contains(user2))
              .toList();

          double pairTacitScore = ScoringService.calculatePairTacitScore(
            user1: allUsers.firstWhere((u) => u.id == user1),
            user2: allUsers.firstWhere((u) => u.id == user2),
            sharedTasks: sharedTasks,
            periodStart: DateTime.now().subtract(const Duration(days: 30)),
            periodEnd: DateTime.now(),
          );

          updates['tacit_${user1}_$user2'] = pairTacitScore;
        }
      }
    }

    // 3. 更新协作池整体统计
    CollaborationPool updatedPool =
        CollaborationScoringManager.updatePoolStatistics(
      pool,
      allUsers,
    );

    updates['poolStatistics'] = {
      'overallTacitScore': updatedPool.overallTacitScore,
      'completionRate': updatedPool.progress.progressPercentage,
      'averageTaskTime': updatedPool.statistics.averageTaskTime,
      'efficiencyScore': updatedPool.statistics.efficiencyScore,
    };

    return updates;
  }

  // ==================== 私有辅助方法 ====================

  static String _getPerformanceLevel(double contribution, double tacitScore) {
    if (contribution >= 80 && tacitScore >= 80) return '优秀';
    if (contribution >= 60 && tacitScore >= 60) return '良好';
    if (contribution >= 40 || tacitScore >= 40) return '一般';
    return '需要改进';
  }

  static List<String> _generateRecommendations(
      double contribution, double tacitScore) {
    List<String> recommendations = [];

    if (contribution < 50) {
      recommendations.add('建议增加任务参与度，提高个人贡献值');
    }

    if (tacitScore < 60) {
      recommendations.add('建议多参与团队协作任务，提升与团队成员的默契度');
    }

    if (contribution >= 80 && tacitScore >= 80) {
      recommendations.add('表现优秀，可以承担更有挑战性的任务或担任团队协调角色');
    } else if (contribution >= 60 || tacitScore >= 60) {
      recommendations.add('表现良好，继续保持并寻求进一步提升的机会');
    }

    if (recommendations.isEmpty) {
      recommendations.add('继续努力，保持积极的工作态度');
    }

    return recommendations;
  }

  static Map<String, dynamic> _calculateTeamEfficiencyTrends(List<Task> tasks) {
    // 按时间分组计算效率趋势
    Map<String, List<Task>> tasksByWeek = {};

    for (Task task in tasks) {
      // 计算任务所在的周
      DateTime weekStart =
          task.createdAt.subtract(Duration(days: task.createdAt.weekday - 1));
      String weekKey = weekStart.toIso8601String().substring(0, 10);

      tasksByWeek.putIfAbsent(weekKey, () => []);
      tasksByWeek[weekKey]!.add(task);
    }

    List<Map<String, dynamic>> weeklyEfficiency = [];

    tasksByWeek.forEach((week, weekTasks) {
      int completedTasks =
          weekTasks.where((t) => t.status == TaskStatus.completed).length;
      double completionRate =
          weekTasks.isNotEmpty ? completedTasks / weekTasks.length : 0.0;

      int onTimeTasks = weekTasks
          .where((t) =>
              t.status == TaskStatus.completed &&
              t.expectedAt != null &&
              t.completedAt != null &&
              !t.completedAt!.isAfter(t.expectedAt!))
          .length;

      double onTimeRate =
          completedTasks > 0 ? onTimeTasks / completedTasks : 0.0;

      weeklyEfficiency.add({
        'week': week,
        'totalTasks': weekTasks.length,
        'completedTasks': completedTasks,
        'completionRate': completionRate,
        'onTimeRate': onTimeRate,
        'efficiency': completionRate * 0.6 + onTimeRate * 0.4, // 综合效率分数
      });
    });

    // 按时间排序
    weeklyEfficiency.sort((a, b) => a['week'].compareTo(b['week']));

    return {
      'weeklyTrends': weeklyEfficiency,
      'overallTrend': weeklyEfficiency.length > 1
          ? weeklyEfficiency.last['efficiency'] -
              weeklyEfficiency.first['efficiency']
          : 0.0,
    };
  }
}
