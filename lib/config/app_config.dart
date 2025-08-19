// 应用配置常量
class AppConfig {
  // API配置
  static const String baseUrl = 'http://47.95.200.35:8081'; // 更新为新的生产服务器
  static const Duration requestTimeout = Duration(seconds: 10);

  // 本地存储键名
  static const String userTokenKey = 'user_token';
  static const String userIdKey = 'user_id';
  static const String lastLoginKey = 'last_login';

  // 默契值计算配置
  static const int taskCompletionBonus = 5;
  static const int timingMatchBonus = 10;
  static const int obstacleReportBonus = 2;
  static const int conflictPenalty = -3;

  // UI配置
  static const double cardBorderRadius = 12.0;
  static const double defaultPadding = 16.0;

  // 通知设置
  static const List<String> criticalNotificationTypes = [
    'taskConflict',
    'dependencyChange',
    'criticalTaskComplete',
  ];

  // 协作池设置
  static const int maxMembersDefault = 10;
  static const int minTasksForAnalytics = 5;
}

// 应用主题常量
class AppTheme {
  static const silentBlue = 0xFF3F51B5; // 静默蓝
  static const tacitGreen = 0xFF4CAF50; // 默契绿
  static const efficiencyOrange = 0xFFFF9800; // 效率橙
  static const conflictRed = 0xFFE53935; // 冲突红
}

// 任务状态常量
class TaskStatusConstants {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String blocked = 'blocked';
  static const String cancelled = 'cancelled';
}

// 协作池状态常量
class PoolStatusConstants {
  static const String active = 'active';
  static const String completed = 'completed';
  static const String archived = 'archived';
}
