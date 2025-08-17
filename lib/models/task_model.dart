import 'subtask_model.dart';
import 'task_template_model.dart';

// 统一的任务模型 - 包含项目和任务，支持模板创建
class Task {
  final String id;
  final String poolId;
  final String? projectId; // 添加项目ID字段
  final String title;
  final String? description;
  final int estimatedMinutes;
  final DateTime? expectedAt; // 预期完成时间
  final DateTime? dueDate; // 截止日期
  final TaskStatus status;
  final String? assigneeId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BlockReason? blockReason;
  final String? blockNote;
  final DateTime createdAt;
  final TaskStatistics statistics;
  final List<KeyNode> keyNodes;
  final List<SubTask> subTasks; // 子任务列表
  final TaskPriority priority; // 任务优先级
  final double baseReward; // 基础奖励分数
  final List<String> assignedUsers; // 多用户分配
  final List<String> tags; // 任务标签
  final List<String> requiredSkills; // 所需技能
  final String? createdBy; // 任务创建者（队长）
  final TaskDifficulty difficulty; // 任务难度
  final List<String> milestones; // 里程碑节点
  final bool isTeamTask; // 是否为团队任务
  final int maxAssignees; // 最大分配人数

  // 新增字段 - 统一任务概念
  final TaskLevel level; // 任务层级（项目级/任务级/任务点级）
  final String? parentTaskId; // 父任务ID（用于子任务）
  final List<String> childTaskIds; // 子任务ID列表
  final TaskTemplate? fromTemplate; // 来源模板
  final TaskCreationMethod creationMethod; // 创建方式
  final Map<String, dynamic> templateParams; // 模板参数

  // 工作流相关字段
  final List<String> prerequisiteTasks; // 前置任务ID列表
  final List<String> dependentTasks; // 依赖此任务的后置任务ID列表
  final WorkflowStatus workflowStatus; // 工作流状态
  final List<TaskSubmission> submissions; // 任务提交记录
  final TaskReviewStatus reviewStatus; // 审核状态
  final String? reviewerId; // 审核人ID
  final String? reviewComment; // 审核意见
  final DateTime? reviewedAt; // 审核时间
  final List<TaskPoint> taskPoints; // 任务点列表（仅对task级别有效）

  const Task({
    required this.id,
    required this.poolId,
    this.projectId, // 添加到构造函数
    required this.title,
    this.description,
    this.estimatedMinutes = 30,
    this.expectedAt,
    this.dueDate, // 添加到构造函数
    this.status = TaskStatus.pending,
    this.assigneeId,
    this.startedAt,
    this.completedAt,
    this.blockReason,
    this.blockNote,
    required this.createdAt,
    required this.statistics,
    this.keyNodes = const [],
    this.subTasks = const [],
    this.priority = TaskPriority.medium,
    this.baseReward = 10.0,
    this.assignedUsers = const [],
    this.tags = const [],
    this.requiredSkills = const [],
    this.createdBy,
    this.difficulty = TaskDifficulty.medium,
    this.milestones = const [],
    this.isTeamTask = false,
    this.maxAssignees = 1,
    // 新增字段初始化
    this.level = TaskLevel.task,
    this.parentTaskId,
    this.childTaskIds = const [],
    this.fromTemplate,
    this.creationMethod = TaskCreationMethod.custom,
    this.templateParams = const {},
    // 工作流相关字段默认值
    this.prerequisiteTasks = const [],
    this.dependentTasks = const [],
    this.workflowStatus = WorkflowStatus.ready,
    this.submissions = const [],
    this.reviewStatus = TaskReviewStatus.pending,
    this.reviewerId,
    this.reviewComment,
    this.reviewedAt,
    this.taskPoints = const [],
  });

