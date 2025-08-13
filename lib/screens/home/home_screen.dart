import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('静默协作'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // 仅显示关键节点提醒
              _showNotifications();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 协作默契值卡片
            _buildTacitCard(),
            const SizedBox(height: 16),

            // 今日关键节点
            _buildTodayNodesCard(),
            const SizedBox(height: 16),

            // 进行中的协作池
            _buildActivePoolsCard(),
            const SizedBox(height: 16),

            // 效率图谱预览
            _buildEfficiencyMapCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreatePoolDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('创建协作池'),
      ),
    );
  }

  Widget _buildTacitCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: Colors.purple[300]),
                const SizedBox(width: 8),
                const Text(
                  '协作默契值',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreItem('本周', '85', Colors.green),
                _buildScoreItem('本月', '78', Colors.blue),
                _buildScoreItem('总分', '892', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String score, Color color) {
    return Column(
      children: [
        Text(
          score,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTodayNodesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.blue[300]),
                const SizedBox(width: 8),
                const Text(
                  '今日关键节点',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildNodeItem('张三完成了「需求文档」', '10:30', Colors.green),
            _buildNodeItem('李四开始了「UI设计」', '14:15', Colors.blue),
            _buildNodeItem('王五遇到卡点「技术选型」', '16:45', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeItem(String content, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(content, style: const TextStyle(fontSize: 14))),
          Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActivePoolsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water, color: Colors.cyan[300]),
                const SizedBox(width: 8),
                const Text(
                  '进行中的协作池',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPoolItem('宿舍清洁分工', '4/6人', 0.75),
            _buildPoolItem('小组作业协作', '3/4人', 0.60),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolItem(String name, String members, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 16)),
              Text(
                members,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[300]!),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyMapCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.green[300]),
                const SizedBox(width: 8),
                const Text(
                  '效率图谱',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEfficiencyTag('启动专家', Colors.green),
                _buildEfficiencyTag('收尾高手', Colors.blue),
                _buildEfficiencyTag('协调者', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showCreatePoolDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建协作池'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: '协作池名称',
                hintText: '例如：宿舍清洁分工',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(value: false, onChanged: (value) {}),
                const Text('匿名协作模式'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 创建协作池逻辑
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关键节点提醒'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('仅显示重要协作节点：'),
            const SizedBox(height: 8),
            Text('• 任务冲突提醒', style: TextStyle(color: Colors.grey[700])),
            Text('• 依赖关系变更', style: TextStyle(color: Colors.grey[700])),
            Text('• 关键任务完成', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
