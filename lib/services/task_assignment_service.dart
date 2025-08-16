import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/collaboration_pool_model.dart';

// 任务分配管理服务
// 支持队长智能分配和个人主动认领
class TaskAssignmentService {
  /// 队长智能任务分配
  /// 根据成员技能、工作风格和历史表现推荐最佳分配方案
  static TaskAssignmentRecommendation recommendTaskAssignment(
    Task task,
    List<User> availableMembers,
    CollaborationPool pool,
  ) {
    List<UserTaskMatch> matches = [];

    for (User user in availableMembers) {
      // 检查用户是否有资格接受此任务
      List<String> userSkillNames =
          user.profile.skills.map((s) => s.name).toList();
      int maxSkillLevel = user.profile.skills.isNotEmpty
          ? user.profile.skills
              .map((s) => s.level)
              .reduce((a, b) => a > b ? a : b)
          : 1;

      if (!task.canBeClaimedBy(user.id, userSkillNames, maxSkillLevel)) {
        continue;
      }

      // 计算综合匹配分数
      double matchScore = _calculateUserTaskMatchScore(user, task, pool);

      matches.add(UserTaskMatch(
        userId: user.id,
        userName: user.name,
        matchScore: matchScore,
        skillMatch: task.calculateMatchScore(
          userSkillNames,
          user.profile.interests,
          user.profile.preferredTaskTypes,
        ),
        availabilityScore: _calculateAvailabilityScore(user, task),
        collaborationHistory: _getCollaborationHistory(user.id, pool),
        workStyleCompatibility: _calculateWorkStyleCompatibility(user, task),
        recommendationReason:
            _generateRecommendationReason(user, task, matchScore),
      ));
    }

    // 按匹配分数排序
    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return TaskAssignmentRecommendation(
      taskId: task.id,
      taskTitle: task.title,
      recommendedAssignments: matches.take(task.maxAssignees).toList(),
      alternativeOptions: matches.skip(task.maxAssignees).take(3).toList(),
      assignmentStrategy: _determineAssignmentStrategy(task, matches),
      confidence: matches.isNotEmpty ? matches.first.matchScore : 0.0,
    );
  }

  /// 个人认领任务推荐
  /// 为个人用户推荐适合的可认领任务
  static List<TaskClaimRecommendation> recommendTasksForUser(
    String userId,
    User user,
    List<Task> availableTasks,
    CollaborationPool pool,
  ) {
    List<TaskClaimRecommendation> recommendations = [];

    List<String> userSkillNames =
        user.profile.skills.map((s) => s.name).toList();
    int maxSkillLevel = user.profile.skills.isNotEmpty
        ? user.profile.skills
            .map((s) => s.level)
            .reduce((a, b) => a > b ? a : b)
        : 1;

    for (Task task in availableTasks) {
      // 检查是否可以认领
      if (!task.canBeClaimedBy(userId, userSkillNames, maxSkillLevel)) {
        continue;
      }

      double matchScore = task.calculateMatchScore(
        userSkillNames,
        user.profile.interests,
        user.profile.preferredTaskTypes,
      );

      // 计算任务价值（奖励和成长潜力）
      // double taskValue = _calculateTaskValue(task, user);

      recommendations.add(TaskClaimRecommendation(
        taskId: task.id,
        taskTitle: task.title,
        taskDescription: task.description ?? '',
        matchScore: matchScore,
        skillGrowthPotential: _calculateSkillGrowthPotential(task, user),
        expectedReward: task.baseReward *
            task.priority.multiplier *
            task.difficulty.scoreMultiplier,
        difficultyLevel: task.difficulty.displayName,
        timeCommitment: task.estimatedMinutes,
        collaborationType: task.isTeamTask ? '团队协作' : '独立完成',
        claimReason: _generateClaimReason(task, user, matchScore),
        riskFactors: _identifyRiskFactors(task, user),
      ));
    }

    // 按综合评分排序（匹配度 + 任务价值）
    recommendations.sort((a, b) {
      double scoreA = (a.matchScore * 0.6 + a.skillGrowthPotential * 0.4);
      double scoreB = (b.matchScore * 0.6 + b.skillGrowthPotential * 0.4);
      return scoreB.compareTo(scoreA);
    });

    return recommendations.take(10).toList(); // 返回前10个推荐
  }