  // 任务进度（基于子任务完成情况）
  double get progress {
    if (subTasks.isEmpty) {
      switch (status) {
        case TaskStatus.pending:
          return 0.0;
        case TaskStatus.inProgress:
          return 0.5;
        case TaskStatus.completed:
          return 1.0;
        case TaskStatus.blocked:
          return statistics.actualMinutes /
              estimatedMinutes.clamp(1, double.infinity);
      }
    }

    double totalWeight = subTasks.fold(0.0, (sum, task) => sum + task.weight);
    double completedWeight = subTasks
        .where((task) => task.status == SubTaskStatus.completed)
        .fold(0.0, (sum, task) => sum + task.weight);

    return totalWeight > 0 ? completedWeight / totalWeight : 0.0;
  }

  // 是否延期
  bool get isOverdue {
    if (expectedAt == null) return false;
    if (completedAt != null) {
      return completedAt!.isAfter(expectedAt!);
    }
    return DateTime.now().isAfter(expectedAt!) &&
        status != TaskStatus.completed;
  }

  // 是否提前完成
  bool get isEarlyCompletion {
    return expectedAt != null &&
        completedAt != null &&
        completedAt!.isBefore(expectedAt!);
  }

  // 完成时间偏差（分钟）
  double get timeDeviation {
    if (expectedAt == null || completedAt == null) return 0.0;
    return completedAt!.difference(expectedAt!).inMinutes.toDouble();
  }

  // 检查用户是否有资格认领此任务
  bool canBeClaimedBy(
      String userId, List<String> userSkills, int userSkillLevel) {
    // 检查是否已达到最大分配人数
    if (assignedUsers.length >= maxAssignees) return false;

    // 检查是否已经分配给该用户
    if (assignedUsers.contains(userId)) return false;

    // 检查任务状态
    if (status != TaskStatus.pending) return false;

    // 检查技能要求
    if (requiredSkills.isNotEmpty) {
      bool hasRequiredSkills = requiredSkills
          .any((skill) => userSkills.contains(skill.toLowerCase()));
      if (!hasRequiredSkills) return false;
    }

    // 检查技能等级要求
    if (userSkillLevel < difficulty.requiredSkillLevel) return false;

    return true;
  }

  // 计算用户与任务的匹配度
  double calculateMatchScore(List<String> userSkills,
      List<String> userInterests, List<String> userPreferredTypes) {
    double score = 0.0;

    // 技能匹配（40%权重）
    if (requiredSkills.isNotEmpty) {
      int skillMatches = requiredSkills
          .where((skill) => userSkills.any((userSkill) =>
              userSkill.toLowerCase().contains(skill.toLowerCase())))
          .length;
      score += (skillMatches / requiredSkills.length) * 0.4;
    }

    // 兴趣匹配（30%权重）
    if (tags.isNotEmpty && userInterests.isNotEmpty) {
      int interestMatches = tags
          .where((tag) => userInterests.any(
              (interest) => interest.toLowerCase().contains(tag.toLowerCase())))
          .length;
      score += (interestMatches / tags.length) * 0.3;
    }

    // 任务类型偏好匹配（30%权重）
    if (userPreferredTypes.isNotEmpty) {
      bool typeMatch = userPreferredTypes.any((type) =>
          tags.contains(type) ||
          type.toLowerCase() == difficulty.name.toLowerCase());
      score += typeMatch ? 0.3 : 0.0;
    }

    return score.clamp(0.0, 1.0);
  }

