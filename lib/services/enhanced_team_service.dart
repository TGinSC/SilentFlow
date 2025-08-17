import '../models/team_pool_model.dart';
import '../models/team_template_model.dart';
import '../models/tacit_understanding_model.dart';
import '../models/task_model.dart';
import '../models/task_template_model.dart';

// 团队创建工作流服务
class TeamCreationService {
  // 基于团队性质创建团队
  static Future<TeamPool> createTeamFromNature({
    required String leaderId,
    required String teamName,
    required String description,
    required TeamNature teamNature,
    TeamTemplate? customTemplate,
  }) async {
    // 获取对应的团队模板
    final TeamTemplate template =
        customTemplate ?? DefaultTeamTemplates.getTemplateByNature(teamNature);

    // 创建基础团队统计
    final statistics = TeamStatistics(
      teamEfficiency: 0.0,
      averageTaskTime: 0.0,
      totalTasksCompleted: 0,
      onTimeCompletionRate: 0.0,
      teamCohesion: 50.0, // 初始默契度
      workflowEfficiency: 50.0,
      communicationQuality: 50.0,
      conflictResolutionRate: 50.0,
      skillCoverage: Map.fromIterable(
        template.recommendedSkills,
        key: (skill) => skill,
        value: (_) => 0.0,
      ),
      memberContributions: {leaderId: 100.0},
      lastActivityAt: DateTime.now(),
    );

    // 创建团队默契度
    final tacitness = TeamTacitUnderstanding(
      teamId: _generateTeamId(),
      overallScore: 50.0,
      dimensionScores: Map.fromIterable(
        TeamTacitUnderstanding.dimensions,
        key: (dim) => dim,
        value: (_) => 50.0,
      ),
      lastCalculated: DateTime.now(),
      factors: [],
      trends: {},
      calculationCount: 1,
    );

    // 创建团队设置
    final settings = TeamSettings(
      isPublic: template.teamSettings['isPublic'] ?? false,
      requireApproval: template.teamSettings['requireApproval'] ?? false,
      allowMemberInvite: template.teamSettings['allowMemberInvite'] ?? true,
      allowMemberCreateTask:
          template.teamSettings['allowMemberCreateTask'] ?? true,
      taskAssignmentMode: TaskAssignmentMode
          .values[template.teamSettings['taskAssignmentMode'] ?? 0],
      notifications: NotificationSettings(
        taskAssigned: true,
        taskCompleted: true,
        newMemberJoined: true,
        deadlineReminder: true,
        milestoneReached: true,
        reminderHoursBefore: 24,
      ),
      autoArchiveDays: template.teamSettings['autoArchiveDays'] ?? 0,
    );

    // 创建团队
    final team = TeamPool(
      id: tacitness.teamId,
      name: teamName,
      description: description,
      leaderId: leaderId,
      memberIds: [],
      status: TeamStatus.active,
      createdAt: DateTime.now(),
      maxMembers: template.recommendedMaxMembers,
      tasks: [],
      settings: settings,
      statistics: statistics,
      inviteTokens: [],
      memberRoles: {},
      events: [
        TeamEvent(
          id: _generateEventId(),
          type: TeamEventType.created,
          description: '团队创建，选择了 ${teamNature.name} 性质',
          timestamp: DateTime.now(),
          userId: leaderId,
          metadata: {
            'teamNature': teamNature.name,
            'templateId': template.id,
          },
        )
      ],
      tags: template.defaultTags,
      teamType: _mapNatureToTeamType(teamNature),
      teamTemplate: template,
      teamNature: teamNature,
      teamTacitness: tacitness,
    );

    return team;
  }

