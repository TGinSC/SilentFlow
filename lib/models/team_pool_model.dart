import 'task_model.dart';
import 'team_template_model.dart';
import 'tacit_understanding_model.dart';

// 团队池模型 - 支持队长管理和任务模板
class TeamPool {
  final String id;
  final String name;
  final String description;
  final String leaderId; // 队长ID（必须）
  final List<String> memberIds; // 成员ID列表
  final TeamStatus status;
  final DateTime createdAt;
  final int maxMembers; // 最大成员数
  final List<Task> tasks; // 任务列表
  final TeamSettings settings; // 团队设置
  final TeamStatistics statistics; // 团队统计信息
  final List<String> inviteTokens; // 邀请码列表
  final Map<String, MemberRole> memberRoles; // 成员角色映射
  final List<TeamEvent> events; // 团队事件记录
  final String? teamAvatar; // 团队头像
  final List<String> tags; // 团队标签
  final TeamType teamType; // 团队类型
  // 新增字段
  final TeamTemplate? teamTemplate; // 团队模版
  final TeamNature? teamNature; // 团队性质
  final TeamTacitUnderstanding? teamTacitness; // 团队默契度

  const TeamPool({
    required this.id,
    required this.name,
    required this.description,
    required this.leaderId,
    this.memberIds = const [],
    this.status = TeamStatus.active,
    required this.createdAt,
    this.maxMembers = 10,
    this.tasks = const [],
    required this.settings,
    required this.statistics,
    this.inviteTokens = const [],
    this.memberRoles = const {},
    this.events = const [],
    this.teamAvatar,
    this.tags = const [],
    this.teamType = TeamType.project,
    // 新增字段初始化
    this.teamTemplate,
    this.teamNature,
    this.teamTacitness,
  });

  // 获取所有成员（包括队长）
  List<String> get allMemberIds {
    Set<String> allMembers = {leaderId};
    allMembers.addAll(memberIds);
    return allMembers.toList();
  }

  // 检查用户是否为队长
  bool isLeader(String userId) => leaderId == userId;

  // 检查用户是否为成员
  bool isMember(String userId) => allMemberIds.contains(userId);

  // 获取用户角色
  MemberRole getUserRole(String userId) {
    if (isLeader(userId)) return MemberRole.leader;
    return memberRoles[userId] ?? MemberRole.member;
  }

  // 检查是否可以加入更多成员
  bool get canAddMoreMembers => allMemberIds.length < maxMembers;

  // 获取团队进度
  TeamProgress get progress {
    if (tasks.isEmpty) {
      return const TeamProgress(
        totalTasks: 0,
        completedTasks: 0,
        inProgressTasks: 0,
        pendingTasks: 0,
        overallProgress: 0.0,
      );
    }

    int totalTasks = tasks.length;
    int completedTasks =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    int inProgressTasks =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    int pendingTasks =
        tasks.where((t) => t.status == TaskStatus.pending).length;

    double overallProgress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    return TeamProgress(
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      inProgressTasks: inProgressTasks,
      pendingTasks: pendingTasks,
      overallProgress: overallProgress,
    );
  }

