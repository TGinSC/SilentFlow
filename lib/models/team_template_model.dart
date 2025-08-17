// 团队性质枚举
enum TeamNature {
  softwareDevelopment(
    name: '软件开发',
    description: '专注于软件产品的设计、开发和维护',
    icon: 'code',
    color: 0xFF2196F3,
  ),
  research(
    name: '研究调研',
    description: '进行学术研究、市场调研和数据分析',
    icon: 'research',
    color: 0xFF4CAF50,
  ),
  business(
    name: '商业企划',
    description: '商业策划、市场营销和业务拓展',
    icon: 'business',
    color: 0xFFFF9800,
  ),
  design(
    name: '设计创意',
    description: '视觉设计、产品设计和创意策划',
    icon: 'design',
    color: 0xFFE91E63,
  ),
  marketing(
    name: '市场推广',
    description: '品牌推广、内容营销和渠道拓展',
    icon: 'marketing',
    color: 0xFF9C27B0,
  ),
  writing(
    name: '内容创作',
    description: '文案写作、内容编辑和媒体制作',
    icon: 'edit',
    color: 0xFF607D8B,
  ),
  education(
    name: '教育培训',
    description: '教学设计、培训开发和知识传播',
    icon: 'school',
    color: 0xFF795548,
  ),
  event(
    name: '活动策划',
    description: '活动组织、项目协调和执行管理',
    icon: 'event',
    color: 0xFFFF5722,
  );

  const TeamNature({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String name;
  final String description;
  final String icon;
  final int color;
}

// 团队模板类
class TeamTemplate {
  final String id;
  final String name; // 团队性质名称，如"软件开发团队"
  final String description; // 详细描述
  final String category; // 大类别：技术、研究、商业、创意等
  final String icon; // 图标名称
  final String color; // 主题色
  final List<String> availableTaskTemplateIds; // 可用的任务模板ID列表
  final List<String> recommendedSkills; // 推荐技能标签
  final List<String> defaultTags; // 默认团队标签
  final int recommendedMinMembers; // 推荐最小成员数
  final int recommendedMaxMembers; // 推荐最大成员数
  final Map<String, dynamic> teamSettings; // 团队默认设置
  final bool isActive; // 是否启用

  const TeamTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    this.availableTaskTemplateIds = const [],
    this.recommendedSkills = const [],
    this.defaultTags = const [],
    this.recommendedMinMembers = 2,
    this.recommendedMaxMembers = 8,
    this.teamSettings = const {},
    this.isActive = true,
  });

  // 从JSON创建对象
  factory TeamTemplate.fromJson(Map<String, dynamic> json) {
    return TeamTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      availableTaskTemplateIds:
          List<String>.from(json['availableTaskTemplateIds'] ?? []),
      recommendedSkills: List<String>.from(json['recommendedSkills'] ?? []),
      defaultTags: List<String>.from(json['defaultTags'] ?? []),
      recommendedMinMembers: json['recommendedMinMembers'] as int? ?? 2,
      recommendedMaxMembers: json['recommendedMaxMembers'] as int? ?? 8,
      teamSettings: Map<String, dynamic>.from(json['teamSettings'] ?? {}),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'icon': icon,
      'color': color,
      'availableTaskTemplateIds': availableTaskTemplateIds,
      'recommendedSkills': recommendedSkills,
      'defaultTags': defaultTags,
      'recommendedMinMembers': recommendedMinMembers,
      'recommendedMaxMembers': recommendedMaxMembers,
      'teamSettings': teamSettings,
      'isActive': isActive,
    };
  }

  // 复制并修改
  TeamTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? icon,
    String? color,
    List<String>? availableTaskTemplateIds,
    List<String>? recommendedSkills,
    List<String>? defaultTags,
    int? recommendedMinMembers,
    int? recommendedMaxMembers,
    Map<String, dynamic>? teamSettings,
    bool? isActive,
  }) {
    return TeamTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      availableTaskTemplateIds:
          availableTaskTemplateIds ?? this.availableTaskTemplateIds,
      recommendedSkills: recommendedSkills ?? this.recommendedSkills,
      defaultTags: defaultTags ?? this.defaultTags,
      recommendedMinMembers:
          recommendedMinMembers ?? this.recommendedMinMembers,
      recommendedMaxMembers:
          recommendedMaxMembers ?? this.recommendedMaxMembers,
      teamSettings: teamSettings ?? this.teamSettings,
      isActive: isActive ?? this.isActive,
    );
  }
}

