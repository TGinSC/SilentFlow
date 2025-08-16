import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'profile_edit_screen.dart';

// 个人资料详情页面
// 显示用户的完整资料信息
class ProfileDetailScreen extends StatefulWidget {
  final String userId;
  final User? user;

  const ProfileDetailScreen({
    Key? key,
    required this.userId,
    this.user,
  }) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  User? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_user == null) {
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 这里应该从API获取用户信息
      // final user = await UserService.getUser(widget.userId);
      // setState(() {
      //   _user = user;
      // });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载用户信息失败：$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? '个人资料'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('用户信息不存在'))
              : RefreshIndicator(
                  onRefresh: _loadUserProfile,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        _buildBasicInfoCard(),
                        const SizedBox(height: 16),
                        _buildSkillsCard(),
                        const SizedBox(height: 16),
                        _buildInterestsCard(),
                        const SizedBox(height: 16),
                        _buildWorkStyleCard(),
                        const SizedBox(height: 16),
                        _buildAvailabilityCard(),
                        const SizedBox(height: 16),
                        _buildAchievementsCard(),
                        const SizedBox(height: 16),
                        _buildStatisticsCard(),
                        const SizedBox(height: 16),
                        _buildContactCard(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    final user = _user!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage:
                  user.avatar != null ? NetworkImage(user.avatar!) : null,
              child: user.avatar == null
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (user.profile.role != null) ...[
              const SizedBox(height: 4),
              Text(
                user.profile.role!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
            ],
            if (user.profile.department != null) ...[
              const SizedBox(height: 4),
              Text(
                user.profile.department!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (user.profile.bio != null) ...[
              const SizedBox(height: 12),
              Text(
                user.profile.bio!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 16),
            _buildScoreChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChips() {
    final user = _user!;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        Chip(
          avatar: const Icon(Icons.star, size: 18),
          label: Text('贡献值: ${user.stats.contributionScore.toInt()}'),
          backgroundColor: Colors.amber.withOpacity(0.2),
        ),
        Chip(
          avatar: const Icon(Icons.trending_up, size: 18),
          label: Text('默契度: ${user.stats.averageTacitScore.toInt()}'),
          backgroundColor: Colors.blue.withOpacity(0.2),
        ),
        Chip(
          avatar: const Icon(Icons.flash_on, size: 18),
          label: Text('完成任务: ${user.stats.completedTasks}'),
          backgroundColor: Colors.green.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildBasicInfoCard() {
    final profile = _user!.profile;

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
            _buildInfoRow(Icons.person, '用户ID', _user!.id),
            if (profile.department != null)
              _buildInfoRow(Icons.business, '部门', profile.department!),
            if (profile.role != null)
              _buildInfoRow(Icons.work, '职位', profile.role!),
            _buildInfoRow(
              Icons.calendar_today,
              '加入时间',
              _formatDate(_user!.createdAt),
            ),
            _buildInfoRow(
                Icons.access_time, '时区', profile.availability.timezone),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    final skills = _user!.profile.skills;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '技能专长',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${skills.length} 项技能',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            skills.isEmpty
                ? const Text('还没有添加技能信息')
                : Column(
                    children: skills.map(_buildSkillItem).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillItem(UserSkill skill) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                        5,
                        (index) => Icon(
                              index < skill.level
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 16,
                              color: Colors.amber,
                            )),
                    const SizedBox(width: 8),
                    Text(
                      '${skill.experienceYears}年经验',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                if (skill.certificate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    skill.certificate!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSkillLevelColor(skill.level).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              skill.levelText,
              style: TextStyle(
                color: _getSkillLevelColor(skill.level),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsCard() {
    final interests = _user!.profile.interests;
    final taskTypes = _user!.profile.preferredTaskTypes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '兴趣与偏好',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (interests.isNotEmpty) ...[
              Text(
                '兴趣领域',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: interests
                    .map((interest) => Chip(
                          label: Text(interest),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (taskTypes.isNotEmpty) ...[
              Text(
                '偏好任务类型',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: taskTypes
                    .map((type) => Chip(
                          label: Text(type),
                          backgroundColor: Colors.purple.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
            if (interests.isEmpty && taskTypes.isEmpty)
              const Text('还没有添加兴趣和偏好信息'),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStyleCard() {
    final workStyle = _user!.profile.workStyle;

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
                '沟通风格', workStyle.communicationStyle, Icons.chat),
            _buildWorkStyleItem('工作节奏', workStyle.workPace, Icons.speed),
            _buildWorkStyleItem(
                '协作偏好', workStyle.preferredCollaborationMode, Icons.group),
            _buildWorkStyleItem(
                '压力处理', workStyle.stressHandling, Icons.psychology),
            _buildWorkStyleItem(
                '反馈方式', workStyle.feedbackStyle, Icons.feedback),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStyleItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final availability = _user!.profile.availability;

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
            _buildInfoRow(
              Icons.schedule,
              '每周最大投入',
              '${availability.maxHoursPerWeek} 小时',
            ),
            _buildInfoRow(Icons.public, '时区', availability.timezone),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    final achievements = _user!.profile.achievements;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '成就徽章',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${achievements.length} 个成就',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            achievements.isEmpty
                ? const Text('还没有获得成就')
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return _buildAchievementItem(achievement);
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(Achievement achievement) {
    return Container(
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getAchievementIcon(achievement.category),
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 4),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final user = _user!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '统计信息',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '参与协作池',
                    '${user.stats.joinedPools}',
                    Icons.folder,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '完成任务',
                    '${user.stats.completedTasks}',
                    Icons.task_alt,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '贡献积分',
                    '${user.stats.contributionScore.toInt()}',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildContactCard() {
    final contact = _user!.profile.contact;

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
            if (contact.email != null)
              _buildInfoRow(Icons.email, '邮箱', contact.email!),
            if (contact.phone != null)
              _buildInfoRow(Icons.phone, '电话', contact.phone!),
            if (contact.wechat != null)
              _buildInfoRow(Icons.chat, '微信', contact.wechat!),
            if (contact.qq != null)
              _buildInfoRow(Icons.alternate_email, 'QQ', contact.qq!),
            if (contact.email == null &&
                contact.phone == null &&
                contact.wechat == null &&
                contact.qq == null)
              const Text('还没有添加联系方式'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getSkillLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAchievementIcon(String category) {
    switch (category) {
      case '协作':
        return Icons.handshake;
      case '效率':
        return Icons.flash_on;
      case '创新':
        return Icons.lightbulb;
      case '领导':
        return Icons.star;
      case '学习':
        return Icons.school;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  void _editProfile() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(
          userId: widget.userId,
          currentUser: _user,
        ),
      ),
    )
        .then((_) {
      // 编辑完成后刷新页面
      _loadUserProfile();
    });
  }
}
