import 'package:flutter/foundation.dart';
import '../models/team_pool_model.dart';
import '../models/task_template_model.dart';
import '../services/team_pool_service.dart';

class TeamPoolProvider with ChangeNotifier {
  final TeamPoolService _teamPoolService = TeamPoolService();

  List<TeamPool> _teamPools = [];
  TeamPool? _currentTeam;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TeamPool> get teamPools => _teamPools;
  TeamPool? get currentTeam => _currentTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCurrentTeam => _currentTeam != null;

  // 获取用户在当前团队的角色
  MemberRole? getCurrentUserRole(String userId) {
    if (_currentTeam == null) return null;
    return _currentTeam!.getUserRole(userId);
  }

  // 检查用户是否有权限
  bool hasPermission(String userId, String permission) {
    final role = getCurrentUserRole(userId);
    return role?.hasPermission(permission) ?? false;
  }

  // 初始化
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _teamPoolService.initialize();

      // 监听数据变化
      _teamPoolService.teamPoolsStream.listen((pools) {
        _teamPools = pools;
        notifyListeners();
      });

      _teamPoolService.currentTeamStream.listen((team) {
        _currentTeam = team;
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '初始化失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // 创建团队
  Future<bool> createTeam({
    required String name,
    required String description,
    required String leaderId,
    required TeamType teamType,
    int maxMembers = 10,
    bool isPublic = false,
    bool requireApproval = true,
    List<String> tags = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _teamPoolService.createTeam(
        name: name,
        description: description,
        leaderId: leaderId,
        teamType: teamType,
        maxMembers: maxMembers,
        isPublic: isPublic,
        requireApproval: requireApproval,
        tags: tags,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '创建团队失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 加入团队
  Future<bool> joinTeam(String teamId, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _teamPoolService.joinTeam(teamId, userId);
      _isLoading = false;
      notifyListeners();

      if (!success) {
        _error = '加入团队失败';
      }

      return success;
    } catch (e) {
      _error = '加入团队失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 通过邀请码加入团队
  Future<bool> joinTeamByInviteCode(String inviteCode, String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success =
          await _teamPoolService.joinTeamByInviteCode(inviteCode, userId);
      _isLoading = false;
      notifyListeners();

      if (!success) {
        _error = '邀请码无效或团队已满';
      }

      return success;
    } catch (e) {
      _error = '加入团队失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 生成邀请码
  Future<String?> generateInviteCode(String teamId, String userId) async {
    try {
      final inviteCode =
          await _teamPoolService.generateInviteCode(teamId, userId);

      if (inviteCode.isEmpty) {
        _error = '权限不足或团队不存在';
        notifyListeners();
        return null;
      }

      return inviteCode;
    } catch (e) {
      _error = '生成邀请码失败: $e';
      notifyListeners();
      return null;
    }
  }

  // 设置当前团队
  Future<void> setCurrentTeam(String teamId) async {
    try {
      await _teamPoolService.setCurrentTeam(teamId);
    } catch (e) {
      _error = '切换团队失败: $e';
      notifyListeners();
    }
  }

  // 获取用户的团队列表
  List<TeamPool> getUserTeams(String userId) {
    return _teamPoolService.getUserTeams(userId);
  }

  // 获取用户领导的团队
  List<TeamPool> getUserLeadingTeams(String userId) {
    return _teamPoolService.getUserLeadingTeams(userId);
  }

  // 从模板创建任务
  Future<bool> createTaskFromTemplate({
    required String teamId,
    required String templateId,
    required String createdBy,
    String? customTitle,
    String? customDescription,
    Map<String, dynamic>? customFieldValues,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final task = await _teamPoolService.createTaskFromTemplate(
        teamId: teamId,
        templateId: templateId,
        createdBy: createdBy,
        customTitle: customTitle,
        customDescription: customDescription,
        customFieldValues: customFieldValues,
      );

      _isLoading = false;
      notifyListeners();

      if (task == null) {
        _error = '创建任务失败';
        return false;
      }

      return true;
    } catch (e) {
      _error = '创建任务失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 分配任务
  Future<bool> assignTask({
    required String teamId,
    required String taskId,
    required String assignerId,
    required List<String> assigneeIds,
  }) async {
    try {
      final success = await _teamPoolService.assignTask(
        teamId: teamId,
        taskId: taskId,
        assignerId: assignerId,
        assigneeIds: assigneeIds,
      );

      if (!success) {
        _error = '分配任务失败';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = '分配任务失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 认领任务
  Future<bool> claimTask({
    required String teamId,
    required String taskId,
    required String userId,
  }) async {
    try {
      final success = await _teamPoolService.claimTask(
        teamId: teamId,
        taskId: taskId,
        userId: userId,
      );

      if (!success) {
        _error = '认领任务失败';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = '认领任务失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 完成任务
  Future<bool> completeTask({
    required String teamId,
    required String taskId,
    required String userId,
  }) async {
    try {
      final success = await _teamPoolService.completeTask(
        teamId: teamId,
        taskId: taskId,
        userId: userId,
      );

      if (!success) {
        _error = '完成任务失败';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = '完成任务失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 离开团队
  Future<bool> leaveTeam(String teamId, String userId) async {
    try {
      final success = await _teamPoolService.leaveTeam(teamId, userId);

      if (!success) {
        _error = '离开团队失败';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = '离开团队失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 转移队长权限
  Future<bool> transferLeadership({
    required String teamId,
    required String currentLeaderId,
    required String newLeaderId,
  }) async {
    try {
      final success = await _teamPoolService.transferLeadership(
        teamId: teamId,
        currentLeaderId: currentLeaderId,
        newLeaderId: newLeaderId,
      );

      if (!success) {
        _error = '转移队长权限失败';
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = '转移队长权限失败: $e';
      notifyListeners();
      return false;
    }
  }

  // 获取公开团队
  List<TeamPool> getPublicTeams() {
    return _teamPoolService.getPublicTeams();
  }

  // 搜索团队
  List<TeamPool> searchTeams(String query) {
    return _teamPoolService.searchTeams(query);
  }

  // 获取可用的任务模板
  List<TaskTemplate> getTaskTemplates() {
    return DefaultTaskTemplates.all;
  }

  // 根据分类获取任务模板
  List<TaskTemplate> getTaskTemplatesByCategory(String category) {
    return DefaultTaskTemplates.all
        .where((template) => template.category == category)
        .toList();
  }

  // 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _teamPoolService.dispose();
    super.dispose();
  }
}
