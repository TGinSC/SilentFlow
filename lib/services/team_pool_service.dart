import 'dart:async';
import '../models/team_pool_model.dart';
import '../models/task_model.dart';
import '../models/task_template_model.dart';
import 'storage_service.dart';

// 团队池服务 - 管理团队创建、加入、任务分配等功能
class TeamPoolService {
  static final TeamPoolService _instance = TeamPoolService._internal();
  factory TeamPoolService() => _instance;
  TeamPoolService._internal();

  final StorageService _storageService = StorageService();
  final StreamController<List<TeamPool>> _teamPoolsController =
      StreamController<List<TeamPool>>.broadcast();
  final StreamController<TeamPool?> _currentTeamController =
      StreamController<TeamPool?>.broadcast();

  List<TeamPool> _teamPools = [];
  TeamPool? _currentTeam;

  // 流
  Stream<List<TeamPool>> get teamPoolsStream => _teamPoolsController.stream;
  Stream<TeamPool?> get currentTeamStream => _currentTeamController.stream;

  // Getters
  List<TeamPool> get teamPools => List.unmodifiable(_teamPools);
  TeamPool? get currentTeam => _currentTeam;

  // 初始化服务
  Future<void> initialize() async {
    await _loadTeamPools();
    await _loadCurrentTeam();
  }

  // 加载团队池数据
  Future<void> _loadTeamPools() async {
    try {
      final data = await _storageService.getData('team_pools');
      if (data != null && data is List) {
        _teamPools = data.map((json) => TeamPool.fromJson(json)).toList();
        _teamPoolsController.add(_teamPools);
      }
    } catch (e) {
      print('加载团队池数据失败: $e');
      _teamPools = [];
      _teamPoolsController.add(_teamPools);
    }
  }

  // 保存团队池数据
  Future<void> _saveTeamPools() async {
    try {
      final data = _teamPools.map((pool) => pool.toJson()).toList();
      await _storageService.saveData('team_pools', data);
      _teamPoolsController.add(_teamPools);
    } catch (e) {
      print('保存团队池数据失败: $e');
    }
  }

  // 加载当前团队
  Future<void> _loadCurrentTeam() async {
    try {
      final teamId = await _storageService.getData('current_team_id');
      if (teamId != null && teamId is String) {
        _currentTeam = _teamPools.cast<TeamPool?>().firstWhere(
              (pool) => pool?.id == teamId,
              orElse: () => null,
            );
        _currentTeam ??= _teamPools.isNotEmpty ? _teamPools.first : null;
      } else if (_teamPools.isNotEmpty) {
        _currentTeam = _teamPools.first;
      }
      _currentTeamController.add(_currentTeam);
    } catch (e) {
      print('加载当前团队失败: $e');
    }
  }

  // 保存当前团队
  Future<void> _saveCurrentTeam() async {
    try {
      await _storageService.saveData('current_team_id', _currentTeam?.id);
      _currentTeamController.add(_currentTeam);
    } catch (e) {
      print('保存当前团队失败: $e');
    }
  }

