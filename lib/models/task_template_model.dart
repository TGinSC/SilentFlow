import 'task_model.dart';
import 'subtask_model.dart';

// 任务模板模型
class TaskTemplate {
  final String id;
  final String name; // 模板名称
  final String description; // 模板描述
  final String category; // 模板分类
  final TaskTemplateType type; // 模板类型
  final List<TaskStepTemplate> steps; // 任务步骤模板
  final int estimatedMinutes; // 预估时间
  final TaskDifficulty difficulty; // 任务难度
  final TaskPriority priority; // 任务优先级
  final List<String> requiredSkills; // 所需技能
  final List<String> tags; // 模板标签
  final String? createdBy; // 创建者ID
  final DateTime createdAt; // 创建时间
  final bool isPublic; // 是否公开模板
  final int usageCount; // 使用次数
  final double rating; // 模板评分
  final List<String> milestoneTemplates; // 里程碑模板
  final Map<String, dynamic> customFields; // 自定义字段
  final bool isActive; // 是否激活

  const TaskTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    this.steps = const [],
    this.estimatedMinutes = 60,
    this.difficulty = TaskDifficulty.medium,
    this.priority = TaskPriority.medium,
    this.requiredSkills = const [],
    this.tags = const [],
    this.createdBy,
    required this.createdAt,
    this.isPublic = false,
    this.usageCount = 0,
    this.rating = 0.0,
    this.milestoneTemplates = const [],
    this.customFields = const {},
    this.isActive = true,
  });

  // 创建任务实例
  Task createTask({
    required String poolId,
    required String taskId,
    String? customTitle,
    String? customDescription,
    String? createdBy,
    Map<String, dynamic>? customFieldValues,
  }) {
    // 创建子任务
    List<SubTask> subTasks = steps.map((stepTemplate) {
      return SubTask(
        id: '${taskId}_${stepTemplate.id}',
        taskId: taskId,
        title: stepTemplate.title,
        description: stepTemplate.description,
        createdAt: DateTime.now(),
        expectedAt: DateTime.now()
            .add(Duration(minutes: stepTemplate.estimatedMinutes)),
        status: SubTaskStatus.pending,
        priority: stepTemplate.priority.index + 1, // 转换为int
        weight: stepTemplate.weight,
        dependencies: stepTemplate.dependencies,
        metadata: {
          'templateStepId': stepTemplate.id,
          'requiredSkills': stepTemplate.requiredSkills,
          'tags': stepTemplate.tags,
          'order': stepTemplate.order,
          'stepType': stepTemplate.stepType.name,
          'isOptional': stepTemplate.isOptional,
        },
      );
    }).toList();

    return Task(
      id: taskId,
      poolId: poolId,
      title: customTitle ?? name,
      description: customDescription ?? description,
      estimatedMinutes: estimatedMinutes,
      status: TaskStatus.pending,
      createdAt: DateTime.now(),
      statistics: const TaskStatistics(),
      subTasks: subTasks,
      priority: priority,
      difficulty: difficulty,
      requiredSkills: requiredSkills,
      tags: tags,
      createdBy: createdBy,
      milestones: milestoneTemplates,
      isTeamTask: subTasks.length > 1,
      maxAssignees: _calculateMaxAssignees(),
    );
  }

  // 计算最大分配人数
  int _calculateMaxAssignees() {
    if (steps.isEmpty) return 1;

    // 基于子任务数量和复杂度计算
    int baseAssignees = (steps.length / 3).ceil(); // 每3个子任务可分配一个人

    // 根据难度调整
    switch (difficulty) {
      case TaskDifficulty.easy:
        return (baseAssignees * 0.5).ceil().clamp(1, 2);
      case TaskDifficulty.medium:
        return baseAssignees.clamp(1, 3);
      case TaskDifficulty.hard:
        return (baseAssignees * 1.5).ceil().clamp(2, 5);
      case TaskDifficulty.expert:
        return (baseAssignees * 2).ceil().clamp(3, 8);
    }
  }

  // 验证模板完整性
  bool get isValid {
    if (name.isEmpty || description.isEmpty) return false;
    if (steps.isEmpty && type != TaskTemplateType.simple) return false;
    if (estimatedMinutes <= 0) return false;
    return true;
  }

  // 获取模板复杂度分数
  double get complexityScore {
    double score = 0.0;

    // 基于步骤数量
    score += steps.length * 0.1;

    // 基于难度
    score += difficulty.scoreMultiplier;

    // 基于所需技能数量
    score += requiredSkills.length * 0.2;

    // 基于里程碑数量
    score += milestoneTemplates.length * 0.3;

    return score;
  }

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      type: TaskTemplateType.values[json['type'] ?? 0],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => TaskStepTemplate.fromJson(e))
              .toList() ??
          [],
      estimatedMinutes: json['estimatedMinutes'] ?? 60,
      difficulty: TaskDifficulty.values[json['difficulty'] ?? 1],
      priority: TaskPriority.values[json['priority'] ?? 1],
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdBy: json['createdBy'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      isPublic: json['isPublic'] ?? false,
      usageCount: json['usageCount'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      milestoneTemplates: List<String>.from(json['milestoneTemplates'] ?? []),
      customFields: json['customFields'] ?? {},
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'type': type.index,
      'steps': steps.map((e) => e.toJson()).toList(),
      'estimatedMinutes': estimatedMinutes,
      'difficulty': difficulty.index,
      'priority': priority.index,
      'requiredSkills': requiredSkills,
      'tags': tags,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
      'usageCount': usageCount,
      'rating': rating,
      'milestoneTemplates': milestoneTemplates,
      'customFields': customFields,
      'isActive': isActive,
    };
  }

  TaskTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    TaskTemplateType? type,
    List<TaskStepTemplate>? steps,
    int? estimatedMinutes,
    TaskDifficulty? difficulty,
    TaskPriority? priority,
    List<String>? requiredSkills,
    List<String>? tags,
    String? createdBy,
    DateTime? createdAt,
    bool? isPublic,
    int? usageCount,
    double? rating,
    List<String>? milestoneTemplates,
    Map<String, dynamic>? customFields,
    bool? isActive,
  }) {
    return TaskTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      steps: steps ?? this.steps,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      difficulty: difficulty ?? this.difficulty,
      priority: priority ?? this.priority,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      tags: tags ?? this.tags,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      usageCount: usageCount ?? this.usageCount,
      rating: rating ?? this.rating,
      milestoneTemplates: milestoneTemplates ?? this.milestoneTemplates,
      customFields: customFields ?? this.customFields,
      isActive: isActive ?? this.isActive,
    );
  }
}

