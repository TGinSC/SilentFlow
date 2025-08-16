import 'package:flutter/material.dart';
import '../../models/user_model.dart';

// 个人资料编辑页面
// 用户可以编辑技能、兴趣、工作风格等信息
class ProfileEditScreen extends StatefulWidget {
  final String userId;
  final User? currentUser;

  const ProfileEditScreen({
    Key? key,
    required this.userId,
    this.currentUser,
  }) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bioController = TextEditingController();
  final _departmentController = TextEditingController();
  final _roleController = TextEditingController();

  List<UserSkill> _skills = [];
  List<String> _interests = [];
  List<String> _preferredTaskTypes = [];

  WorkStyle _workStyle = const WorkStyle(
    communicationStyle: '平衡',
    workPace: '稳定',
    preferredCollaborationMode: '混合',
    stressHandling: '正常',
    feedbackStyle: '建设性',
  );

  AvailabilityInfo _availability = const AvailabilityInfo();
  ContactInfo _contact = const ContactInfo();

  bool _isLoading = false;
  bool _isEditing = false;

  // 预定义的技能选项
  final List<String> _skillOptions = [
    'Flutter开发',
    'Java开发',
    'Python编程',
    '前端开发',
    '后端开发',
    '数据库设计',
    'UI/UX设计',
    '项目管理',
    '团队协作',
    '沟通表达',
    '问题解决',
    '创新思维',
    '时间管理',
    '文档编写',
    '测试调试',
    '系统架构',
    '算法设计',
    '数据分析',
    '产品设计',
    '用户研究'
  ];

  // 预定义的兴趣选项
  final List<String> _interestOptions = [
    '技术研究',
    '产品设计',
    '用户体验',
    '数据分析',
    '人工智能',
    '移动开发',
    'Web开发',
    '游戏开发',
    '区块链',
    '云计算',
    '物联网',
    '机器学习',
    '网络安全',
    '开源项目',
    '创业创新'
  ];

