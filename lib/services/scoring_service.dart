// 前端评分计算服务
// 基于后端数据进行前端的贡献值和默契度计算
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';

class ScoringService {
  /// 计算用户贡献值
  /// 基于用户完成的子任务数量、质量和及时性
  static double calculateContributionScore({
    required List<SubTask> completedSubTasks,
    required List<SubTask> allSubTasks,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (allSubTasks.isEmpty) return 0.0;

    // 基础完成率分数 (40%)
    double completionRate = completedSubTasks.length / allSubTasks.length;
    double completionScore = completionRate * 40.0;

    // 及时性分数 (30%)
    double timelinessScore =
        _calculateTimelinessScore(completedSubTasks) * 30.0;

    // 任务复杂度加权分数 (30%)
    double complexityScore =
        _calculateComplexityScore(completedSubTasks, allSubTasks) * 30.0;

    return (completionScore + timelinessScore + complexityScore)
        .clamp(0.0, 100.0);
  }

  /// 计算团队默契度
  /// 基于团队成员之间的工作配合流畅度
  static double calculateTeamTacitScore({
    required List<Task> teamTasks,
    required List<User> teamMembers,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (teamTasks.isEmpty || teamMembers.isEmpty) return 0.0;

    // 团队任务完成效率 (40%)
    double efficiencyScore = _calculateTeamEfficiency(teamTasks) * 40.0;

    // 成员协作流畅度 (35%)
    double collaborationScore =
        _calculateCollaborationSmoothness(teamTasks, teamMembers) * 35.0;

    // 时间预期达成度 (25%)
    double expectationScore = _calculateExpectationScore(teamTasks) * 25.0;

    return (efficiencyScore + collaborationScore + expectationScore)
        .clamp(0.0, 100.0);
  }

  /// 计算个人与个人之间的默契度
  /// 基于两个用户在共同任务中的配合程度
  static double calculatePairTacitScore({
    required User user1,
    required User user2,
    required List<Task> sharedTasks,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    if (sharedTasks.isEmpty) return 50.0; // 默认中性分数

    // 任务交接流畅度 (40%)
    double handoffScore =
        _calculateTaskHandoffSmoothness(user1, user2, sharedTasks) * 40.0;

    // 沟通效率 (30%) - 基于任务完成时间和预期时间的差异
    double communicationScore =
        _calculateCommunicationEfficiency(sharedTasks) * 30.0;

    // 互补性分数 (30%) - 基于技能互补和任务分配合理性
    double complementScore =
        _calculateComplementariness(user1, user2, sharedTasks) * 30.0;

    return (handoffScore + communicationScore + complementScore)
        .clamp(0.0, 100.0);
  }

  /// 动态惩罚机制 - 超时惩罚
  static double applyTimelinePenalty({
    required double originalScore,
    required DateTime expectedTime,
    required DateTime actualTime,
    double maxPenalty = 30.0, // 最大惩罚30分
  }) {
    if (actualTime.isBefore(expectedTime) ||
        actualTime.isAtSameMomentAs(expectedTime)) {
      return originalScore; // 没有惩罚
    }

    // 计算超时天数
    int overdueDays = actualTime.difference(expectedTime).inDays;

    // 渐进式惩罚：每超时1天扣3分，最多扣30分
    double penalty = (overdueDays * 3.0).clamp(0.0, maxPenalty);

    return (originalScore - penalty).clamp(0.0, 100.0);
  }

  /// 动态奖励机制 - 提前完成奖励
  static double applyEarlyBonus({
    required double originalScore,
    required DateTime expectedTime,
    required DateTime actualTime,
    double maxBonus = 20.0, // 最大奖励20分
  }) {
    if (actualTime.isAfter(expectedTime) ||
        actualTime.isAtSameMomentAs(expectedTime)) {
      return originalScore; // 没有奖励
    }

    // 计算提前天数
    int earlyDays = expectedTime.difference(actualTime).inDays;

    // 渐进式奖励：每提前1天奖励2分，最多奖励20分
    double bonus = (earlyDays * 2.0).clamp(0.0, maxBonus);

    return (originalScore + bonus).clamp(0.0, 100.0);
  }

  // ==================== 私有辅助方法 ====================

  /// 计算及时性分数
  static double _calculateTimelinessScore(List<SubTask> completedSubTasks) {
    if (completedSubTasks.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (var subTask in completedSubTasks) {
      if (subTask.completedAt != null) {
        // 基于完成时间与创建时间的关系计算及时性
        Duration taskDuration =
            subTask.completedAt!.difference(subTask.createdAt);

        // 假设合理的任务完成时间是1-3天，超出会扣分
        if (taskDuration.inDays <= 1) {
          totalScore += 1.0; // 1天内完成得满分
        } else if (taskDuration.inDays <= 3) {
          totalScore += 0.8; // 3天内完成得80%
        } else if (taskDuration.inDays <= 7) {
          totalScore += 0.6; // 7天内完成得60%
        } else {
          totalScore += 0.3; // 超过7天得30%
        }
      }
    }

    return totalScore / completedSubTasks.length;
  }

  /// 计算复杂度加权分数
  static double _calculateComplexityScore(
      List<SubTask> completedSubTasks, List<SubTask> allSubTasks) {
    if (completedSubTasks.isEmpty) return 0.0;

    // 假设所有子任务的复杂度权重相同
    // 在实际应用中，可以根据子任务的类型、描述长度等因素来计算复杂度
    double totalComplexity = allSubTasks.length.toDouble();
    double completedComplexity = completedSubTasks.length.toDouble();

    return completedComplexity / totalComplexity;
  }

  /// 计算团队效率
  static double _calculateTeamEfficiency(List<Task> teamTasks) {
    if (teamTasks.isEmpty) return 0.0;

    int completedTasks =
        teamTasks.where((task) => task.status == TaskStatus.completed).length;
    return completedTasks / teamTasks.length;
  }

  /// 计算协作流畅度
  static double _calculateCollaborationSmoothness(
      List<Task> teamTasks, List<User> teamMembers) {
    // 基于任务的平均完成时间来评估协作流畅度
    // 这是一个简化的算法，实际应用中可能需要更复杂的逻辑
    if (teamTasks.isEmpty) return 0.5;

    double totalSmoothness = 0.0;
    int validTasks = 0;

    for (var task in teamTasks) {
      if (task.status == TaskStatus.completed && task.completedAt != null) {
        Duration taskDuration = task.completedAt!.difference(task.createdAt);

        // 假设合理的任务完成时间是7天，根据实际时间计算流畅度
        if (taskDuration.inDays <= 7) {
          totalSmoothness += 1.0;
        } else if (taskDuration.inDays <= 14) {
          totalSmoothness += 0.7;
        } else {
          totalSmoothness += 0.3;
        }
        validTasks++;
      }
    }

    return validTasks > 0 ? totalSmoothness / validTasks : 0.5;
  }

  /// 计算预期达成度
  static double _calculateExpectationScore(List<Task> teamTasks) {
    if (teamTasks.isEmpty) return 0.0;

    int onTimeTasks = 0;
    int totalValidTasks = 0;

    for (var task in teamTasks) {
      if (task.status == TaskStatus.completed && task.completedAt != null) {
        // 假设每个任务都有7天的预期完成时间
        DateTime expectedCompletion =
            task.createdAt.add(const Duration(days: 7));

        if (task.completedAt!.isBefore(expectedCompletion) ||
            task.completedAt!.isAtSameMomentAs(expectedCompletion)) {
          onTimeTasks++;
        }
        totalValidTasks++;
      }
    }

    return totalValidTasks > 0 ? onTimeTasks / totalValidTasks : 0.0;
  }

  /// 计算任务交接流畅度
  static double _calculateTaskHandoffSmoothness(
      User user1, User user2, List<Task> sharedTasks) {
    // 这是一个简化的算法，实际应用中需要分析任务的依赖关系和时间序列
    if (sharedTasks.isEmpty) return 0.5;

    double totalSmoothness = 0.0;
    for (var task in sharedTasks) {
      // 基于任务完成的及时性来评估交接流畅度
      if (task.status == TaskStatus.completed && task.completedAt != null) {
        Duration taskDuration = task.completedAt!.difference(task.createdAt);
        if (taskDuration.inDays <= 5) {
          totalSmoothness += 1.0;
        } else if (taskDuration.inDays <= 10) {
          totalSmoothness += 0.6;
        } else {
          totalSmoothness += 0.2;
        }
      }
    }

    return totalSmoothness / sharedTasks.length;
  }

  /// 计算沟通效率
  static double _calculateCommunicationEfficiency(List<Task> sharedTasks) {
    if (sharedTasks.isEmpty) return 0.5;

    // 基于任务完成的一致性来评估沟通效率
    int efficientTasks = 0;
    for (var task in sharedTasks) {
      if (task.status == TaskStatus.completed && task.completedAt != null) {
        Duration taskDuration = task.completedAt!.difference(task.createdAt);
        if (taskDuration.inDays <= 7) {
          efficientTasks++;
        }
      }
    }

    return efficientTasks / sharedTasks.length;
  }

  /// 计算互补性分数
  static double _calculateComplementariness(
      User user1, User user2, List<Task> sharedTasks) {
    // 这是一个简化的互补性算法
    // 实际应用中可能需要分析用户的技能标签、任务类型偏好等

    if (sharedTasks.isEmpty) return 0.5;

    // 基于共同完成任务的数量和质量来评估互补性
    int successfulCollaborations =
        sharedTasks.where((task) => task.status == TaskStatus.completed).length;
    double collaborationRate = successfulCollaborations / sharedTasks.length;

    // 互补性分数基于协作成功率
    if (collaborationRate >= 0.8) {
      return 1.0; // 高互补性
    } else if (collaborationRate >= 0.6) {
      return 0.7; // 中等互补性
    } else {
      return 0.4; // 低互补性
    }
  }

  /// 计算综合评分趋势
  static Map<String, double> calculateScoreTrends({
    required User user,
    required List<Task> userTasks,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    // 计算不同时间段的评分变化趋势
    final trends = <String, double>{};

    // 按周计算趋势
    DateTime currentWeek = periodStart;
    List<double> weeklyScores = [];

    while (currentWeek.isBefore(periodEnd)) {
      DateTime weekEnd = currentWeek.add(const Duration(days: 7));
      if (weekEnd.isAfter(periodEnd)) weekEnd = periodEnd;

      List<Task> weekTasks = userTasks
          .where((task) =>
              task.createdAt.isAfter(currentWeek) &&
              task.createdAt.isBefore(weekEnd))
          .toList();

      if (weekTasks.isNotEmpty) {
        // 简化的周评分计算
        int completedCount = weekTasks
            .where((task) => task.status == TaskStatus.completed)
            .length;
        double weekScore = (completedCount / weekTasks.length) * 100;
        weeklyScores.add(weekScore);
      }

      currentWeek = weekEnd;
    }

    if (weeklyScores.isNotEmpty) {
      trends['average'] =
          weeklyScores.reduce((a, b) => a + b) / weeklyScores.length;
      trends['trend'] = weeklyScores.length > 1
          ? weeklyScores.last - weeklyScores.first
          : 0.0;
      trends['stability'] = _calculateStability(weeklyScores);
    }

    return trends;
  }

  /// 计算分数稳定性
  static double _calculateStability(List<double> scores) {
    if (scores.length < 2) return 100.0;

    double mean = scores.reduce((a, b) => a + b) / scores.length;
    double variance = scores
            .map((score) => (score - mean) * (score - mean))
            .reduce((a, b) => a + b) /
        scores.length;
    double standardDeviation = variance.isNaN ? 0.0 : variance;

    // 稳定性 = 100 - 标准差（标准差越小越稳定）
    return (100.0 - standardDeviation).clamp(0.0, 100.0);
  }

  /// 更新成员间默契度评分
  static Map<String, double> updateMemberTacitScores(
    List<String> memberIds,
    List<dynamic> events, // 协作事件
    List<Task> tasks,
    Map<String, double> currentScores,
  ) {
    Map<String, double> updatedScores = Map.from(currentScores);

    // 为每一对成员计算默契度
    for (int i = 0; i < memberIds.length; i++) {
      for (int j = i + 1; j < memberIds.length; j++) {
        String member1 = memberIds[i];
        String member2 = memberIds[j];

        // 找到两人共同参与的任务
        List<Task> sharedTasks = tasks
            .where((task) =>
                task.assignedUsers.contains(member1) &&
                task.assignedUsers.contains(member2))
            .toList();

        if (sharedTasks.isNotEmpty) {
          double pairTacitScore = calculatePairTacitScore(
            user1: User(
              id: member1,
              name: member1,
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
                  email: 'member1@example.com',
                  phone: '',
                ),
              ),
            ),
            user2: User(
              id: member2,
              name: member2,
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
                  email: 'member2@example.com',
                  phone: '',
                ),
              ),
            ),
            sharedTasks: sharedTasks,
            periodStart: DateTime.now().subtract(const Duration(days: 30)),
            periodEnd: DateTime.now(),
          );

          String pairKey = '${member1}_$member2';
          updatedScores[pairKey] = pairTacitScore;
        }
      }
    }

    return updatedScores;
  }

  /// 计算任务中用户的贡献度
  static double calculateTaskContribution(Task task, String userId) {
    // 检查用户是否参与了这个任务
    if (!task.assignedUsers.contains(userId)) {
      return 0.0;
    }

    // 基础贡献分数
    double baseScore = task.baseReward;

    // 如果任务未完成，只能获得部分分数
    if (task.status != TaskStatus.completed) {
      return baseScore * task.progress * 0.5; // 未完成任务只能获得50%的进度分数
    }

    // 完成的任务可以获得奖励计算
    TaskReward reward = task.calculateReward();

    // 如果是多人任务，按人数分配贡献度
    if (task.assignedUsers.length > 1) {
      return reward.totalScore / task.assignedUsers.length;
    }

    return reward.totalScore;
  }

  /// 批量计算用户在多个任务中的总贡献度
  static double calculateUserTotalContribution(
    String userId,
    List<Task> tasks,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    // 筛选时间范围内的任务
    List<Task> periodTasks = tasks
        .where((task) =>
            task.createdAt.isAfter(periodStart) &&
            task.createdAt.isBefore(periodEnd))
        .toList();

    double totalContribution = 0.0;
    for (Task task in periodTasks) {
      totalContribution += calculateTaskContribution(task, userId);
    }

    return totalContribution;
  }
}
