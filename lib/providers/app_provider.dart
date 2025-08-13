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
      // TODO: 检查本地存储的登录状态
      // 如果有保存的token，尝试获取用户信息
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟初始化时间
    } catch (e) {
      setError('初始化应用失败: $e');
    } finally {
      setLoading(false);
    }
  }
}
