class User {
  final String id;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final bool isAnonymous;
  final UserStats stats;

  const User({
    required this.id,
    required this.name,
    this.avatar,
    required this.createdAt,
    this.isAnonymous = false,
    required this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isAnonymous: json['isAnonymous'] ?? false,
      stats: UserStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'isAnonymous': isAnonymous,
      'stats': stats.toJson(),
    };
  }
}

class UserStats {
  final int completedTasks;
  final int joinedPools;
  final double averageTacitScore;
  final List<String> efficiencyTags;

  const UserStats({
    this.completedTasks = 0,
    this.joinedPools = 0,
    this.averageTacitScore = 0.0,
    this.efficiencyTags = const [],
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      completedTasks: json['completedTasks'] ?? 0,
      joinedPools: json['joinedPools'] ?? 0,
      averageTacitScore: (json['averageTacitScore'] ?? 0.0).toDouble(),
      efficiencyTags: List<String>.from(json['efficiencyTags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedTasks': completedTasks,
      'joinedPools': joinedPools,
      'averageTacitScore': averageTacitScore,
      'efficiencyTags': efficiencyTags,
    };
  }
}
