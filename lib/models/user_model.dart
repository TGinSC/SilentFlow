class User {
  final String id;
  final String name;
  final String? avatar;
  final DateTime createdAt;
  final bool isAnonymous;
  final UserStats stats;
  final UserProfile profile; // 个人资料和技能信息

  const User({
    required this.id,
    required this.name,
    this.avatar,
    required this.createdAt,
    this.isAnonymous = false,
    required this.stats,
    required this.profile,
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
      profile: UserProfile.fromJson(json['profile'] ?? {}),
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
      'profile': profile.toJson(),
    };
  }
}

class UserStats {
  final int completedTasks; // 完成的任务数
  final int joinedPools; // 加入的协作池数量
  final double contributionScore; // 个人贡献值 (0-100)
  final double averageTacitScore; // 平均默契度 (0-100)
  final List<String> efficiencyTags; // 效率标签
  final int totalSubTasks; // 总子任务数
  final int completedSubTasks; // 完成的子任务数
  final double onTimeRate; // 按时完成率 (0-1)
  final int earlyCompletions; // 提前完成次数
  final int lateCompletions; // 延期完成次数

  const UserStats({
    this.completedTasks = 0,
    this.joinedPools = 0,
    this.contributionScore = 0.0,
    this.averageTacitScore = 0.0,
    this.efficiencyTags = const [],
    this.totalSubTasks = 0,
    this.completedSubTasks = 0,
    this.onTimeRate = 0.0,
    this.earlyCompletions = 0,
    this.lateCompletions = 0,
  });

  // 贡献度等级
  String get contributionLevel {
    if (contributionScore >= 90) return '协作大师';
    if (contributionScore >= 80) return '高效贡献者';
    if (contributionScore >= 70) return '积极参与者';
    if (contributionScore >= 60) return '稳定贡献者';
    if (contributionScore >= 50) return '普通参与者';
    return '新手协作者';
  }

  // 默契度等级
  String get tacitLevel {
    if (averageTacitScore >= 90) return '完美默契';
    if (averageTacitScore >= 80) return '高度默契';
    if (averageTacitScore >= 70) return '良好默契';
    if (averageTacitScore >= 60) return '基础默契';
    if (averageTacitScore >= 50) return '磨合中';
    return '需要磨合';
  }

  // 子任务完成率
  double get subTaskCompletionRate {
    if (totalSubTasks == 0) return 0.0;
    return completedSubTasks / totalSubTasks;
  }

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      completedTasks: json['completedTasks'] ?? 0,
      joinedPools: json['joinedPools'] ?? 0,
      contributionScore: (json['contributionScore'] ?? 0.0).toDouble(),
      averageTacitScore: (json['averageTacitScore'] ?? 0.0).toDouble(),
      efficiencyTags: List<String>.from(json['efficiencyTags'] ?? []),
      totalSubTasks: json['totalSubTasks'] ?? 0,
      completedSubTasks: json['completedSubTasks'] ?? 0,
      onTimeRate: (json['onTimeRate'] ?? 0.0).toDouble(),
      earlyCompletions: json['earlyCompletions'] ?? 0,
      lateCompletions: json['lateCompletions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedTasks': completedTasks,
      'joinedPools': joinedPools,
      'contributionScore': contributionScore,
      'averageTacitScore': averageTacitScore,
      'efficiencyTags': efficiencyTags,
      'totalSubTasks': totalSubTasks,
      'completedSubTasks': completedSubTasks,
      'onTimeRate': onTimeRate,
      'earlyCompletions': earlyCompletions,
      'lateCompletions': lateCompletions,
    };
  }
}

// 用户个人资料和技能信息
class UserProfile {
  final String? bio; // 个人简介
  final String? department; // 部门/专业
  final String? role; // 角色/职位
  final List<UserSkill> skills; // 技能列表
  final List<String> interests; // 兴趣领域
  final WorkStyle workStyle; // 工作风格
  final AvailabilityInfo availability; // 时间可用性
  final List<String> preferredTaskTypes; // 偏好的任务类型
  final ContactInfo contact; // 联系方式
  final List<Achievement> achievements; // 成就记录