  // 为团队创建推荐任务
  static List<Task> createRecommendedTasks({
    required TeamPool team,
    required List<TaskTemplate> templates,
    int maxTasks = 5,
  }) {
    final List<Task> recommendedTasks = [];

    // 根据团队性质和模板创建任务
    for (int i = 0; i < maxTasks && i < templates.length; i++) {
      final template = templates[i];
      final task = Task(
        id: _generateTaskId(),
        poolId: team.id,
        title: template.name, // 使用name而不是title
        description: template.description,
        estimatedMinutes: template.estimatedMinutes,
        priority: template.priority,
        difficulty: template.difficulty,
        requiredSkills: template.requiredSkills,
        tags: template.tags,
        isTeamTask: template.steps.length > 1, // 根据步骤数判断是否团队任务
        maxAssignees: TeamCreationService._calculateMaxAssigneesFromTemplate(
            template), // 计算最大分配人数
        createdAt: DateTime.now(),
        statistics: TaskStatistics(),
        // 新字段
        level: TaskLevel.project, // 推荐的都是项目级任务
        fromTemplate: template,
        creationMethod: TaskCreationMethod.fromTemplate,
        templateParams: {}, // 使用空参数，TaskTemplate没有defaultParameters字段
        createdBy: team.leaderId,
      );

      recommendedTasks.add(task);
    }

    return recommendedTasks;
  }

  // 计算团队匹配度（用于推荐队友）
  static double calculateTeamMatchScore({
    required TeamPool team,
    required String candidateUserId,
    required List<String> candidateSkills,
    required List<String> candidateInterests,
  }) {
    double score = 0.0;

    // 技能匹配度 (40%)
    if (team.teamTemplate?.recommendedSkills.isNotEmpty == true) {
      int skillMatches = team.teamTemplate!.recommendedSkills
          .where((skill) => candidateSkills.contains(skill))
          .length;
      score +=
          (skillMatches / team.teamTemplate!.recommendedSkills.length) * 0.4;
    }

    // 兴趣匹配度 (30%)
    if (team.tags.isNotEmpty && candidateInterests.isNotEmpty) {
      int interestMatches =
          team.tags.where((tag) => candidateInterests.contains(tag)).length;
      score += (interestMatches / team.tags.length) * 0.3;
    }

    // 团队规模适配度 (20%)
    double sizeScore = team.canAddMoreMembers ? 1.0 : 0.0;
    score += sizeScore * 0.2;

    // 活跃度匹配 (10%)
    double activityScore = team.statistics.lastActivityAt != null
        ? (DateTime.now().difference(team.statistics.lastActivityAt!).inDays < 7
            ? 1.0
            : 0.5)
        : 0.0;
    score += activityScore * 0.1;

    return score.clamp(0.0, 1.0);
  }

  // 生成ID的辅助方法
  static String _generateTeamId() {
    return 'team_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateEventId() {
    return 'event_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}';
  }

  // 映射团队性质到团队类型
  static TeamType _mapNatureToTeamType(TeamNature nature) {
    switch (nature) {
      case TeamNature.softwareDevelopment:
        return TeamType.project;
      case TeamNature.research:
        return TeamType.study;
      case TeamNature.business:
        return TeamType.project;
      case TeamNature.design:
        return TeamType.project;
      case TeamNature.marketing:
        return TeamType.project;
      case TeamNature.writing:
        return TeamType.project;
      case TeamNature.education:
        return TeamType.study;
      case TeamNature.event:
        return TeamType.other;
    }
  }

  // 计算模板的最大分配人数
  static int _calculateMaxAssigneesFromTemplate(TaskTemplate template) {
    // 如果有多个步骤，说明是团队任务，可以分配给多人
    if (template.steps.length > 1) {
      return (template.steps.length / 2).ceil().clamp(1, 5); // 最多5人
    }
    return 1; // 单人任务
  }
}

// 任务创建服务
class TaskCreationService {
  // 从模板创建任务
  static Task createFromTemplate({
    required String teamId,
    required TaskTemplate template,
    required String createdBy,
    Map<String, dynamic> customParams = const {},
    TaskLevel level = TaskLevel.task,
    String? parentTaskId,
  }) {
    // TaskTemplate没有defaultParameters，使用自定义参数
    final params = customParams;

    return Task(
      id: _generateTaskId(),
      poolId: teamId,
      title: _replaceTemplateVariables(template.name, params), // 使用name
      description: _replaceTemplateVariables(template.description, params),
      estimatedMinutes: template.estimatedMinutes,
      priority: template.priority,
      difficulty: template.difficulty,
      requiredSkills: template.requiredSkills,
      tags: template.tags,
      isTeamTask: template.steps.length > 1, // 根据步骤判断
      maxAssignees:
          TeamCreationService._calculateMaxAssigneesFromTemplate(template),
      createdAt: DateTime.now(),
      statistics: TaskStatistics(),
      level: level,
      parentTaskId: parentTaskId,
      fromTemplate: template,
      creationMethod: TaskCreationMethod.fromTemplate,
      templateParams: params,
      createdBy: createdBy,
    );
  }

