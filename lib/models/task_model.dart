class Task {
  final String id;
  final String poolId;
  final String title;
  final String? description;
  final int estimatedMinutes;
  final TaskStatus status;
  final String? assigneeId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final BlockReason? blockReason;
  final String? blockNote;
  final DateTime createdAt;
  final TaskStatistics statistics;
  final List<KeyNode> keyNodes;

  const Task({
    required this.id,
    required this.poolId,
    required this.title,
    this.description,
    this.estimatedMinutes = 30,
    this.status = TaskStatus.pending,
    this.assigneeId,
    this.startedAt,
    this.completedAt,
    this.blockReason,
    this.blockNote,
    required this.createdAt,
    required this.statistics,
    this.keyNodes = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      poolId: json['poolId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      estimatedMinutes: json['estimatedMinutes'] ?? 30,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poolId': poolId,
      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'status': status.index,
      'assigneeId': assigneeId,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'blockReason': blockReason?.index,
      'blockNote': blockNote,
      'createdAt': createdAt.toIso8601String(),
      'statistics': statistics.toJson(),
      'keyNodes': keyNodes.map((node) => node.toJson()).toList(),
    };
  }
}

enum TaskStatus { pending, inProgress, completed, blocked }

enum BlockReason { lackOfTools, needHelp, timeConflict, other }

class TaskStatistics {
  final int actualMinutes;
  final int tacitScoreContribution;
  final List<String> interactions;

  const TaskStatistics({
    this.actualMinutes = 0,
    this.tacitScoreContribution = 0,
    this.interactions = const [],
  });

  factory TaskStatistics.fromJson(Map<String, dynamic> json) {
    return TaskStatistics(
      actualMinutes: json['actualMinutes'] ?? 0,
      tacitScoreContribution: json['tacitScoreContribution'] ?? 0,
      interactions: List<String>.from(json['interactions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actualMinutes': actualMinutes,
      'tacitScoreContribution': tacitScoreContribution,
      'interactions': interactions,
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