  // 创建团队
  Future<TeamPool> createTeam({
    required String name,
    required String description,
    required String leaderId,
    required TeamType teamType,
    int maxMembers = 10,
    bool isPublic = false,
    bool requireApproval = true,
    List<String> tags = const [],
  }) async {
    final teamId = 'team_${DateTime.now().millisecondsSinceEpoch}';

    final team = TeamPool(
      id: teamId,
      name: name,
      description: description,
      leaderId: leaderId,
      teamType: teamType,
      maxMembers: maxMembers,
      createdAt: DateTime.now(),
      status: TeamStatus.active,
      tags: tags,
      settings: TeamSettings(
        isPublic: isPublic,
        requireApproval: requireApproval,
        notifications: const NotificationSettings(),
      ),
      statistics: const TeamStatistics(),
      memberRoles: {leaderId: MemberRole.leader},
      events: [
        TeamEvent(
          id: 'event_${DateTime.now().millisecondsSinceEpoch}',
          type: TeamEventType.created,
          description: '团队"$name"已创建',
          timestamp: DateTime.now(),
          userId: leaderId,
        ),
      ],
    );

    _teamPools.add(team);

    // 自动创建团队的主项目任务
    final mainProject = Task(
      id: 'project_${DateTime.now().millisecondsSinceEpoch}',
      poolId: teamId,
      title: '${name}主项目',
      description: description.isNotEmpty ? description : '${name}团队的主要项目任务',
      estimatedMinutes: 480, // 默认8小时
      expectedAt: DateTime.now().add(const Duration(days: 30)), // 默认30天完成
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      statistics: const TaskStatistics(),
      priority: TaskPriority.high,
      baseReward: 100.0,
      tags: ['主项目', ...tags],
      requiredSkills: [],
      difficulty: TaskDifficulty.medium,
      maxAssignees: maxMembers,
      isTeamTask: true,
      subTasks: [],
      keyNodes: [],
      assignedUsers: [],
      level: TaskLevel.project, // 设置为项目级别
    );

    // 保存主项目任务到任务存储中
    await _saveMainProjectTask(mainProject);

    // 如果这是用户的第一个团队，设为当前团队
    if (_currentTeam == null) {
      _currentTeam = team;
      await _saveCurrentTeam();
    }

    await _saveTeamPools();
    return team;
  }

  // 通过邀请码加入团队
  Future<bool> joinTeamByInviteCode(String inviteCode, String userId) async {
    TeamPool? team;
    try {
      team = _teamPools.firstWhere(
        (pool) => pool.inviteTokens.contains(inviteCode),
      );
    } catch (e) {
      return false;
    }

    return await joinTeam(team.id, userId);
  }

