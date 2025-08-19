import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/team_pool_model.dart';
import '../models/task_template_model.dart';
import '../models/task_model.dart';
import '../services/team_service.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';

class TeamPoolProvider with ChangeNotifier {
  // 使用TeamService进行团队管理

  List<TeamPool> _teamPools = [];
  TeamPool? _currentTeam;
  bool _isLoading = false;
  String? _error;

  // 缓存的搜索结果和公开团队
  List<TeamPool> _cachedPublicTeams = [];
  List<TeamPool> _cachedSearchResults = [];
  List<TeamPool> _cachedUserLeadingTeams = [];

  // Getters
  List<TeamPool> get teamPools => _teamPools;
  List<TeamPool> get publicTeams => _cachedPublicTeams;
  List<TeamPool> get searchResults => _cachedSearchResults;
  List<TeamPool> get userLeadingTeams => _cachedUserLeadingTeams;
  TeamPool? get currentTeam => _currentTeam;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 初始化
  Future<void> initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('TeamPoolProvider 初始化中...');
      // 这里可以加载初始数据
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟加载

      _isLoading = false;
      print('TeamPoolProvider 初始化完成');
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('TeamPoolProvider 初始化失败: $e');
      notifyListeners();
    }
  }

  // 创建团队
  Future<bool> createTeam({
    required String name,
    required String description,
    required String leaderId,
    String? template,
    bool isPublic = true,
    List<String> tags = const [],
    Map<String, dynamic>? settings,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('TeamPoolProvider.createTeam 开始...');
      print('创建团队: $name, 领导者: $leaderId');

      // 检查leaderId是否为空
      if (leaderId.isEmpty) {
        throw Exception('用户ID为空，无法创建团队');
      }

      // 测试网络连接
      print('测试网络连接...');
      final isConnected = await ApiService.testConnection();
      if (!isConnected) {
        throw Exception('无法连接到后端服务，请检查网络或确认后端服务已启动');
      }
      print('网络连接测试成功');

      // 生成6位随机团队ID
      final random = Random();
      final teamIdNum = 100000 + random.nextInt(900000); // 生成6位数ID

      // 生成4位随机密码
      final teamPasswordNum = 1000 + random.nextInt(9000); // 生成4位数密码

      print('生成的团队ID: $teamIdNum, 密码: $teamPasswordNum');
      print('领导者ID: $leaderId (类型: ${leaderId.runtimeType})');

      // 使用TeamService创建团队
      print('调用TeamService.createTeam...');
      final teamId = await TeamService.createTeam(
        teamId: teamIdNum.toString(),
        teamPassword: teamPasswordNum.toString(),
        teamLeader: leaderId,
      );

      print('TeamService.createTeam 返回结果: $teamId');

      if (teamId != null && teamId.isNotEmpty) {
        print('团队创建成功: $teamId');

        // 创建一个临时的团队对象添加到本地缓存
        final newTeam = TeamPool(
          id: teamId,
          name: name,
          description: description,
          leaderId: leaderId,
          memberIds: [leaderId], // 创建者自动成为成员
          createdAt: DateTime.now(),
          settings: const TeamSettings(
            notifications: NotificationSettings(),
          ),
          statistics: const TeamStatistics(),
          status: TeamStatus.active,
          teamType: TeamType.project,
        );

        // 添加到本地缓存
        _teamPools.add(newTeam);
        print('团队已添加到本地缓存，当前团队数量: ${_teamPools.length}');

        // 🆕 为新团队创建主项目任务
        try {
          print('为新团队创建主项目任务...');
          await _createMainProjectForTeam(teamId, name, leaderId);
          print('主项目任务创建成功');
        } catch (e) {
          print('创建主项目任务失败，但团队创建成功: $e');
          // 即使主项目创建失败，团队创建仍然是成功的
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        print('TeamService.createTeam 返回null或空字符串，创建失败');
        _error = '后端服务创建团队失败，请检查网络连接';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('创建团队失败: $e');
      print('错误堆栈: ${StackTrace.current}');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 加入团队
  Future<bool> joinTeam(String teamId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('用户 $userId 尝试加入团队 $teamId');
      // 这里可以调用实际的加入团队API
      await Future.delayed(const Duration(milliseconds: 300));

      _isLoading = false;
      print('用户 $userId 成功加入团队 $teamId');
      notifyListeners();
      return true;
    } catch (e) {
      print('加入团队失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 通过邀请码加入团队
  Future<bool> joinTeamByInviteCode(String inviteCode, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('用户 $userId 通过邀请码 $inviteCode 加入团队');
      await Future.delayed(const Duration(milliseconds: 300));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('通过邀请码加入团队失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 生成邀请码
  Future<String?> generateInviteCode(String teamId, String userId) async {
    try {
      print('为团队 $teamId 生成邀请码');
      await Future.delayed(const Duration(milliseconds: 300));

      final inviteCode = 'INV${DateTime.now().millisecondsSinceEpoch}';
      print('生成的邀请码: $inviteCode');
      return inviteCode;
    } catch (e) {
      print('生成邀请码失败: $e');
      return null;
    }
  }

  // 同步获取用户团队（从缓存）
  List<TeamPool> getUserTeamsSync(String userId) => _teamPools
      .where(
          (team) => team.memberIds.contains(userId) || team.leaderId == userId)
      .toList();

  // 同步获取用户领导的团队（从缓存）
  List<TeamPool> getUserLeadingTeamsSync(String userId) =>
      _teamPools.where((team) => team.leaderId == userId).toList();

  // 同步获取公开团队（从缓存）
  List<TeamPool> get allPublicTeams =>
      _teamPools.where((team) => team.status == TeamStatus.active).toList();

  // 同步搜索团队（从缓存）
  List<TeamPool> searchTeamsSync(String query) {
    if (query.isEmpty) return allPublicTeams;
    return _teamPools
        .where((team) =>
            team.name.toLowerCase().contains(query.toLowerCase()) ||
            team.description.toLowerCase().contains(query.toLowerCase()) ||
            team.tags
                .any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  // 获取当前用户ID的辅助方法
  String getCurrentUserId() {
    // 这里应该从某个地方获取当前用户ID，暂时返回空字符串
    return '';
  }

  // 设置当前团队
  Future<void> setCurrentTeam(String teamId) async {
    try {
      print('设置当前团队: $teamId');
      // 这里可以从缓存或API获取团队信息
      _currentTeam = null; // 临时设置为null
      notifyListeners();
    } catch (e) {
      print('设置当前团队失败: $e');
    }
  }

  // 获取用户团队
  Future<List<TeamPool>> getUserTeams(String userId) async {
    try {
      print('获取用户团队: $userId');
      await Future.delayed(const Duration(milliseconds: 300));
      return [];
    } catch (e) {
      print('获取用户团队失败: $e');
      return [];
    }
  }

  // 获取用户领导的团队
  Future<List<TeamPool>> getUserLeadingTeams(String userId) async {
    try {
      print('获取用户领导的团队: $userId');
      await Future.delayed(const Duration(milliseconds: 300));

      _cachedUserLeadingTeams = []; // 空列表作为示例
      notifyListeners();
      return _cachedUserLeadingTeams;
    } catch (e) {
      print('获取用户领导团队失败: $e');
      return [];
    }
  }

  // 从模板创建任务
  Future<bool> createTaskFromTemplate({
    required String teamId,
    required TaskTemplate template,
    required String assigneeId,
    DateTime? deadline,
    Map<String, dynamic>? customData,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('从模板创建任务: ${template.name} for 团队 $teamId');
      await Future.delayed(const Duration(milliseconds: 500));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('从模板创建任务失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 分配任务
  Future<bool> assignTask({
    required String taskId,
    required String assignerId,
    required String assigneeId,
    String? note,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('分配任务 $taskId: $assignerId -> $assigneeId');
      await Future.delayed(const Duration(milliseconds: 300));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('分配任务失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 认领任务
  Future<bool> claimTask({
    required String taskId,
    required String userId,
    String? message,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('用户 $userId 认领任务 $taskId');
      await Future.delayed(const Duration(milliseconds: 300));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('认领任务失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 完成任务
  Future<bool> completeTask({
    required String taskId,
    required String userId,
    String? completionNote,
    List<String>? attachments,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('用户 $userId 完成任务 $taskId');
      await Future.delayed(const Duration(milliseconds: 300));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('完成任务失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 离开团队
  Future<bool> leaveTeam(String teamId, String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('用户 $userId 离开团队 $teamId');
      await Future.delayed(const Duration(milliseconds: 300));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('离开团队失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 删除团队
  Future<bool> deleteTeam(String teamId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('删除团队: $teamId');
      final success = await TeamService.deleteTeam(teamId);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      print('删除团队失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 转移领导权
  Future<bool> transferLeadership({
    required String teamId,
    required String currentLeaderId,
    required String newLeaderId,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('转移团队 $teamId 的领导权: $currentLeaderId -> $newLeaderId');
      await Future.delayed(const Duration(milliseconds: 500));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('转移领导权失败: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 获取公开团队列表
  Future<List<TeamPool>> getPublicTeams() async {
    try {
      print('获取公开团队列表');

      // 目前后端没有获取所有团队的API，暂时返回空列表
      // 后续可以通过用户信息获取相关团队
      await Future.delayed(const Duration(milliseconds: 300));

      // 通知 UI 更新
      notifyListeners();
      return _teamPools;
    } catch (e) {
      print('获取公开团队失败: $e');
      return [];
    }
  } // 搜索团队

  Future<List<TeamPool>> searchTeams(String query) async {
    try {
      print('搜索团队: $query');
      await Future.delayed(const Duration(milliseconds: 300));

      _cachedSearchResults = []; // 空列表作为示例
      notifyListeners();
      return _cachedSearchResults;
    } catch (e) {
      print('搜索团队失败: $e');
      return [];
    }
  }

  @override
  void dispose() {
    print('TeamPoolProvider disposed');
    super.dispose();
  }

  // 🆕 为新创建的团队创建主项目任务
  Future<void> _createMainProjectForTeam(
      String teamId, String teamName, String leaderId) async {
    try {
      // 创建主项目任务
      final mainProject = await TaskService.createTask(
        teamId: teamId,
        title: '$teamName - 主项目',
        description: '$teamName 的主要协作项目。这是团队的核心工作项目，包含所有主要任务和里程碑。',
        estimatedMinutes: 480, // 默认8小时
        priority: TaskPriority.high,
        level: TaskLevel.project,
        tags: ['主项目', '团队协作'],
        baseReward: 50.0,
      );

      if (mainProject != null) {
        print('主项目创建成功: ${mainProject.id}');

        // 创建一些初始子任务
        await _createInitialSubTasks(teamId, mainProject.id, leaderId);
      }
    } catch (e) {
      print('创建主项目任务失败: $e');
      rethrow;
    }
  }

  // 🆕 为主项目创建初始子任务
  Future<void> _createInitialSubTasks(
      String teamId, String parentTaskId, String leaderId) async {
    try {
      // 项目规划任务
      await TaskService.createTask(
        teamId: teamId,
        title: '项目需求分析',
        description: '分析项目需求，制定详细的项目计划和时间安排',
        estimatedMinutes: 120,
        priority: TaskPriority.high,
        level: TaskLevel.task,
        parentTaskId: parentTaskId,
        tags: ['规划', '需求分析'],
        baseReward: 20.0,
      );

      // 团队协调任务
      await TaskService.createTask(
        teamId: teamId,
        title: '团队角色分配',
        description: '确定团队成员的角色和职责分工，建立协作机制',
        estimatedMinutes: 60,
        priority: TaskPriority.medium,
        level: TaskLevel.task,
        parentTaskId: parentTaskId,
        tags: ['团队管理', '角色分配'],
        baseReward: 15.0,
        assignedUsers: [leaderId], // 分配给团队领导者
      );

      // 里程碑设定任务
      await TaskService.createTask(
        teamId: teamId,
        title: '项目里程碑设定',
        description: '设定项目的重要里程碑和检查点，建立项目进度跟踪机制',
        estimatedMinutes: 90,
        priority: TaskPriority.medium,
        level: TaskLevel.task,
        parentTaskId: parentTaskId,
        tags: ['里程碑', '进度管理'],
        baseReward: 18.0,
      );

      print('初始子任务创建完成');
    } catch (e) {
      print('创建初始子任务失败: $e');
      // 不抛出异常，因为这不是关键功能
    }
  }
}