  const UserProfile({
    this.bio,
    this.department,
    this.role,
    this.skills = const [],
    this.interests = const [],
    required this.workStyle,
    required this.availability,
    this.preferredTaskTypes = const [],
    required this.contact,
    this.achievements = const [],
  });

  // 获取最擅长的技能
  List<UserSkill> get topSkills {
    List<UserSkill> sorted = List.from(skills);
    sorted.sort((a, b) => b.level.compareTo(a.level));
    return sorted.take(3).toList();
  }

  // 获取技能匹配度
  double getSkillMatchScore(List<String> requiredSkills) {
    if (requiredSkills.isEmpty) return 0.0;

    int matchCount = 0;
    double totalScore = 0.0;

    for (String required in requiredSkills) {
      UserSkill? matchedSkill = skills.cast<UserSkill?>().firstWhere(
            (skill) => skill?.name.toLowerCase() == required.toLowerCase(),
            orElse: () => null,
          );

      if (matchedSkill != null) {
        matchCount++;
        totalScore += matchedSkill.level / 5.0; // 标准化到0-1
      }
    }

    if (matchCount == 0) return 0.0;
    return totalScore / requiredSkills.length;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio'],
      department: json['department'],
      role: json['role'],
      skills: (json['skills'] as List<dynamic>?)
              ?.map((skill) => UserSkill.fromJson(skill))
              .toList() ??
          [],
      interests: List<String>.from(json['interests'] ?? []),
      workStyle: WorkStyle.fromJson(json['workStyle'] ?? {}),
      availability: AvailabilityInfo.fromJson(json['availability'] ?? {}),
      preferredTaskTypes: List<String>.from(json['preferredTaskTypes'] ?? []),
      contact: ContactInfo.fromJson(json['contact'] ?? {}),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((achievement) => Achievement.fromJson(achievement))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'department': department,
      'role': role,
      'skills': skills.map((skill) => skill.toJson()).toList(),
      'interests': interests,
      'workStyle': workStyle.toJson(),
      'availability': availability.toJson(),
      'preferredTaskTypes': preferredTaskTypes,
      'contact': contact.toJson(),
      'achievements':
          achievements.map((achievement) => achievement.toJson()).toList(),
    };
  }

  UserProfile copyWith({
    String? bio,
    String? department,
    String? role,
    List<UserSkill>? skills,
    List<String>? interests,
    WorkStyle? workStyle,
    AvailabilityInfo? availability,
    List<String>? preferredTaskTypes,
    ContactInfo? contact,
    List<Achievement>? achievements,
  }) {
    return UserProfile(
      bio: bio ?? this.bio,
      department: department ?? this.department,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      interests: interests ?? this.interests,
      workStyle: workStyle ?? this.workStyle,
      availability: availability ?? this.availability,
      preferredTaskTypes: preferredTaskTypes ?? this.preferredTaskTypes,
      contact: contact ?? this.contact,
      achievements: achievements ?? this.achievements,
    );
  }
}

// 用户技能
class UserSkill {
  final String name; // 技能名称
  final int level; // 熟练程度 1-5
  final List<String> tags; // 技能标签
  final int experienceYears; // 经验年限
  final String? certificate; // 认证信息
  final DateTime? lastUsed; // 最后使用时间

  const UserSkill({
    required this.name,
    required this.level,
    this.tags = const [],
    this.experienceYears = 0,
    this.certificate,
    this.lastUsed,
  });

  String get levelText {
    switch (level) {
      case 1:
        return '入门';
      case 2:
        return '初级';
      case 3:
        return '中级';
      case 4:
        return '高级';
      case 5:
        return '专家';
      default:
        return '未知';
    }
  }