  // 生成邀请码
  String generateInviteToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${id.substring(0, 4)}${timestamp.toString().substring(8)}';
  }

  factory TeamPool.fromJson(Map<String, dynamic> json) {
    return TeamPool(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      leaderId: json['leaderId'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      status: TeamStatus.values[json['status'] ?? 0],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      maxMembers: json['maxMembers'] ?? 10,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e))
              .toList() ??
          [],
      settings: TeamSettings.fromJson(json['settings'] ?? {}),
      statistics: TeamStatistics.fromJson(json['statistics'] ?? {}),
      inviteTokens: List<String>.from(json['inviteTokens'] ?? []),
      memberRoles: Map<String, MemberRole>.from((json['memberRoles'] ?? {})
          .map((k, v) => MapEntry(k, MemberRole.values[v]))),
      events: (json['events'] as List<dynamic>?)
              ?.map((e) => TeamEvent.fromJson(e))
              .toList() ??
          [],
      teamAvatar: json['teamAvatar'],
      tags: List<String>.from(json['tags'] ?? []),
      teamType: TeamType.values[json['teamType'] ?? 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'maxMembers': maxMembers,
      'tasks': tasks.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'statistics': statistics.toJson(),
      'inviteTokens': inviteTokens,
      'memberRoles': memberRoles.map((k, v) => MapEntry(k, v.index)),
      'events': events.map((e) => e.toJson()).toList(),
      'teamAvatar': teamAvatar,
      'tags': tags,
      'teamType': teamType.index,
    };
  }

  TeamPool copyWith({
    String? id,
    String? name,
    String? description,
    String? leaderId,
    List<String>? memberIds,
    TeamStatus? status,
    DateTime? createdAt,
    int? maxMembers,
    List<Task>? tasks,
    TeamSettings? settings,
    TeamStatistics? statistics,
    List<String>? inviteTokens,
    Map<String, MemberRole>? memberRoles,
    List<TeamEvent>? events,
    String? teamAvatar,
    List<String>? tags,
    TeamType? teamType,
  }) {
    return TeamPool(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      leaderId: leaderId ?? this.leaderId,
      memberIds: memberIds ?? this.memberIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      maxMembers: maxMembers ?? this.maxMembers,
      tasks: tasks ?? this.tasks,
      settings: settings ?? this.settings,
      statistics: statistics ?? this.statistics,
      inviteTokens: inviteTokens ?? this.inviteTokens,
      memberRoles: memberRoles ?? this.memberRoles,
      events: events ?? this.events,
      teamAvatar: teamAvatar ?? this.teamAvatar,
      tags: tags ?? this.tags,
      teamType: teamType ?? this.teamType,
    );
  }
}

// 团队状态枚举
enum TeamStatus { active, paused, completed, disbanded }

// 团队类型枚举
enum TeamType {
  project, // 项目团队
  study, // 学习团队
  competition, // 竞赛团队
  research, // 研究团队
  development, // 开发团队
  design, // 设计团队
  marketing, // 营销团队
  other, // 其他
}

extension TeamTypeExtension on TeamType {
  String get displayName {
    switch (this) {
      case TeamType.project:
        return '项目团队';
      case TeamType.study:
        return '学习团队';
      case TeamType.competition:
        return '竞赛团队';
      case TeamType.research:
        return '研究团队';
      case TeamType.development:
        return '开发团队';
      case TeamType.design:
        return '设计团队';
      case TeamType.marketing:
        return '营销团队';
      case TeamType.other:
        return '其他';
    }
  }

  List<String> get recommendedTags {
    switch (this) {
      case TeamType.project:
        return ['项目管理', '协作', '执行', '目标导向'];
      case TeamType.study:
        return ['学习', '知识分享', '讨论', '教学'];
      case TeamType.competition:
        return ['竞赛', '创新', '快速迭代', '团队合作'];
      case TeamType.research:
        return ['研究', '分析', '实验', '文献调研'];
      case TeamType.development:
        return ['开发', '编程', '技术', '产品'];
      case TeamType.design:
        return ['设计', '创意', '用户体验', '视觉'];
      case TeamType.marketing:
        return ['营销', '推广', '品牌', '市场分析'];
      case TeamType.other:
        return ['通用', '灵活', '多样化'];
    }
  }
}

// 团队进度
class TeamProgress {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int pendingTasks;
  final double overallProgress;

  const TeamProgress({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.pendingTasks,
    required this.overallProgress,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
      'pendingTasks': pendingTasks,
      'overallProgress': overallProgress,
    };
  }

  factory TeamProgress.fromJson(Map<String, dynamic> json) {
    return TeamProgress(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      pendingTasks: json['pendingTasks'] ?? 0,
      overallProgress: (json['overallProgress'] ?? 0.0).toDouble(),
    );
  }
}