  // 任务奖励计算（基于完成质量、时间和团队协作）
  TaskReward calculateReward() {
    if (status != TaskStatus.completed) {
      return const TaskReward(
        baseScore: 0.0,
        timeBonus: 0.0,
        timePenalty: 0.0,
        collaborationBonus: 0.0,
        totalScore: 0.0,
      );
    }

    double baseScore =
        baseReward * priority.multiplier * difficulty.scoreMultiplier;
    double timeBonus = 0.0;
    double timePenalty = 0.0;
    double collaborationBonus = 0.0;

    // 时间奖励/惩罚
    if (isEarlyCompletion) {
      // 提前完成奖励：最多50%
      double earlyMinutes = -timeDeviation;
      timeBonus = baseScore * (earlyMinutes / (estimatedMinutes * 60)) * 0.5;
      timeBonus = timeBonus.clamp(0.0, baseScore * 0.5);
    } else if (isOverdue) {
      // 延期惩罚：最多70%
      double lateMinutes = timeDeviation;
      timePenalty = baseScore * (lateMinutes / (estimatedMinutes * 60)) * 0.3;
      timePenalty = timePenalty.clamp(0.0, baseScore * 0.7);
    }

    // 协作奖励（基于子任务分配和完成情况）
    if (assignedUsers.length > 1 || subTasks.length > 1) {
      double avgSubTaskScore = subTasks.isEmpty
          ? 0.0
          : subTasks.fold(0.0, (sum, task) => sum + task.contributionValue) /
              subTasks.length;
      collaborationBonus = avgSubTaskScore * 0.2; // 协作奖励20%
    }

    double totalScore =
        baseScore + timeBonus - timePenalty + collaborationBonus;

    return TaskReward(
      baseScore: baseScore,
      timeBonus: timeBonus,
      timePenalty: timePenalty,
      collaborationBonus: collaborationBonus,
      totalScore: totalScore,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      poolId: json['poolId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      estimatedMinutes: json['estimatedMinutes'] ?? 30,
      expectedAt: json['expectedAt'] != null
          ? DateTime.parse(json['expectedAt'])
          : null,
      status: TaskStatus.values[json['status'] ?? 0],
      assigneeId: json['assigneeId'],
      startedAt:
          json['startedAt'] != null ? DateTime.parse(json['startedAt']) : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      blockReason: json['blockReason'] != null
          ? BlockReason.values[json['blockReason']]
          : null,
      blockNote: json['blockNote'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      statistics: TaskStatistics.fromJson(json['statistics'] ?? {}),
      keyNodes: (json['keyNodes'] as List? ?? [])
          .map((node) => KeyNode.fromJson(node))
          .toList(),
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map((e) => SubTask.fromJson(e))
              .toList() ??
          [],
      priority: TaskPriority.values[json['priority'] ?? 1],
      baseReward: (json['baseReward'] ?? 10.0).toDouble(),
      assignedUsers: List<String>.from(json['assignedUsers'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      createdBy: json['createdBy'],
      difficulty: TaskDifficulty.values[json['difficulty'] ?? 1],
      milestones: List<String>.from(json['milestones'] ?? []),
      isTeamTask: json['isTeamTask'] ?? false,
      maxAssignees: json['maxAssignees'] ?? 1,
      // 新增字段的反序列化
      level: TaskLevel.values[json['level'] ?? 1],
      parentTaskId: json['parentTaskId'],
      childTaskIds: List<String>.from(json['childTaskIds'] ?? []),
      fromTemplate: json['fromTemplate'] != null
          ? TaskTemplate.fromJson(json['fromTemplate'])
          : null,
      creationMethod: TaskCreationMethod.values[json['creationMethod'] ?? 1],
      templateParams: Map<String, dynamic>.from(json['templateParams'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poolId': poolId,
      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'expectedAt': expectedAt?.toIso8601String(),
      'status': status.index,
      'assigneeId': assigneeId,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'blockReason': blockReason?.index,
      'blockNote': blockNote,
      'createdAt': createdAt.toIso8601String(),
      'statistics': statistics.toJson(),
      'keyNodes': keyNodes.map((node) => node.toJson()).toList(),
      'subTasks': subTasks.map((e) => e.toJson()).toList(),
      'priority': priority.index,
      'baseReward': baseReward,
      'assignedUsers': assignedUsers,
      'tags': tags,
      'requiredSkills': requiredSkills,
      'createdBy': createdBy,
      'difficulty': difficulty.index,
      'milestones': milestones,
      'isTeamTask': isTeamTask,
      'maxAssignees': maxAssignees,
      // 新增字段的序列化
      'level': level.index,
      'parentTaskId': parentTaskId,
      'childTaskIds': childTaskIds,
      'fromTemplate': fromTemplate?.toJson(),
      'creationMethod': creationMethod.index,
      'templateParams': templateParams,
    };
  }

  Task copyWith({
    String? id,
    String? poolId,
    String? title,
    String? description,
    int? estimatedMinutes,
    DateTime? expectedAt,
    TaskStatus? status,
    String? assigneeId,
    DateTime? startedAt,
    DateTime? completedAt,
    BlockReason? blockReason,
    String? blockNote,
    DateTime? createdAt,
    TaskStatistics? statistics,
    List<KeyNode>? keyNodes,
    List<SubTask>? subTasks,
    TaskPriority? priority,
    double? baseReward,
    List<String>? assignedUsers,
    List<String>? tags,
    List<String>? requiredSkills,
    String? createdBy,
    TaskDifficulty? difficulty,
    List<String>? milestones,
    bool? isTeamTask,
    int? maxAssignees,
  }) {
    return Task(
      id: id ?? this.id,
      poolId: poolId ?? this.poolId,
      title: title ?? this.title,
      description: description ?? this.description,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      expectedAt: expectedAt ?? this.expectedAt,
      status: status ?? this.status,
      assigneeId: assigneeId ?? this.assigneeId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      blockReason: blockReason ?? this.blockReason,
      blockNote: blockNote ?? this.blockNote,
      createdAt: createdAt ?? this.createdAt,
      statistics: statistics ?? this.statistics,
      keyNodes: keyNodes ?? this.keyNodes,
      subTasks: subTasks ?? this.subTasks,
      priority: priority ?? this.priority,
      baseReward: baseReward ?? this.baseReward,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      tags: tags ?? this.tags,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      createdBy: createdBy ?? this.createdBy,
      difficulty: difficulty ?? this.difficulty,
      milestones: milestones ?? this.milestones,
      isTeamTask: isTeamTask ?? this.isTeamTask,
      maxAssignees: maxAssignees ?? this.maxAssignees,
    );
  }
}

enum TaskStatus { pending, inProgress, completed, blocked }

// TaskStatus 扩展
extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.pending:
        return '待处理';
      case TaskStatus.inProgress:
        return '进行中';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.blocked:
        return '被阻塞';
    }
  }
}

enum BlockReason { lackOfTools, needHelp, timeConflict, other }

// 任务难度枚举
enum TaskDifficulty {
  easy, // 简单
  medium, // 中等
  hard, // 困难
  expert, // 专家级
}

// 任务难度扩展
extension TaskDifficultyExtension on TaskDifficulty {
  String get displayName {
    switch (this) {
      case TaskDifficulty.easy:
        return '简单';
      case TaskDifficulty.medium:
        return '中等';
      case TaskDifficulty.hard:
        return '困难';
      case TaskDifficulty.expert:
        return '专家级';
    }
  }

  double get scoreMultiplier {
    switch (this) {
      case TaskDifficulty.easy:
        return 0.8;
      case TaskDifficulty.medium:
        return 1.0;
      case TaskDifficulty.hard:
        return 1.4;
      case TaskDifficulty.expert:
        return 2.0;
    }
  }

  int get requiredSkillLevel {
    switch (this) {
      case TaskDifficulty.easy:
        return 1;
      case TaskDifficulty.medium:
        return 2;
      case TaskDifficulty.hard:
        return 4;
      case TaskDifficulty.expert:
        return 5;
    }
  }
}

// 任务优先级枚举
enum TaskPriority {
  low, // 低优先级
  medium, // 中等优先级
  high, // 高优先级
  urgent, // 紧急
}

// 任务优先级扩展
extension TaskPriorityExtension on TaskPriority {
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return '低优先级';
      case TaskPriority.medium:
        return '中等优先级';
      case TaskPriority.high:
        return '高优先级';
      case TaskPriority.urgent:
        return '紧急';
    }
  }

  double get multiplier {
    switch (this) {
      case TaskPriority.low:
        return 0.8;
      case TaskPriority.medium:
        return 1.0;
      case TaskPriority.high:
        return 1.3;
      case TaskPriority.urgent:
        return 1.6;
    }
  }
}

class TaskStatistics {
  final int actualMinutes;
  final int tacitScoreContribution;
  final List<String> interactions;
  final double contributionScore; // 贡献分数
  final double tacitScore; // 默契度分数
  final int collaborationEvents; // 协作事件数量

