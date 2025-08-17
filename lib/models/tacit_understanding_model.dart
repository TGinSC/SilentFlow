// 默契度相关模型
// 团队默契度 - 整体团队的协作配合度
class TeamTacitUnderstanding {
  final String teamId;
  final double overallScore; // 整体默契度得分 (0-100)
  final Map<String, double> dimensionScores; // 各维度得分
  final DateTime lastCalculated; // 最后计算时间
  final List<TacitnessFactor> factors; // 影响因素
  final Map<String, TacitnessTrend> trends; // 趋势数据
  final int calculationCount; // 计算次数

  const TeamTacitUnderstanding({
    required this.teamId,
    this.overallScore = 0.0,
    this.dimensionScores = const {},
    required this.lastCalculated,
    this.factors = const [],
    this.trends = const {},
    this.calculationCount = 0,
  });

  // 主要维度
  static const List<String> dimensions = [
    'communication_efficiency', // 沟通效率
    'task_coordination', // 任务协调
    'time_synchronization', // 时间同步
    'workflow_harmony', // 工作流协调
    'mutual_support', // 相互支持
    'conflict_resolution', // 冲突解决
  ];

  factory TeamTacitUnderstanding.fromJson(Map<String, dynamic> json) {
    return TeamTacitUnderstanding(
      teamId: json['teamId'] as String,
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      dimensionScores: Map<String, double>.from(
        (json['dimensionScores'] ?? {})
            .map((k, v) => MapEntry(k, v.toDouble())),
      ),
      lastCalculated: DateTime.parse(json['lastCalculated']),
      factors: (json['factors'] as List<dynamic>?)
              ?.map((e) => TacitnessFactor.fromJson(e))
              .toList() ??
          [],
      trends: Map<String, TacitnessTrend>.from(
        (json['trends'] ?? {})
            .map((k, v) => MapEntry(k, TacitnessTrend.fromJson(v))),
      ),
      calculationCount: json['calculationCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'overallScore': overallScore,
      'dimensionScores': dimensionScores,
      'lastCalculated': lastCalculated.toIso8601String(),
      'factors': factors.map((e) => e.toJson()).toList(),
      'trends': trends.map((k, v) => MapEntry(k, v.toJson())),
      'calculationCount': calculationCount,
    };
  }
}

// 个人与他人的默契度 - 两人间的协作配合度
class PairTacitUnderstanding {
  final String userId1; // 用户1 ID
  final String userId2; // 用户2 ID
  final String teamId; // 所在团队ID
  final double tacitScore; // 默契度得分 (0-100)
  final Map<String, double> interactionScores; // 交互维度得分
  final DateTime lastCalculated;
  final List<CollaborationRecord> collaborationHistory; // 协作历史记录
  final Map<String, dynamic> collaborationMetrics; // 协作指标
  final int totalCollaborations; // 总协作次数

  const PairTacitUnderstanding({
    required this.userId1,
    required this.userId2,
    required this.teamId,
    this.tacitScore = 0.0,
    this.interactionScores = const {},
    required this.lastCalculated,
    this.collaborationHistory = const [],
    this.collaborationMetrics = const {},
    this.totalCollaborations = 0,
  });

  // 获取排序后的用户ID对（确保一致性）
  String get pairKey {
    List<String> users = [userId1, userId2]..sort();
    return '${users[0]}_${users[1]}';
  }

  // 交互维度
  static const List<String> interactionDimensions = [
    'response_time', // 响应时间
    'task_handoff_quality', // 任务交接质量
    'communication_clarity', // 沟通清晰度
    'conflict_frequency', // 冲突频率（负向）
    'mutual_assistance', // 相互帮助
    'workflow_alignment', // 工作流匹配
  ];

  factory PairTacitUnderstanding.fromJson(Map<String, dynamic> json) {
    return PairTacitUnderstanding(
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      teamId: json['teamId'] as String,
      tacitScore: (json['tacitScore'] ?? 0.0).toDouble(),
      interactionScores: Map<String, double>.from(
        (json['interactionScores'] ?? {})
            .map((k, v) => MapEntry(k, v.toDouble())),
      ),
      lastCalculated: DateTime.parse(json['lastCalculated']),
      collaborationHistory: (json['collaborationHistory'] as List<dynamic>?)
              ?.map((e) => CollaborationRecord.fromJson(e))
              .toList() ??
          [],
      collaborationMetrics:
          Map<String, dynamic>.from(json['collaborationMetrics'] ?? {}),
      totalCollaborations: json['totalCollaborations'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId1': userId1,
      'userId2': userId2,
      'teamId': teamId,
      'tacitScore': tacitScore,
      'interactionScores': interactionScores,
      'lastCalculated': lastCalculated.toIso8601String(),
      'collaborationHistory':
          collaborationHistory.map((e) => e.toJson()).toList(),
      'collaborationMetrics': collaborationMetrics,
      'totalCollaborations': totalCollaborations,
    };
  }
}

// 默契度影响因素
class TacitnessFactor {
  final String id;
  final String type; // 因素类型
  final String description; // 描述
  final double weight; // 权重
  final double currentValue; // 当前值
  final double impact; // 对默契度的影响 (-1 到 1)
  final DateTime measuredAt;