// 团队设置
class TeamSettings {
  final bool isPublic; // 是否公开可见
  final bool requireApproval; // 加入是否需要批准
  final bool allowMemberInvite; // 允许成员邀请他人
  final bool allowMemberCreateTask; // 允许成员创建任务
  final TaskAssignmentMode taskAssignmentMode; // 任务分配模式
  final NotificationSettings notifications; // 通知设置
  final int autoArchiveDays; // 自动归档天数（0表示不自动归档）

  const TeamSettings({
    this.isPublic = false,
    this.requireApproval = true,
    this.allowMemberInvite = false,
    this.allowMemberCreateTask = true,
    this.taskAssignmentMode = TaskAssignmentMode.leaderAssign,
    required this.notifications,
    this.autoArchiveDays = 0,
  });

  factory TeamSettings.fromJson(Map<String, dynamic> json) {
    return TeamSettings(
      isPublic: json['isPublic'] ?? false,
      requireApproval: json['requireApproval'] ?? true,
      allowMemberInvite: json['allowMemberInvite'] ?? false,
      allowMemberCreateTask: json['allowMemberCreateTask'] ?? true,
      taskAssignmentMode:
          TaskAssignmentMode.values[json['taskAssignmentMode'] ?? 0],
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
      autoArchiveDays: json['autoArchiveDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
      'requireApproval': requireApproval,
      'allowMemberInvite': allowMemberInvite,
      'allowMemberCreateTask': allowMemberCreateTask,
      'taskAssignmentMode': taskAssignmentMode.index,
      'notifications': notifications.toJson(),
      'autoArchiveDays': autoArchiveDays,
    };
  }
}

// 任务分配模式
enum TaskAssignmentMode {
  leaderAssign, // 队长分配
  memberChoose, // 成员自选
  mixed, // 混合模式
}

extension TaskAssignmentModeExtension on TaskAssignmentMode {
  String get displayName {
    switch (this) {
      case TaskAssignmentMode.leaderAssign:
        return '队长分配';
      case TaskAssignmentMode.memberChoose:
        return '成员自选';
      case TaskAssignmentMode.mixed:
        return '混合模式';
    }
  }
}

// 通知设置
class NotificationSettings {
  final bool taskAssigned; // 任务分配通知
  final bool taskCompleted; // 任务完成通知
  final bool newMemberJoined; // 新成员加入通知
  final bool deadlineReminder; // 截止日期提醒
  final bool milestoneReached; // 里程碑达成通知
  final int reminderHoursBefore; // 提前多少小时提醒

  const NotificationSettings({
    this.taskAssigned = true,
    this.taskCompleted = true,
    this.newMemberJoined = true,
    this.deadlineReminder = true,
    this.milestoneReached = true,
    this.reminderHoursBefore = 24,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      taskAssigned: json['taskAssigned'] ?? true,
      taskCompleted: json['taskCompleted'] ?? true,
      newMemberJoined: json['newMemberJoined'] ?? true,
      deadlineReminder: json['deadlineReminder'] ?? true,
      milestoneReached: json['milestoneReached'] ?? true,
      reminderHoursBefore: json['reminderHoursBefore'] ?? 24,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taskAssigned': taskAssigned,
      'taskCompleted': taskCompleted,
      'newMemberJoined': newMemberJoined,
      'deadlineReminder': deadlineReminder,
      'milestoneReached': milestoneReached,
      'reminderHoursBefore': reminderHoursBefore,
    };
  }
}

// 团队统计 - 重新设计为团队属性和人际属性
class TeamStatistics {
  // 团队属性
  final double teamEfficiency; // 团队效率
  final double averageTaskTime; // 平均任务时间
  final int totalTasksCompleted; // 总完成任务数
  final double onTimeCompletionRate; // 按时完成率
  final DateTime? lastActivityAt; // 最后活跃时间
  final List<MilestoneRecord> milestones; // 里程碑记录

  // 团队协作指标
  final double teamCohesion; // 团队凝聚力
  final double workflowEfficiency; // 工作流效率
  final double communicationQuality; // 沟通质量
  final double conflictResolutionRate; // 冲突解决率
  final Map<String, double> skillCoverage; // 技能覆盖度