  /// 创建关键节点
  /// 队长可以为任务设置重要的检查点和里程碑
  static List<TaskMilestone> createTaskMilestones(
    Task task,
    String createdBy, // 队长ID
  ) {
    List<TaskMilestone> milestones = [];

    // 根据任务难度和时长创建默认里程碑
    DateTime startTime = DateTime.now();
    DateTime endTime = task.expectedAt ??
        startTime.add(Duration(minutes: task.estimatedMinutes));

    switch (task.difficulty) {
      case TaskDifficulty.easy:
        // 简单任务：开始 -> 完成
        milestones.addAll([
          TaskMilestone(
            id: '${task.id}_start',
            taskId: task.id,
            title: '任务开始',
            description: '开始执行任务',
            expectedTime: startTime,
            type: MilestoneType.start,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_complete',
            taskId: task.id,
            title: '任务完成',
            description: '提交最终成果',
            expectedTime: endTime,
            type: MilestoneType.completion,
            isRequired: true,
            createdBy: createdBy,
          ),
        ]);
        break;

      case TaskDifficulty.medium:
        // 中等任务：开始 -> 中期检查 -> 完成
        Duration halfDuration = Duration(minutes: task.estimatedMinutes ~/ 2);
        milestones.addAll([
          TaskMilestone(
            id: '${task.id}_start',
            taskId: task.id,
            title: '任务开始',
            description: '开始执行任务，确认需求理解',
            expectedTime: startTime,
            type: MilestoneType.start,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_midpoint',
            taskId: task.id,
            title: '中期检查',
            description: '检查进度，汇报问题和风险',
            expectedTime: startTime.add(halfDuration),
            type: MilestoneType.checkpoint,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_complete',
            taskId: task.id,
            title: '任务完成',
            description: '提交最终成果并总结',
            expectedTime: endTime,
            type: MilestoneType.completion,
            isRequired: true,
            createdBy: createdBy,
          ),
        ]);
        break;

      case TaskDifficulty.hard:
      case TaskDifficulty.expert:
        // 困难/专家级任务：开始 -> 需求确认 -> 方案设计 -> 中期检查 -> 完成验证 -> 最终完成
        Duration quarterDuration =
            Duration(minutes: task.estimatedMinutes ~/ 4);
        milestones.addAll([
          TaskMilestone(
            id: '${task.id}_start',
            taskId: task.id,
            title: '任务开始',
            description: '接收任务，进行初步分析',
            expectedTime: startTime,
            type: MilestoneType.start,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_requirement',
            taskId: task.id,
            title: '需求确认',
            description: '确认具体需求和交付标准',
            expectedTime: startTime.add(quarterDuration),
            type: MilestoneType.checkpoint,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_design',
            taskId: task.id,
            title: '方案设计',
            description: '制定详细的执行方案',
            expectedTime: startTime.add(quarterDuration * 2),
            type: MilestoneType.checkpoint,
            isRequired: false,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_midpoint',
            taskId: task.id,
            title: '中期检查',
            description: '进度汇报和问题讨论',
            expectedTime: startTime.add(quarterDuration * 3),
            type: MilestoneType.checkpoint,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_verification',
            taskId: task.id,
            title: '完成验证',
            description: '验证成果质量和完整性',
            expectedTime: endTime
                .subtract(Duration(minutes: task.estimatedMinutes ~/ 10)),
            type: MilestoneType.verification,
            isRequired: true,
            createdBy: createdBy,
          ),
          TaskMilestone(
            id: '${task.id}_complete',
            taskId: task.id,
            title: '最终完成',
            description: '正式提交并进行总结反思',
            expectedTime: endTime,
            type: MilestoneType.completion,
            isRequired: true,
            createdBy: createdBy,
          ),
        ]);
        break;
    }

    return milestones;
  }

