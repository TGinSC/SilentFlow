import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/collaboration_pool_model.dart';
import 'scoring_service.dart';

// 协作评分管理器 - 整合所有评分功能的管理类
class CollaborationScoringManager {
  // 更新协作池的综合统计
  static CollaborationPool updatePoolStatistics(
    CollaborationPool pool,
    List<User> users,
  ) {
    // 更新成员间默契度
    Map<String, double> updatedTacitScores =
        ScoringService.updateMemberTacitScores(
      pool.memberIds,
      pool.events,
      pool.tasks,
      pool.memberTacitScores,
    );

    // 计算整体统计数据
    PoolStatistics updatedStats = _calculatePoolStatistics(
      pool.tasks,
      pool.events,
      updatedTacitScores,
    );

    // 更新进度
    PoolProgress updatedProgress = _calculatePoolProgress(pool.tasks);

    return pool.copyWith(
      memberTacitScores: updatedTacitScores,
      statistics: updatedStats,
      progress: updatedProgress,
    );
  }

  // 计算用户在协作池中的综合贡献度
  static double calculateUserPoolContribution(
    String userId,
    CollaborationPool pool,
  ) {
    if (pool.tasks.isEmpty) return 0.0;

    double totalContribution = 0.0;
    int contributedTasks = 0;

    for (Task task in pool.tasks) {
      double taskContribution =
          ScoringService.calculateTaskContribution(task, userId);
      if (taskContribution > 0) {
        totalContribution += taskContribution;
        contributedTasks++;
      }
    }

    if (contributedTasks == 0) return 0.0;

    // 计算平均贡献度，考虑协作池设置的奖励机制
    double averageContribution = totalContribution / contributedTasks;

    // 应用协作池的协作奖励机制
    if (pool.settings.enableCollaborationBonus) {
      // 基于用户在多个任务中的参与情况给予奖励
      double collaborationBonus = contributedTasks > 1
          ? 1.0 + (contributedTasks - 1) * pool.settings.collaborationBonusRate
          : 1.0;
      averageContribution *= collaborationBonus;
    }

    return averageContribution;
  }

  // 计算用户与协作池中其他成员的平均默契度
  static double calculateUserAverageTacitScore(
    String userId,
    CollaborationPool pool,
  ) {
    List<String> otherMembers =
        pool.memberIds.where((id) => id != userId).toList();
    if (otherMembers.isEmpty) return 0.0;

    double totalTacitScore = 0.0;
    int tacitPairs = 0;

    for (String otherId in otherMembers) {
      double tacitScore = pool.getTacitScoreBetween(userId, otherId);
      if (tacitScore > 0) {
        totalTacitScore += tacitScore;
        tacitPairs++;
      }
    }

    return tacitPairs > 0 ? totalTacitScore / tacitPairs : 0.0;
  }

