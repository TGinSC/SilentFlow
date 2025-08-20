// 全局应用状态管理
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AppProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  // 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // 设置错误信息
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 用户登录
  Future<bool> login(String username, String password) async {
    try {
      setLoading(true);
      clearError();

      final user = await UserService.login(username, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        setError('登录失败，请检查用户名和密码');
        return false;
      }
    } catch (e) {
      setError('登录过程中发生错误: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 用户注册
  Future<bool> register(String username, String password) async {
    try {
      setLoading(true);
      clearError();

      final user = await UserService.register(username, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      } else {
        setError('注册失败，请稍后重试');
        return false;
      }
    } catch (e) {
      setError('注册过程中发生错误: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 用户登出
  void logout() {
    _currentUser = null;
    clearError();
    notifyListeners();
  }

  // 更新用户信息
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      setLoading(true);

      final success = await UserService.updateUserProfile(updatedUser);
      if (success) {
        _currentUser = updatedUser;
        notifyListeners();
        return true;
      } else {
        setError('更新用户信息失败');
        return false;
      }
    } catch (e) {
      setError('更新用户信息时发生错误: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 初始化应用（检查是否已登录等）
  Future<void> initialize() async {
    try {
      setLoading(true);

      // 检查本地存储的登录状态
      await _checkLocalLoginStatus();

      await Future.delayed(const Duration(milliseconds: 500)); // 模拟初始化时间
    } catch (e) {
      setError('初始化应用失败: $e');
    } finally {
      setLoading(false);
    }
  }

  // 检查本地登录状态
  Future<void> _checkLocalLoginStatus() async {
    try {
      // TODO: 从本地存储检查是否有保存的登录token
      // final token = await StorageService.getLoginToken();
      // if (token != null) {
      //   // 尝试使用token获取用户信息
      //   final user = await UserService.getUserByToken(token);
      //   if (user != null) {
      //     _currentUser = user;
      //     notifyListeners();
      //   }
      // }

      // 暂时不自动登录，让用户手动登录
      // 注释掉自动创建测试用户的代码
      print('检查登录状态：未找到本地登录信息');
    } catch (e) {
      print('检查登录状态失败: $e');
    }
  }

  // 创建测试用户（仅用于登录后）
  User createTestUser() {
    return User(
      id: 'test_user_001',
      name: '张小明',
      avatar: null, // 没有头像，将显示默认图标
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      isAnonymous: false,
      stats: const UserStats(
        completedTasks: 12,
        joinedPools: 5,
        contributionScore: 85.5,
        averageTacitScore: 92.0,
        efficiencyTags: ['高效', '积极', '协作'],
        totalSubTasks: 45,
        completedSubTasks: 42,
        onTimeRate: 0.93,
        earlyCompletions: 8,
        lateCompletions: 1,
      ),
      profile: UserProfile(
        bio: '热爱技术，喜欢团队协作，擅长前端开发和用户体验设计。',
        department: '技术部',
        role: '前端工程师',
        skills: [
          const UserSkill(
            name: 'Flutter',
            level: 4,
            tags: ['移动开发', 'UI/UX'],
            experienceYears: 2,
          ),
          const UserSkill(
            name: 'React',
            level: 5,
            tags: ['前端开发', 'Web'],
            experienceYears: 3,
          ),
          const UserSkill(
            name: 'UI设计',
            level: 3,
            tags: ['设计', '用户体验'],
            experienceYears: 2,
          ),
        ],
        interests: ['技术分享', '用户体验', '移动开发', '团队协作'],
        workStyle: const WorkStyle(
          communicationStyle: 'direct',
          workPace: 'stable',
          preferredCollaborationMode: 'team',
          workingHours: ['9:00-18:00'],
          stressHandling: 'normal',
          feedbackStyle: 'constructive',
        ),
        availability: const AvailabilityInfo(
          weeklySchedule: {
            'Monday': ['9:00-12:00', '14:00-18:00'],
            'Tuesday': ['9:00-12:00', '14:00-18:00'],
            'Wednesday': ['9:00-12:00', '14:00-18:00'],
            'Thursday': ['9:00-12:00', '14:00-18:00'],
            'Friday': ['9:00-12:00', '14:00-17:00'],
          },
          timezone: 'UTC+8',
          maxHoursPerWeek: 40,
          busyPeriods: ['会议时间: 周二14:00-15:00'],
        ),
        preferredTaskTypes: ['UI开发', '前端实现', '用户体验优化', '代码审查'],
        contact: const ContactInfo(
          email: 'zhangxiaoming@example.com',
          phone: '138****1234',
          wechat: 'zxm_dev',
        ),
        achievements: [
          Achievement(
            id: 'achievement_001',
            title: '高效协作者',
            description: '在团队协作中表现出色，完成任务及时率达90%以上',
            achievedAt: DateTime.now().subtract(const Duration(days: 10)),
            category: '协作',
            points: 100,
          ),
          Achievement(
            id: 'achievement_002',
            title: '技术专家',
            description: '在Flutter开发方面展现专业技能',
            achievedAt: DateTime.now().subtract(const Duration(days: 20)),
            category: '技术',
            points: 150,
          ),
        ],
      ),
    );
  }
}