// 默认团队模板
class DefaultTeamTemplates {
  // 根据团队性质获取对应模板
  static TeamTemplate getTemplateByNature(TeamNature nature) {
    switch (nature) {
      case TeamNature.softwareDevelopment:
        return softwareDevelopmentTeam;
      case TeamNature.research:
        return researchTeam;
      case TeamNature.business:
        return businessTeam;
      case TeamNature.design:
        return designTeam;
      case TeamNature.marketing:
        return marketingTeam;
      case TeamNature.writing:
        return writingTeam;
      case TeamNature.education:
        return educationTeam;
      case TeamNature.event:
        return eventTeam;
    }
  }

  static List<TeamTemplate> get all => [
        softwareDevelopmentTeam,
        researchTeam,
        businessTeam,
        designTeam,
        marketingTeam,
        writingTeam,
        educationTeam,
        eventTeam,
      ];

  // 软件开发团队
  static TeamTemplate get softwareDevelopmentTeam => TeamTemplate(
        id: 'team_software_dev',
        name: '软件开发团队',
        description: '专注于软件产品开发，包含前端、后端、测试等角色',
        category: '技术',
        icon: 'code',
        color: '#2196F3',
        availableTaskTemplateIds: [
          'template_software_dev',
          'template_tech_documentation',
          'template_code_review',
          'template_bug_fixing',
        ],
        recommendedSkills: ['编程', '软件设计', '测试', '项目管理', 'Git'],
        defaultTags: ['开发', '技术', '软件'],
        recommendedMinMembers: 3,
        recommendedMaxMembers: 8,
        teamSettings: {
          'allowTaskClaim': true,
          'requireCodeReview': true,
          'dailyStandup': true,
        },
      );

  // 研究团队
  static TeamTemplate get researchTeam => TeamTemplate(
        id: 'team_research',
        name: '学术研究团队',
        description: '从事学术研究，论文撰写，数据分析等工作',
        category: '学术',
        icon: 'science',
        color: '#4CAF50',
        availableTaskTemplateIds: [
          'template_research',
          'template_academic_paper',
          'template_data_analysis',
          'template_literature_review',
        ],
        recommendedSkills: ['研究方法', '数据分析', '学术写作', '文献综述'],
        defaultTags: ['研究', '学术', '论文'],
        recommendedMinMembers: 2,
        recommendedMaxMembers: 6,
        teamSettings: {
          'allowAnonymousReview': true,
          'requirePeerReview': true,
          'trackCitations': true,
        },
      );

  // 商业团队
  static TeamTemplate get businessTeam => TeamTemplate(
        id: 'team_business',
        name: '商业策划团队',
        description: '商业计划制定，市场分析，财务规划等商业活动',
        category: '商业',
        icon: 'business_center',
        color: '#FF9800',
        availableTaskTemplateIds: [
          'template_business_proposal',
          'template_market_research',
          'template_financial_planning',
          'template_competitor_analysis',
        ],
        recommendedSkills: ['商业分析', '财务规划', '市场研究', '演示制作'],
        defaultTags: ['商业', '策划', '分析'],
        recommendedMinMembers: 3,
        recommendedMaxMembers: 8,
        teamSettings: {
          'requireFinancialReview': true,
          'trackROI': true,
          'allowClientAccess': false,
        },
      );