  factory UserSkill.fromJson(Map<String, dynamic> json) {
    return UserSkill(
      name: json['name'] ?? '',
      level: json['level'] ?? 1,
      tags: List<String>.from(json['tags'] ?? []),
      experienceYears: json['experienceYears'] ?? 0,
      certificate: json['certificate'],
      lastUsed:
          json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'level': level,
      'tags': tags,
      'experienceYears': experienceYears,
      'certificate': certificate,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }
}

// 工作风格
class WorkStyle {
  final String communicationStyle; // 沟通风格: 直接/委婉/详细/简洁
  final String workPace; // 工作节奏: 快速/稳定/灵活
  final String preferredCollaborationMode; // 协作偏好: 独立/团队/混合
  final List<String> workingHours; // 工作时间偏好
  final String stressHandling; // 压力处理方式
  final String feedbackStyle; // 反馈风格

  const WorkStyle({
    required this.communicationStyle,
    required this.workPace,
    required this.preferredCollaborationMode,
    this.workingHours = const [],
    required this.stressHandling,
    required this.feedbackStyle,
  });

  factory WorkStyle.fromJson(Map<String, dynamic> json) {
    return WorkStyle(
      communicationStyle: json['communicationStyle'] ?? '平衡',
      workPace: json['workPace'] ?? '稳定',
      preferredCollaborationMode: json['preferredCollaborationMode'] ?? '混合',
      workingHours: List<String>.from(json['workingHours'] ?? []),
      stressHandling: json['stressHandling'] ?? '正常',
      feedbackStyle: json['feedbackStyle'] ?? '建设性',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'communicationStyle': communicationStyle,
      'workPace': workPace,
      'preferredCollaborationMode': preferredCollaborationMode,
      'workingHours': workingHours,
      'stressHandling': stressHandling,
      'feedbackStyle': feedbackStyle,
    };
  }
}

// 时间可用性信息
class AvailabilityInfo {
  final Map<String, List<String>> weeklySchedule; // 每周时间表
  final String timezone; // 时区
  final int maxHoursPerWeek; // 每周最大投入小时数
  final List<String> busyPeriods; // 繁忙时段
  final String? vacationInfo; // 假期信息

  const AvailabilityInfo({
    this.weeklySchedule = const {},
    this.timezone = 'UTC+8',
    this.maxHoursPerWeek = 40,
    this.busyPeriods = const [],
    this.vacationInfo,
  });

  factory AvailabilityInfo.fromJson(Map<String, dynamic> json) {
    return AvailabilityInfo(
      weeklySchedule: Map<String, List<String>>.from(json['weeklySchedule']
              ?.map((key, value) => MapEntry(key, List<String>.from(value))) ??
          {}),
      timezone: json['timezone'] ?? 'UTC+8',
      maxHoursPerWeek: json['maxHoursPerWeek'] ?? 40,
      busyPeriods: List<String>.from(json['busyPeriods'] ?? []),
      vacationInfo: json['vacationInfo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklySchedule': weeklySchedule,
      'timezone': timezone,
      'maxHoursPerWeek': maxHoursPerWeek,
      'busyPeriods': busyPeriods,
      'vacationInfo': vacationInfo,
    };
  }
}

// 联系信息
class ContactInfo {
  final String? email;
  final String? phone;
  final String? wechat;
  final String? qq;
  final Map<String, String> socialMedia; // 社交媒体链接

  const ContactInfo({
    this.email,
    this.phone,
    this.wechat,
    this.qq,
    this.socialMedia = const {},
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      email: json['email'],
      phone: json['phone'],
      wechat: json['wechat'],
      qq: json['qq'],
      socialMedia: Map<String, String>.from(json['socialMedia'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'phone': phone,
      'wechat': wechat,
      'qq': qq,
      'socialMedia': socialMedia,
    };
  }
}

// 成就记录
class Achievement {
  final String id;
  final String title;
  final String description;
  final DateTime achievedAt;
  final String category; // 类别：协作/效率/创新/领导等
  final int points; // 成就积分

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.achievedAt,
    required this.category,
    required this.points,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      achievedAt: DateTime.parse(
        json['achievedAt'] ?? DateTime.now().toIso8601String(),
      ),
      category: json['category'] ?? '',
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'achievedAt': achievedAt.toIso8601String(),
      'category': category,
      'points': points,
    };
  }
}