  // 预定义的任务类型选项
  final List<String> _taskTypeOptions = [
    '开发任务',
    '设计任务',
    '测试任务',
    '文档任务',
    '研究任务',
    '管理任务',
    '协调任务',
    '培训任务',
    '优化任务',
    '维护任务'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() {
    if (widget.currentUser != null) {
      final user = widget.currentUser!;
      _bioController.text = user.profile.bio ?? '';
      _departmentController.text = user.profile.department ?? '';
      _roleController.text = user.profile.role ?? '';

      _skills = List.from(user.profile.skills);
      _interests = List.from(user.profile.interests);
      _preferredTaskTypes = List.from(user.profile.preferredTaskTypes);
      _workStyle = user.profile.workStyle;
      _availability = user.profile.availability;
      _contact = user.profile.contact;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _saveProfile,
              child: const Text('保存', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInfoSection(),
                    const SizedBox(height: 24),
                    _buildSkillsSection(),
                    const SizedBox(height: 24),
                    _buildInterestsSection(),
                    const SizedBox(height: 24),
                    _buildTaskPreferencesSection(),
                    const SizedBox(height: 24),
                    _buildWorkStyleSection(),
                    const SizedBox(height: 24),
                    _buildAvailabilitySection(),
                    const SizedBox(height: 24),
                    _buildContactSection(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: '个人简介',
                hintText: '简单介绍一下你自己...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: _isEditing,
              onChanged: (_) => _markAsEditing(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: '部门/专业',
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              onChanged: (_) => _markAsEditing(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: '角色/职位',
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              onChanged: (_) => _markAsEditing(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '技能专长',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_isEditing)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _showAddSkillDialog,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _skills.isEmpty
                ? const Text('还没有添加技能信息')
                : Column(
                    children: _skills.map(_buildSkillItem).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillItem(UserSkill skill) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(skill.name),
        subtitle: Text('${skill.levelText} • ${skill.experienceYears}年经验'),
        trailing: _isEditing
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditSkillDialog(skill),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeSkill(skill),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildInterestsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '兴趣领域',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ..._interests.map((interest) => Chip(
                      label: Text(interest),
                      deleteIcon: _isEditing ? const Icon(Icons.close) : null,
                      onDeleted:
                          _isEditing ? () => _removeInterest(interest) : null,
                    )),
                if (_isEditing)
                  ActionChip(
                    label: const Text('+ 添加兴趣'),
                    onPressed: _showAddInterestDialog,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '任务偏好',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ..._preferredTaskTypes.map((type) => Chip(
                      label: Text(type),
                      deleteIcon: _isEditing ? const Icon(Icons.close) : null,
                      onDeleted:
                          _isEditing ? () => _removeTaskType(type) : null,
                    )),
                if (_isEditing)
                  ActionChip(
                    label: const Text('+ 添加偏好'),
                    onPressed: _showAddTaskTypeDialog,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStyleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '工作风格',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildWorkStyleItem(
                '沟通风格', _workStyle.communicationStyle, ['直接', '委婉', '详细', '简洁'],
                (value) {
              _workStyle = WorkStyle(
                communicationStyle: value,
                workPace: _workStyle.workPace,
                preferredCollaborationMode:
                    _workStyle.preferredCollaborationMode,
                stressHandling: _workStyle.stressHandling,
                feedbackStyle: _workStyle.feedbackStyle,
              );
            }),
            _buildWorkStyleItem('工作节奏', _workStyle.workPace, ['快速', '稳定', '灵活'],
                (value) {
              _workStyle = WorkStyle(
                communicationStyle: _workStyle.communicationStyle,
                workPace: value,
                preferredCollaborationMode:
                    _workStyle.preferredCollaborationMode,
                stressHandling: _workStyle.stressHandling,
                feedbackStyle: _workStyle.feedbackStyle,
              );
            }),
            _buildWorkStyleItem('协作偏好', _workStyle.preferredCollaborationMode,
                ['独立', '团队', '混合'], (value) {
              _workStyle = WorkStyle(
                communicationStyle: _workStyle.communicationStyle,
                workPace: _workStyle.workPace,
                preferredCollaborationMode: value,
                stressHandling: _workStyle.stressHandling,
                feedbackStyle: _workStyle.feedbackStyle,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStyleItem(String title, String currentValue,
      List<String> options, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: currentValue,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: options
                  .map((option) => DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ))
                  .toList(),
              onChanged: _isEditing
                  ? (value) {
                      setState(() {
                        onChanged(value!);
                      });
                      _markAsEditing();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '时间可用性',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('每周最大投入时间：'),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _availability.maxHoursPerWeek.toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      suffixText: '小时',
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _isEditing,
                    onChanged: (value) {
                      final hours = int.tryParse(value) ?? 40;
                      _availability = AvailabilityInfo(
                        weeklySchedule: _availability.weeklySchedule,
                        timezone: _availability.timezone,
                        maxHoursPerWeek: hours,
                        busyPeriods: _availability.busyPeriods,
                        vacationInfo: _availability.vacationInfo,
                      );
                      _markAsEditing();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '联系方式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _contact.email,
              decoration: const InputDecoration(
                labelText: '邮箱',
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              onChanged: (value) {
                _contact = ContactInfo(
                  email: value,
                  phone: _contact.phone,
                  wechat: _contact.wechat,
                  qq: _contact.qq,
                  socialMedia: _contact.socialMedia,
                );
                _markAsEditing();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _contact.wechat,
              decoration: const InputDecoration(
                labelText: '微信',
                border: OutlineInputBorder(),
              ),
              enabled: _isEditing,
              onChanged: (value) {
                _contact = ContactInfo(
                  email: _contact.email,
                  phone: _contact.phone,
                  wechat: value,
                  qq: _contact.qq,
                  socialMedia: _contact.socialMedia,
                );
                _markAsEditing();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isEditing
                ? null
                : () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
            child: const Text('编辑资料'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _isEditing ? _cancelEdit : null,
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }

  void _markAsEditing() {
    if (!_isEditing) {
      setState(() {
        _isEditing = true;
      });
    }
  }

  void _showAddSkillDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSkillDialog(
        skillOptions: _skillOptions,
        onSkillAdded: (skill) {
          setState(() {
            _skills.add(skill);
          });
          _markAsEditing();
        },
      ),
    );
  }

  void _showEditSkillDialog(UserSkill skill) {
    showDialog(
      context: context,
      builder: (context) => AddSkillDialog(
        skillOptions: _skillOptions,
        initialSkill: skill,
        onSkillAdded: (updatedSkill) {
          setState(() {
            final index = _skills.indexOf(skill);
            _skills[index] = updatedSkill;
          });
          _markAsEditing();
        },
      ),
    );
  }

  void _removeSkill(UserSkill skill) {
    setState(() {
      _skills.remove(skill);
    });
    _markAsEditing();
  }

  void _showAddInterestDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        title: '添加兴趣领域',
        options: _interestOptions,
        selectedItems: _interests,
        onItemsSelected: (selected) {
          setState(() {
            _interests = selected;
          });
          _markAsEditing();
        },
      ),
    );
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
    _markAsEditing();
  }

  void _showAddTaskTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        title: '添加任务偏好',
        options: _taskTypeOptions,
        selectedItems: _preferredTaskTypes,
        onItemsSelected: (selected) {
          setState(() {
            _preferredTaskTypes = selected;
          });
          _markAsEditing();
        },
      ),
    );
  }

  void _removeTaskType(String taskType) {
    setState(() {
      _preferredTaskTypes.remove(taskType);
    });
    _markAsEditing();
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _loadUserProfile(); // 重新加载原始数据
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 这里应该调用API保存用户资料
      // await UserService.updateUserProfile(widget.userId, profile);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('个人资料已保存')),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    _departmentController.dispose();
    _roleController.dispose();
    super.dispose();
  }
}

// 添加技能对话框
class AddSkillDialog extends StatefulWidget {
  final List<String> skillOptions;
  final UserSkill? initialSkill;
  final Function(UserSkill) onSkillAdded;

  const AddSkillDialog({
    Key? key,
    required this.skillOptions,
    this.initialSkill,
    required this.onSkillAdded,
  }) : super(key: key);

  @override
  State<AddSkillDialog> createState() => _AddSkillDialogState();
}

class _AddSkillDialogState extends State<AddSkillDialog> {
  final _nameController = TextEditingController();
  int _level = 1;
  int _experienceYears = 0;
  String? _certificate;

  @override
  void initState() {
    super.initState();
    if (widget.initialSkill != null) {
      final skill = widget.initialSkill!;
      _nameController.text = skill.name;
      _level = skill.level;
      _experienceYears = skill.experienceYears;
      _certificate = skill.certificate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialSkill == null ? '添加技能' : '编辑技能'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: widget.skillOptions.contains(_nameController.text)
                  ? _nameController.text
                  : null,
              decoration: const InputDecoration(
                labelText: '选择技能',
                border: OutlineInputBorder(),
              ),
              items: widget.skillOptions
                  .map((skill) => DropdownMenuItem(
                        value: skill,
                        child: Text(skill),
                      ))
                  .toList(),
              onChanged: (value) {
                _nameController.text = value ?? '';
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '技能名称（或自定义）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _level,
              decoration: const InputDecoration(
                labelText: '熟练程度',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                  5,
                  (index) => DropdownMenuItem(
                        value: index + 1,
                        child:
                            Text('${index + 1} - ${_getLevelText(index + 1)}'),
                      )),
              onChanged: (value) {
                setState(() {
                  _level = value ?? 1;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _experienceYears.toString(),
              decoration: const InputDecoration(
                labelText: '经验年限',
                border: OutlineInputBorder(),
                suffixText: '年',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _experienceYears = int.tryParse(value) ?? 0;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _certificate,
              decoration: const InputDecoration(
                labelText: '认证信息（可选）',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _certificate = value.isEmpty ? null : value;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _saveSkill,
          child: const Text('保存'),
        ),
      ],
    );
  }

  String _getLevelText(int level) {
    switch (level) {
      case 1:
        return '入门';
      case 2:
        return '初级';
      case 3:
        return '中级';
      case 4:
        return '高级';
      case 5:
        return '专家';
      default:
        return '未知';
    }
  }

  void _saveSkill() {
    if (_nameController.text.isEmpty) return;

    final skill = UserSkill(
      name: _nameController.text,
      level: _level,
      experienceYears: _experienceYears,
      certificate: _certificate,
      lastUsed: DateTime.now(),
    );

    widget.onSkillAdded(skill);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

// 添加条目对话框
class AddItemDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedItems;
  final Function(List<String>) onItemsSelected;

  const AddItemDialog({
    Key? key,
    required this.title,
    required this.options,
    required this.selectedItems,
    required this.onItemsSelected,
  }) : super(key: key);

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  late List<String> _selected;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            // 自定义输入
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    decoration: const InputDecoration(
                      hintText: '自定义添加...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addCustomItem,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 预设选项
            Expanded(
              child: ListView.builder(
                itemCount: widget.options.length,
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final isSelected = _selected.contains(option);

                  return CheckboxListTile(
                    title: Text(option),
                    value: isSelected,
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selected.add(option);
                        } else {
                          _selected.remove(option);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            // 已选择的条目
            if (_selected.isNotEmpty)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _selected
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(item),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () {
                                  setState(() {
                                    _selected.remove(item);
                                  });
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onItemsSelected(_selected);
            Navigator.of(context).pop();
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _addCustomItem() {
    final text = _customController.text.trim();
    if (text.isNotEmpty && !_selected.contains(text)) {
      setState(() {
        _selected.add(text);
      });
      _customController.clear();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}
