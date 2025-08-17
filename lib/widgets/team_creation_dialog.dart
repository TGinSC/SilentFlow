import 'package:flutter/material.dart';
import '../models/team_template_model.dart';
import '../models/task_model.dart';
import '../models/task_template_model.dart';
import '../services/enhanced_team_service.dart';
import '../services/task_service.dart';
import '../providers/team_pool_provider.dart';
import '../providers/app_provider.dart';
import 'package:provider/provider.dart';

class TeamCreationDialog extends StatefulWidget {
  final Map<String, dynamic>? initialTemplate;
  final bool isCustomCreation;

  const TeamCreationDialog({
    super.key,
    this.initialTemplate,
    this.isCustomCreation = false,
  });

  @override
  State<TeamCreationDialog> createState() => _TeamCreationDialogState();
}

class _TeamCreationDialogState extends State<TeamCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _teamDescriptionController = TextEditingController();

  TeamNature? _selectedNature;
  TeamTemplate? _selectedTemplate;
  bool _isLoading = false;
  int _maxMembers = 6;
  bool _isPrivate = false;

  // 所有可用的团队性质
  final List<TeamNature> _availableNatures = TeamNature.values;

  @override
  void initState() {
    super.initState();
    _initializeWithTemplate();
  }

  void _initializeWithTemplate() {
    if (widget.initialTemplate != null) {
      final template = widget.initialTemplate!;
      _teamNameController.text = template['name'] ?? '';
      _teamDescriptionController.text = template['description'] ?? '';

      // 根据模板名称匹配团队性质
      final templateName = template['name'] as String? ?? '';
      if (templateName.contains('软件开发')) {
        _selectedNature = TeamNature.softwareDevelopment;
      } else if (templateName.contains('协作写作')) {
        _selectedNature = TeamNature.writing;
      } else if (templateName.contains('学术论文')) {
        _selectedNature = TeamNature.research;
      } else if (templateName.contains('商业提案')) {
        _selectedNature = TeamNature.business;
      } else if (templateName.contains('技术文档')) {
        _selectedNature = TeamNature.writing;
      } else if (templateName.contains('研究项目')) {
        _selectedNature = TeamNature.research;
      } else if (templateName.contains('营销活动')) {
        _selectedNature = TeamNature.marketing;
      } else if (templateName.contains('设计项目')) {
        _selectedNature = TeamNature.design;
      }

      if (_selectedNature != null) {
        _selectedTemplate =
            DefaultTeamTemplates.getTemplateByNature(_selectedNature!);
        _maxMembers = _selectedTemplate?.recommendedMaxMembers ?? 6;
      }
    }
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _teamDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTeamBasicInfo(),
                      const SizedBox(height: 24),
                      _buildTeamNatureSelection(),
                      const SizedBox(height: 24),
                      if (_selectedTemplate != null) ...[
                        _buildTemplatePreview(),
                        const SizedBox(height: 24),
                      ],
                      _buildTeamSettings(),
                    ],
                  ),
                ),
              ),
            ),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.indigo[400]!,
            Colors.indigo[600]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.group_add,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '创建新团队',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isCustomCreation ? '自定义团队设置' : '基于模板创建团队',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '基本信息',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _teamNameController,
          decoration: InputDecoration(
            labelText: '团队名称',
            hintText: '为你的团队取个好名字',
            prefixIcon: const Icon(Icons.group),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入团队名称';
            }
            if (value.trim().length < 2) {
              return '团队名称至少需要2个字符';
            }
            if (value.trim().length > 30) {
              return '团队名称不能超过30个字符';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _teamDescriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: '团队描述',
            hintText: '简单描述团队目标和协作方式',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '请输入团队描述';
            }
            if (value.trim().length > 200) {
              return '团队描述不能超过200个字符';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTeamNatureSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '团队性质',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '选择最符合你团队工作内容的性质',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _availableNatures.map((nature) {
              final isSelected = _selectedNature == nature;
              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.indigo[50] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RadioListTile<TeamNature>(
                  value: nature,
                  groupValue: _selectedNature,
                  onChanged: (value) {
                    setState(() {
                      _selectedNature = value;
                      if (value != null) {
                        _selectedTemplate =
                            DefaultTeamTemplates.getTemplateByNature(value);
                        _maxMembers =
                            _selectedTemplate?.recommendedMaxMembers ?? 6;
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(nature.color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForNature(nature),
                          color: Color(nature.color),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nature.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nature.description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  activeColor: Colors.indigo,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatePreview() {
    if (_selectedTemplate == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.indigo),
              const SizedBox(width: 8),
              const Text(
                '模板预览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '推荐技能: ${_selectedTemplate!.recommendedSkills.take(3).join(', ')}${_selectedTemplate!.recommendedSkills.length > 3 ? ' 等' : ''}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '推荐成员数: ${_selectedTemplate!.recommendedMinMembers}-${_selectedTemplate!.recommendedMaxMembers}人',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          if (_selectedTemplate!.defaultTags.isNotEmpty) ...[
            Text(
              '默认标签: ${_selectedTemplate!.defaultTags.take(3).join(', ')}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '团队设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // 最大成员数设置
        Text(
          '最大成员数: $_maxMembers人',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _maxMembers.toDouble(),
          min: 2,
          max: 20,
          divisions: 18,
          label: '$_maxMembers人',
          onChanged: (value) {
            setState(() {
              _maxMembers = value.toInt();
            });
          },
          activeColor: Colors.indigo,
        ),
        const SizedBox(height: 16),

        // 隐私设置
        SwitchListTile(
          value: _isPrivate,
          onChanged: (value) {
            setState(() {
              _isPrivate = value;
            });
          },
          title: const Text(
            '私有团队',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _isPrivate ? '只有受邀请才能加入' : '其他用户可以申请加入',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          activeColor: Colors.indigo,
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '取消',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createTeam,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '创建团队',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForNature(TeamNature nature) {
    switch (nature) {
      case TeamNature.softwareDevelopment:
        return Icons.code;
      case TeamNature.research:
        return Icons.science;
      case TeamNature.business:
        return Icons.business_center;
      case TeamNature.design:
        return Icons.design_services;
      case TeamNature.marketing:
        return Icons.campaign;
      case TeamNature.writing:
        return Icons.edit_note;
      case TeamNature.education:
        return Icons.school;
      case TeamNature.event:
        return Icons.event;
    }
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedNature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择团队性质')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final teamPoolProvider =
          Provider.of<TeamPoolProvider>(context, listen: false);
      final currentUser = appProvider.currentUser;

      if (currentUser == null) {
        throw Exception('用户未登录');
      }

      // 使用增强的团队创建服务
      final newTeam = await TeamCreationService.createTeamFromNature(
        leaderId: currentUser.id,
        teamName: _teamNameController.text.trim(),
        description: _teamDescriptionController.text.trim(),
        teamNature: _selectedNature!,
        customTemplate: _selectedTemplate?.copyWith(
          teamSettings: {
            ..._selectedTemplate!.teamSettings,
            'isPrivate': _isPrivate,
            'maxMembers': _maxMembers,
          },
        ),
      );

      // 使用 TeamPoolProvider 的正确方法签名
      final success = await teamPoolProvider.createTeam(
        name: newTeam.name,
        description: newTeam.description,
        leaderId: newTeam.leaderId,
        teamType: newTeam.teamType,
        maxMembers: _maxMembers,
        isPublic: !_isPrivate,
        requireApproval: true,
        tags: newTeam.tags,
      );

      if (success) {
        // 为新创建的团队自动创建主项目
        await _createMainProjectForTeam(newTeam);

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('团队 "${newTeam.name}" 创建成功！已自动创建主项目'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: '查看',
                textColor: Colors.white,
                onPressed: () {
                  // 跳转到团队详情
                },
              ),
            ),
          );
        }
      } else {
        throw Exception(teamPoolProvider.error ?? '创建团队失败');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建团队失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 为团队创建主项目
  Future<void> _createMainProjectForTeam(dynamic newTeam) async {
    try {
      // 创建团队的主项目（主任务）
      final mainProject = await TaskService.createTask(
        teamId: newTeam.id,
        title: newTeam.name, // 使用团队名作为主项目名
        description: '${newTeam.name}的主要项目任务',
        estimatedMinutes: 480, // 默认8小时
        priority: TaskPriority.high,
        level: TaskLevel.project,
        tags: ['主项目', ...newTeam.tags],
      );

      // 如果使用了模板，根据模板创建对应的子任务
      if (_selectedTemplate != null && mainProject != null) {
        await _createSubTasksFromTemplate(
            newTeam.id, mainProject.id, _selectedTemplate!);
      }
    } catch (e) {
      print('创建主项目失败: $e');
      // 即使主项目创建失败，也不影响团队创建成功的提示
    }
  }

  // 根据模板创建子任务
  Future<void> _createSubTasksFromTemplate(
      String teamId, String parentTaskId, TeamTemplate template) async {
    try {
      // 获取模板对应的任务模板列表
      final taskTemplates = await _getTaskTemplatesForTeamTemplate(template);

      for (final taskTemplate in taskTemplates) {
        // 为每个任务模板创建子任务
        final task = await TaskService.createTask(
          teamId: teamId,
          title: taskTemplate.name, // 使用 name 而不是 title
          description: taskTemplate.description,
          estimatedMinutes: taskTemplate.estimatedMinutes,
          priority: taskTemplate.priority,
          level: TaskLevel.task,
          parentTaskId: parentTaskId,
          tags: taskTemplate.tags,
        );

        // 为特定类型的任务创建详细的子任务点
        if (task != null) {
          await _createDetailedSubTasks(teamId, task.id, taskTemplate);
        }
      }
    } catch (e) {
      print('从模板创建子任务失败: $e');
    }
  }

  // 为每个任务创建详细的子任务点
  Future<void> _createDetailedSubTasks(
      String teamId, String parentTaskId, TaskTemplate template) async {
    List<Map<String, dynamic>> subTasks = [];

    // 根据任务类别创建相应的子任务点
    switch (template.category) {
      case '前端':
        subTasks = [
          {
            'title': '界面设计原型',
            'description': '设计用户界面原型和交互流程',
            'estimatedMinutes': 120,
            'priority': TaskPriority.high,
            'tags': ['UI设计', '原型'],
          },
          {
            'title': '响应式布局开发',
            'description': '实现跨设备的响应式页面布局',
            'estimatedMinutes': 180,
            'priority': TaskPriority.medium,
            'tags': ['响应式', '布局'],
          },
          {
            'title': '组件开发',
            'description': '开发可复用的UI组件',
            'estimatedMinutes': 240,
            'priority': TaskPriority.medium,
            'tags': ['组件', '复用'],
          },
          {
            'title': '状态管理',
            'description': '实现前端状态管理和数据流',
            'estimatedMinutes': 120,
            'priority': TaskPriority.medium,
            'tags': ['状态管理', '数据流'],
          },
        ];
        break;

      case '后端':
        subTasks = [
          {
            'title': 'API接口设计',
            'description': '设计RESTful API接口规范',
            'estimatedMinutes': 120,
            'priority': TaskPriority.high,
            'tags': ['API', '接口设计'],
          },
          {
            'title': '业务逻辑实现',
            'description': '实现核心业务逻辑和算法',
            'estimatedMinutes': 300,
            'priority': TaskPriority.high,
            'tags': ['业务逻辑', '算法'],
          },
          {
            'title': '数据访问层',
            'description': '实现数据库访问和ORM映射',
            'estimatedMinutes': 180,
            'priority': TaskPriority.medium,
            'tags': ['数据访问', 'ORM'],
          },
          {
            'title': '认证授权',
            'description': '实现用户认证和权限控制',
            'estimatedMinutes': 180,
            'priority': TaskPriority.high,
            'tags': ['认证', '授权'],
          },
        ];
        break;

      case '数据库':
        subTasks = [
          {
            'title': '表结构设计',
            'description': '设计数据库表结构和关系',
            'estimatedMinutes': 120,
            'priority': TaskPriority.high,
            'tags': ['表结构', '关系设计'],
          },
          {
            'title': '索引优化',
            'description': '创建和优化数据库索引',
            'estimatedMinutes': 90,
            'priority': TaskPriority.medium,
            'tags': ['索引', '优化'],
          },
          {
            'title': '数据迁移',
            'description': '编写数据库迁移脚本',
            'estimatedMinutes': 60,
            'priority': TaskPriority.medium,
            'tags': ['迁移', '脚本'],
          },
        ];
        break;

      case '测试运维':
        subTasks = [
          {
            'title': '单元测试',
            'description': '编写和执行单元测试用例',
            'estimatedMinutes': 180,
            'priority': TaskPriority.high,
            'tags': ['单元测试', '测试用例'],
          },
          {
            'title': '集成测试',
            'description': '进行系统集成测试',
            'estimatedMinutes': 120,
            'priority': TaskPriority.medium,
            'tags': ['集成测试', '系统测试'],
          },
          {
            'title': '部署配置',
            'description': '配置生产环境和部署脚本',
            'estimatedMinutes': 150,
            'priority': TaskPriority.medium,
            'tags': ['部署', '配置'],
          },
          {
            'title': '监控告警',
            'description': '设置系统监控和告警机制',
            'estimatedMinutes': 120,
            'priority': TaskPriority.low,
            'tags': ['监控', '告警'],
          },
        ];
        break;

      default:
        // 对于其他类别，创建通用的子任务点
        subTasks = [
          {
            'title': '任务分解',
            'description': '将任务分解为更小的执行单元',
            'estimatedMinutes': 60,
            'priority': TaskPriority.medium,
            'tags': ['分解', '规划'],
          },
          {
            'title': '执行实施',
            'description': '具体执行任务内容',
            'estimatedMinutes': template.estimatedMinutes ~/ 2,
            'priority': TaskPriority.medium,
            'tags': ['执行', '实施'],
          },
          {
            'title': '质量检查',
            'description': '检查任务完成质量',
            'estimatedMinutes': 30,
            'priority': TaskPriority.medium,
            'tags': ['质量', '检查'],
          },
        ];
    }

    // 创建所有子任务点
    for (final subTask in subTasks) {
      await TaskService.createTask(
        teamId: teamId,
        title: subTask['title'],
        description: subTask['description'],
        estimatedMinutes: subTask['estimatedMinutes'],
        priority: subTask['priority'],
        level: TaskLevel.taskPoint,
        parentTaskId: parentTaskId,
        tags: List<String>.from(subTask['tags']),
      );
    }
  }

  // 获取团队模板对应的任务模板
  Future<List<TaskTemplate>> _getTaskTemplatesForTeamTemplate(
      TeamTemplate teamTemplate) async {
    // 根据团队性质返回相应的任务模板
    switch (_selectedNature) {
      case TeamNature.softwareDevelopment:
        return [
          TaskTemplate(
            id: 'dev_1',
            name: '需求分析',
            description: '分析项目需求，制定开发计划',
            category: '开发',
            type: TaskTemplateType.structured,
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            tags: ['分析', '规划'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'dev_2',
            name: '系统设计',
            description: '设计系统架构和数据库结构',
            category: '开发',
            type: TaskTemplateType.structured,
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            tags: ['设计', '架构'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'dev_3',
            name: '前端开发',
            description: '开发用户界面和交互功能',
            category: '前端',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 360,
            priority: TaskPriority.high,
            tags: ['前端', 'UI', '交互'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'dev_4',
            name: '后端开发',
            description: '开发服务器端逻辑和API接口',
            category: '后端',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 480,
            priority: TaskPriority.high,
            tags: ['后端', 'API', '服务器'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'dev_5',
            name: '数据库设计',
            description: '设计和优化数据库结构',
            category: '数据库',
            type: TaskTemplateType.structured,
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            tags: ['数据库', '设计', '优化'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'dev_6',
            name: '测试运维',
            description: '系统测试、部署和运维监控',
            category: '测试运维',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            tags: ['测试', '部署', '运维'],
            createdAt: DateTime.now(),
          ),
        ];

      case TeamNature.research:
        return [
          TaskTemplate(
            id: 'research_1',
            name: '文献调研',
            description: '收集和分析相关研究文献',
            category: '研究',
            type: TaskTemplateType.structured,
            estimatedMinutes: 240,
            priority: TaskPriority.high,
            tags: ['调研', '文献'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'research_2',
            name: '实验设计',
            description: '设计实验方案和流程',
            category: '研究',
            type: TaskTemplateType.structured,
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            tags: ['实验', '设计'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'research_3',
            name: '数据收集',
            description: '执行实验并收集数据',
            category: '研究',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 360,
            priority: TaskPriority.medium,
            tags: ['数据', '收集'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'research_4',
            name: '结果分析',
            description: '分析实验结果并得出结论',
            category: '研究',
            type: TaskTemplateType.structured,
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            tags: ['分析', '总结'],
            createdAt: DateTime.now(),
          ),
        ];

      case TeamNature.marketing:
        return [
          TaskTemplate(
            id: 'marketing_1',
            name: '市场调研',
            description: '分析目标市场和竞争对手',
            category: '营销',
            type: TaskTemplateType.structured,
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            tags: ['调研', '市场'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'marketing_2',
            name: '策略制定',
            description: '制定营销策略和推广计划',
            category: '营销',
            type: TaskTemplateType.structured,
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            tags: ['策略', '计划'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'marketing_3',
            name: '内容创作',
            description: '创作营销内容和宣传素材',
            category: '营销',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            tags: ['内容', '创作'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'marketing_4',
            name: '推广执行',
            description: '执行推广活动和效果跟踪',
            category: '营销',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 180,
            priority: TaskPriority.medium,
            tags: ['推广', '执行'],
            createdAt: DateTime.now(),
          ),
        ];

      case TeamNature.design:
        return [
          TaskTemplate(
            id: 'design_1',
            name: '需求调研',
            description: '了解设计需求和用户期望',
            category: '设计',
            type: TaskTemplateType.structured,
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            tags: ['调研', '需求'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'design_2',
            name: '概念设计',
            description: '制作初步设计概念和方案',
            category: '设计',
            type: TaskTemplateType.structured,
            estimatedMinutes: 180,
            priority: TaskPriority.high,
            tags: ['概念', '设计'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'design_3',
            name: '详细设计',
            description: '完善设计细节和规范',
            category: '设计',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            tags: ['详细', '完善'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'design_4',
            name: '设计验证',
            description: '验证设计效果和用户反馈',
            category: '设计',
            type: TaskTemplateType.structured,
            estimatedMinutes: 90,
            priority: TaskPriority.medium,
            tags: ['验证', '反馈'],
            createdAt: DateTime.now(),
          ),
        ];

      default:
        // 对于其他性质的团队，返回通用的任务模板
        return [
          TaskTemplate(
            id: 'general_1',
            name: '项目规划',
            description: '制定项目计划和时间安排',
            category: '通用',
            type: TaskTemplateType.structured,
            estimatedMinutes: 120,
            priority: TaskPriority.high,
            tags: ['规划', '计划'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'general_2',
            name: '任务执行',
            description: '执行核心项目任务',
            category: '通用',
            type: TaskTemplateType.collaborative,
            estimatedMinutes: 240,
            priority: TaskPriority.medium,
            tags: ['执行', '核心'],
            createdAt: DateTime.now(),
          ),
          TaskTemplate(
            id: 'general_3',
            name: '进度跟踪',
            description: '跟踪项目进度和质量',
            category: '通用',
            type: TaskTemplateType.simple,
            estimatedMinutes: 60,
            priority: TaskPriority.low,
            tags: ['跟踪', '质量'],
            createdAt: DateTime.now(),
          ),
        ];
    }
  }
}

// 扩展 TeamTemplate 以支持 copyWith
extension TeamTemplateExtension on TeamTemplate {
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