  // 加入团队
  Future<bool> joinTeam(String teamId, String userId) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];

    // 检查是否已经是成员
    if (team.isMember(userId)) return false;

    // 检查是否还能加入更多成员
    if (!team.canAddMoreMembers) return false;

    // 更新团队成员
    final updatedMemberIds = List<String>.from(team.memberIds)..add(userId);
    final updatedMemberRoles = Map<String, MemberRole>.from(team.memberRoles);
    updatedMemberRoles[userId] = MemberRole.member;

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.memberJoined,
      description: '新成员加入团队',
      timestamp: DateTime.now(),
      userId: userId,
    ));

    final updatedTeam = team.copyWith(
      memberIds: updatedMemberIds,
      memberRoles: updatedMemberRoles,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    // 如果用户还没有当前团队，设置为当前团队
    if (_currentTeam == null) {
      _currentTeam = updatedTeam;
      await _saveCurrentTeam();
    }

    await _saveTeamPools();
    return true;
  }

  // 生成邀请码
  Future<String> generateInviteCode(String teamId, String userId) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return '';

    final team = _teamPools[teamIndex];

    // 检查权限
    if (!team.isLeader(userId) &&
        !(team.settings.allowMemberInvite && team.isMember(userId))) {
      return '';
    }

    final inviteCode = team.generateInviteToken();
    final updatedInviteTokens = List<String>.from(team.inviteTokens)
      ..add(inviteCode);

    final updatedTeam = team.copyWith(inviteTokens: updatedInviteTokens);
    _teamPools[teamIndex] = updatedTeam;

    await _saveTeamPools();
    return inviteCode;
  }

  // 设置当前团队
  Future<void> setCurrentTeam(String teamId) async {
    TeamPool? team;
    try {
      team = _teamPools.firstWhere(
        (pool) => pool.id == teamId,
      );
    } catch (e) {
      return;
    }

    _currentTeam = team;
    await _saveCurrentTeam();
  }

  // 获取用户参与的团队
  List<TeamPool> getUserTeams(String userId) {
    return _teamPools.where((pool) => pool.isMember(userId)).toList();
  }

  // 获取用户领导的团队
  List<TeamPool> getUserLeadingTeams(String userId) {
    return _teamPools.where((pool) => pool.isLeader(userId)).toList();
  }

  // 从模板创建任务
  Future<Task?> createTaskFromTemplate({
    required String teamId,
    required String templateId,
    required String createdBy,
    String? customTitle,
    String? customDescription,
    Map<String, dynamic>? customFieldValues,
  }) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return null;

    final team = _teamPools[teamIndex];

    // 检查权限
    final userRole = team.getUserRole(createdBy);
    if (!userRole.hasPermission('create_task')) return null;

    // 获取模板（这里应该从模板服务获取，暂时使用默认模板）
    final template = DefaultTaskTemplates.all.firstWhere(
      (t) => t.id == templateId,
      orElse: () => DefaultTaskTemplates.softwareDevelopmentTemplate,
    );

    final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';
    final task = template.createTask(
      poolId: teamId,
      taskId: taskId,
      customTitle: customTitle,
      customDescription: customDescription,
      createdBy: createdBy,
      customFieldValues: customFieldValues,
    );

    // 更新团队任务列表
    final updatedTasks = List<Task>.from(team.tasks)..add(task);

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.taskCreated,
      description: '创建了新任务: ${task.title}',
      timestamp: DateTime.now(),
      userId: createdBy,
      metadata: {'taskId': taskId, 'templateId': templateId},
    ));

    final updatedTeam = team.copyWith(
      tasks: updatedTasks,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    // 更新当前团队
    if (_currentTeam?.id == teamId) {
      _currentTeam = updatedTeam;
      _currentTeamController.add(_currentTeam);
    }

    await _saveTeamPools();
    return task;
  }

  // 分配任务给成员
  Future<bool> assignTask({
    required String teamId,
    required String taskId,
    required String assignerId,
    required List<String> assigneeIds,
  }) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];
    final assignerRole = team.getUserRole(assignerId);

    // 检查分配权限
    if (!assignerRole.hasPermission('assign_task')) return false;

    // 验证被分配者都是团队成员
    for (String assigneeId in assigneeIds) {
      if (!team.isMember(assigneeId)) return false;
    }

    // 查找并更新任务
    final updatedTasks = team.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(
          assignedUsers: assigneeIds,
          status: TaskStatus.pending,
        );
      }
      return task;
    }).toList();

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.taskAssigned,
      description: '任务已分配给 ${assigneeIds.length} 名成员',
      timestamp: DateTime.now(),
      userId: assignerId,
      metadata: {
        'taskId': taskId,
        'assigneeIds': assigneeIds,
      },
    ));

    final updatedTeam = team.copyWith(
      tasks: updatedTasks,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    if (_currentTeam?.id == teamId) {
      _currentTeam = updatedTeam;
      _currentTeamController.add(_currentTeam);
    }

    await _saveTeamPools();
    return true;
  }

  // 成员自选任务
  Future<bool> claimTask({
    required String teamId,
    required String taskId,
    required String userId,
  }) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];
    final userRole = team.getUserRole(userId);

    // 检查认领权限
    if (!userRole.hasPermission('claim_task')) return false;

    // 查找任务
    final taskIndex = team.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return false;

    final task = team.tasks[taskIndex];

    // 检查任务是否可以被认领
    if (task.status != TaskStatus.pending) return false;
    if (task.assignedUsers.contains(userId)) return false;
    if (task.assignedUsers.length >= task.maxAssignees) return false;

    // 更新任务
    final updatedAssignedUsers = List<String>.from(task.assignedUsers)
      ..add(userId);
    final updatedTask = task.copyWith(
      assignedUsers: updatedAssignedUsers,
      status: TaskStatus.inProgress,
      startedAt: DateTime.now(),
    );

    final updatedTasks = List<Task>.from(team.tasks);
    updatedTasks[taskIndex] = updatedTask;

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.taskAssigned,
      description: '成员认领了任务: ${task.title}',
      timestamp: DateTime.now(),
      userId: userId,
      metadata: {'taskId': taskId, 'action': 'claim'},
    ));

    final updatedTeam = team.copyWith(
      tasks: updatedTasks,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    if (_currentTeam?.id == teamId) {
      _currentTeam = updatedTeam;
      _currentTeamController.add(_currentTeam);
    }

    await _saveTeamPools();
    return true;
  }

  // 完成任务
  Future<bool> completeTask({
    required String teamId,
    required String taskId,
    required String userId,
  }) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];
    final userRole = team.getUserRole(userId);

    // 检查权限
    if (!userRole.hasPermission('complete_task')) return false;

    // 查找任务
    final taskIndex = team.tasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) return false;

    final task = team.tasks[taskIndex];

    // 检查是否可以完成任务
    if (!task.assignedUsers.contains(userId) && !team.isLeader(userId))
      return false;

    // 更新任务
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
    );

    final updatedTasks = List<Task>.from(team.tasks);
    updatedTasks[taskIndex] = updatedTask;

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.taskCompleted,
      description: '任务已完成: ${task.title}',
      timestamp: DateTime.now(),
      userId: userId,
      metadata: {'taskId': taskId},
    ));

    final updatedTeam = team.copyWith(
      tasks: updatedTasks,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    if (_currentTeam?.id == teamId) {
      _currentTeam = updatedTeam;
      _currentTeamController.add(_currentTeam);
    }

    await _saveTeamPools();
    return true;
  }

  // 更新团队设置
  Future<bool> updateTeamSettings({
    required String teamId,
    required String userId,
    required TeamSettings settings,
  }) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];
    final userRole = team.getUserRole(userId);

    // 检查权限
    if (!userRole.hasPermission('modify_settings')) return false;

    final updatedTeam = team.copyWith(settings: settings);
    _teamPools[teamIndex] = updatedTeam;

    if (_currentTeam?.id == teamId) {
      _currentTeam = updatedTeam;
      _currentTeamController.add(_currentTeam);
    }

    await _saveTeamPools();
    return true;
  }

  // 离开团队
  Future<bool> leaveTeam(String teamId, String userId) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];

    // 队长不能直接离开团队（需要先转移队长权限）
    if (team.isLeader(userId)) return false;

    // 不是成员的话无法离开
    if (!team.isMember(userId)) return false;

    // 更新团队成员
    final updatedMemberIds = List<String>.from(team.memberIds)..remove(userId);
    final updatedMemberRoles = Map<String, MemberRole>.from(team.memberRoles);
    updatedMemberRoles.remove(userId);

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.memberLeft,
      description: '成员离开了团队',
      timestamp: DateTime.now(),
      userId: userId,
    ));

    final updatedTeam = team.copyWith(
      memberIds: updatedMemberIds,
      memberRoles: updatedMemberRoles,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    // 如果离开的是当前团队，切换到其他团队或清空
    if (_currentTeam?.id == teamId) {
      final userTeams = getUserTeams(userId);
      _currentTeam = userTeams.isNotEmpty ? userTeams.first : null;
      await _saveCurrentTeam();
    }

    await _saveTeamPools();
    return true;
  }

  // 删除团队（仅限队长）
  Future<bool> deleteTeam(String teamId) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    // 从列表中移除团队
    _teamPools.removeAt(teamIndex);

    // 如果删除的是当前团队，清空当前团队
    if (_currentTeam?.id == teamId) {
      _currentTeam = null;
      await _saveCurrentTeam();
    }

    // 保存更新
    await _saveTeamPools();
    return true;
  }

  // 转移队长权限
  Future<bool> transferLeadership({
    required String teamId,
    required String currentLeaderId,
    required String newLeaderId,
  }) async {
    final teamIndex = _teamPools.indexWhere((pool) => pool.id == teamId);
    if (teamIndex == -1) return false;

    final team = _teamPools[teamIndex];

    // 验证当前队长
    if (!team.isLeader(currentLeaderId)) return false;

    // 验证新队长是团队成员
    if (!team.isMember(newLeaderId)) return false;

    // 更新角色
    final updatedMemberRoles = Map<String, MemberRole>.from(team.memberRoles);
    updatedMemberRoles[currentLeaderId] = MemberRole.member;
    updatedMemberRoles[newLeaderId] = MemberRole.leader;

    // 添加事件
    final updatedEvents = List<TeamEvent>.from(team.events);
    updatedEvents.add(TeamEvent(
      id: 'event_${DateTime.now().millisecondsSinceEpoch}',
      type: TeamEventType.memberRoleChanged,
      description: '队长权限已转移',
      timestamp: DateTime.now(),
      userId: currentLeaderId,
      metadata: {
        'oldLeaderId': currentLeaderId,
        'newLeaderId': newLeaderId,
      },
    ));

    final updatedTeam = team.copyWith(
      leaderId: newLeaderId,
      memberRoles: updatedMemberRoles,
      events: updatedEvents,
    );

    _teamPools[teamIndex] = updatedTeam;

    if (_currentTeam?.id == teamId) {
      _currentTeam = updatedTeam;
      _currentTeamController.add(_currentTeam);
    }

    await _saveTeamPools();
    return true;
  }

  // 获取公开的团队（可加入）
  List<TeamPool> getPublicTeams() {
    return _teamPools
        .where((pool) =>
            pool.settings.isPublic &&
            pool.status == TeamStatus.active &&
            pool.canAddMoreMembers)
        .toList();
  }

  // 搜索团队
  List<TeamPool> searchTeams(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getPublicTeams()
        .where((pool) =>
            pool.name.toLowerCase().contains(lowercaseQuery) ||
            pool.description.toLowerCase().contains(lowercaseQuery) ||
            pool.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)))
        .toList();
  }

  // 保存团队的主项目任务
  Future<void> _saveMainProjectTask(Task mainProject) async {
    try {
      const String key = 'team_main_projects';
      final storage = StorageService();

      // 获取现有的主项目列表
      final existingData = await storage.getData(key);
      List<Map<String, dynamic>> projectsList = [];

      if (existingData != null) {
        projectsList = List<Map<String, dynamic>>.from(existingData);
      }

      // 添加新的主项目
      projectsList.add(mainProject.toJson());

      // 保存更新后的列表
      await storage.saveData(key, projectsList);
    } catch (e) {
      print('保存主项目任务失败: $e');
    }
  }

  // 获取团队的主项目任务
  Future<Task?> getTeamMainProject(String teamId) async {
    try {
      const String key = 'team_main_projects';
      final storage = StorageService();

      final data = await storage.getData(key);
      if (data != null) {
        final projectsList = List<Map<String, dynamic>>.from(data);
        final projectData = projectsList.firstWhere(
          (project) => project['poolId'] == teamId,
          orElse: () => <String, dynamic>{},
        );

        if (projectData.isNotEmpty) {
          return Task.fromJson(projectData);
        }
      }
      return null;
    } catch (e) {
      print('获取主项目任务失败: $e');
      return null;
    }
  }

  // 获取所有团队的主项目
  Future<List<Task>> getAllMainProjects() async {
    try {
      const String key = 'team_main_projects';
      final storage = StorageService();

      final data = await storage.getData(key);
      if (data != null) {
        final projectsList = List<Map<String, dynamic>>.from(data);
        return projectsList.map((project) => Task.fromJson(project)).toList();
      }
      return [];
    } catch (e) {
      print('获取所有主项目失败: $e');
      return [];
    }
  }

  // 释放资源
  void dispose() {
    _teamPoolsController.close();
    _currentTeamController.close();
  }
}
