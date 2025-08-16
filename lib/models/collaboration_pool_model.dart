import 'task_model.dart';

// 协作池模型 - 支持团队默契度和动态奖惩机制
class CollaborationPool {
  final String id;
  final String name;
  final String description;
  final List<String> memberIds; // 成员ID列表
  final bool isAnonymous;
  final PoolStatus status;
  final DateTime createdAt;
  final String createdBy; // 创建者ID
  final int tacitScore; // 基础默契度（保持兼容性）
  final PoolProgress progress;
  final List<String> keyNodes;
  final List<Task> tasks; // 任务列表
  final Map<String, double> memberTacitScores; // 成员间默契度
  final List<CollaborationEvent> events; // 协作事件记录
  final PoolSettings settings; // 协作池设置
  final PoolStatistics statistics; // 详细统计信息
  final String? leaderId; // 队长ID
  final Map<String, MemberRole> memberRoles; // 成员角色映射

  const CollaborationPool({
    required this.id,
    required this.name,
    required this.description,
    this.memberIds = const [],
    this.isAnonymous = false,
    this.status = PoolStatus.active,
    required this.createdAt,
    required this.createdBy,
    this.tacitScore = 0,
    required this.progress,
    this.keyNodes = const [],
    this.tasks = const [],
    this.memberTacitScores = const {},
    this.events = const [],
    required this.settings,
    required this.statistics,
    this.leaderId,
    this.memberRoles = const {},
  });

  // 计算整体团队默契度
  double get overallTacitScore {
    if (memberTacitScores.isEmpty) return tacitScore.toDouble();

    double totalScore = 0.0;
    int pairCount = 0;

    for (String member1 in memberIds) {
      for (String member2 in memberIds) {
        if (member1 != member2) {
          String pairKey = _createPairKey(member1, member2);
          if (memberTacitScores.containsKey(pairKey)) {
            totalScore += memberTacitScores[pairKey]!;
            pairCount++;
          }
        }
      }
    }

    return pairCount > 0 ? totalScore / pairCount : tacitScore.toDouble();
  }

  // 获取两个成员间的默契度
  double getTacitScoreBetween(String member1, String member2) {
    String pairKey = _createPairKey(member1, member2);
    return memberTacitScores[pairKey] ?? 0.0;
  }

  // 创建成员对的键
  String _createPairKey(String member1, String member2) {
    List<String> sorted = [member1, member2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // 计算任务完成效率
  double get taskCompletionEfficiency {
    if (tasks.isEmpty) return 0.0;

    List<Task> completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).toList();
    if (completedTasks.isEmpty) return 0.0;

    double totalEfficiency = 0.0;
    int validTasks = 0;

    for (Task task in completedTasks) {
      if (task.expectedAt != null && task.completedAt != null) {
        double expectedMinutes = task.estimatedMinutes.toDouble();
        double actualMinutes = task.statistics.actualMinutes.toDouble();

        if (actualMinutes > 0) {
          double efficiency = expectedMinutes / actualMinutes;
          totalEfficiency += efficiency;
          validTasks++;
        }
      }
    }

    return validTasks > 0 ? totalEfficiency / validTasks : 0.0;
  }

  // 获取按时完成率
  double get onTimeCompletionRate {
    List<Task> completedTasks = tasks
        .where((t) =>
            t.status == TaskStatus.completed &&
            t.expectedAt != null &&
            t.completedAt != null)
        .toList();

    if (completedTasks.isEmpty) return 0.0;

    int onTimeTasks = completedTasks
        .where((t) => !t.completedAt!.isAfter(t.expectedAt!))
        .length;

    return onTimeTasks / completedTasks.length;
  }

  // 团队默契度等级
  String get tacitLevel {
    double score = overallTacitScore;
    if (score >= 90) return '完美默契';
    if (score >= 80) return '高度默契';
    if (score >= 70) return '良好默契';
    if (score >= 60) return '基础默契';
    if (score >= 50) return '磨合中';
    return '需要磨合';
  }

  factory CollaborationPool.fromJson(Map<String, dynamic> json) {
    return CollaborationPool(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      status: PoolStatus.values[json['status'] ?? 0],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      createdBy: json['createdBy'] ?? '',
      tacitScore: json['tacitScore'] ?? 0,
      progress: PoolProgress.fromJson(json['progress'] ?? {}),
      keyNodes: List<String>.from(json['keyNodes'] ?? []),
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e))
              .toList() ??
          [],
      memberTacitScores: Map<String, double>.from(
          (json['memberTacitScores'] ?? {})
              .map((k, v) => MapEntry(k, v.toDouble()))),
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => CollaborationEvent.fromJson(e))
              .toList() ??
          [],
      settings: PoolSettings.fromJson(json['settings'] ?? {}),
      statistics: PoolStatistics.fromJson(json['statistics'] ?? {}),
      leaderId: json['leaderId'],
      memberRoles: Map<String, MemberRole>.from((json['memberRoles'] ?? {})
          .map((k, v) => MapEntry(k, MemberRole.values[v]))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'isAnonymous': isAnonymous,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'tacitScore': tacitScore,
      'progress': progress.toJson(),
      'keyNodes': keyNodes,
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'memberTacitScores': memberTacitScores,
      'events': events.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'statistics': statistics.toJson(),
      'leaderId': leaderId,
      'memberRoles': memberRoles.map((k, v) => MapEntry(k, v.index)),
    };
  }

  CollaborationPool copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? memberIds,
    bool? isAnonymous,
    PoolStatus? status,
    DateTime? createdAt,
    String? createdBy,
    int? tacitScore,
    PoolProgress? progress,
    List<String>? keyNodes,
    List<Task>? tasks,
    Map<String, double>? memberTacitScores,
    List<CollaborationEvent>? events,
    PoolSettings? settings,
    PoolStatistics? statistics,
    String? leaderId,
    Map<String, MemberRole>? memberRoles,
  }) {
    return CollaborationPool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      tacitScore: tacitScore ?? this.tacitScore,
      progress: progress ?? this.progress,
      keyNodes: keyNodes ?? this.keyNodes,
      tasks: tasks ?? this.tasks,
      memberTacitScores: memberTacitScores ?? this.memberTacitScores,
      events: events ?? this.events,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      leaderId: leaderId ?? this.leaderId,
      memberRoles: memberRoles ?? this.memberRoles,
    );
  }
}

