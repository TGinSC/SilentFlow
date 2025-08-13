// 用户相关的API服务
// TODO: 连接后端用户管理接口
import '../models/user_model.dart';

class UserService {
  // 获取用户信息
  static Future<User?> getUserProfile(String userId) async {
    try {
      // TODO: 调用后端API获取用户信息
      // final response = await ApiService.get('/users/$userId');
      // return User.fromJson(response.data);

      // 临时返回模拟数据
      return _getMockUser(userId);
    } catch (e) {
      print('获取用户信息失败: $e');
      return null;
    }
  }

  // 更新用户信息
  static Future<bool> updateUserProfile(User user) async {
    try {
      // TODO: 调用后端API更新用户信息
      // final response = await ApiService.put('/users/${user.id}', data: user.toJson());
      // return response.statusCode == 200;

      // 临时返回成功
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('更新用户信息失败: $e');
      return false;
    }
  }

  // 获取用户统计信息
  static Future<UserStats?> getUserStats(String userId) async {
    try {
      // TODO: 调用后端API获取用户统计
      // final response = await ApiService.get('/users/$userId/stats');
      // return UserStats.fromJson(response.data);

      // 临时返回模拟数据
      return _getMockUserStats();
    } catch (e) {
      print('获取用户统计失败: $e');
      return null;
    }
  }

  // 用户登录
  static Future<User?> login(String username, String password) async {
    try {
      // TODO: 调用后端登录接口
      // final response = await ApiService.post('/auth/login', data: {
      //   'username': username,
      //   'password': password,
      // });
      // return User.fromJson(response.data['user']);

      // 临时返回模拟用户
      await Future.delayed(const Duration(seconds: 1));
      return _getMockUser('user_001');
    } catch (e) {
      print('登录失败: $e');
      return null;
    }
  }

  // 用户注册
  static Future<User?> register(String username, String password) async {
    try {
      // TODO: 调用后端注册接口
      // final response = await ApiService.post('/auth/register', data: {
      //   'username': username,
      //   'password': password,
      // });
      // return User.fromJson(response.data['user']);

      // 临时返回模拟用户
      await Future.delayed(const Duration(seconds: 1));
      return _getMockUser('user_${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      print('注册失败: $e');
      return null;
    }
  }

  // 获取认证Token（预留）
  static String? getAuthToken() {
    // TODO: 从本地存储获取token
    return null;
  }

  // ==================== 模拟数据 ====================
  static User _getMockUser(String userId) {
    return User(
      id: userId,
      name: '静默协作者',
      createdAt: DateTime.now().subtract(const Duration(days: 32)),
      isAnonymous: false,
      stats: const UserStats(
        completedTasks: 47,
        joinedPools: 8,
        averageTacitScore: 85.0,
        efficiencyTags: ['收尾专家', '时间规划师', '效率达人'],
      ),
    );
  }

  static UserStats _getMockUserStats() {
    return const UserStats(
      completedTasks: 47,
      joinedPools: 8,
      averageTacitScore: 85.0,
      efficiencyTags: ['收尾专家', '时间规划师', '效率达人'],
    );
  }
}