  const TaskStatistics({
    this.actualMinutes = 0,
    this.tacitScoreContribution = 0,
    this.interactions = const [],
    this.contributionScore = 0.0,
    this.tacitScore = 0.0,
    this.collaborationEvents = 0,
  });

  factory TaskStatistics.fromJson(Map<String, dynamic> json) {
    return TaskStatistics(
      actualMinutes: json['actualMinutes'] ?? 0,
      tacitScoreContribution: json['tacitScoreContribution'] ?? 0,
      interactions: List<String>.from(json['interactions'] ?? []),
      contributionScore: (json['contributionScore'] ?? 0.0).toDouble(),
      tacitScore: (json['tacitScore'] ?? 0.0).toDouble(),
      collaborationEvents: json['collaborationEvents'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actualMinutes': actualMinutes,
      'tacitScoreContribution': tacitScoreContribution,
      'interactions': interactions,
      'contributionScore': contributionScore,
      'tacitScore': tacitScore,
      'collaborationEvents': collaborationEvents,
    };
  }
}

class KeyNode {
  final String id;
  final String type; // 'started', 'completed', 'blocked', 'resumed'
  final DateTime timestamp;
  final String? note;
  final Map<String, dynamic>? metadata;

  const KeyNode({
    required this.id,
    required this.type,
    required this.timestamp,
    this.note,
    this.metadata,
  });