  /// 批量任务分配
  /// 队长可以同时为多个任务分配合适的成员
  static Map<String, List<String>> batchAssignTasks(
    List<Task> tasks,
    List<User> availableMembers,
    CollaborationPool pool,
  ) {
    Map<String, List<String>> assignments = {};
    Map<String, int> memberWorkload = {}; // 跟踪成员工作量

    // 初始化成员工作量
    for (User member in availableMembers) {
      memberWorkload[member.id] = 0;
    }

    // 按任务优先级和难度排序
    List<Task> sortedTasks = List.from(tasks);
    sortedTasks.sort((a, b) {
      int priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return b.difficulty.index.compareTo(a.difficulty.index);
    });

    for (Task task in sortedTasks) {
      TaskAssignmentRecommendation recommendation = recommendTaskAssignment(
        task,
        availableMembers
            .where((member) =>
                memberWorkload[member.id]! <
                member.profile.availability.maxHoursPerWeek * 60 ~/ 7)
            .toList(),
        pool,
      );

      List<String> assignedMembers = [];
      for (UserTaskMatch match in recommendation.recommendedAssignments) {
        if (memberWorkload[match.userId]! + task.estimatedMinutes <=
            availableMembers
                    .firstWhere((m) => m.id == match.userId)
                    .profile
                    .availability
                    .maxHoursPerWeek *
                60 ~/
                7) {
          assignedMembers.add(match.userId);
          memberWorkload[match.userId] =
              memberWorkload[match.userId]! + task.estimatedMinutes;
        }
      }

      if (assignedMembers.isNotEmpty) {
        assignments[task.id] = assignedMembers;
      }
    }

    return assignments;
  }

  // ==================== 私有辅助方法 ====================

  static double _calculateUserTaskMatchScore(
      User user, Task task, CollaborationPool pool) {
    double skillScore = task.calculateMatchScore(
      user.profile.skills.map((s) => s.name).toList(),
      user.profile.interests,
      user.profile.preferredTaskTypes,
    );

    double availabilityScore = _calculateAvailabilityScore(user, task);
    double historyScore = _getCollaborationHistory(user.id, pool);
    double workStyleScore = _calculateWorkStyleCompatibility(user, task);

    // 加权计算综合分数
    return (skillScore * 0.4 +
        availabilityScore * 0.2 +
        historyScore * 0.2 +
        workStyleScore * 0.2);
  }

  static double _calculateAvailabilityScore(User user, Task task) {
    // 基于用户的时间可用性计算分数
    int userMaxHours = user.profile.availability.maxHoursPerWeek;
    int taskHours = (task.estimatedMinutes / 60).ceil();

    if (taskHours > userMaxHours) return 0.0;

    return 1.0 - (taskHours / userMaxHours);
  }

  static double _getCollaborationHistory(
      String userId, CollaborationPool pool) {
    // 计算用户在该协作池中的历史表现
    if (!pool.memberIds.contains(userId)) return 0.5; // 新成员默认分数

    double tacitScore =
        pool.getTacitScoreBetween(userId, pool.memberIds.first) / 100.0;
    // 这里可以加入更多历史数据分析

    return tacitScore;
  }

