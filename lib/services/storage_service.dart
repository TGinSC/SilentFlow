import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _keyUserId = 'user_id';
  static const String _keyUserInfo = 'user_info';
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRememberLogin = 'remember_login';
  static const String _keyLastLoginTime = 'last_login_time';

  // 获取SharedPreferences实例
  static Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }

  // 保存用户登录信息
  static Future<void> saveLoginInfo({
    required String userId,
    required String username,
    String? authToken,
    bool rememberLogin = false,
  }) async {
    final prefs = await _prefs;

    // 保存基础信息
    await prefs.setString(_keyUserId, userId);
    await prefs.setBool(_keyRememberLogin, rememberLogin);
    await prefs.setString(_keyLastLoginTime, DateTime.now().toIso8601String());

    // 如果用户选择记住登录，保存用户名（不保存密码）
    if (rememberLogin) {
      final userInfo = {
        'username': username,
        'userId': userId,
      };
      await prefs.setString(_keyUserInfo, json.encode(userInfo));
    }

    // 保存认证Token
    if (authToken != null) {
      await prefs.setString(_keyAuthToken, authToken);
    }
  }

  // 获取保存的用户信息
  static Future<Map<String, String>?> getSavedUserInfo() async {
    final prefs = await _prefs;
    final userInfoStr = prefs.getString(_keyUserInfo);

    if (userInfoStr != null) {
      final userInfo = json.decode(userInfoStr) as Map<String, dynamic>;
      return {
        'username': userInfo['username'] ?? '',
        'userId': userInfo['userId'] ?? '',
      };
    }
    return null;
  }

  // 获取认证Token
  static Future<String?> getAuthToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAuthToken);
  }

  // 检查是否记住登录
  static Future<bool> shouldRememberLogin() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyRememberLogin) ?? false;
  }

  // 获取当前用户ID
  static Future<String?> getCurrentUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserId);
  }

  // 清除登录信息（退出登录时调用）
  static Future<void> clearLoginInfo() async {
    final prefs = await _prefs;
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserInfo);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyRememberLogin);
    await prefs.remove(_keyLastLoginTime);
  }

  // 更新用户信息（不包含敏感数据）
  static Future<void> updateUserInfo(Map<String, dynamic> userInfo) async {
    final prefs = await _prefs;
    final currentUserInfo = await getSavedUserInfo();

    if (currentUserInfo != null) {
      final updatedInfo = {
        ...currentUserInfo,
        'userProfile': userInfo,
      };
      await prefs.setString(_keyUserInfo, json.encode(updatedInfo));
    }
  }

  // 更新认证Token
  static Future<void> updateAuthToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAuthToken, token);
  }

  // 检查登录是否过期
  static Future<bool> isLoginExpired() async {
    final prefs = await _prefs;
    final lastLoginStr = prefs.getString(_keyLastLoginTime);

    if (lastLoginStr == null) return true;

    final lastLogin = DateTime.parse(lastLoginStr);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    // 设置登录有效期为7天
    return difference.inDays > 7;
  }

  // 通用数据保存方法
  Future<void> saveData(String key, dynamic data) async {
    final prefs = await StorageService._prefs;
    final jsonString = json.encode(data);
    await prefs.setString(key, jsonString);
  }

  // 通用数据获取方法
  Future<dynamic> getData(String key) async {
    final prefs = await StorageService._prefs;
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }

  // 删除数据
  Future<void> removeData(String key) async {
    final prefs = await StorageService._prefs;
    await prefs.remove(key);
  }

  // 检查数据是否存在
  Future<bool> hasData(String key) async {
    final prefs = await StorageService._prefs;
    return prefs.containsKey(key);
  }
}
