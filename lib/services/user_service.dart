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
      // 首先尝试本地模拟登录（用于开发测试）
      if (username == 'admin' && password == '123456') {
        return _createLocalUser(username);
      }

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

          // 获取完整用户信息
          final userResponse =
              await ApiService.get('/user/get/$returnedUserUID');
          if (userResponse.statusCode == 200 &&
              userResponse.data['user'] != null) {
            final userData = userResponse.data['user'];
            final user = User(
              id: userData['userUID'].toString(),
              name: _generateUserName(userData['userUID'].toString()),
              createdAt: DateTime.now(),
              stats: const UserStats(),
              profile: UserProfile.fromJson({}),
            );

            // 保存登录信息
            await StorageService.saveLoginInfo(
              userId: user.id,
              username: user.name,
              rememberLogin: true,
            );

            return user;
          }
        } else {
          print('登录失败: ${data['error']}');
        }
      }
      return null;
    } on DioException catch (e) {
      print('登录网络错误: ${e.message}');
      // 如果网络连接失败，提供离线模拟登录
      if (username.isNotEmpty && password.isNotEmpty) {
        print('网络连接失败，使用离线模拟登录');
        return _createLocalUser(username);
      }
      return null;
    } catch (e) {
      print('登录异常: $e');
      // 提供备用登录方式
      if (username.isNotEmpty && password.isNotEmpty) {
        return _createLocalUser(username);
      }
      return null;
    }
  }

  // 创建本地用户（用于测试和离线模式）
  static User _createLocalUser(String username) {
    final userNames = ['张小明', '李小红', '王小华', '刘小强', '陈小美'];
    final randomName = username == 'admin'
        ? '管理员'
        : userNames[username.hashCode % userNames.length];

    return User(
      id: 'local_${username}_${DateTime.now().millisecondsSinceEpoch % 100000}',
      name: randomName,
      avatar: null,
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
          email: 'user@example.com',
          phone: '138****1234',
          wechat: 'dev_user',
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

  // 生成用户显示名称
  static String _generateUserName(String userId) {
    final userNames = ['张小明', '李小红', '王小华', '刘小强', '陈小美', '赵小刚', '孙小丽', '周小鹏'];
    final index = userId.hashCode % userNames.length;
    return userNames[index.abs()];
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