  static double _calculateWorkStyleCompatibility(User user, Task task) {
    // 计算用户工作风格与任务要求的兼容性
    double score = 0.5; // 基础分数

    // 团队任务偏好匹配
    if (task.isTeamTask &&
        user.profile.workStyle.preferredCollaborationMode == '团队') {
      score += 0.3;
    } else if (!task.isTeamTask &&
        user.profile.workStyle.preferredCollaborationMode == '独立') {
      score += 0.3;
    }

    // 工作节奏匹配
    if (task.priority == TaskPriority.urgent &&
        user.profile.workStyle.workPace == '快速') {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  static String _generateRecommendationReason(
      User user, Task task, double matchScore) {
    List<String> reasons = [];

    if (matchScore >= 0.8) {
      reasons.add('技能高度匹配');
    } else if (matchScore >= 0.6) {
      reasons.add('技能基本匹配');
    }

    if (user.profile.interests
        .any((interest) => task.tags.contains(interest))) {
      reasons.add('符合兴趣方向');
    }

    if (user.stats.onTimeRate > 0.8) {
      reasons.add('按时完成率高');
    }

    return reasons.isNotEmpty ? reasons.join('，') : '基本符合任务要求';
  }

  // 暂时注释掉未使用的方法
  /*
  static double _calculateTaskValue(Task task, User user) {
    // 计算任务对用户的价值（奖励 + 成长潜力）
    double rewardValue = task.baseReward * task.priority.multiplier * task.difficulty.scoreMultiplier;
    double growthValue = _calculateSkillGrowthPotential(task, user);
    
    return (rewardValue / 100.0) * 0.6 + growthValue * 0.4; // 标准化到0-1
  }
  */

  static double _calculateSkillGrowthPotential(Task task, User user) {
    // 计算任务对用户技能成长的潜力
    if (task.requiredSkills.isEmpty) return 0.3; // 无特定技能要求的默认成长潜力

    double growthPotential = 0.0;

    for (String requiredSkill in task.requiredSkills) {
      UserSkill? userSkill = user.profile.skills.cast<UserSkill?>().firstWhere(
            (skill) => skill?.name.toLowerCase() == requiredSkill.toLowerCase(),
            orElse: () => null,
          );

      if (userSkill == null) {
        // 全新技能，高成长潜力
        growthPotential += 0.8;
      } else if (userSkill.level < 4) {
        // 现有技能可以提升
        growthPotential += (5 - userSkill.level) / 5.0 * 0.6;
      }
    }

    return (growthPotential / task.requiredSkills.length).clamp(0.0, 1.0);
  }

  static String _generateClaimReason(Task task, User user, double matchScore) {
    if (matchScore >= 0.8) {
      return '高度匹配你的专业技能，推荐优先认领';
    } else if (matchScore >= 0.6) {
      return '符合你的能力范围，可以尝试挑战';
    } else if (matchScore >= 0.4) {
      return '可作为技能提升的练习机会';
    } else {
      return '挑战难度较大，建议谨慎考虑';
    }
  }

  static List<String> _identifyRiskFactors(Task task, User user) {
    List<String> risks = [];

    // 技能差距风险
    if (task.difficulty.requiredSkillLevel >
        user.profile.skills
            .fold(0, (max, skill) => skill.level > max ? skill.level : max)) {
      risks.add('技能要求超出当前水平');
    }

    // 时间压力风险
    if (task.priority == TaskPriority.urgent) {
      risks.add('时间要求紧急');
    }

    // 工作量风险
    if (task.estimatedMinutes >
        user.profile.availability.maxHoursPerWeek * 60 * 0.3) {
      risks.add('预计工作量较大');
    }

    // 协作风险
    if (task.isTeamTask &&
        user.profile.workStyle.preferredCollaborationMode == '独立') {
      risks.add('需要团队协作');
    }

    return risks;
  }

  static String _determineAssignmentStrategy(
      Task task, List<UserTaskMatch> matches) {
    if (task.isTeamTask) {
      return '团队协作分配';
    } else if (task.difficulty == TaskDifficulty.expert) {
      return '专家单独执行';
    } else {
      return matches.isNotEmpty && matches.first.matchScore >= 0.8
          ? '最佳匹配分配'
          : '平衡分配';
    }
  }
}

// ==================== 数据模型 ====================

// 任务分配推荐结果
class TaskAssignmentRecommendation {
  final String taskId;
  final String taskTitle;
  final List<UserTaskMatch> recommendedAssignments;
  final List<UserTaskMatch> alternativeOptions;
  final String assignmentStrategy;
  final double confidence;

  const TaskAssignmentRecommendation({
    required this.taskId,
    required this.taskTitle,
    required this.recommendedAssignments,
    required this.alternativeOptions,
    required this.assignmentStrategy,
    required this.confidence,
  });
}

// 用户任务匹配信息
class UserTaskMatch {
  final String userId;
  final String userName;
  final double matchScore;
  final double skillMatch;
  final double availabilityScore;
  final double collaborationHistory;
  final double workStyleCompatibility;
  final String recommendationReason;

  const UserTaskMatch({
    required this.userId,
    required this.userName,
    required this.matchScore,
    required this.skillMatch,
    required this.availabilityScore,
    required this.collaborationHistory,
    required this.workStyleCompatibility,
    required this.recommendationReason,
  });
}

// 个人任务认领推荐
class TaskClaimRecommendation {
  final String taskId;
  final String taskTitle;
  final String taskDescription;
  final double matchScore;
  final double skillGrowthPotential;
  final double expectedReward;
  final String difficultyLevel;
  final int timeCommitment;
  final String collaborationType;
  final String claimReason;
  final List<String> riskFactors;

  const TaskClaimRecommendation({
    required this.taskId,
    required this.taskTitle,
    required this.taskDescription,
    required this.matchScore,
    required this.skillGrowthPotential,
    required this.expectedReward,
    required this.difficultyLevel,
    required this.timeCommitment,
    required this.collaborationType,
    required this.claimReason,
    required this.riskFactors,
  });
}

// 任务里程碑
class TaskMilestone {
  final String id;
  final String taskId;
  final String title;
  final String description;
  final DateTime expectedTime;
  final DateTime? actualTime;
  final MilestoneType type;
  final bool isRequired;
  final bool isCompleted;
  final String createdBy;
  final String? completedBy;
  final String? notes;

  const TaskMilestone({
    required this.id,
    required this.taskId,
    required this.title,
    required this.description,
    required this.expectedTime,
    this.actualTime,
    required this.type,
    required this.isRequired,
    this.isCompleted = false,
    required this.createdBy,
    this.completedBy,
    this.notes,
  });

  bool get isOverdue {
    if (isCompleted) return false;
    return DateTime.now().isAfter(expectedTime);
  }

  factory TaskMilestone.fromJson(Map<String, dynamic> json) {
    return TaskMilestone(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      expectedTime: DateTime.parse(
          json['expectedTime'] ?? DateTime.now().toIso8601String()),
      actualTime: json['actualTime'] != null
          ? DateTime.parse(json['actualTime'])
          : null,
      type: MilestoneType.values[json['type'] ?? 0],
      isRequired: json['isRequired'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      createdBy: json['createdBy'] ?? '',
      completedBy: json['completedBy'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'description': description,
      'expectedTime': expectedTime.toIso8601String(),
      'actualTime': actualTime?.toIso8601String(),
      'type': type.index,
      'isRequired': isRequired,
      'isCompleted': isCompleted,
      'createdBy': createdBy,
      'completedBy': completedBy,
      'notes': notes,
    };
  }
}

// 里程碑类型
enum MilestoneType {
  start, // 开始
  checkpoint, // 检查点
  verification, // 验证
  completion, // 完成
}

extension MilestoneTypeExtension on MilestoneType {
  String get displayName {
    switch (this) {
      case MilestoneType.start:
        return '开始';
      case MilestoneType.checkpoint:
        return '检查点';
      case MilestoneType.verification:
        return '验证';
      case MilestoneType.completion:
        return '完成';
    }
  }
}
