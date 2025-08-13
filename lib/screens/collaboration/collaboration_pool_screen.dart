import 'package:flutter/material.dart';

class CollaborationPoolScreen extends StatefulWidget {
  const CollaborationPoolScreen({super.key});

  @override
  State<CollaborationPoolScreen> createState() =>
      _CollaborationPoolScreenState();
}

class _CollaborationPoolScreenState extends State<CollaborationPoolScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('协作池'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我参与的'),
            Tab(text: '公开池'),
            Tab(text: '已完成'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPoolsList(),
          _buildPublicPoolsList(),
          _buildCompletedPoolsList(),
        ],
      ),
    );
  }

  Widget _buildMyPoolsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildPoolCard(
          title: '宿舍清洁分工',
          description: '每周轮流打扫，静默认领任务',
          memberCount: 4,
          taskCount: 12,
          completedTasks: 8,
          isAnonymous: false,
          tacitScore: 85,
        );
      },
    );
  }

  Widget _buildPublicPoolsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildPoolCard(
          title: '图书馆座位协调',
          description: '匿名协作，避免占座冲突',
          memberCount: 12,
          taskCount: 20,
          completedTasks: 15,
          isAnonymous: true,
          tacitScore: 72,
          showJoinButton: true,
        );
      },
    );
  }

  Widget _buildCompletedPoolsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2,
      itemBuilder: (context, index) {
        return _buildPoolCard(
          title: '小组作业完成',
          description: '期末项目协作',
          memberCount: 4,
          taskCount: 15,
          completedTasks: 15,
          isAnonymous: false,
          tacitScore: 92,
          isCompleted: true,
        );
      },
    );
  }

  Widget _buildPoolCard({
    required String title,
    required String description,
    required int memberCount,
    required int taskCount,
    required int completedTasks,
    required bool isAnonymous,
    required int tacitScore,
    bool showJoinButton = false,
    bool isCompleted = false,
  }) {
    double progress = completedTasks / taskCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Navigate to task board for this pool
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isAnonymous) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  '匿名',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showJoinButton)
                    ElevatedButton(
                      onPressed: () {
                        _showJoinPoolDialog();
                      },
                      child: const Text('加入'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('$memberCount人', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.task_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$completedTasks/$taskCount',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getScoreColor(tacitScore).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '默契值 $tacitScore',
                      style: TextStyle(
                        color: _getScoreColor(tacitScore),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  void _showJoinPoolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入协作池'),
        content: const Text('确定要加入这个协作池吗？加入后您可以认领和完成任务。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('成功加入协作池')));
            },
            child: const Text('加入'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
