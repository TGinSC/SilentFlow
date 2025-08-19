import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/team_template_model.dart';
import '../providers/team_pool_provider.dart';
import '../providers/app_provider.dart';
import '../widgets/debug_info_dialog.dart';
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
          // 添加调试按钮
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DebugInfoDialog(),
              );
            },
            icon: const Icon(Icons.bug_report, color: Colors.white70),
            tooltip: '网络调试',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请选择团队性质'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Web环境的特殊处理
    if (kIsWeb) {
      _showWebEnvironmentDialog();
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
        throw Exception('用户未登录，请先登录后再创建团队');
      }

      print('开始创建团队，用户: ${currentUser.name} (${currentUser.id})');

      // 使用TeamPoolProvider创建团队
      final success = await teamPoolProvider.createTeam(
        name: _teamNameController.text.trim(),
        description: _teamDescriptionController.text.trim(),
        leaderId: currentUser.id,
        isPublic: !_isPrivate, // 将私有设置转换为公开设置
      );

      // 检查Widget是否仍然挂载
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('团队 "${_teamNameController.text.trim()}" 创建成功！'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // 获取详细错误信息
        final errorMsg = teamPoolProvider.error ?? '创建团队失败，请稍后重试';
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('创建团队异常: $e');

      // 检查Widget是否仍然挂载
      if (!mounted) return;

      // 显示详细的错误信息
      String userFriendlyError = '创建团队失败';
      if (e.toString().contains('无法连接')) {
        userFriendlyError = '无法连接到服务器，请检查网络连接或后端服务状态';
      } else if (e.toString().contains('用户未登录')) {
        userFriendlyError = '用户未登录，请重新登录';
      } else if (e.toString().contains('用户ID为空')) {
        userFriendlyError = '用户信息异常，请重新登录';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userFriendlyError),
              const SizedBox(height: 4),
              Text(
                '详细错误: ${e.toString()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      // 检查Widget是否仍然挂载
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => const DebugInfoDialog(),
                        );
                      }
                    },
                    child: const Text(
                      '网络测试',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: '关闭',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      // 检查Widget是否仍然挂载
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showWebEnvironmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.web, color: Colors.orange),
            SizedBox(width: 8),
            Text('Web环境限制'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('当前运行在Web浏览器环境中，由于浏览器的同源策略限制，无法直接向后端服务器发送POST请求。'),
            const SizedBox(height: 16),
            const Text('🔧 解决方案：'),
            const SizedBox(height: 8),
            const Text('1. 使用移动应用或桌面应用版本'),
            const SizedBox(height: 4),
            const Text('2. 配置后端服务器的CORS头部'),
            const SizedBox(height: 4),
            const Text('3. 使用代理服务器转发请求'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '后端CORS配置示例：',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access-Control-Allow-Origin: *\n'
                    'Access-Control-Allow-Methods: POST,GET,OPTIONS\n'
                    'Access-Control-Allow-Headers: Content-Type',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => const DebugInfoDialog(),
              );
            },
            child: const Text('网络测试'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解了'),
          ),
        ],
      ),
    );
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
