// 协作池相关的API服务
// TODO: 连接后端协作池管理接口
import '../models/collaboration_pool_model.dart';

class CollaborationPoolService {
  // 获取用户参与的协作池
  static Future<List<CollaborationPool>> getUserPools(String userId) async {
    try {
      // TODO: 调用后端API获取用户的协作池
      // final response = await ApiService.get('/users/$userId/pools');
      // return (response.data as List)
      //     .map((json) => CollaborationPool.fromJson(json))
      //     .toList();

      // 临时返回模拟数据
      await Future.delayed(const Duration(milliseconds: 300));
      return _getMockUserPools();
    } catch (e) {
      print('获取用户协作池失败: $e');
      return [];
    }
  }

  // 获取公开的协作池
  static Future<List<CollaborationPool>> getPublicPools() async {
    try {
      // TODO: 调用后端API获取公开协作池
      // final response = await ApiService.get('/pools/public');
      // return (response.data as List)
      //     .map((json) => CollaborationPool.fromJson(json))
      //     .toList();

      // 临时返回模拟数据
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockPublicPools();
    } catch (e) {
      print('获取公开协作池失败: $e');
      return [];
    }
  }

  // 创建新的协作池
  static Future<CollaborationPool?> createPool({
    required String name,
    required String description,
    required bool isAnonymous,
    required bool isPublic,
    required int maxMembers,
  }) async {
    try {
      // TODO: 调用后端API创建协作池
      // final response = await ApiService.post('/pools', data: {
      //   'name': name,
      //   'description': description,
      //   'isAnonymous': isAnonymous,
      //   'isPublic': isPublic,
      //   'maxMembers': maxMembers,
      // });
      // return CollaborationPool.fromJson(response.data);

      // 临时返回模拟创建结果
      await Future.delayed(const Duration(seconds: 1));
      return CollaborationPool(
        id: 'pool_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        memberIds: const ['current_user_id'], // 创建者自动加入
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
        tacitScore: 0,
        status: PoolStatus.active,
        progress: const PoolProgress(),
      );
    } catch (e) {
      print('创建协作池失败: $e');
      return null;
    }
  }

  // 加入协作池
  static Future<bool> joinPool(String poolId, String userId) async {
    try {
      // TODO: 调用后端API加入协作池
      // final response = await ApiService.post('/pools/$poolId/join', data: {
      //   'userId': userId,
      // });
      // return response.statusCode == 200;

      // 临时返回成功
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('加入协作池失败: $e');
      return false;
    }
  }

  // 获取协作池进度
  static Future<PoolProgress?> getPoolProgress(String poolId) async {
    try {
      // TODO: 调用后端API获取协作池进度
      // final response = await ApiService.get('/pools/$poolId/progress');
      // return PoolProgress.fromJson(response.data);

      // 临时返回模拟数据
      await Future.delayed(const Duration(milliseconds: 200));
      return _getMockPoolProgress();
    } catch (e) {
      print('获取协作池进度失败: $e');
      return null;
    }
  }

  // ==================== 模拟数据 ====================
  static List<CollaborationPool> _getMockUserPools() {
    return [
      CollaborationPool(
        id: 'pool_001',
        name: '宿舍清洁分工',
        description: '每周轮流打扫，静默认领任务',
        memberIds: const ['user_001', 'user_002', 'user_003', 'user_004'],
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        tacitScore: 85,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 12,
          completedTasks: 8,
          inProgressTasks: 2,
        ),
      ),
      CollaborationPool(
        id: 'pool_002',
        name: '小组作业协作',
        description: '期末项目分工协作',
        memberIds: const ['user_001', 'user_005', 'user_006'],
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        tacitScore: 78,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 15,
          completedTasks: 9,
          inProgressTasks: 3,
        ),
      ),
    ];
  }

  static List<CollaborationPool> _getMockPublicPools() {
    return [
      CollaborationPool(
        id: 'pool_public_001',
        name: '图书馆座位协调',
        description: '匿名协作，避免占座冲突',
        memberIds: List.generate(12, (i) => 'anonymous_user_$i'),
        isAnonymous: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        tacitScore: 72,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 20,
          completedTasks: 15,
          inProgressTasks: 3,
        ),
      ),
      CollaborationPool(
        id: 'pool_public_002',
        name: '社区志愿活动',
        description: '周末公园清洁志愿活动组织',
        memberIds: List.generate(8, (i) => 'volunteer_$i'),
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        tacitScore: 88,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 18,
          completedTasks: 12,
          inProgressTasks: 4,
        ),
      ),
    ];
  }

  static PoolProgress _getMockPoolProgress() {
    return const PoolProgress(
      totalTasks: 12,
      completedTasks: 8,
      inProgressTasks: 2,
    );
  }
}
