import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_pool_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/team_pool_provider.dart';
import '../../widgets/workflow_graph_widget.dart';

/// 统一的工作流图页面
/// 显示用户创建或加入的团队的工作流图
class WorkflowScreen extends StatefulWidget {
  final String? teamId;
  final String? teamName;

  const WorkflowScreen({
    super.key,
    this.teamId,
    this.teamName,
  });

  @override
  State<WorkflowScreen> createState() => _WorkflowScreenState();
}

class _WorkflowScreenState extends State<WorkflowScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<TeamPool> _userTeams = [];
  TeamPool? _selectedTeam;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserTeams();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserTeams() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final appProvider = context.read<AppProvider>();
      final teamPoolProvider = context.read<TeamPoolProvider>();
      final userId = appProvider.currentUser?.id;

      if (userId != null) {
        // 获取用户创建或加入的团队
        final allTeams = teamPoolProvider.teamPools;
        _userTeams = allTeams
            .where((team) =>
                team.leaderId == userId || team.memberIds.contains(userId))
            .toList();

        // 设置初始选中的团队
        if (widget.teamId != null && _userTeams.isNotEmpty) {
          _selectedTeam = _userTeams.firstWhere(
            (team) => team.id == widget.teamId,
            orElse: () => _userTeams.first,
          );
        } else if (_userTeams.isNotEmpty) {
          _selectedTeam = _userTeams.first;
        }

        // 安全地初始化TabController
        _tabController?.dispose();
        if (_userTeams.isNotEmpty && mounted) {
          _tabController = TabController(
            length: _userTeams.length,
            vsync: this,
            initialIndex:
                _selectedTeam != null ? _userTeams.indexOf(_selectedTeam!) : 0,
          );
        }
      }
    } catch (e) {
      print('WorkflowScreen: 加载团队数据失败 - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载团队数据失败: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.teamName != null ? '${widget.teamName} - 工作流图' : '团队工作流图'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserTeams,
            tooltip: '刷新数据',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showWorkflowInfo,
            tooltip: '工作流说明',
          ),
        ],
        bottom: _userTeams.isEmpty || _tabController == null
            ? null
            : TabBar(
                controller: _tabController!,
                isScrollable: _userTeams.length > 3,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: _userTeams
                    .map((team) => Tab(
                          text: team.name,
                          icon: Icon(
                            team.leaderId ==
                                    context.read<AppProvider>().currentUser?.id
                                ? Icons.admin_panel_settings
                                : Icons.people,
                            size: 16,
                          ),
                        ))
                    .toList(),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userTeams.isEmpty
              ? _buildEmptyState()
              : _buildWorkflowContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '暂无团队工作流',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '您还没有创建或加入任何团队\n创建团队或加入团队后即可查看工作流图',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('返回团队池'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowContent() {
    if (_userTeams.isEmpty || _tabController == null) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.1, 1.0],
          colors: [
            const Color(0xFF667eea).withOpacity(0.1),
            Colors.white.withOpacity(0.8),
            Colors.white,
          ],
        ),
      ),
      child: TabBarView(
        controller: _tabController!,
        children: _userTeams.map((team) => _buildTeamWorkflow(team)).toList(),
      ),
    );
  }

  Widget _buildTeamWorkflow(TeamPool team) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 团队信息卡片
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      team.leaderId ==
                              context.read<AppProvider>().currentUser?.id
                          ? Icons.admin_panel_settings
                          : Icons.people,
                      color: const Color(0xFF667eea),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team.description.isEmpty ? '暂无描述' : team.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${team.memberIds.length + 1} 名成员',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: team.status == TeamStatus.active
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                team.status == TeamStatus.active ? '活跃' : '非活跃',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: team.status == TeamStatus.active
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 工作流图
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: WorkflowGraphWidget(
                  teamId: team.id,
                  team: team,
                  isEditable: team.leaderId ==
                      context.read<AppProvider>().currentUser?.id,
                  showLegend: true,
                  showStatistics: true,
                  enableRealTimeUpdates: false,
                  onTaskTap: (taskId) => _handleTaskTap(taskId, team),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTaskTap(String taskId, TeamPool team) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('任务详情'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('任务ID: $taskId'),
            Text('所属团队: ${team.name}'),
            const SizedBox(height: 16),
            const Text('操作选项：'),
            const SizedBox(height: 8),
            const Text('• 查看任务详细信息'),
            const Text('• 编辑任务内容'),
            const Text('• 查看任务进度'),
            const Text('• 管理任务依赖'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 导航到任务详情页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('任务详情功能开发中...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
            ),
            child: const Text('查看详情'),
          ),
        ],
      ),
    );
  }

  void _showWorkflowInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('工作流图说明'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '工作流图功能说明：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('📊 可视化显示：以图形方式展示任务间的依赖关系'),
              SizedBox(height: 8),
              Text('🔄 实时更新：任务状态变化时自动更新工作流'),
              SizedBox(height: 8),
              Text('👥 团队协作：显示团队成员的任务分配情况'),
              SizedBox(height: 8),
              Text('📈 进度跟踪：直观展示项目整体进展'),
              SizedBox(height: 16),
              Text(
                '状态颜色说明：',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFFED8936)),
                  SizedBox(width: 8),
                  Text('待处理'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFF4299E1)),
                  SizedBox(width: 8),
                  Text('进行中'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFF48BB78)),
                  SizedBox(width: 8),
                  Text('已完成'),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFFE53E3E)),
                  SizedBox(width: 8),
                  Text('受阻'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解了'),
          ),
        ],
      ),
    );
  }
}