enum PoolStatus { active, completed, paused, archived }

class PoolProgress {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final double averageProgress; // 平均进度
  final int blockedTasks; // 被阻塞的任务数
  final int overdueTasks; // 逾期任务数

  const PoolProgress({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.inProgressTasks = 0,
    this.averageProgress = 0.0,
    this.blockedTasks = 0,
    this.overdueTasks = 0,
  });

  double get progressPercentage {
    if (totalTasks == 0) return 0.0;
    return completedTasks / totalTasks;
  }

  factory PoolProgress.fromJson(Map<String, dynamic> json) {
    return PoolProgress(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      averageProgress: (json['averageProgress'] ?? 0.0).toDouble(),
      blockedTasks: json['blockedTasks'] ?? 0,
      overdueTasks: json['overdueTasks'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
      'averageProgress': averageProgress,
      'blockedTasks': blockedTasks,
      'overdueTasks': overdueTasks,
    };
  }
}

// 协作池设置
class PoolSettings {
  final bool allowAnonymous; // 允许匿名
  final int maxMembers; // 最大成员数
  final bool autoAssignTasks; // 自动分配任务
  final int tacitScoreThreshold; // 默契度阈值
  final bool enableTimePenalty; // 启用时间惩罚
  final double timePenaltyRate; // 时间惩罚率
  final bool enableCollaborationBonus; // 启用协作奖励
  final double collaborationBonusRate; // 协作奖励率
  final bool enableAutoAssignment; // 启用自动分配
  final bool requireApproval; // 需要队长批准
  final int maxPoolSize; // 协作池最大规模

  const PoolSettings({
    this.allowAnonymous = true,
    this.maxMembers = 10,
    this.autoAssignTasks = false,
    this.tacitScoreThreshold = 70,
    this.enableTimePenalty = true,
    this.timePenaltyRate = 0.1,
    this.enableCollaborationBonus = true,
    this.collaborationBonusRate = 0.2,
    this.enableAutoAssignment = false,
    this.requireApproval = false,
    this.maxPoolSize = 20,
  });

