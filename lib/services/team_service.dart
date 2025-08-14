// 团队相关的API服务
// 连接后端团队管理接口
import 'api_service.dart';
import 'package:dio/dio.dart';

class TeamService {
  // 获取团队信息 - GET /team/get/:teamuid
  static Future<Map<String, dynamic>?> getTeamInfo(String teamId) async {
    try {
      final response = await ApiService.get('/team/get/$teamId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['team'] != null) {
          return data['team'];
        }
      }
      return null;
    } on DioException catch (e) {
      print('获取团队信息失败: ${e.message}');
      return null;
    } catch (e) {
      print('获取团队信息异常: $e');
      return null;
    }
  }

  // 创建团队 - POST /team/create
  static Future<String?> createTeam({
    required String teamId,
    required String teamPassword,
    required String teamLeader,
  }) async {
    try {
      final response = await ApiService.post('/team/create', data: {
        'teamUID': int.parse(teamId),
        'teamPassword': int.parse(teamPassword), // API文档显示是数字类型
        'teamLeader': int.parse(teamLeader),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return data['teamUID'].toString();
        } else {
          print('创建团队失败: ${data['message'] ?? data['error']}');
        }
      }
      return null;
    } on DioException catch (e) {
      print('创建团队失败: ${e.message}');
      return null;
    } catch (e) {
      print('创建团队异常: $e');
      return null;
    }
  }

  // 更新团队 - POST /team/updata
  static Future<bool> updateTeam({
    required String teamId,
    required Map<String, dynamic> changedThings,
  }) async {
    try {
      final response = await ApiService.post('/team/updata', data: {
        'teamUID': int.parse(teamId),
        'ChangedThings': changedThings, // 根据API文档的命名
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('更新团队失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('更新团队失败: ${e.message}');
      return false;
    } catch (e) {
      print('更新团队异常: $e');
      return false;
    }
  }

  // 删除团队 - POST /team/delete
  static Future<bool> deleteTeam(String teamId) async {
    try {
      final response = await ApiService.post('/team/delete', data: {
        'teamUID': int.parse(teamId),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('删除团队失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('删除团队失败: ${e.message}');
      return false;
    } catch (e) {
      print('删除团队异常: $e');
      return false;
    }
  }

  // 更新团队密码 - POST /team/updatapassword
  static Future<bool> updateTeamPassword({
    required String teamId,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post('/team/updatapassword', data: {
        'teamUID': int.parse(teamId),
        'teamPassword': int.parse(newPassword), // API文档显示是数字类型
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('更新团队密码失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('更新团队密码失败: ${e.message}');
      return false;
    } catch (e) {
      print('更新团队密码异常: $e');
      return false;
    }
  }
}
