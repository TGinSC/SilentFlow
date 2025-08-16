// 协作池状态管理
import 'package:flutter/foundation.dart';
import '../models/collaboration_pool_model.dart';
import '../services/collaboration_pool_service.dart';

class CollaborationPoolProvider with ChangeNotifier {
  List<CollaborationPool> _userPools = [];
  List<CollaborationPool> _publicPools = [];
  List<CollaborationPool> _completedPools = [];
  Map<String, PoolProgress> _poolProgresses = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CollaborationPool> get userPools => _userPools;
  List<CollaborationPool> get publicPools => _publicPools;
  List<CollaborationPool> get completedPools => _completedPools;
  Map<String, PoolProgress> get poolProgresses => _poolProgresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  // 获取用户参与的协作池
  Future<void> loadUserPools(String userId) async {
    try {
      setLoading(true);
      clearError();

      final pools = await CollaborationPoolService.getUserPools(userId);
      _userPools =
          pools.where((pool) => pool.status == PoolStatus.active).toList();
      _completedPools =
          pools.where((pool) => pool.status == PoolStatus.completed).toList();

      notifyListeners();
    } catch (e) {
      setError('加载协作池失败: $e');
    } finally {
      setLoading(false);
    }
  }

  // 获取公开协作池
  Future<void> loadPublicPools() async {
    try {
      final pools = await CollaborationPoolService.getPublicPools();
      _publicPools = pools;
      notifyListeners();
    } catch (e) {
      setError('加载公开协作池失败: $e');
    }
  }

  // 创建新协作池
  Future<CollaborationPool?> createPool({
    required String name,
    required String description,
    required bool isAnonymous,
    required bool isPublic,
    List<String> memberIds = const [],
    String? createdBy,
  }) async {
    try {
      setLoading(true);
      clearError();

      final pool = await CollaborationPoolService.createPool(
        name: name,
        description: description,
        isAnonymous: isAnonymous,
        isPublic: isPublic,
        memberIds: memberIds,
        createdBy: createdBy,
      );

      if (pool != null) {
        _userPools.add(pool);
        notifyListeners();
      }

      return pool;
    } catch (e) {
      setError('创建协作池失败: $e');
      return null;
    } finally {
      setLoading(false);
    }
  }

  // 加入协作池
  Future<bool> joinPool(String poolId, String userId) async {
    try {
      setLoading(true);
      clearError();

      final success = await CollaborationPoolService.joinPool(poolId, userId);

      if (success) {
        // 从公开池移到用户池
        final pool = _publicPools.firstWhere((p) => p.id == poolId);
        _publicPools.remove(pool);
        _userPools.add(pool);
        notifyListeners();
      }

      return success;
    } catch (e) {
      setError('加入协作池失败: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 获取协作池进度
  Future<PoolProgress?> getPoolProgress(String poolId) async {
    try {
      if (_poolProgresses.containsKey(poolId)) {
        return _poolProgresses[poolId];
      }

      // 通过获取协作池详细信息来获取进度
      final pool = await CollaborationPoolService.getPool(poolId);
      if (pool != null) {
        _poolProgresses[poolId] = pool.progress;
        notifyListeners();
        return pool.progress;
      }

      return null;
    } catch (e) {
      setError('获取协作池进度失败: $e');
      return null;
    }
  }

  // 根据ID获取协作池
  CollaborationPool? getPoolById(String poolId) {
    try {
      return [
        ..._userPools,
        ..._publicPools,
        ..._completedPools,
      ].firstWhere((pool) => pool.id == poolId);
    } catch (e) {
      return null;
    }
  }

  // 刷新所有数据
  Future<void> refreshAll(String userId) async {
    await Future.wait([loadUserPools(userId), loadPublicPools()]);
  }
}