// 任务模板类型
enum TaskTemplateType {
  simple, // 简单任务（无子任务）
  structured, // 结构化任务（有步骤）
  collaborative, // 协作任务（多人参与）
  iterative, // 迭代任务（循环执行）
}

extension TaskTemplateTypeExtension on TaskTemplateType {
  String get displayName {
    switch (this) {
      case TaskTemplateType.simple:
        return '简单任务';
      case TaskTemplateType.structured:
        return '结构化任务';
      case TaskTemplateType.collaborative:
        return '协作任务';
      case TaskTemplateType.iterative:
        return '迭代任务';
    }
  }

  String get description {
    switch (this) {
      case TaskTemplateType.simple:
        return '单一目标的简单任务，无需分解';
      case TaskTemplateType.structured:
        return '按步骤执行的结构化任务';
      case TaskTemplateType.collaborative:
        return '需要多人协作完成的任务';
      case TaskTemplateType.iterative:
        return '需要反复执行和优化的任务';
    }
  }
}

// 任务步骤模板
class TaskStepTemplate {
  final String id;
  final String title; // 步骤标题
  final String description; // 步骤描述
  final int estimatedMinutes; // 预估时间
  final TaskPriority priority; // 步骤优先级
  final List<String> requiredSkills; // 所需技能
  final double weight; // 权重（用于进度计算）
  final int order; // 执行顺序
  final List<String> dependencies; // 依赖的步骤ID
  final List<String> tags; // 步骤标签
  final Map<String, dynamic> metadata; // 元数据
  final bool isOptional; // 是否可选
  final StepType stepType; // 步骤类型

  const TaskStepTemplate({
    required this.id,
    required this.title,
    required this.description,
    this.estimatedMinutes = 30,
    this.priority = TaskPriority.medium,
    this.requiredSkills = const [],
    this.weight = 1.0,
    required this.order,
    this.dependencies = const [],
    this.tags = const [],
    this.metadata = const {},
    this.isOptional = false,
    this.stepType = StepType.task,
  });

  factory TaskStepTemplate.fromJson(Map<String, dynamic> json) {
    return TaskStepTemplate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      estimatedMinutes: json['estimatedMinutes'] ?? 30,
      priority: TaskPriority.values[json['priority'] ?? 1],
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      weight: (json['weight'] ?? 1.0).toDouble(),
      order: json['order'] ?? 0,
      dependencies: List<String>.from(json['dependencies'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      metadata: json['metadata'] ?? {},
      isOptional: json['isOptional'] ?? false,
      stepType: StepType.values[json['stepType'] ?? 0],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'priority': priority.index,
      'requiredSkills': requiredSkills,
      'weight': weight,
      'order': order,
      'dependencies': dependencies,
      'tags': tags,
      'metadata': metadata,
      'isOptional': isOptional,
      'stepType': stepType.index,
    };
  }
}

// 步骤类型
enum StepType {
  task, // 任务步骤
  milestone, // 里程碑步骤
  review, // 审核步骤
  approval, // 批准步骤
  notification, // 通知步骤
}

extension StepTypeExtension on StepType {
  String get displayName {
    switch (this) {
      case StepType.task:
        return '任务步骤';
      case StepType.milestone:
        return '里程碑';
      case StepType.review:
        return '审核步骤';
      case StepType.approval:
        return '批准步骤';
      case StepType.notification:
        return '通知步骤';
    }
  }
}

// 预定义任务模板
class DefaultTaskTemplates {
  static List<TaskTemplate> get all => [
        softwareDevelopmentTemplate,
        researchProjectTemplate,
        marketingCampaignTemplate,
        eventPlanningTemplate,
        contentCreationTemplate,
        designProjectTemplate,
        dataAnalysisTemplate,
        learningProjectTemplate,
        collaborativeWritingTemplate,
        academicPaperTemplate,
        businessProposalTemplate,
        technicalDocumentationTemplate,
      ];

