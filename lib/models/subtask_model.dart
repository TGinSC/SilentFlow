// 子任务模型 - 用于详细的贡献度计算
class SubTask {
  final String id;
  final String taskId; // 父任务ID
  final String title; // 子任务标题
  final String description; // 子任务描述
  final String? assignedUserId; // 分配给的用户ID
  final DateTime createdAt; // 创建时间
  final DateTime expectedAt; // 预期完成时间
  final DateTime? completedAt; // 实际完成时间
  final SubTaskStatus status; // 子任务状态
  final int priority; // 优先级 (1-5)
  final double weight; // 权重，用于计算贡献度
  final List<String> dependencies; // 依赖的其他子任务ID
  final Map<String, dynamic> metadata; // 额外元数据

  const SubTask({
    required this.id,
    required this.taskId,
    required this.title,
    this.description = '',
    this.assignedUserId,
    required this.createdAt,
    required this.expectedAt,
    this.completedAt,
    this.status = SubTaskStatus.pending,
    this.priority = 3,
    this.weight = 1.0,
    this.dependencies = const [],
    this.metadata = const {},
  });

  // 是否延期
  bool get isOverdue {
    if (completedAt != null) {
      return completedAt!.isAfter(expectedAt);
    }
    return DateTime.now().isAfter(expectedAt) &&
        status != SubTaskStatus.completed;
  }

  // 是否提前完成
  bool get isEarlyCompletion {
    return completedAt != null && completedAt!.isBefore(expectedAt);
  }

  // 完成时间偏差（小时）
  double get timeDeviation {
    if (completedAt == null) return 0.0;
    return completedAt!.difference(expectedAt).inHours.toDouble();
  }

  // 贡献度计算（基于完成质量和时间）
  double get contributionValue {
    if (status != SubTaskStatus.completed) return 0.0;

    double baseValue = weight * priority;

    // 时间奖励/惩罚
    if (isEarlyCompletion) {
      // 提前完成奖励：最多20%
      double earlyBonus = (-timeDeviation / 24) * 0.2;
      baseValue *= (1 + earlyBonus.clamp(0.0, 0.2));
    } else if (isOverdue) {
      // 延期惩罚：最多50%
      double latePenalty = (timeDeviation / 24) * 0.1;
      baseValue *= (1 - latePenalty.clamp(0.0, 0.5));
    }

    return baseValue;
  }

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      assignedUserId: json['assignedUserId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      expectedAt: DateTime.parse(
        json['expectedAt'] ??
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      ),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      status: SubTaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubTaskStatus.pending,
      ),
      priority: json['priority'] ?? 3,
      weight: (json['weight'] ?? 1.0).toDouble(),
      dependencies: List<String>.from(json['dependencies'] ?? []),
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'title': title,
      'description': description,
      'assignedUserId': assignedUserId,
      'createdAt': createdAt.toIso8601String(),
      'expectedAt': expectedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'status': status.toString().split('.').last,
      'priority': priority,
      'weight': weight,
      'dependencies': dependencies,
      'metadata': metadata,
    };
  }

  SubTask copyWith({
    String? id,
    String? taskId,
    String? title,
    String? description,
    String? assignedUserId,
    DateTime? createdAt,
    DateTime? expectedAt,
    DateTime? completedAt,
    SubTaskStatus? status,
    int? priority,
    double? weight,
    List<String>? dependencies,
    Map<String, dynamic>? metadata,
  }) {
    return SubTask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      createdAt: createdAt ?? this.createdAt,
      expectedAt: expectedAt ?? this.expectedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      weight: weight ?? this.weight,
      dependencies: dependencies ?? this.dependencies,
      metadata: metadata ?? this.metadata,
    );
  }
}

// 子任务状态枚举
enum SubTaskStatus {
  pending, // 待处理
  inProgress, // 进行中
  blocked, // 被阻塞
  completed, // 已完成
  cancelled, // 已取消
}

// 子任务状态扩展
extension SubTaskStatusExtension on SubTaskStatus {
  String get displayName {
    switch (this) {
      case SubTaskStatus.pending:
        return '待处理';
      case SubTaskStatus.inProgress:
        return '进行中';
      case SubTaskStatus.blocked:
        return '被阻塞';
      case SubTaskStatus.completed:
        return '已完成';
      case SubTaskStatus.cancelled:
        return '已取消';
    }
  }

  bool get isCompleted => this == SubTaskStatus.completed;
  bool get canBeWorkedOn =>
      this == SubTaskStatus.pending || this == SubTaskStatus.inProgress;
}