  // 生成协作池评分报告
  static CollaborationReport generatePoolReport(
    CollaborationPool pool,
    List<User> users,
  ) {
    List<UserContributionReport> userReports = [];

    for (String memberId in pool.memberIds) {
      User? user = users.firstWhere(
        (u) => u.id == memberId,
        orElse: () => User(
          id: memberId,
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

      double contribution = calculateUserPoolContribution(memberId, pool);
      double averageTacit = calculateUserAverageTacitScore(memberId, pool);

      userReports.add(UserContributionReport(
        userId: memberId,
        userName: user.name,
        contribution: contribution,
        averageTacitScore: averageTacit,
        completedTasks: pool.tasks
            .where((t) =>
                t.assignedUsers.contains(memberId) &&
                t.status == TaskStatus.completed)
            .length,
        onTimeRate: _calculateUserOnTimeRate(memberId, pool.tasks),
        earlyCompletionRate:
            _calculateUserEarlyCompletionRate(memberId, pool.tasks),
      ));
    }

    // 按贡献度排序
    userReports.sort((a, b) => b.contribution.compareTo(a.contribution));

    return CollaborationReport(
      poolId: pool.id,
      poolName: pool.name,
      overallTacitScore: pool.overallTacitScore,
      taskCompletionRate: pool.progress.progressPercentage,
      onTimeCompletionRate: pool.onTimeCompletionRate,
      averageTaskTime: pool.statistics.averageTaskTime,
      userReports: userReports,
      generatedAt: DateTime.now(),
    );
  }

  // 推荐最佳协作组合
  static List<CollaborationRecommendation> recommendCollaborations(
    CollaborationPool pool,
    int maxRecommendations,
  ) {
    List<CollaborationRecommendation> recommendations = [];

    // 分析所有成员对的默契度
    for (int i = 0; i < pool.memberIds.length; i++) {
      for (int j = i + 1; j < pool.memberIds.length; j++) {
        String member1 = pool.memberIds[i];
        String member2 = pool.memberIds[j];

        double tacitScore = pool.getTacitScoreBetween(member1, member2);

        // 计算预期协作效果
        double expectedEfficiency = _calculateExpectedEfficiency(
          member1,
          member2,
          pool,
        );

        recommendations.add(CollaborationRecommendation(
          member1Id: member1,
          member2Id: member2,
          tacitScore: tacitScore,
          expectedEfficiency: expectedEfficiency,
          recommendationReason:
              _generateRecommendationReason(tacitScore, expectedEfficiency),
        ));
      }
    }

    // 按预期效率排序并返回前N个
    recommendations
        .sort((a, b) => b.expectedEfficiency.compareTo(a.expectedEfficiency));
    return recommendations.take(maxRecommendations).toList();
  }

  // 计算协作池统计
  static PoolStatistics _calculatePoolStatistics(
    List<Task> tasks,
    List<CollaborationEvent> events,
    Map<String, double> tacitScores,
  ) {
    List<Task> completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).toList();

    double averageTaskTime = 0.0;
    if (completedTasks.isNotEmpty) {
      double totalTime = completedTasks
          .map((t) => t.statistics.actualMinutes.toDouble())
          .reduce((a, b) => a + b);
      averageTaskTime = totalTime / completedTasks.length;
    }

    double teamTacitScore = tacitScores.values.isNotEmpty
        ? tacitScores.values.reduce((a, b) => a + b) / tacitScores.values.length
        : 0.0;

    int onTimeTasks = completedTasks
        .where((t) =>
            t.expectedAt != null &&
            t.completedAt != null &&
            !t.completedAt!.isAfter(t.expectedAt!))
        .length;

    double onTimeRate =
        completedTasks.isNotEmpty ? onTimeTasks / completedTasks.length : 0.0;

    int earlyTasks = completedTasks
        .where((t) =>
            t.expectedAt != null &&
            t.completedAt != null &&
            t.completedAt!.isBefore(t.expectedAt!))
        .length;

    double earlyCompletionRate =
        completedTasks.isNotEmpty ? earlyTasks / completedTasks.length : 0.0;

    return PoolStatistics(
      averageTaskTime: averageTaskTime,
      teamTacitScore: teamTacitScore,
      collaborationEvents: events.length,
      efficiencyScore: onTimeRate * 100,
      onTimeRate: onTimeRate,
      earlyCompletionRate: earlyCompletionRate,
    );
  }

  // 计算协作池进度
  static PoolProgress _calculatePoolProgress(List<Task> tasks) {
    int totalTasks = tasks.length;
    int completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    int inProgressTasks =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    int blockedTasks =
        tasks.where((t) => t.status == TaskStatus.blocked).length;

    int overdueTasks = tasks
        .where((t) =>
            t.expectedAt != null &&
            DateTime.now().isAfter(t.expectedAt!) &&
            t.status != TaskStatus.completed)
        .length;

    double averageProgress = 0.0;
    if (tasks.isNotEmpty) {
      double totalProgress =
          tasks.map((t) => t.progress).reduce((a, b) => a + b);
      averageProgress = totalProgress / tasks.length;
    }

    return PoolProgress(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      inProgressTasks: inProgressTasks,
      averageProgress: averageProgress,
      blockedTasks: blockedTasks,
      overdueTasks: overdueTasks,
    );
  }

  // 计算用户按时完成率
  static double _calculateUserOnTimeRate(String userId, List<Task> tasks) {
    List<Task> userCompletedTasks = tasks
        .where((t) =>
            t.assignedUsers.contains(userId) &&
            t.status == TaskStatus.completed &&
            t.expectedAt != null &&
            t.completedAt != null)
        .toList();

    if (userCompletedTasks.isEmpty) return 0.0;

    int onTimeTasks = userCompletedTasks
        .where((t) => !t.completedAt!.isAfter(t.expectedAt!))
        .length;

    return onTimeTasks / userCompletedTasks.length;
  }

  // 计算用户提前完成率
  static double _calculateUserEarlyCompletionRate(
      String userId, List<Task> tasks) {
    List<Task> userCompletedTasks = tasks
        .where((t) =>
            t.assignedUsers.contains(userId) &&
            t.status == TaskStatus.completed &&
            t.expectedAt != null &&
            t.completedAt != null)
        .toList();

    if (userCompletedTasks.isEmpty) return 0.0;

    int earlyTasks = userCompletedTasks
        .where((t) => t.completedAt!.isBefore(t.expectedAt!))
        .length;

    return earlyTasks / userCompletedTasks.length;
  }

  // 计算预期协作效率
  static double _calculateExpectedEfficiency(
    String member1,
    String member2,
    CollaborationPool pool,
  ) {
    double tacitScore = pool.getTacitScoreBetween(member1, member2);

    // 基于历史协作表现计算
    List<Task> sharedTasks = pool.tasks
        .where((t) =>
            t.assignedUsers.contains(member1) &&
            t.assignedUsers.contains(member2))
        .toList();

    if (sharedTasks.isEmpty) {
      // 没有历史协作数据，基于默契度估算
      return tacitScore * 0.8; // 保守估计
    }

    List<Task> completedSharedTasks =
        sharedTasks.where((t) => t.status == TaskStatus.completed).toList();

    if (completedSharedTasks.isEmpty) {
      return tacitScore * 0.6; // 更保守的估计
    }

    // 计算历史协作的平均效率
    double totalEfficiency = 0.0;
    for (Task task in completedSharedTasks) {
      if (task.expectedAt != null && task.completedAt != null) {
        double expectedMinutes = task.estimatedMinutes.toDouble();
        double actualMinutes = task.statistics.actualMinutes.toDouble();

        if (actualMinutes > 0) {
          double efficiency = expectedMinutes / actualMinutes;
          totalEfficiency += efficiency;
        }
      }
    }

    double averageEfficiency = totalEfficiency / completedSharedTasks.length;

    // 结合默契度和历史效率
    return (tacitScore / 100.0 * 0.4 + averageEfficiency * 0.6) * 100;
  }

  // 生成推荐理由
  static String _generateRecommendationReason(
      double tacitScore, double efficiency) {
    if (tacitScore >= 85 && efficiency >= 85) {
      return '高默契度高效率，推荐承担重要任务';
    } else if (tacitScore >= 75 && efficiency >= 75) {
      return '良好配合，适合常规协作任务';
    } else if (tacitScore >= 60) {
      return '具备合作基础，建议从简单任务开始';
    } else {
      return '需要磨合，建议安排培养默契度的任务';
    }
  }
}

// 协作报告模型
class CollaborationReport {
  final String poolId;
  final String poolName;
  final double overallTacitScore;
  final double taskCompletionRate;
  final double onTimeCompletionRate;
  final double averageTaskTime;
  final List<UserContributionReport> userReports;
  final DateTime generatedAt;