  // 软件开发模板
  static TaskTemplate get softwareDevelopmentTemplate => TaskTemplate(
        id: 'template_software_dev',
        name: '软件开发项目',
        description: '完整的软件开发流程，包含需求分析、设计、开发、测试和部署',
        category: '开发',
        type: TaskTemplateType.structured,
        estimatedMinutes: 2400, // 40小时
        difficulty: TaskDifficulty.hard,
        priority: TaskPriority.high,
        requiredSkills: ['编程', '软件设计', '测试'],
        tags: ['开发', '软件', '项目管理'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['需求确认', '设计完成', '开发完成', '测试通过', '上线部署'],
        steps: [
          TaskStepTemplate(
            id: 'requirements_analysis',
            title: '需求分析',
            description: '收集和分析项目需求，编写需求文档',
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            requiredSkills: ['需求分析', '文档编写'],
            weight: 2.0,
            order: 1,
            stepType: StepType.milestone,
            tags: ['需求', '分析'],
          ),
          TaskStepTemplate(
            id: 'system_design',
            title: '系统设计',
            description: '设计系统架构和详细设计',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['系统设计', '架构'],
            weight: 2.5,
            order: 2,
            dependencies: ['requirements_analysis'],
            tags: ['设计', '架构'],
          ),
          TaskStepTemplate(
            id: 'development',
            title: '编码实现',
            description: '根据设计文档进行编码实现',
            estimatedMinutes: 1200,
            priority: TaskPriority.medium,
            requiredSkills: ['编程', '代码规范'],
            weight: 3.0,
            order: 3,
            dependencies: ['system_design'],
            tags: ['编程', '实现'],
          ),
          TaskStepTemplate(
            id: 'testing',
            title: '测试验证',
            description: '进行单元测试、集成测试和系统测试',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['测试', '调试'],
            weight: 2.0,
            order: 4,
            dependencies: ['development'],
            tags: ['测试', '质量保证'],
          ),
          TaskStepTemplate(
            id: 'deployment',
            title: '部署上线',
            description: '部署到生产环境并进行验证',
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            requiredSkills: ['部署', '运维'],
            weight: 1.5,
            order: 5,
            dependencies: ['testing'],
            stepType: StepType.milestone,
            tags: ['部署', '上线'],
          ),
        ],
      );

  // 研究项目模板
  static TaskTemplate get researchProjectTemplate => TaskTemplate(
        id: 'template_research',
        name: '研究项目',
        description: '学术或商业研究项目，包含文献调研、实验设计、数据收集和分析',
        category: '研究',
        type: TaskTemplateType.structured,
        estimatedMinutes: 1800, // 30小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.medium,
        requiredSkills: ['研究方法', '数据分析', '学术写作'],
        tags: ['研究', '学术', '数据分析'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['研究计划确定', '文献调研完成', '数据收集完成', '分析完成', '报告提交'],
        steps: [
          TaskStepTemplate(
            id: 'literature_review',
            title: '文献调研',
            description: '搜集和分析相关文献资料',
            estimatedMinutes: 480,
            priority: TaskPriority.high,
            requiredSkills: ['文献检索', '批判性思维'],
            weight: 2.0,
            order: 1,
            tags: ['文献', '调研'],
          ),
          TaskStepTemplate(
            id: 'methodology_design',
            title: '方法论设计',
            description: '设计研究方法和实验方案',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['研究方法', '实验设计'],
            weight: 2.5,
            order: 2,
            dependencies: ['literature_review'],
            tags: ['方法论', '设计'],
          ),
          TaskStepTemplate(
            id: 'data_collection',
            title: '数据收集',
            description: '按照设计方案收集研究数据',
            estimatedMinutes: 600,
            priority: TaskPriority.medium,
            requiredSkills: ['数据收集', '实验操作'],
            weight: 2.0,
            order: 3,
            dependencies: ['methodology_design'],
            tags: ['数据', '收集'],
          ),
          TaskStepTemplate(
            id: 'data_analysis',
            title: '数据分析',
            description: '对收集的数据进行统计分析',
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            requiredSkills: ['数据分析', '统计学'],
            weight: 2.5,
            order: 4,
            dependencies: ['data_collection'],
            tags: ['分析', '统计'],
          ),
          TaskStepTemplate(
            id: 'report_writing',
            title: '报告撰写',
            description: '撰写研究报告或论文',
            estimatedMinutes: 120,
            priority: TaskPriority.medium,
            requiredSkills: ['学术写作', '报告撰写'],
            weight: 1.5,
            order: 5,
            dependencies: ['data_analysis'],
            stepType: StepType.milestone,
            tags: ['写作', '报告'],
          ),
        ],
      );

  // 营销活动模板
  static TaskTemplate get marketingCampaignTemplate => TaskTemplate(
        id: 'template_marketing',
        name: '营销活动策划',
        description: '完整的营销活动策划和执行流程',
        category: '营销',
        type: TaskTemplateType.collaborative,
        estimatedMinutes: 960, // 16小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.medium,
        requiredSkills: ['市场营销', '创意策划', '项目管理'],
        tags: ['营销', '策划', '推广'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['策划方案确定', '物料准备完成', '活动执行', '效果评估'],
        steps: [
          TaskStepTemplate(
            id: 'market_research',
            title: '市场调研',
            description: '分析目标市场和竞争对手',
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            requiredSkills: ['市场调研', '数据分析'],
            weight: 2.0,
            order: 1,
            tags: ['调研', '市场'],
          ),
          TaskStepTemplate(
            id: 'campaign_strategy',
            title: '活动策略制定',
            description: '制定营销活动的整体策略',
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            requiredSkills: ['策略规划', '创意思维'],
            weight: 2.5,
            order: 2,
            dependencies: ['market_research'],
            tags: ['策略', '规划'],
          ),
          TaskStepTemplate(
            id: 'content_creation',
            title: '内容创作',
            description: '制作活动相关的宣传内容',
            estimatedMinutes: 360,
            priority: TaskPriority.medium,
            requiredSkills: ['内容创作', '设计'],
            weight: 2.0,
            order: 3,
            dependencies: ['campaign_strategy'],
            tags: ['内容', '创作'],
          ),
          TaskStepTemplate(
            id: 'campaign_execution',
            title: '活动执行',
            description: '实施营销活动',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['项目执行', '协调管理'],
            weight: 2.0,
            order: 4,
            dependencies: ['content_creation'],
            stepType: StepType.milestone,
            tags: ['执行', '实施'],
          ),
          TaskStepTemplate(
            id: 'performance_analysis',
            title: '效果分析',
            description: '分析活动效果和ROI',
            estimatedMinutes: 60,
            priority: TaskPriority.medium,
            requiredSkills: ['数据分析', '报告撰写'],
            weight: 1.0,
            order: 5,
            dependencies: ['campaign_execution'],
            tags: ['分析', '评估'],
          ),
        ],
      );

  // 活动策划模板
  static TaskTemplate get eventPlanningTemplate => TaskTemplate(
        id: 'template_event',
        name: '活动策划',
        description: '线下或线上活动的完整策划流程',
        category: '活动',
        type: TaskTemplateType.collaborative,
        estimatedMinutes: 720, // 12小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.medium,
        requiredSkills: ['活动策划', '项目管理', '协调沟通'],
        tags: ['活动', '策划', '执行'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['方案确定', '场地预订', '物料准备', '活动举办', '总结评估'],
        steps: [
          TaskStepTemplate(
            id: 'event_concept',
            title: '活动概念设计',
            description: '确定活动主题、目标和基本框架',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['创意策划', '概念设计'],
            weight: 2.0,
            order: 1,
            stepType: StepType.milestone,
            tags: ['概念', '设计'],
          ),
          TaskStepTemplate(
            id: 'venue_booking',
            title: '场地预订',
            description: '选择和预订活动场地',
            estimatedMinutes: 90,
            priority: TaskPriority.high,
            requiredSkills: ['商务谈判', '场地评估'],
            weight: 1.5,
            order: 2,
            dependencies: ['event_concept'],
            tags: ['场地', '预订'],
          ),
          TaskStepTemplate(
            id: 'supplier_coordination',
            title: '供应商协调',
            description: '联系和协调各类供应商',
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            requiredSkills: ['供应商管理', '协调沟通'],
            weight: 1.5,
            order: 3,
            dependencies: ['venue_booking'],
            tags: ['供应商', '协调'],
          ),
          TaskStepTemplate(
            id: 'promotion_marketing',
            title: '宣传推广',
            description: '进行活动宣传和参与者招募',
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            requiredSkills: ['市场推广', '社交媒体'],
            weight: 2.0,
            order: 4,
            dependencies: ['event_concept'],
            tags: ['宣传', '推广'],
          ),
          TaskStepTemplate(
            id: 'event_execution',
            title: '活动执行',
            description: '现场活动的组织和执行',
            estimatedMinutes: 60,
            priority: TaskPriority.high,
            requiredSkills: ['现场管理', '应急处理'],
            weight: 2.5,
            order: 5,
            dependencies: ['supplier_coordination', 'promotion_marketing'],
            stepType: StepType.milestone,
            tags: ['执行', '现场'],
          ),
          TaskStepTemplate(
            id: 'post_event_summary',
            title: '活动总结',
            description: '收集反馈并撰写活动总结报告',
            estimatedMinutes: 30,
            priority: TaskPriority.low,
            requiredSkills: ['总结分析', '反馈收集'],
            weight: 1.0,
            order: 6,
            dependencies: ['event_execution'],
            tags: ['总结', '反馈'],
          ),
        ],
      );

  // 内容创作模板
  static TaskTemplate get contentCreationTemplate => TaskTemplate(
        id: 'template_content',
        name: '内容创作项目',
        description: '从策划到发布的完整内容创作流程',
        category: '内容',
        type: TaskTemplateType.structured,
        estimatedMinutes: 480, // 8小时
        difficulty: TaskDifficulty.easy,
        priority: TaskPriority.medium,
        requiredSkills: ['写作', '编辑', '内容策划'],
        tags: ['内容', '写作', '创作'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['选题确定', '初稿完成', '编辑完成', '发布上线'],
        steps: [
          TaskStepTemplate(
            id: 'topic_research',
            title: '选题调研',
            description: '研究目标受众需求，确定内容主题',
            estimatedMinutes: 60,
            priority: TaskPriority.high,
            requiredSkills: ['市场调研', '用户分析'],
            weight: 1.5,
            order: 1,
            tags: ['调研', '选题'],
          ),
          TaskStepTemplate(
            id: 'content_outline',
            title: '内容大纲',
            description: '制定详细的内容大纲和结构',
            estimatedMinutes: 60,
            priority: TaskPriority.high,
            requiredSkills: ['内容策划', '逻辑思维'],
            weight: 1.5,
            order: 2,
            dependencies: ['topic_research'],
            tags: ['大纲', '结构'],
          ),
          TaskStepTemplate(
            id: 'content_writing',
            title: '内容撰写',
            description: '按照大纲撰写完整内容',
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            requiredSkills: ['写作', '表达能力'],
            weight: 3.0,
            order: 3,
            dependencies: ['content_outline'],
            tags: ['写作', '撰写'],
          ),
          TaskStepTemplate(
            id: 'content_editing',
            title: '编辑校对',
            description: '对内容进行编辑、校对和优化',
            estimatedMinutes: 90,
            priority: TaskPriority.medium,
            requiredSkills: ['编辑', '校对'],
            weight: 1.5,
            order: 4,
            dependencies: ['content_writing'],
            tags: ['编辑', '校对'],
          ),
          TaskStepTemplate(
            id: 'content_publishing',
            title: '发布推广',
            description: '发布内容并进行初期推广',
            estimatedMinutes: 30,
            priority: TaskPriority.low,
            requiredSkills: ['社交媒体', '推广'],
            weight: 1.0,
            order: 5,
            dependencies: ['content_editing'],
            stepType: StepType.milestone,
            tags: ['发布', '推广'],
          ),
        ],
      );

  // 设计项目模板
  static TaskTemplate get designProjectTemplate => TaskTemplate(
        id: 'template_design',
        name: '设计项目',
        description: '从需求分析到最终交付的设计项目流程',
        category: '设计',
        type: TaskTemplateType.structured,
        estimatedMinutes: 960, // 16小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.medium,
        requiredSkills: ['视觉设计', '用户体验', '创意思维'],
        tags: ['设计', 'UI/UX', '创意'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['需求确认', '概念设计', '详细设计', '原型制作', '最终交付'],
        steps: [
          TaskStepTemplate(
            id: 'design_brief',
            title: '需求分析',
            description: '分析客户需求和项目目标',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['需求分析', '沟通能力'],
            weight: 2.0,
            order: 1,
            stepType: StepType.milestone,
            tags: ['需求', '分析'],
          ),
          TaskStepTemplate(
            id: 'concept_design',
            title: '概念设计',
            description: '制作初步的设计概念和方向',
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            requiredSkills: ['概念设计', '创意思维'],
            weight: 2.5,
            order: 2,
            dependencies: ['design_brief'],
            tags: ['概念', '创意'],
          ),
          TaskStepTemplate(
            id: 'detailed_design',
            title: '详细设计',
            description: '完成详细的视觉设计',
            estimatedMinutes: 360,
            priority: TaskPriority.medium,
            requiredSkills: ['视觉设计', '设计软件'],
            weight: 3.0,
            order: 3,
            dependencies: ['concept_design'],
            tags: ['详细设计', '视觉'],
          ),
          TaskStepTemplate(
            id: 'prototype',
            title: '原型制作',
            description: '制作可交互的设计原型',
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            requiredSkills: ['原型设计', '交互设计'],
            weight: 2.0,
            order: 4,
            dependencies: ['detailed_design'],
            tags: ['原型', '交互'],
          ),
          TaskStepTemplate(
            id: 'final_delivery',
            title: '最终交付',
            description: '整理设计文件并交付给客户',
            estimatedMinutes: 60,
            priority: TaskPriority.low,
            requiredSkills: ['文件整理', '客户沟通'],
            weight: 1.0,
            order: 5,
            dependencies: ['prototype'],
            stepType: StepType.milestone,
            tags: ['交付', '整理'],
          ),
        ],
      );

  // 数据分析模板
  static TaskTemplate get dataAnalysisTemplate => TaskTemplate(
        id: 'template_data_analysis',
        name: '数据分析项目',
        description: '完整的数据分析项目流程，从数据收集到结果呈现',
        category: '数据分析',
        type: TaskTemplateType.structured,
        estimatedMinutes: 720, // 12小时
        difficulty: TaskDifficulty.hard,
        priority: TaskPriority.medium,
        requiredSkills: ['数据分析', '统计学', '可视化'],
        tags: ['数据', '分析', '统计'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['数据收集完成', '数据清洗完成', '分析完成', '报告提交'],
        steps: [
          TaskStepTemplate(
            id: 'data_collection',
            title: '数据收集',
            description: '收集和整理分析所需的数据',
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            requiredSkills: ['数据收集', '数据库操作'],
            weight: 2.0,
            order: 1,
            tags: ['数据', '收集'],
          ),
          TaskStepTemplate(
            id: 'data_cleaning',
            title: '数据清洗',
            description: '清理和预处理收集到的数据',
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            requiredSkills: ['数据清洗', '数据预处理'],
            weight: 2.5,
            order: 2,
            dependencies: ['data_collection'],
            tags: ['清洗', '预处理'],
          ),
          TaskStepTemplate(
            id: 'exploratory_analysis',
            title: '探索性分析',
            description: '进行初步的数据探索和分析',
            estimatedMinutes: 120,
            priority: TaskPriority.medium,
            requiredSkills: ['统计分析', '数据挖掘'],
            weight: 2.0,
            order: 3,
            dependencies: ['data_cleaning'],
            tags: ['探索', '分析'],
          ),
          TaskStepTemplate(
            id: 'statistical_analysis',
            title: '统计分析',
            description: '进行深入的统计分析和建模',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['统计学', '建模'],
            weight: 2.5,
            order: 4,
            dependencies: ['exploratory_analysis'],
            tags: ['统计', '建模'],
          ),
          TaskStepTemplate(
            id: 'visualization',
            title: '数据可视化',
            description: '制作数据可视化图表和报表',
            estimatedMinutes: 60,
            priority: TaskPriority.medium,
            requiredSkills: ['数据可视化', '图表制作'],
            weight: 1.5,
            order: 5,
            dependencies: ['statistical_analysis'],
            tags: ['可视化', '图表'],
          ),
        ],
      );

  // 学习项目模板
  static TaskTemplate get learningProjectTemplate => TaskTemplate(
        id: 'template_learning',
        name: '学习项目',
        description: '结构化的学习项目，适合技能提升和知识获取',
        category: '学习',
        type: TaskTemplateType.structured,
        estimatedMinutes: 600, // 10小时
        difficulty: TaskDifficulty.easy,
        priority: TaskPriority.low,
        requiredSkills: ['学习能力', '时间管理'],
        tags: ['学习', '技能', '知识'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['学习计划制定', '理论学习完成', '实践练习完成', '项目总结'],
        steps: [
          TaskStepTemplate(
            id: 'learning_plan',
            title: '制定学习计划',
            description: '制定详细的学习计划和目标',
            estimatedMinutes: 60,
            priority: TaskPriority.high,
            requiredSkills: ['规划能力', '目标设定'],
            weight: 1.5,
            order: 1,
            stepType: StepType.milestone,
            tags: ['计划', '目标'],
          ),
          TaskStepTemplate(
            id: 'theory_study',
            title: '理论学习',
            description: '学习相关的理论知识和概念',
            estimatedMinutes: 300,
            priority: TaskPriority.medium,
            requiredSkills: ['阅读理解', '知识吸收'],
            weight: 3.0,
            order: 2,
            dependencies: ['learning_plan'],
            tags: ['理论', '知识'],
          ),
          TaskStepTemplate(
            id: 'practical_exercise',
            title: '实践练习',
            description: '通过练习巩固所学知识',
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            requiredSkills: ['实践能力', '问题解决'],
            weight: 2.5,
            order: 3,
            dependencies: ['theory_study'],
            tags: ['实践', '练习'],
          ),
          TaskStepTemplate(
            id: 'knowledge_review',
            title: '知识回顾',
            description: '回顾和总结学习成果',
            estimatedMinutes: 60,
            priority: TaskPriority.medium,
            requiredSkills: ['总结能力', '反思'],
            weight: 1.0,
            order: 4,
            dependencies: ['practical_exercise'],
            stepType: StepType.milestone,
            tags: ['回顾', '总结'],
          ),
        ],
      );

  // 协作写作项目模板
  static TaskTemplate get collaborativeWritingTemplate => TaskTemplate(
        id: 'template_collaborative_writing',
        name: '协作写作项目',
        description: '多人协作完成文档或创作项目，包含大纲设计、内容编写、审核修改',
        category: '写作',
        type: TaskTemplateType.structured,
        estimatedMinutes: 1200, // 20小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.medium,
        requiredSkills: ['写作', '编辑', '协作'],
        tags: ['写作', '协作', '文档'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['大纲确定', '初稿完成', '审核完成', '终稿发布'],
        steps: [
          TaskStepTemplate(
            id: 'outline_planning',
            title: '大纲规划',
            description: '制定写作大纲和内容结构，分配章节责任',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['规划能力', '结构设计'],
            weight: 2.0,
            order: 1,
            stepType: StepType.milestone,
            tags: ['大纲', '规划'],
          ),
          TaskStepTemplate(
            id: 'content_writing',
            title: '内容撰写',
            description: '根据分工完成各自负责的章节内容',
            estimatedMinutes: 600,
            priority: TaskPriority.high,
            requiredSkills: ['写作', '表达能力'],
            weight: 3.0,
            order: 2,
            dependencies: ['outline_planning'],
            tags: ['写作', '内容'],
          ),
          TaskStepTemplate(
            id: 'peer_review',
            title: '同行评议',
            description: '团队成员互相审阅和修改内容',
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            requiredSkills: ['审阅', '批判性思维'],
            weight: 2.0,
            order: 3,
            dependencies: ['content_writing'],
            tags: ['审阅', '修改'],
          ),
          TaskStepTemplate(
            id: 'editing_revision',
            title: '编辑修订',
            description: '统一格式、语言风格和最终润色',
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            requiredSkills: ['编辑', '语言润色'],
            weight: 1.5,
            order: 4,
            dependencies: ['peer_review'],
            tags: ['编辑', '润色'],
          ),
          TaskStepTemplate(
            id: 'final_review',
            title: '终审发布',
            description: '最终审核并准备发布',
            estimatedMinutes: 60,
            priority: TaskPriority.high,
            requiredSkills: ['质量控制'],
            weight: 1.0,
            order: 5,
            dependencies: ['editing_revision'],
            stepType: StepType.milestone,
            tags: ['审核', '发布'],
          ),
        ],
      );

  // 学术论文协作模板
  static TaskTemplate get academicPaperTemplate => TaskTemplate(
        id: 'template_academic_paper',
        name: '学术论文协作',
        description: '多人合作完成学术论文，包含文献综述、研究设计、数据分析、论文撰写',
        category: '学术',
        type: TaskTemplateType.structured,
        estimatedMinutes: 2400, // 40小时
        difficulty: TaskDifficulty.hard,
        priority: TaskPriority.high,
        requiredSkills: ['学术写作', '研究方法', '数据分析'],
        tags: ['学术', '论文', '研究'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['文献综述完成', '研究设计确定', '数据收集完成', '初稿完成', '论文发表'],
        steps: [
          TaskStepTemplate(
            id: 'literature_review',
            title: '文献综述',
            description: '收集和分析相关文献，建立理论基础',
            estimatedMinutes: 480,
            priority: TaskPriority.high,
            requiredSkills: ['文献检索', '批判性阅读'],
            weight: 2.5,
            order: 1,
            stepType: StepType.milestone,
            tags: ['文献', '综述'],
          ),
          TaskStepTemplate(
            id: 'research_design',
            title: '研究设计',
            description: '设计研究方法和实验方案',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['研究方法', '实验设计'],
            weight: 2.5,
            order: 2,
            dependencies: ['literature_review'],
            tags: ['研究', '设计'],
          ),
          TaskStepTemplate(
            id: 'data_collection',
            title: '数据收集',
            description: '执行研究方案，收集实验数据',
            estimatedMinutes: 720,
            priority: TaskPriority.high,
            requiredSkills: ['数据收集', '实验执行'],
            weight: 3.0,
            order: 3,
            dependencies: ['research_design'],
            tags: ['数据', '实验'],
          ),
          TaskStepTemplate(
            id: 'data_analysis',
            title: '数据分析',
            description: '分析实验数据，得出研究结论',
            estimatedMinutes: 480,
            priority: TaskPriority.high,
            requiredSkills: ['统计分析', '数据解读'],
            weight: 2.5,
            order: 4,
            dependencies: ['data_collection'],
            tags: ['分析', '统计'],
          ),
          TaskStepTemplate(
            id: 'paper_writing',
            title: '论文撰写',
            description: '撰写完整的学术论文',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['学术写作', '逻辑表达'],
            weight: 2.0,
            order: 5,
            dependencies: ['data_analysis'],
            stepType: StepType.milestone,
            tags: ['写作', '论文'],
          ),
        ],
      );

  // 商业提案协作模板
  static TaskTemplate get businessProposalTemplate => TaskTemplate(
        id: 'template_business_proposal',
        name: '商业提案协作',
        description: '团队合作完成商业提案，包含市场分析、财务规划、风险评估',
        category: '商业',
        type: TaskTemplateType.structured,
        estimatedMinutes: 1440, // 24小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.high,
        requiredSkills: ['商业分析', '财务规划', '演示制作'],
        tags: ['商业', '提案', '分析'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['市场调研完成', '商业模式确定', '财务计划完成', '提案初稿', '最终演示'],
        steps: [
          TaskStepTemplate(
            id: 'market_research',
            title: '市场调研',
            description: '分析目标市场和竞争环境',
            estimatedMinutes: 300,
            priority: TaskPriority.high,
            requiredSkills: ['市场分析', '竞争分析'],
            weight: 2.0,
            order: 1,
            stepType: StepType.milestone,
            tags: ['市场', '调研'],
          ),
          TaskStepTemplate(
            id: 'business_model',
            title: '商业模式设计',
            description: '设计和验证商业模式',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['商业模式', '战略规划'],
            weight: 2.5,
            order: 2,
            dependencies: ['market_research'],
            tags: ['商业模式', '策略'],
          ),
          TaskStepTemplate(
            id: 'financial_planning',
            title: '财务规划',
            description: '制定财务预测和投资计划',
            estimatedMinutes: 480,
            priority: TaskPriority.high,
            requiredSkills: ['财务分析', '投资规划'],
            weight: 3.0,
            order: 3,
            dependencies: ['business_model'],
            tags: ['财务', '预测'],
          ),
          TaskStepTemplate(
            id: 'risk_assessment',
            title: '风险评估',
            description: '识别和评估潜在风险',
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            requiredSkills: ['风险管理', '分析能力'],
            weight: 1.5,
            order: 4,
            dependencies: ['financial_planning'],
            tags: ['风险', '评估'],
          ),
          TaskStepTemplate(
            id: 'proposal_writing',
            title: '提案撰写',
            description: '整合所有内容，撰写完整提案',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['商业写作', '整合能力'],
            weight: 1.0,
            order: 5,
            dependencies: ['risk_assessment'],
            stepType: StepType.milestone,
            tags: ['提案', '撰写'],
          ),
        ],
      );

  // 技术文档协作模板
  static TaskTemplate get technicalDocumentationTemplate => TaskTemplate(
        id: 'template_tech_documentation',
        name: '技术文档协作',
        description: '团队协作编写技术文档，包含需求分析、架构设计、API文档、用户手册',
        category: '技术',
        type: TaskTemplateType.structured,
        estimatedMinutes: 1800, // 30小时
        difficulty: TaskDifficulty.medium,
        priority: TaskPriority.medium,
        requiredSkills: ['技术写作', '文档规范', '工具使用'],
        tags: ['技术', '文档', '协作'],
        createdAt: DateTime.now(),
        isPublic: true,
        milestoneTemplates: ['需求文档完成', '设计文档完成', 'API文档完成', '用户手册完成', '文档发布'],
        steps: [
          TaskStepTemplate(
            id: 'requirements_doc',
            title: '需求文档',
            description: '编写详细的功能需求文档',
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            requiredSkills: ['需求分析', '技术写作'],
            weight: 2.0,
            order: 1,
            stepType: StepType.milestone,
            tags: ['需求', '文档'],
          ),
          TaskStepTemplate(
            id: 'architecture_doc',
            title: '架构文档',
            description: '设计和文档化系统架构',
            estimatedMinutes: 480,
            priority: TaskPriority.high,
            requiredSkills: ['系统架构', '图表制作'],
            weight: 2.5,
            order: 2,
            dependencies: ['requirements_doc'],
            tags: ['架构', '设计'],
          ),
          TaskStepTemplate(
            id: 'api_documentation',
            title: 'API文档',
            description: '编写详细的API接口文档',
            estimatedMinutes: 540,
            priority: TaskPriority.high,
            requiredSkills: ['API设计', '接口文档'],
            weight: 3.0,
            order: 3,
            dependencies: ['architecture_doc'],
            tags: ['API', '接口'],
          ),
          TaskStepTemplate(
            id: 'user_manual',
            title: '用户手册',
            description: '编写面向用户的操作手册',
            estimatedMinutes: 300,
            priority: TaskPriority.medium,
            requiredSkills: ['用户体验', '说明书写作'],
            weight: 2.0,
            order: 4,
            dependencies: ['api_documentation'],
            tags: ['用户', '手册'],
          ),
          TaskStepTemplate(
            id: 'documentation_review',
            title: '文档审核',
            description: '全面审核和完善文档',
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            requiredSkills: ['审核', '质量控制'],
            weight: 1.0,
            order: 5,
            dependencies: ['user_manual'],
            stepType: StepType.milestone,
            tags: ['审核', '完善'],
          ),
        ],
      );
}