  // 人际协作指标
  final Map<String, double> memberContributions; // 成员贡献度
  final Map<String, PairTacitUnderstanding> pairTacitness; // 成员间默契度
  final Map<String, double> leadershipScores; // 领导力得分
  final Map<String, List<String>> collaborationNetworks; // 协作网络

  const TeamStatistics({
    // 基础团队指标
    this.teamEfficiency = 0.0,
    this.averageTaskTime = 0.0,
    this.totalTasksCompleted = 0,
    this.onTimeCompletionRate = 0.0,
    this.lastActivityAt,
    this.milestones = const [],

    // 团队协作指标
    this.teamCohesion = 0.0,
    this.workflowEfficiency = 0.0,
    this.communicationQuality = 0.0,
    this.conflictResolutionRate = 0.0,
    this.skillCoverage = const {},

    // 人际协作指标
    this.memberContributions = const {},
    this.pairTacitness = const {},
    this.leadershipScores = const {},
    this.collaborationNetworks = const {},
  });

  // 计算团队总体协作得分
  double get overallCollaborationScore {
    double teamScore = (teamCohesion +
            workflowEfficiency +
            communicationQuality +
            conflictResolutionRate) /
        4;
    double pairScore = pairTacitness.values.isNotEmpty
        ? pairTacitness.values
                .map((p) => p.tacitScore)
                .reduce((a, b) => a + b) /
            pairTacitness.length
        : 0.0;
    return (teamScore + pairScore) / 2;
  }

  // 获取最佳协作对
  List<String>? getBestCollaborationPair() {
    if (pairTacitness.isEmpty) return null;

    String bestPairKey = '';
    double bestScore = 0.0;

    pairTacitness.forEach((key, pair) {
      if (pair.tacitScore > bestScore) {
        bestScore = pair.tacitScore;
        bestPairKey = key;
      }
    });

    if (bestPairKey.isNotEmpty) {
      return bestPairKey.split('_');
    }
    return null;
  }

  factory TeamStatistics.fromJson(Map<String, dynamic> json) {
    return TeamStatistics(
      teamEfficiency: (json['teamEfficiency'] ?? 0.0).toDouble(),
      averageTaskTime: (json['averageTaskTime'] ?? 0.0).toDouble(),
      totalTasksCompleted: json['totalTasksCompleted'] ?? 0,
      onTimeCompletionRate: (json['onTimeCompletionRate'] ?? 0.0).toDouble(),
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'])
          : null,
      milestones: (json['milestones'] as List<dynamic>?)
              ?.map((e) => MilestoneRecord.fromJson(e))
              .toList() ??
          [],
      // 团队协作指标
      teamCohesion: (json['teamCohesion'] ?? 0.0).toDouble(),
      workflowEfficiency: (json['workflowEfficiency'] ?? 0.0).toDouble(),
      communicationQuality: (json['communicationQuality'] ?? 0.0).toDouble(),
      conflictResolutionRate:
          (json['conflictResolutionRate'] ?? 0.0).toDouble(),
      skillCoverage: Map<String, double>.from((json['skillCoverage'] ?? {})
          .map((k, v) => MapEntry(k, v.toDouble()))),
      // 人际协作指标
      memberContributions: Map<String, double>.from(
          (json['memberContributions'] ?? {})
              .map((k, v) => MapEntry(k, v.toDouble()))),
      pairTacitness: Map<String, PairTacitUnderstanding>.from(
          (json['pairTacitness'] ?? {})
              .map((k, v) => MapEntry(k, PairTacitUnderstanding.fromJson(v)))),
      leadershipScores: Map<String, double>.from(
          (json['leadershipScores'] ?? {})
              .map((k, v) => MapEntry(k, v.toDouble()))),
      collaborationNetworks: Map<String, List<String>>.from(
          (json['collaborationNetworks'] ?? {})
              .map((k, v) => MapEntry(k, List<String>.from(v)))),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamEfficiency': teamEfficiency,
      'averageTaskTime': averageTaskTime,
      'totalTasksCompleted': totalTasksCompleted,
      'onTimeCompletionRate': onTimeCompletionRate,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'milestones': milestones.map((e) => e.toJson()).toList(),
      // 团队协作指标
      'teamCohesion': teamCohesion,
      'workflowEfficiency': workflowEfficiency,
      'communicationQuality': communicationQuality,
      'conflictResolutionRate': conflictResolutionRate,
      'skillCoverage': skillCoverage,
      // 人际协作指标
      'memberContributions': memberContributions,
      'pairTacitness': pairTacitness.map((k, v) => MapEntry(k, v.toJson())),
      'leadershipScores': leadershipScores,
      'collaborationNetworks': collaborationNetworks,
    };
  }
}

// 团队事件
class TeamEvent {
  final String id;
  final TeamEventType type;
  final String description;
  final DateTime timestamp;
  final String? userId; // 相关用户ID
  final Map<String, dynamic> metadata; // 事件元数据

