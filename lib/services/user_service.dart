// 用户相关的API服务
// 连接后端用户管理接口
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'package:dio/dio.dart';

class UserService {
  // 用户登录 - POST /user/signin
  static Future<User?> login(String username, String password) async {
    try {
      // 尝试将用户名转换为数字，如果失败则使用0作为测试
      int userUID;
      try {
        userUID = int.parse(username);
      } catch (e) {
        print('用户名不是数字格式，使用123456作为测试');
        userUID = 123456; // 使用一个测试ID
      }

      print('尝试登录 - userUID: $userUID, password: $password');

      final response = await ApiService.post('/user/signin', data: {
        'userUID': userUID,
        'userPassword': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        print('登录响应: $data');

        if (data['error'] == null || data['error'].toString().isEmpty) {
          final returnedUserUID = data['userUID'];

          // 根据后端返回的userUID获取完整用户信息
          final userInfo = await getUserProfile(returnedUserUID.toString());
          if (userInfo != null) {
            // 保存登录信息到本地
            await StorageService.saveLoginInfo(
              userId: userInfo.id,
              username: userInfo.name,
              rememberLogin: true,
            );

            return userInfo;
          }
        } else {
          print('登录失败: ${data['error']}');
        }
      }
      return null;
    } on DioException catch (e) {
      print('登录网络错误: ${e.message}');
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        print('错误详情: ${errorData}');
      }
      return null;
    } catch (e) {
      print('登录异常: $e');
      return null;
    }
  }

  // 用户注册 - POST /user/signup
  static Future<User?> register(String username, String password) async {
    try {
      // 生成一个随机的用户ID或使用时间戳
      final userUID = DateTime.now().millisecondsSinceEpoch % 1000000;

      print('尝试注册 - userUID: $userUID, password: $password');

      final response = await ApiService.post('/user/signup', data: {
        'userUID': userUID,
        'userPassword': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        print('注册响应: $data');

        if (data['error'] == null || data['error'].toString().isEmpty) {
          final returnedUserUID = data['userUID'];

          // 注册成功后获取用户信息
          final userInfo = await getUserProfile(returnedUserUID.toString());
          if (userInfo != null) {
            // 保存登录信息到本地
            await StorageService.saveLoginInfo(
              userId: userInfo.id,
              username: userInfo.name,
              rememberLogin: true,
            );

            return userInfo;
          }
        } else {
          print('注册失败: ${data['error']}');
        }
      }
      return null;
    } on DioException catch (e) {
      print('注册网络错误: ${e.message}');
      if (e.response != null && e.response?.data != null) {
        final errorData = e.response?.data;
        print('错误详情: ${errorData}');
      }
      return null;
    } catch (e) {
      print('注册异常: $e');
      return null;
    }
  }

  // 获取用户信息 - GET /user/get/:uid
  static Future<User?> getUserProfile(String userId) async {
    try {
      final response = await ApiService.get('/user/get/$userId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['user'] != null) {
          final userInfo = data['user'];

          // 根据后端返回的数据结构创建User对象
          // 注意：API文档中字段名是 TeamsBelong 和 messions
          return User(
            id: userInfo['userUID'].toString(),
            name: 'User ${userInfo['userUID']}', // 使用userUID作为显示名
            createdAt: DateTime.now(), // 后端暂无创建时间字段
            isAnonymous: false,
            stats: UserStats(
              completedTasks:
                  userInfo['messions']?.length ?? 0, // 使用 messions 长度
              joinedPools:
                  userInfo['TeamsBelong']?.length ?? 0, // 使用 TeamsBelong 长度
              averageTacitScore: userInfo['TeamsBelong']?.isNotEmpty == true
                  ? userInfo['TeamsBelong'][0]['score']?.toDouble() ?? 0.0
                  : 0.0,
              efficiencyTags: [], // 后端暂无此数据
            ),
            profile: const UserProfile(
              workStyle: WorkStyle(
                communicationStyle: 'direct',
                workPace: 'stable',
                preferredCollaborationMode: 'team',
                workingHours: ['9:00-18:00'],
                stressHandling: 'normal',
                feedbackStyle: 'constructive',
              ),
              availability: AvailabilityInfo(
                weeklySchedule: {
                  'Monday': ['9:00-18:00']
                },
                timezone: 'UTC+8',
                maxHoursPerWeek: 40,
                busyPeriods: [],
              ),
              contact: ContactInfo(
                email: 'user@example.com',
                phone: '',
              ),
            ),
          );
        }
      }
      return null;
    } on DioException catch (e) {
      print('获取用户信息失败: ${e.message}');
      return null;
    } catch (e) {
      print('获取用户信息异常: $e');
      return null;
    }
  }