  const CollaborationReport({
    required this.poolId,
    required this.poolName,
    required this.overallTacitScore,
    required this.taskCompletionRate,
    required this.onTimeCompletionRate,
    required this.averageTaskTime,
    required this.userReports,
    required this.generatedAt,
  });
}

// 用户贡献报告
class UserContributionReport {
  final String userId;
  final String userName;
  final double contribution;
  final double averageTacitScore;
  final int completedTasks;
  final double onTimeRate;
  final double earlyCompletionRate;

  const UserContributionReport({
    required this.userId,
    required this.userName,
    required this.contribution,
    required this.averageTacitScore,
    required this.completedTasks,
    required this.onTimeRate,
    required this.earlyCompletionRate,
  });

  String get performanceLevel {
    if (contribution >= 80 && averageTacitScore >= 80) return '优秀';
    if (contribution >= 60 && averageTacitScore >= 60) return '良好';
    if (contribution >= 40 || averageTacitScore >= 40) return '一般';
    return '需要改进';
  }
}

// 协作推荐
class CollaborationRecommendation {
  final String member1Id;
  final String member2Id;
  final double tacitScore;
  final double expectedEfficiency;
  final String recommendationReason;

  const CollaborationRecommendation({
    required this.member1Id,
    required this.member2Id,
    required this.tacitScore,
    required this.expectedEfficiency,
    required this.recommendationReason,
  });

  String get recommendationLevel {
    if (expectedEfficiency >= 85) return '强烈推荐';
    if (expectedEfficiency >= 70) return '推荐';
    if (expectedEfficiency >= 50) return '可以尝试';
    return '不推荐';
  }
}
