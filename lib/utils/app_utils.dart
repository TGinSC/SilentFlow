// 日期时间格式化工具
import 'package:intl/intl.dart';

class DateUtils {
  static final _timeFormat = DateFormat('HH:mm');
  static final _dateFormat = DateFormat('yyyy-MM-dd');
  static final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final _relativeFormat = DateFormat('MM-dd HH:mm');

  // 格式化时间为相对时间
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return _relativeFormat.format(dateTime);
    }
  }

  // 格式化任务持续时间
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}小时${minutes}分钟';
    } else {
      return '${minutes}分钟';
    }
  }

  // 判断是否为今天
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  // 判断是否为本周
  static bool isThisWeek(DateTime dateTime) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return dateTime.isAfter(startOfWeek) && dateTime.isBefore(endOfWeek);
  }
}

// 默契值计算工具
class TacitScoreCalculator {
  // 计算任务完成的默契值奖励
  static int calculateTaskCompletionScore({
    required Duration estimatedDuration,
    required Duration actualDuration,
    required bool hadObstacles,
  }) {
    int baseScore = 5; // 基础完成分

    // 时间准确性奖励
    final accuracyRatio =
        estimatedDuration.inMinutes / actualDuration.inMinutes;
    if (accuracyRatio >= 0.8 && accuracyRatio <= 1.2) {
      baseScore += 3; // 时间预估准确
    }

    // 无障碍完成奖励
    if (!hadObstacles) {
      baseScore += 2;
    }

    return baseScore;
  }

  // 计算协作衔接默契值
  static int calculateCollaborationScore({
    required DateTime task1CompleteTime,
    required DateTime task2StartTime,
    required bool isDependentTask,
  }) {
    if (!isDependentTask) return 0;

    final gap = task2StartTime.difference(task1CompleteTime);

    if (gap.inMinutes <= 5) {
      return 10; // 完美衔接
    } else if (gap.inMinutes <= 30) {
      return 5; // 良好衔接
    } else if (gap.inHours <= 2) {
      return 2; // 正常衔接
    } else {
      return 0; // 无衔接奖励
    }
  }

  // 计算障碍报告的贡献分
  static int calculateObstacleReportScore(String obstacleType) {
    switch (obstacleType) {
      case 'missingTools':
      case 'dependencyBlocked':
        return 3; // 关键信息
      case 'needHelp':
      case 'timeConflict':
        return 2; // 重要信息
      default:
        return 1; // 一般信息
    }
  }
}

// 效率标签生成工具
class EfficiencyTagGenerator {
  // 根据用户行为生成效率标签
  static List<String> generateTags({
    required int completedTasks,
    required double avgCompletionRatio,
    required int obstacleReports,
    required int taskConflicts,
    required Map<String, int> tasksByTimeSlot,
  }) {
    List<String> tags = [];

    // 完成率相关标签
    if (avgCompletionRatio >= 0.95) {
      tags.add('完成专家');
    } else if (avgCompletionRatio >= 0.85) {
      tags.add('可靠执行者');
    }

    // 障碍处理标签
    if (obstacleReports > completedTasks * 0.8) {
      tags.add('问题发现者');
    } else if (obstacleReports < completedTasks * 0.2) {
      tags.add('顺利推进者');
    }

    // 冲突处理标签
    if (taskConflicts == 0 && completedTasks >= 10) {
      tags.add('协调高手');
    } else if (taskConflicts < completedTasks * 0.1) {
      tags.add('默契合作者');
    }

    // 时间偏好标签
    final morningTasks = tasksByTimeSlot['morning'] ?? 0;
    final afternoonTasks = tasksByTimeSlot['afternoon'] ?? 0;
    final eveningTasks = tasksByTimeSlot['evening'] ?? 0;

    final maxTasks = [
      morningTasks,
      afternoonTasks,
      eveningTasks,
    ].reduce((a, b) => a > b ? a : b);

    if (maxTasks == morningTasks && morningTasks >= completedTasks * 0.6) {
      tags.add('晨间高效');
    } else if (maxTasks == eveningTasks &&
        eveningTasks >= completedTasks * 0.6) {
      tags.add('夜猫达人');
    }

    return tags;
  }
}

// 字符串处理工具
class StringUtils {
  // 截断字符串并添加省略号
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }

  // 验证用户名格式
  static bool isValidUsername(String username) {
    return RegExp(r'^[a-zA-Z0-9_\u4e00-\u9fa5]{2,20}$').hasMatch(username);
  }

  // 验证密码强度
  static bool isValidPassword(String password) {
    return password.length >= 6 && password.length <= 20;
  }
}