  // 自定义创建任务
  static Task createCustomTask({
    required String teamId,
    required String title,
    required String createdBy,
    String? description,
    int estimatedMinutes = 60,
    TaskPriority priority = TaskPriority.medium,
    TaskDifficulty difficulty = TaskDifficulty.medium,
    List<String> requiredSkills = const [],
    List<String> tags = const [],
    bool isTeamTask = false,
    int maxAssignees = 1,
    TaskLevel level = TaskLevel.task,
    String? parentTaskId,
  }) {
    return Task(
      id: _generateTaskId(),
      poolId: teamId,
      title: title,
      description: description,
      estimatedMinutes: estimatedMinutes,
      priority: priority,
      difficulty: difficulty,
      requiredSkills: requiredSkills,
      tags: tags,
      isTeamTask: isTeamTask,
      maxAssignees: maxAssignees,
      createdAt: DateTime.now(),
      statistics: TaskStatistics(),
      level: level,
      parentTaskId: parentTaskId,
      creationMethod: TaskCreationMethod.custom,
      templateParams: {},
      createdBy: createdBy,
    );
  }

  // 为项目级任务创建子任务
  static List<Task> createSubTasksForProject({
    required Task projectTask,
    required List<TaskTemplate> subTaskTemplates,
  }) {
    final List<Task> subTasks = [];

    for (final template in subTaskTemplates) {
      final subTask = createFromTemplate(
        teamId: projectTask.poolId,
        template: template,
        createdBy: projectTask.createdBy ?? '',
        level: TaskLevel.taskPoint,
        parentTaskId: projectTask.id,
      );

      subTasks.add(subTask);
    }

    return subTasks;
  }

  // 模板变量替换
  static String _replaceTemplateVariables(
      String text, Map<String, dynamic> params) {
    String result = text;
    params.forEach((key, value) {
      result = result.replaceAll('\${$key}', value.toString());
    });
    return result;
  }