  factory KeyNode.fromJson(Map<String, dynamic> json) {
    return KeyNode(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      note: json['note'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'metadata': metadata,
    };
  }
}

// 任务奖励模型
class TaskReward {
  final double baseScore; // 基础分数
  final double timeBonus; // 时间奖励
  final double timePenalty; // 时间惩罚
  final double collaborationBonus; // 协作奖励
  final double totalScore; // 总分数

  const TaskReward({
    required this.baseScore,
    required this.timeBonus,
    required this.timePenalty,
    required this.collaborationBonus,
    required this.totalScore,
  });

  Map<String, dynamic> toJson() {
    return {
      'baseScore': baseScore,
      'timeBonus': timeBonus,
      'timePenalty': timePenalty,
      'collaborationBonus': collaborationBonus,
      'totalScore': totalScore,
    };
  }

  factory TaskReward.fromJson(Map<String, dynamic> json) {
    return TaskReward(
      baseScore: (json['baseScore'] ?? 0.0).toDouble(),
      timeBonus: (json['timeBonus'] ?? 0.0).toDouble(),
      timePenalty: (json['timePenalty'] ?? 0.0).toDouble(),
      collaborationBonus: (json['collaborationBonus'] ?? 0.0).toDouble(),
      totalScore: (json['totalScore'] ?? 0.0).toDouble(),
    );
  }
}

// 任务层级枚举
enum TaskLevel {
  project, // 项目级
  task, // 任务级
  taskPoint, // 任务点级（最小执行单元）
}

// 任务创建方式
enum TaskCreationMethod {
  fromTemplate, // 从模板创建
  custom, // 自定义创建
  imported, // 导入创建
  cloned, // 克隆创建
}

// 工作流状态枚举
enum WorkflowStatus {
  ready, // 准备就绪（前置任务已完成）
  waiting, // 等待中（前置任务未完成）
  inProgress, // 进行中
  reviewing, // 审核中
  completed, // 已完成
  blocked, // 被阻塞
}

// 审核状态枚举
enum TaskReviewStatus {
  pending, // 待审核
  approved, // 审核通过
  rejected, // 审核拒绝
  needsRevision, // 需要修改
}

// 任务提交记录
class TaskSubmission {
  final String id;
  final String taskId;
  final String submitterId;
  final String submitterName;
  final DateTime submittedAt;
  final String content; // 提交内容
  final List<String> attachments; // 附件URL列表
  final TaskSubmissionType type;
  final TaskSubmissionStatus status;
  final String? reviewComment; // 审核意见
  final DateTime? reviewedAt;
  final String? reviewerId;