  // 更新用户信息 - POST /user/updata (注意：API文档中是updata不是update)
  static Future<bool> updateUserProfile(User user) async {
    try {
      final response = await ApiService.post('/user/updata', data: {
        'userUID': int.parse(user.id),
        'userPassword': '', // 需要提供密码，实际使用时需要用户输入
        'TeamsBelong': [], // 根据实际需求填充，注意大写T
        'messions': [], // 注意是messions不是missions
        'teamsOwn': [],
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          // 更新本地存储的用户信息
          await StorageService.updateUserInfo(user.toJson());
          return true;
        } else {
          print('更新用户信息失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('更新用户信息失败: ${e.message}');
      return false;
    } catch (e) {
      print('更新用户信息异常: $e');
      return false;
    }
  }

  // 获取用户统计信息（从用户信息中提取）
  static Future<UserStats?> getUserStats(String userId) async {
    try {
      final user = await getUserProfile(userId);
      return user?.stats;
    } catch (e) {
      print('获取用户统计失败: $e');
      return null;
    }
  }

  // 加入团队 - POST /user/jointeam
  static Future<bool> joinTeam(
      String userId, String teamId, String teamPassword) async {
    try {
      final response = await ApiService.post('/user/jointeam', data: {
        'userUID': int.parse(userId),
        'teamUID': int.parse(teamId),
        'teamPassword': int.parse(teamPassword), // API文档显示是数字类型
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('加入团队失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('加入团队失败: ${e.message}');
      return false;
    } catch (e) {
      print('加入团队异常: $e');
      return false;
    }
  }

  // 离开团队 - POST /user/leaveteam
  static Future<bool> leaveTeam(String userId, String teamId) async {
    try {
      final response = await ApiService.post('/user/leaveteam', data: {
        'userUID': int.parse(userId),
        'teamUID': int.parse(teamId),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('离开团队失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('离开团队失败: ${e.message}');
      return false;
    } catch (e) {
      print('离开团队异常: $e');
      return false;
    }
  }

  // 更新密码 - POST /user/updatepassword
  static Future<bool> updatePassword(String userId, String newPassword) async {
    try {
      final response = await ApiService.post('/user/updatepassword', data: {
        'userUID': int.parse(userId),
        'userPassword': newPassword,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('更新密码失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('更新密码失败: ${e.message}');
      return false;
    } catch (e) {
      print('更新密码异常: $e');
      return false;
    }
  }

  // 删除用户 - POST /user/delete
  static Future<bool> deleteUser(String userId) async {
    try {
      final response = await ApiService.post('/user/delete', data: {
        'userUID': int.parse(userId),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          // 删除成功后清除本地存储
          await StorageService.clearLoginInfo();
          return true;
        } else {
          print('删除用户失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('删除用户失败: ${e.message}');
      return false;
    } catch (e) {
      print('删除用户异常: $e');
      return false;
    }
  }

  // 用户登出
  static Future<void> logout() async {
    try {
      // 清除本地存储的登录信息
      await StorageService.clearLoginInfo();
    } catch (e) {
      print('登出失败: $e');
    }
  }

  // 自动登录检查
  static Future<User?> checkAutoLogin() async {
    try {
      final savedUser = await StorageService.getSavedUserInfo();
      if (savedUser != null && !await StorageService.isLoginExpired()) {
        final userId = savedUser['userId'];
        if (userId != null) {
          // 验证用户信息是否有效
          final userProfile = await getUserProfile(userId);
          if (userProfile != null) {
            return userProfile;
          }
        }
      }
    } catch (e) {
      print('自动登录检查失败: $e');
    }

    // 用户信息无效或过期，清除本地登录信息
    await StorageService.clearLoginInfo();
    return null;
  }

  // 获取认证Token（保持兼容性）
  static Future<String?> getAuthToken() async {
    return await StorageService.getAuthToken();
  }
}