  static String _generateTaskId() {
    return 'task_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}

// 默契度计算服务
class TacitnessCalculationService {
  // 计算团队默契度
  static TeamTacitUnderstanding calculateTeamTacitness({
    required TeamPool team,
    required List<Task> completedTasks,
    required List<TeamEvent> events,
  }) {
    final Map<String, double> dimensionScores = {};

    // 沟通效率
    dimensionScores['communication_efficiency'] =
        _calculateCommunicationEfficiency(events);

    // 任务协调
    dimensionScores['task_coordination'] =
        _calculateTaskCoordination(completedTasks);

    // 时间同步
    dimensionScores['time_synchronization'] =
        _calculateTimeSynchronization(completedTasks);

    // 工作流协调
    dimensionScores['workflow_harmony'] =
        _calculateWorkflowHarmony(completedTasks, events);

    // 相互支持
    dimensionScores['mutual_support'] = _calculateMutualSupport(events);

    // 冲突解决
    dimensionScores['conflict_resolution'] =
        _calculateConflictResolution(events);

    // 计算总体得分
    double overallScore =
        dimensionScores.values.reduce((a, b) => a + b) / dimensionScores.length;

    return TeamTacitUnderstanding(
      teamId: team.id,
      overallScore: overallScore,
      dimensionScores: dimensionScores,
      lastCalculated: DateTime.now(),
      factors: _generateTacitFactors(team, completedTasks, events),
      trends: _generateTrends(team.teamTacitness, dimensionScores),
      calculationCount: (team.teamTacitness?.calculationCount ?? 0) + 1,
    );
  }

  // 计算成员间默契度
  static PairTacitUnderstanding calculatePairTacitness({
    required String userId1,
    required String userId2,
    required String teamId,
    required List<Task> sharedTasks,
    required List<CollaborationRecord> collaborationHistory,
  }) {
    final Map<String, double> interactionScores = {};

    // 响应时间
    interactionScores['response_time'] =
        _calculateResponseTime(collaborationHistory);

    // 任务交接质量
    interactionScores['task_handoff_quality'] =
        _calculateHandoffQuality(sharedTasks);

    // 沟通清晰度
    interactionScores['communication_clarity'] =
        _calculateCommunicationClarity(collaborationHistory);

    // 冲突频率（负向）
    interactionScores['conflict_frequency'] =
        _calculateConflictFrequency(collaborationHistory);

    // 相互帮助
    interactionScores['mutual_assistance'] =
        _calculateMutualAssistance(collaborationHistory);

    // 工作流匹配
    interactionScores['workflow_alignment'] =
        _calculateWorkflowAlignment(sharedTasks);

    // 计算总体默契度
    double tacitScore = interactionScores.values.reduce((a, b) => a + b) /
        interactionScores.length;

    return PairTacitUnderstanding(
      userId1: userId1,
      userId2: userId2,
      teamId: teamId,
      tacitScore: tacitScore,
      interactionScores: interactionScores,
      lastCalculated: DateTime.now(),
      collaborationHistory: collaborationHistory,
      collaborationMetrics:
          _generateCollaborationMetrics(sharedTasks, collaborationHistory),
      totalCollaborations: collaborationHistory.length,
    );
  }

  // 私有计算方法
  static double _calculateCommunicationEfficiency(List<TeamEvent> events) {
    // 基于沟通相关事件计算效率
    return 75.0; // 简化实现
  }

  static double _calculateTaskCoordination(List<Task> tasks) {
    // 基于任务完成情况计算协调度
    return 80.0; // 简化实现
  }

  static double _calculateTimeSynchronization(List<Task> tasks) {
    // 基于时间同步情况计算
    return 70.0; // 简化实现
  }

  static double _calculateWorkflowHarmony(
      List<Task> tasks, List<TeamEvent> events) {
    // 基于工作流协调情况计算
    return 85.0; // 简化实现
  }

  static double _calculateMutualSupport(List<TeamEvent> events) {
    // 基于相互支持事件计算
    return 78.0; // 简化实现
  }

  static double _calculateConflictResolution(List<TeamEvent> events) {
    // 基于冲突解决情况计算
    return 82.0; // 简化实现
  }

  static List<TacitnessFactor> _generateTacitFactors(
      TeamPool team, List<Task> tasks, List<TeamEvent> events) {
    return []; // 简化实现
  }

  static Map<String, TacitnessTrend> _generateTrends(
    TeamTacitUnderstanding? previous,
    Map<String, double> current,
  ) {
    return {}; // 简化实现
  }

  // 人际默契度计算方法
  static double _calculateResponseTime(List<CollaborationRecord> records) {
    return 75.0; // 简化实现
  }

  static double _calculateHandoffQuality(List<Task> tasks) {
    return 80.0; // 简化实现
  }

  static double _calculateCommunicationClarity(
      List<CollaborationRecord> records) {
    return 85.0; // 简化实现
  }

  static double _calculateConflictFrequency(List<CollaborationRecord> records) {
    return 90.0; // 简化实现（高分表示冲突少）
  }

  static double _calculateMutualAssistance(List<CollaborationRecord> records) {
    return 78.0; // 简化实现
  }

  static double _calculateWorkflowAlignment(List<Task> tasks) {
    return 82.0; // 简化实现
  }

  static Map<String, dynamic> _generateCollaborationMetrics(
    List<Task> tasks,
    List<CollaborationRecord> records,
  ) {
    return {
      'totalCollaborations': records.length,
      'averageQuality': records.isNotEmpty
          ? records.map((r) => r.qualityScore).reduce((a, b) => a + b) /
              records.length
          : 0.0,
      'sharedTasksCount': tasks.length,
    };
  }
}