  const TeamEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.timestamp,
    this.userId,
    this.metadata = const {},
  });

  factory TeamEvent.fromJson(Map<String, dynamic> json) {
    return TeamEvent(
      id: json['id'] ?? '',
      type: TeamEventType.values[json['type'] ?? 0],
      description: json['description'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      userId: json['userId'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'metadata': metadata,
    };
  }
}

// 团队事件类型
enum TeamEventType {
  created, // 团队创建
  memberJoined, // 成员加入
  memberLeft, // 成员离开
  memberRoleChanged, // 成员角色变更
  taskCreated, // 任务创建
  taskAssigned, // 任务分配
  taskCompleted, // 任务完成
  milestoneReached, // 里程碑达成
  settingsChanged, // 设置变更
}

extension TeamEventTypeExtension on TeamEventType {
  String get displayName {
    switch (this) {
      case TeamEventType.created:
        return '团队创建';
      case TeamEventType.memberJoined:
        return '成员加入';
      case TeamEventType.memberLeft:
        return '成员离开';
      case TeamEventType.memberRoleChanged:
        return '角色变更';
      case TeamEventType.taskCreated:
        return '任务创建';
      case TeamEventType.taskAssigned:
        return '任务分配';
      case TeamEventType.taskCompleted:
        return '任务完成';
      case TeamEventType.milestoneReached:
        return '里程碑达成';
      case TeamEventType.settingsChanged:
        return '设置变更';
    }
  }
}

// 里程碑记录
class MilestoneRecord {
  final String id;
  final String title;
  final String description;
  final DateTime achievedAt;
  final List<String> participants; // 参与成员
  final double progress; // 达成时的进度

  const MilestoneRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.achievedAt,
    this.participants = const [],
    required this.progress,
  });

  factory MilestoneRecord.fromJson(Map<String, dynamic> json) {
    return MilestoneRecord(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      achievedAt: DateTime.parse(
        json['achievedAt'] ?? DateTime.now().toIso8601String(),
      ),
      participants: List<String>.from(json['participants'] ?? []),
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'achievedAt': achievedAt.toIso8601String(),
      'participants': participants,
      'progress': progress,
    };
  }
}

// 成员角色枚举（重新定义以匹配团队概念）
enum MemberRole {
  leader, // 队长
  coLeader, // 副队长
  member, // 普通成员
  observer, // 观察者
}

extension MemberRoleExtension on MemberRole {
  String get displayName {
    switch (this) {
      case MemberRole.leader:
        return '队长';
      case MemberRole.coLeader:
        return '副队长';
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
          'modify_settings',
          'dissolve_team',
        ];
      case MemberRole.coLeader:
        return [
          'assign_task',
          'create_task',
          'modify_task',
          'approve_member',
          'set_milestone',
          'view_analytics',
        ];
      case MemberRole.member:
        return [
          'claim_task',
          'complete_task',
          'create_subtask',
          'collaborate',
          'invite_member',
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