  const TacitnessFactor({
    required this.id,
    required this.type,
    required this.description,
    this.weight = 1.0,
    this.currentValue = 0.0,
    this.impact = 0.0,
    required this.measuredAt,
  });

  factory TacitnessFactor.fromJson(Map<String, dynamic> json) {
    return TacitnessFactor(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      weight: (json['weight'] ?? 1.0).toDouble(),
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      impact: (json['impact'] ?? 0.0).toDouble(),
      measuredAt: DateTime.parse(json['measuredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'weight': weight,
      'currentValue': currentValue,
      'impact': impact,
      'measuredAt': measuredAt.toIso8601String(),
    };
  }
}

// 默契度趋势
class TacitnessTrend {
  final String dimension;
  final List<TrendPoint> dataPoints; // 时间序列数据点
  final double currentValue;
  final double previousValue;
  final TrendDirection direction; // 趋势方向
  final double changeRate; // 变化率
  final DateTime updatedAt;

  const TacitnessTrend({
    required this.dimension,
    this.dataPoints = const [],
    this.currentValue = 0.0,
    this.previousValue = 0.0,
    this.direction = TrendDirection.stable,
    this.changeRate = 0.0,
    required this.updatedAt,
  });

  factory TacitnessTrend.fromJson(Map<String, dynamic> json) {
    return TacitnessTrend(
      dimension: json['dimension'] as String,
      dataPoints: (json['dataPoints'] as List<dynamic>?)
              ?.map((e) => TrendPoint.fromJson(e))
              .toList() ??
          [],
      currentValue: (json['currentValue'] ?? 0.0).toDouble(),
      previousValue: (json['previousValue'] ?? 0.0).toDouble(),
      direction: TrendDirection.values[json['direction'] ?? 2],
      changeRate: (json['changeRate'] ?? 0.0).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dimension': dimension,
      'dataPoints': dataPoints.map((e) => e.toJson()).toList(),
      'currentValue': currentValue,
      'previousValue': previousValue,
      'direction': direction.index,
      'changeRate': changeRate,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// 趋势数据点
class TrendPoint {
  final DateTime timestamp;
  final double value;
  final Map<String, dynamic> metadata;

  const TrendPoint({
    required this.timestamp,
    required this.value,
    this.metadata = const {},
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: (json['value']).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'value': value,
      'metadata': metadata,
    };
  }
}

// 协作记录
class CollaborationRecord {
  final String id;
  final String taskId;
  final DateTime startTime;
  final DateTime? endTime;
  final CollaborationType type;
  final double qualityScore; // 质量评分
  final Duration duration;
  final Map<String, dynamic> metrics; // 协作指标
  final List<String> tags;

  const CollaborationRecord({
    required this.id,
    required this.taskId,
    required this.startTime,
    this.endTime,
    required this.type,
    this.qualityScore = 0.0,
    this.duration = Duration.zero,
    this.metrics = const {},
    this.tags = const [],
  });

  factory CollaborationRecord.fromJson(Map<String, dynamic> json) {
    return CollaborationRecord(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      type: CollaborationType.values[json['type'] ?? 0],
      qualityScore: (json['qualityScore'] ?? 0.0).toDouble(),
      duration: Duration(milliseconds: json['duration'] ?? 0),
      metrics: Map<String, dynamic>.from(json['metrics'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'type': type.index,
      'qualityScore': qualityScore,
      'duration': duration.inMilliseconds,
      'metrics': metrics,
      'tags': tags,
    };
  }
}

// 协作类型
enum CollaborationType {
  taskHandoff, // 任务交接
  jointWork, // 共同工作
  peerReview, // 同行评议
  knowledgeShare, // 知识分享
  problemSolving, // 问题解决
  conflictResolution, // 冲突解决
}

// 趋势方向
enum TrendDirection {
  decreasing, // 下降
  increasing, // 上升
  stable, // 稳定
}

// 合作伙伴关系（为后续扩展预留）
class Partnership {
  final String id;
  final String userId1;
  final String userId2;
  final PartnershipType type;
  final double compatibilityScore; // 兼容性得分
  final List<String> sharedTeams; // 共同团队
  final Map<String, double> collaborationHistory; // 协作历史统计
  final DateTime establishedAt;
  final bool isActive;

  const Partnership({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.type,
    this.compatibilityScore = 0.0,
    this.sharedTeams = const [],
    this.collaborationHistory = const {},
    required this.establishedAt,
    this.isActive = true,
  });

  factory Partnership.fromJson(Map<String, dynamic> json) {
    return Partnership(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      type: PartnershipType.values[json['type'] ?? 0],
      compatibilityScore: (json['compatibilityScore'] ?? 0.0).toDouble(),
      sharedTeams: List<String>.from(json['sharedTeams'] ?? []),
      collaborationHistory: Map<String, double>.from(
        (json['collaborationHistory'] ?? {})
            .map((k, v) => MapEntry(k, v.toDouble())),
      ),
      establishedAt: DateTime.parse(json['establishedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'type': type.index,
      'compatibilityScore': compatibilityScore,
      'sharedTeams': sharedTeams,
      'collaborationHistory': collaborationHistory,
      'establishedAt': establishedAt.toIso8601String(),
      'isActive': isActive,
    };
  }
}

// 合作伙伴关系类型
enum PartnershipType {
  suggested, // 系统推荐
  established, // 已建立
  frequent, // 频繁合作
  preferred, // 偏好合作
}