  // 设计团队
  static TeamTemplate get designTeam => TeamTemplate(
        id: 'team_design',
        name: '创意设计团队',
        description: 'UI/UX设计，平面设计，品牌设计等创意工作',
        category: '创意',
        icon: 'design_services',
        color: '#E91E63',
        availableTaskTemplateIds: [
          'template_design_project',
          'template_ui_ux_design',
          'template_brand_design',
          'template_prototype_creation',
        ],
        recommendedSkills: ['UI设计', 'UX设计', '平面设计', '原型制作', '用户研究'],
        defaultTags: ['设计', '创意', 'UI'],
        recommendedMinMembers: 2,
        recommendedMaxMembers: 6,
        teamSettings: {
          'requireDesignReview': true,
          'trackDesignVersions': true,
          'allowClientFeedback': true,
        },
      );

  // 营销团队
  static TeamTemplate get marketingTeam => TeamTemplate(
        id: 'team_marketing',
        name: '市场营销团队',
        description: '营销策划，内容创作，社媒运营等市场推广工作',
        category: '营销',
        icon: 'campaign',
        color: '#9C27B0',
        availableTaskTemplateIds: [
          'template_marketing_campaign',
          'template_content_creation',
          'template_social_media',
          'template_event_planning',
        ],
        recommendedSkills: ['营销策划', '内容创作', '社媒运营', '数据分析', '活动策划'],
        defaultTags: ['营销', '推广', '内容'],
        recommendedMinMembers: 2,
        recommendedMaxMembers: 8,
        teamSettings: {
          'trackCampaignMetrics': true,
          'allowPublicContent': true,
          'requireContentApproval': true,
        },
      );

  // 写作团队
  static TeamTemplate get writingTeam => TeamTemplate(
        id: 'team_writing',
        name: '协作写作团队',
        description: '文档编写，书籍创作，技术写作等协作写作项目',
        category: '写作',
        icon: 'edit_note',
        color: '#3F51B5',
        availableTaskTemplateIds: [
          'template_collaborative_writing',
          'template_technical_writing',
          'template_book_writing',
          'template_documentation',
        ],
        recommendedSkills: ['写作', '编辑', '文档规范', '内容策划', '校对'],
        defaultTags: ['写作', '文档', '协作'],
        recommendedMinMembers: 2,
        recommendedMaxMembers: 6,
        teamSettings: {
          'requirePeerReview': true,
          'trackWritingProgress': true,
          'allowAnonymousEdit': false,
        },
      );

  // 教育团队
  static TeamTemplate get educationTeam => TeamTemplate(
        id: 'team_education',
        name: '教育培训团队',
        description: '课程开发，教学设计，培训材料制作等教育相关工作',
        category: '教育',
        icon: 'school',
        color: '#607D8B',
        availableTaskTemplateIds: [
          'template_course_development',
          'template_training_material',
          'template_curriculum_design',
          'template_assessment_creation',
        ],
        recommendedSkills: ['教学设计', '课程开发', '内容创作', '评估设计', '多媒体制作'],
        defaultTags: ['教育', '培训', '课程'],
        recommendedMinMembers: 2,
        recommendedMaxMembers: 8,
        teamSettings: {
          'requirePedagogicalReview': true,
          'trackLearningOutcomes': true,
          'allowStudentFeedback': true,
        },
      );

  // 活动团队
  static TeamTemplate get eventTeam => TeamTemplate(
        id: 'team_event',
        name: '活动策划团队',
        description: '会议组织，活动策划，项目执行等事件管理工作',
        category: '活动',
        icon: 'event',
        color: '#795548',
        availableTaskTemplateIds: [
          'template_event_planning',
          'template_conference_organization',
          'template_workshop_planning',
          'template_logistics_management',
        ],
        recommendedSkills: ['活动策划', '项目管理', '协调沟通', '预算管理', '执行力'],
        defaultTags: ['活动', '策划', '执行'],
        recommendedMinMembers: 3,
        recommendedMaxMembers: 10,
        teamSettings: {
          'requireTimelineTracking': true,
          'trackBudget': true,
          'allowVendorAccess': false,
        },
      );
}
