class CollaborationPool {
  final String id;
  final String name;
  final String description;
  final List<String> memberIds;
  final bool isAnonymous;
  final PoolStatus status;
  final DateTime createdAt;
  final int tacitScore;
  final PoolProgress progress;
  final List<String> keyNodes;

  const CollaborationPool({
    required this.id,
    required this.name,
    required this.description,
    this.memberIds = const [],
    this.isAnonymous = false,
    this.status = PoolStatus.active,
    required this.createdAt,
    this.tacitScore = 0,
    required this.progress,
    this.keyNodes = const [],
  });

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
      tacitScore: json['tacitScore'] ?? 0,
      progress: PoolProgress.fromJson(json['progress'] ?? {}),
      keyNodes: List<String>.from(json['keyNodes'] ?? []),
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
      'tacitScore': tacitScore,
      'progress': progress.toJson(),
      'keyNodes': keyNodes,
    };
  }
}

enum PoolStatus { active, completed, paused }

class PoolProgress {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;

  const PoolProgress({
    this.totalTasks = 0,
    this.completedTasks = 0,
    this.inProgressTasks = 0,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'inProgressTasks': inProgressTasks,
    };
  }
}
