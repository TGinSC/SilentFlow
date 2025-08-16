// 静默协作评分系统集成示例
// 演示如何使用贡献值计算、默契度评估和动态奖惩机制

import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/subtask_model.dart';
import '../models/collaboration_pool_model.dart';
import '../services/scoring_service.dart';
import '../services/task_service.dart';
import '../services/collaboration_pool_service.dart';

class SilentCollaborationExample {
  /// 完整的静默协作流程示例
  static Future<Map<String, dynamic>> demonstrateFullWorkflow() async {
    print('=== 静默协作系统完整演示 ===\n');

    // 1. 模拟用户（实际应用中从登录获取）
    User demoUser = User(
      id: 'demo_001',
      name: '演示用户',
      createdAt: DateTime.now(),
      stats: const UserStats(),
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
          email: 'demo@example.com',
          phone: '',
        ),
      ),
    );

    print('1. 演示用户: ${demoUser.id}');

    // 2. 获取或创建协作池
    List<CollaborationPool> userPools =
        await CollaborationPoolService.getUserPools(demoUser.id);
    CollaborationPool? currentPool;

    if (userPools.isNotEmpty) {
      currentPool = userPools.first;
      print('2. 使用现有协作池: ${currentPool.name}');
    } else {
      // 创建新的协作池
      currentPool = await CollaborationPoolService.createPool(
        name: '演示协作池',
        description: '用于演示静默协作功能的测试池',
        isAnonymous: false,
        isPublic: false,
        memberIds: [demoUser.id, 'demo_user_2', 'demo_user_3'],
        createdBy: demoUser.id,
      );
      print('2. 创建新协作池: ${currentPool?.name ?? "失败"}');
    }

    if (currentPool == null) {
      return {'error': '无法获取或创建协作池'};
    }

    // 3. 创建示例任务
    Task? demoTask = await TaskService.createTask(
      teamId: currentPool.id,
      title: '优化用户界面响应速度',
      description: '分析当前UI性能瓶颈，提出优化方案并实施',
      estimatedMinutes: 120,
      expectedAt: DateTime.now().add(const Duration(hours: 4)),
      priority: TaskPriority.high,
      assignedUsers: [demoUser.id, 'demo_user_2'],
      baseReward: 25.0,
    );

    if (demoTask == null) {
      print('3. 创建演示任务失败');
      return {'error': '无法创建演示任务'};
    }

    print('3. 创建演示任务: ${demoTask.title}');

    // 4. 创建子任务
    List<SubTask> subTasks = [];

    SubTask? subTask1 = await TaskService.createSubTask(
      parentTaskId: demoTask.id,
      title: '分析性能瓶颈',
      description: '使用性能分析工具识别UI卡顿原因',
      assigneeId: demoUser.id,
      weight: 1.5,
      estimatedMinutes: 60,
    );

    SubTask? subTask2 = await TaskService.createSubTask(
      parentTaskId: demoTask.id,
      title: '实施优化方案',
      description: '根据分析结果实施具体优化措施',
      assigneeId: 'demo_user_2',
      weight: 2.0,
      estimatedMinutes: 60,
    );

    if (subTask1 != null) subTasks.add(subTask1);
    if (subTask2 != null) subTasks.add(subTask2);

    print('4. 创建 ${subTasks.length} 个子任务');

    // 5. 模拟任务执行过程
    print('\n--- 开始任务执行 ---');

    // 开始任务
    await TaskService.startTask(
      teamId: currentPool.id,
      taskId: demoTask.id,
      userId: demoUser.id,
    );

    print('5. 任务已开始执行');

    // 模拟一段执行时间
    await Future.delayed(const Duration(milliseconds: 100));

    // 6. 完成任务并计算奖励
    Map<String, dynamic>? completionResult = await TaskService.completeTask(
      teamId: currentPool.id,
      taskId: demoTask.id,
      userId: demoUser.id,
      completionNote: '任务顺利完成，UI响应速度提升30%',
      completedSubTasks: subTasks.map((st) => st.id).toList(),
    );

    if (completionResult != null) {
      Task completedTask = completionResult['task'];
      TaskReward reward = completionResult['reward'];
      double userContribution = completionResult['userContribution'];
      double adjustedContribution = completionResult['adjustedContribution'];

      print('6. 任务完成！');
      print('   - 基础奖励: ${reward.baseScore}分');
      print('   - 时间奖励: ${reward.timeBonus}分');
      print('   - 协作奖励: ${reward.collaborationBonus}分');
      double totalReward = reward.baseScore +
          reward.timeBonus +
          reward.collaborationBonus -
          reward.timePenalty;
      print('   - 总奖励: ${totalReward.toStringAsFixed(2)}分');
      print('   - 用户贡献值: ${userContribution.toStringAsFixed(2)}');
      print('   - 调整后贡献值: ${adjustedContribution.toStringAsFixed(2)}');
      print(
          '   - 时间表现: ${completedTask.isEarlyCompletion ? "提前完成" : (completedTask.isOverdue ? "延期完成" : "按时完成")}');
    }

    // 7. 计算团队默契度
    double poolTacitScore =
        await CollaborationPoolService.calculatePoolTacitScore(currentPool.id);
    print('7. 当前协作池默契度: ${poolTacitScore.toStringAsFixed(1)}分');

    // 8. 生成协作报告
    Map<String, dynamic> poolReport =
        await CollaborationPoolService.generatePoolReport(currentPool.id);
    print('\n8. 协作池报告:');
    print('   - 池名称: ${poolReport['poolName']}');
    print('   - 成员数量: ${poolReport['memberCount']}');
    print('   - 默契度得分: ${poolReport['tacitScore']}');

    if (poolReport['progress'] != null) {
      Map<String, dynamic> progress = poolReport['progress'];
      print('   - 总任务数: ${progress['totalTasks']}');
      print('   - 已完成: ${progress['completedTasks']}');
      print(
          '   - 完成率: ${(progress['completionRate'] * 100).toStringAsFixed(1)}%');
    }

    // 9. 演示评分系统功能
    print('\n--- 评分系统功能演示 ---');

    await _demonstrateScoringFeatures(demoUser, currentPool.id);

    return {
      'success': true,
      'message': '静默协作系统演示完成',
      'poolId': currentPool.id,
      'taskId': demoTask.id,
      'completionResult': completionResult,
      'tacitScore': poolTacitScore,
      'report': poolReport,
    };
  }

  /// 演示评分系统的各项功能
  static Future<void> _demonstrateScoringFeatures(
      User user, String poolId) async {
    try {
      // 1. 时间奖惩机制演示
      print('1. 时间奖惩机制演示:');

      // 提前完成奖励
      double earlyBonus = ScoringService.applyEarlyBonus(
        originalScore: 100.0,
        expectedTime: DateTime.now().add(const Duration(hours: 2)),
        actualTime: DateTime.now().add(const Duration(hours: 1)),
      );
      print('   - 提前1小时完成，奖励后分数: ${earlyBonus.toStringAsFixed(2)}');

      // 延期惩罚
      double latePenalty = ScoringService.applyTimelinePenalty(
        originalScore: 100.0,
        expectedTime: DateTime.now().subtract(const Duration(hours: 1)),
        actualTime: DateTime.now(),
      );
      print('   - 延期1小时完成，惩罚后分数: ${latePenalty.toStringAsFixed(2)}');

      // 2. 任务完成统计
      print('2. 任务完成统计:');
      print('   - 模拟数据显示：提前完成率65%，按时完成率25%，延期完成率10%');

      // 3. 协作效率分析
      print('3. 协作效率分析:');
      print('   - 团队协作任务平均完成时间: 预期时间的95%');
      print('   - 个人任务平均完成时间: 预期时间的110%');
      print('   - 协作带来的效率提升: 15%');

      // 4. 质量评估
      print('4. 质量评估示例:');
      print('   - 高质量任务(无返工，提前完成): 120分 -> 150分');
      print('   - 标准质量任务(按时完成): 120分 -> 120分');
      print('   - 低质量任务(需要返工，延期): 120分 -> 85分');

      print('\n--- 评分系统演示完成 ---');
    } catch (e) {
      print('评分系统演示出错: $e');
    }
  }

  /// 生成评分系统使用指南
  static Map<String, dynamic> generateScoringGuide() {
    return {
      'title': '静默协作评分系统使用指南',
      'version': '1.0.0',
      'sections': {
        'overview': {
          'title': '系统概述',
          'content':
              '静默协作评分系统通过个人贡献值和团队默契度的计算，实现公平、透明的协作评价机制。支持子任务分解、动态奖惩、质量评估等多维度评分。',
        },
        'contribution': {
          'title': '个人贡献值计算',
          'features': [
            '基于任务完成质量和效率',
            '考虑任务难度和复杂度系数',
            '子任务权重分配机制',
            '时间管理奖惩系统',
            '协作参与度评估',
          ],
          'formula': '贡献值 = (基础分数 × 难度系数 × 质量系数 + 协作奖励) × 时间系数',
        },
        'tacit': {
          'title': '团队默契度评估',
          'features': [
            '成员间协作频率分析',
            '任务配合效率评估',
            '沟通成本最小化程度',
            '任务分配合理性',
            '团队整体完成效率',
          ],
          'calculation': '基于成员间共同完成任务的表现、沟通效率、时间协调等多因素计算',
        },
        'penalties': {
          'title': '动态奖惩机制',
          'timeBonus': {
            'early': '提前完成：+5%~20% 奖励',
            'onTime': '准时完成：无额外奖惩',
            'late': '延期完成：-10%~50% 惩罚',
          },
          'qualityBonus': {
            'highQuality': '高质量：+10%~30% 奖励',
            'standard': '标准质量：无额外奖惩',
            'lowQuality': '低质量：-15%~40% 惩罚',
          },
          'collaborationBonus': {
            'activeParticipation': '积极协作：+5%~15% 奖励',
            'passiveParticipation': '消极协作：-5%~20% 惩罚',
          },
        },
        'subtasks': {
          'title': '子任务系统',
          'features': [
            '任务分解和权重分配',
            '子任务依赖关系管理',
            '子任务完成度追踪',
            '基于子任务的贡献度计算',
            '子任务协作效率分析',
          ],
          'usage': '通过TaskService.createSubTask()创建子任务，系统会自动根据子任务完成情况计算贡献度',
        },
        'integration': {
          'title': '系统集成使用',
          'steps': [
            '1. 初始化协作池：CollaborationPoolService.createPool()',
            '2. 创建任务：TaskService.createTask()',
            '3. 分解子任务：TaskService.createSubTask()',
            '4. 执行任务：TaskService.startTask()',
            '5. 完成任务：TaskService.completeTask()',
            '6. 查看评分：ScoringService.calculateTaskContribution()',
            '7. 生成报告：CollaborationPoolService.generatePoolReport()',
          ],
        },
        'bestPractices': {
          'title': '最佳实践建议',
          'tips': [
            '合理设置任务预期时间，避免过于宽松或紧张',
            '鼓励主动协作和知识分享',
            '定期查看团队默契度报告，优化协作流程',
            '利用子任务系统进行精细化管理',
            '关注质量指标，避免为追求速度而牺牲质量',
            '建立良好的沟通机制，减少协作成本',
          ],
        },
      },
      'examples': {
        'basicUsage':
            'await SilentCollaborationExample.demonstrateFullWorkflow()',
        'reportGeneration':
            'await CollaborationPoolService.generatePoolReport(poolId)',
        'guide': 'SilentCollaborationExample.generateScoringGuide()',
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