  factory PoolSettings.fromJson(Map<String, dynamic> json) {
    return PoolSettings(
      allowAnonymous: json['allowAnonymous'] ?? true,
      maxMembers: json['maxMembers'] ?? 10,
      autoAssignTasks: json['autoAssignTasks'] ?? false,
      tacitScoreThreshold: json['tacitScoreThreshold'] ?? 70,
      enableTimePenalty: json['enableTimePenalty'] ?? true,
      timePenaltyRate: (json['timePenaltyRate'] ?? 0.1).toDouble(),
      enableCollaborationBonus: json['enableCollaborationBonus'] ?? true,
      collaborationBonusRate:
          (json['collaborationBonusRate'] ?? 0.2).toDouble(),
      enableAutoAssignment: json['enableAutoAssignment'] ?? false,
      requireApproval: json['requireApproval'] ?? false,
      maxPoolSize: json['maxPoolSize'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowAnonymous': allowAnonymous,
      'maxMembers': maxMembers,
      'autoAssignTasks': autoAssignTasks,
      'tacitScoreThreshold': tacitScoreThreshold,
      'enableTimePenalty': enableTimePenalty,
      'timePenaltyRate': timePenaltyRate,
      'enableCollaborationBonus': enableCollaborationBonus,
      'collaborationBonusRate': collaborationBonusRate,
      'enableAutoAssignment': enableAutoAssignment,
      'requireApproval': requireApproval,
      'maxPoolSize': maxPoolSize,
    };
  }
}

// 协作池统计
class PoolStatistics {
  final double averageTaskTime; // 平均任务时间
  final double teamTacitScore; // 团队默契度
  final int collaborationEvents; // 协作事件数
  final double efficiencyScore; // 效率分数
  final List<TacitTrend> tacitTrends; // 默契度趋势
  final double onTimeRate; // 按时完成率
  final double earlyCompletionRate; // 提前完成率

  const PoolStatistics({
    this.averageTaskTime = 0.0,
    this.teamTacitScore = 0.0,
    this.collaborationEvents = 0,
    this.efficiencyScore = 0.0,
    this.tacitTrends = const [],
    this.onTimeRate = 0.0,
    this.earlyCompletionRate = 0.0,
  });

  factory PoolStatistics.fromJson(Map<String, dynamic> json) {
    return PoolStatistics(
      averageTaskTime: (json['averageTaskTime'] ?? 0.0).toDouble(),
      teamTacitScore: (json['teamTacitScore'] ?? 0.0).toDouble(),
      collaborationEvents: json['collaborationEvents'] ?? 0,
      efficiencyScore: (json['efficiencyScore'] ?? 0.0).toDouble(),
      tacitTrends: (json['tacitTrends'] as List<dynamic>?)
              ?.map((e) => TacitTrend.fromJson(e))
              .toList() ??
          [],
      onTimeRate: (json['onTimeRate'] ?? 0.0).toDouble(),
      earlyCompletionRate: (json['earlyCompletionRate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageTaskTime': averageTaskTime,
      'teamTacitScore': teamTacitScore,
      'collaborationEvents': collaborationEvents,
      'efficiencyScore': efficiencyScore,
      'tacitTrends': tacitTrends.map((e) => e.toJson()).toList(),
      'onTimeRate': onTimeRate,
      'earlyCompletionRate': earlyCompletionRate,
    };
  }
}

// 协作事件
class CollaborationEvent {
  final String id;
  final String type; // 事件类型
  final DateTime timestamp; // 时间戳
  final List<String> participants; // 参与者
  final String? description; // 描述
  final Map<String, dynamic> data; // 事件数据
  final double tacitImpact; // 对默契度的影响

  const CollaborationEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    this.participants = const [],
    this.description,
    this.data = const {},
    this.tacitImpact = 0.0,
  });

  factory CollaborationEvent.fromJson(Map<String, dynamic> json) {
    return CollaborationEvent(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      participants: List<String>.from(json['participants'] ?? []),
      description: json['description'],
      data: json['data'] ?? {},
      tacitImpact: (json['tacitImpact'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'participants': participants,
      'description': description,
      'data': data,
      'tacitImpact': tacitImpact,
    };
  }
}

// 默契度趋势
class TacitTrend {
  final DateTime date;
  final double score;
  final String? note;

  const TacitTrend({
    required this.date,
    required this.score,
    this.note,
  });

  factory TacitTrend.fromJson(Map<String, dynamic> json) {
    return TacitTrend(
      date: DateTime.parse(
        json['date'] ?? DateTime.now().toIso8601String(),
      ),
      score: (json['score'] ?? 0.0).toDouble(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'score': score,
      'note': note,
    };
  }
}

// 成员角色枚举
enum MemberRole {
  leader, // 队长
  member, // 普通成员
  observer, // 观察者
}

extension MemberRoleExtension on MemberRole {
  String get displayName {
    switch (this) {
      case MemberRole.leader:
        return '队长';
      case MemberRole.member:
        return '成员';
      case MemberRole.observer:
        return '观察者';
    }
  }

  List<String> get permissions {
    switch (this) {
      case MemberRole.leader:
        return [
          'assign_task',
          'create_task',
          'modify_task',
          'approve_member',
          'remove_member',
          'set_milestone',
          'view_analytics',
        ];
      case MemberRole.member:
        return [
          'claim_task',
          'complete_task',
          'create_subtask',
          'collaborate',
        ];
      case MemberRole.observer:
        return [
          'view_progress',
          'view_tasks',
        ];
    }
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }
}
