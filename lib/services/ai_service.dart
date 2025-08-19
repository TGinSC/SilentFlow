// AI助手相关的API服务
// 连接后端AI助手接口
import 'api_service.dart';
import 'package:dio/dio.dart';

class AiService {
  // AI助手 - POST /ai/assist
  static Future<String?> getAiAssistance({
    required String prompt,
    required String userId,
    required String teamId,
  }) async {
    try {
      final response = await ApiService.post('/ai/assist', data: {
        'prompt': prompt,
        'userUID': int.parse(userId),
        'teamUID': int.parse(teamId),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].toString().isEmpty) {
          return data['response'];
        } else {
          print('AI助手响应失败: ${data['message'] ?? data['error']}');
        }
      }
      return null;
    } on DioException catch (e) {
      print('AI助手请求失败: ${e.message}');
      return null;
    } catch (e) {
      print('AI助手异常: $e');
      return null;
    }
  }

  // 获取任务建议
  static Future<String?> getTaskSuggestion({
    required String teamId,
    required String userId,
    required String taskDescription,
  }) async {
    final prompt = '''
请为以下任务提供改进建议和执行方案：

任务描述：$taskDescription

请提供：
1. 任务分解建议
2. 执行步骤规划  
3. 可能的风险和解决方案
4. 预估时间和资源需求
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }

  // 获取团队协作建议
  static Future<String?> getTeamCollaborationAdvice({
    required String teamId,
    required String userId,
    required String collaborationContext,
  }) async {
    final prompt = '''
请为我们团队的协作提供建议：

协作背景：$collaborationContext

请提供：
1. 团队协作优化建议
2. 沟通改进方案
3. 效率提升策略
4. 潜在问题预警
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }

  // 获取项目管理建议
  static Future<String?> getProjectManagementAdvice({
    required String teamId,
    required String userId,
    required String projectContext,
  }) async {
    final prompt = '''
请为我们的项目管理提供专业建议：

项目情况：$projectContext

请提供：
1. 项目进度管理建议
2. 资源分配优化
3. 里程碑设置建议
4. 质量控制要点
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }

  // 获取学习资源推荐
  static Future<String?> getLearningResourceRecommendation({
    required String teamId,
    required String userId,
    required String skillsNeeded,
  }) async {
    final prompt = '''
请为我们团队推荐学习资源：

需要提升的技能：$skillsNeeded

请提供：
1. 相关学习资源推荐
2. 学习路径规划
3. 实践项目建议
4. 技能验证方法
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }

  // 获取代码审查建议（针对软件开发团队）
  static Future<String?> getCodeReviewSuggestion({
    required String teamId,
    required String userId,
    required String codeContext,
  }) async {
    final prompt = '''
请对以下代码或技术方案提供审查建议：

代码/技术内容：$codeContext

请提供：
1. 代码质量评估
2. 潜在问题识别
3. 优化建议
4. 最佳实践推荐
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }

  // 获取问题解决方案
  static Future<String?> getProblemSolution({
    required String teamId,
    required String userId,
    required String problemDescription,
  }) async {
    final prompt = '''
我们遇到了以下问题，请提供解决方案：

问题描述：$problemDescription

请提供：
1. 问题分析
2. 可行的解决方案
3. 实施步骤
4. 注意事项
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }

  // 获取会议纪要总结
  static Future<String?> getMeetingSummary({
    required String teamId,
    required String userId,
    required String meetingContent,
  }) async {
    final prompt = '''
请帮我整理以下会议内容的纪要：

会议内容：$meetingContent

请提供：
1. 会议要点总结
2. 决策事项
3. 行动项目和负责人
4. 下次会议安排
''';

    return await getAiAssistance(
      prompt: prompt,
      userId: userId,
      teamId: teamId,
    );
  }
}