  const TaskSubmission({
    required this.id,
    required this.taskId,
    required this.submitterId,
    required this.submitterName,
    required this.submittedAt,
    required this.content,
    this.attachments = const [],
    required this.type,
    this.status = TaskSubmissionStatus.submitted,
    this.reviewComment,
    this.reviewedAt,
    this.reviewerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'submitterId': submitterId,
      'submitterName': submitterName,
      'submittedAt': submittedAt.toIso8601String(),
      'content': content,
      'attachments': attachments,
      'type': type.name,
      'status': status.name,
      'reviewComment': reviewComment,
      'reviewedAt': reviewedAt?.toIso8601String(),
      'reviewerId': reviewerId,
    };
  }

  factory TaskSubmission.fromJson(Map<String, dynamic> json) {
    return TaskSubmission(
      id: json['id'],
      taskId: json['taskId'],
      submitterId: json['submitterId'],
      submitterName: json['submitterName'],
      submittedAt: DateTime.parse(json['submittedAt']),
      content: json['content'],
      attachments: List<String>.from(json['attachments'] ?? []),
      type: TaskSubmissionType.values.firstWhere((e) => e.name == json['type']),
      status: TaskSubmissionStatus.values
          .firstWhere((e) => e.name == json['status']),
      reviewComment: json['reviewComment'],
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      reviewerId: json['reviewerId'],
    );
  }
}

// 提交类型枚举
enum TaskSubmissionType {
  progress, // 进度提交
  completion, // 完成提交
  revision, // 修改提交
}

// 提交状态枚举
enum TaskSubmissionStatus {
  submitted, // 已提交
  approved, // 已通过
  rejected, // 已拒绝
  needsRevision, // 需要修改
}

// 任务点（最小执行单元）
class TaskPoint {
  final String id;
  final String taskId; // 所属任务ID
  final String title;
  final String? description;
  final int estimatedMinutes;
  final TaskPointStatus status;
  final String? assigneeId;
  final DateTime? completedAt;
  final DateTime createdAt;
  final int order; // 执行顺序
  final bool isRequired; // 是否必需完成
  final double weight; // 权重（用于进度计算）

  const TaskPoint({
    required this.id,
    required this.taskId,
    required this.title,
    this.description,
    required this.estimatedMinutes,
    this.status = TaskPointStatus.pending,
    this.assigneeId,
    this.completedAt,
    required this.createdAt,
    this.order = 0,
    this.isRequired = true,
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'status': status.name,
      'assigneeId': assigneeId,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'order': order,
      'isRequired': isRequired,
      'weight': weight,
    };
  }

  factory TaskPoint.fromJson(Map<String, dynamic> json) {
    return TaskPoint(
      id: json['id'],
      taskId: json['taskId'],
      title: json['title'],
      description: json['description'],
      estimatedMinutes: json['estimatedMinutes'],
      status:
          TaskPointStatus.values.firstWhere((e) => e.name == json['status']),
      assigneeId: json['assigneeId'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      order: json['order'] ?? 0,
      isRequired: json['isRequired'] ?? true,
      weight: (json['weight'] ?? 1.0).toDouble(),
    );
  }
}

// 任务点状态枚举
enum TaskPointStatus {
  pending, // 待处理
  inProgress, // 进行中
  completed, // 已完成
  skipped, // 已跳过（仅非必需项可跳过）
}
