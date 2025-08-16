// 协作池管理服务（简化版）
// 管理团队协作、默契度计算和动态评分
import '../models/collaboration_pool_model.dart';

class CollaborationPoolService {
  /// 获取用户参与的协作池
  static Future<List<CollaborationPool>> getUserPools(String userId) async {
    try {
      // TODO: 根据用户获取其参与的团队，然后转换为协作池
      // 暂时返回模拟数据
      await Future.delayed(const Duration(milliseconds: 300));
      return _getMockUserPools();
    } catch (e) {
      print('获取用户协作池失败: $e');
      return [];
    }
  }

  /// 获取公开的协作池
  static Future<List<CollaborationPool>> getPublicPools() async {
    try {
      // TODO: 调用后端API获取公开协作池
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockPublicPools();
    } catch (e) {
      print('获取公开协作池失败: $e');
      return [];
    }
  }

  /// 创建协作池
  static Future<CollaborationPool?> createPool({
    required String name,
    required String description,
    required bool isAnonymous,
    required bool isPublic,
    required List<String> memberIds,
    String? createdBy,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return CollaborationPool(
        id: 'pool_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        memberIds: memberIds,
        isAnonymous: isAnonymous,
        createdAt: DateTime.now(),
        createdBy: createdBy ?? 'system',
        tacitScore: 0,
        status: PoolStatus.active,
        progress: const PoolProgress(),
        settings: const PoolSettings(),
        statistics: const PoolStatistics(),
      );
    } catch (e) {
      print('创建协作池失败: $e');
      return null;
    }
  }

  /// 获取协作池详细信息
  static Future<CollaborationPool?> getPool(String poolId) async {
    try {
      // 模拟从后端获取协作池信息
      await Future.delayed(const Duration(milliseconds: 300));

      // 从模拟数据中查找
      List<CollaborationPool> allPools = [
        ..._getMockUserPools(),
        ..._getMockPublicPools(),
      ];

      try {
        return allPools.firstWhere((pool) => pool.id == poolId);
      } catch (e) {
        return _getDefaultPool(poolId);
      }
    } catch (e) {
      print('获取协作池信息失败: $e');
      return null;
    }
  }

  /// 加入协作池
  static Future<bool> joinPool(String poolId, String userId) async {
    try {
      // TODO: 调用团队加入API
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('加入协作池失败: $e');
      return false;
    }
  }

  /// 离开协作池
  static Future<bool> leavePool(String poolId, String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      print('离开协作池失败: $e');
      return false;
    }
  }

  /// 更新协作池统计数据
  static Future<CollaborationPool?> updatePoolStatistics(String poolId) async {
    try {
      CollaborationPool? pool = await getPool(poolId);
      if (pool == null) return null;

      // 模拟更新统计数据
      await Future.delayed(const Duration(milliseconds: 200));

      // 这里可以添加实际的统计计算逻辑
      return pool;
    } catch (e) {
      print('更新协作池统计失败: $e');
      return null;
    }
  }

  /// 计算协作池默契度
  static Future<double> calculatePoolTacitScore(String poolId) async {
    try {
      CollaborationPool? pool = await getPool(poolId);
      if (pool == null) return 0.0;

      // 模拟默契度计算
      return pool.tacitScore.toDouble();
    } catch (e) {
      print('计算默契度失败: $e');
      return 0.0;
    }
  }

  /// 生成协作池报告
  static Future<Map<String, dynamic>> generatePoolReport(String poolId) async {
    try {
      CollaborationPool? pool = await getPool(poolId);
      if (pool == null) {
        return {'error': '协作池不存在'};
      }

      return {
        'poolId': poolId,
        'poolName': pool.name,
        'memberCount': pool.memberIds.length,
        'tacitScore': pool.tacitScore,
        'progress': {
          'totalTasks': pool.progress.totalTasks,
          'completedTasks': pool.progress.completedTasks,
          'inProgressTasks': pool.progress.inProgressTasks,
          'completionRate': pool.progress.totalTasks > 0
              ? pool.progress.completedTasks / pool.progress.totalTasks
              : 0.0,
        },
        'status': pool.status.name,
        'createdAt': pool.createdAt.toIso8601String(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('生成协作池报告失败: $e');
      return {'error': '生成报告失败: $e'};
    }
  }

  /// 搜索公开协作池
  static Future<List<CollaborationPool>> searchPools(String query) async {
    try {
      List<CollaborationPool> allPools = await getPublicPools();
      return allPools
          .where((pool) =>
              pool.name.toLowerCase().contains(query.toLowerCase()) ||
              pool.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('搜索协作池失败: $e');
      return [];
    }
  }

  // ==================== 私有辅助方法 ====================

  static CollaborationPool _getDefaultPool(String poolId) {
    return CollaborationPool(
      id: poolId,
      name: '默认协作池',
      description: '系统默认创建的协作池',
      memberIds: const [],
      isAnonymous: false,
      createdAt: DateTime.now(),
      createdBy: 'system',
      tacitScore: 0,
      status: PoolStatus.active,
      progress: const PoolProgress(),
      settings: const PoolSettings(),
      statistics: const PoolStatistics(),
    );
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
        createdBy: 'user_001',
        tacitScore: 85,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 12,
          completedTasks: 8,
          inProgressTasks: 2,
        ),
        settings: const PoolSettings(),
        statistics: const PoolStatistics(),
      ),
      CollaborationPool(
        id: 'pool_002',
        name: '小组作业协作',
        description: '期末项目分工协作',
        memberIds: const ['user_001', 'user_005', 'user_006'],
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        createdBy: 'user_001',
        tacitScore: 78,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 15,
          completedTasks: 9,
          inProgressTasks: 3,
        ),
        settings: const PoolSettings(),
        statistics: const PoolStatistics(),
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
        createdBy: 'system',
        tacitScore: 72,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 20,
          completedTasks: 15,
          inProgressTasks: 3,
        ),
        settings: const PoolSettings(),
        statistics: const PoolStatistics(),
      ),
      CollaborationPool(
        id: 'pool_public_002',
        name: '社区志愿活动',
        description: '周末公园清洁志愿活动组织',
        memberIds: List.generate(8, (i) => 'volunteer_$i'),
        isAnonymous: false,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'volunteer_1',
        tacitScore: 88,
        status: PoolStatus.active,
        progress: const PoolProgress(
          totalTasks: 18,
          completedTasks: 12,
          inProgressTasks: 4,
        ),
        settings: const PoolSettings(),
        statistics: const PoolStatistics(),
      ),
    ];
  }
}
