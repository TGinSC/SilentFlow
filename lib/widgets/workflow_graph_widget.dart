import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/workflow_service.dart';
import '../models/team_pool_model.dart';

/// 增强版工作流图组件
/// 专门显示用户创建或加入的团队的工作流，以图表形式呈现
/// 支持团队任务依赖关系可视化、实时状态更新、交互操作
class WorkflowGraphWidget extends StatefulWidget {
  final String teamId; // 团队ID，用于获取团队工作流数据
  final TeamPool? team; // 可选的团队对象
  final bool isEditable;
  final Function(String taskId)? onTaskTap;
  final bool showLegend;
  final bool showStatistics;
  final bool enableRealTimeUpdates;

  const WorkflowGraphWidget({
    super.key,
    required this.teamId,
    this.team,
    this.isEditable = false,
    this.onTaskTap,
    this.showLegend = true,
    this.showStatistics = true,
    this.enableRealTimeUpdates = false,
  });

  @override
  State<WorkflowGraphWidget> createState() => _WorkflowGraphWidgetState();
}

class _WorkflowGraphWidgetState extends State<WorkflowGraphWidget> {
  Map<String, dynamic> _workflowData = {};
  bool _isLoading = true;
  String? _selectedTaskId;
  bool _isRealTimeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadWorkflowData();
  }

  Future<void> _loadWorkflowData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 修复：直接传递teamId给getWorkflowGraph方法
      final workflowData =
          await WorkflowService.getWorkflowGraph(widget.teamId);
      if (mounted) {
        setState(() {
          _workflowData = workflowData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('WorkflowGraphWidget: 加载工作流数据失败 - $e');
      if (mounted) {
        setState(() {
          _workflowData = {};
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载团队工作流失败: $e'),
            backgroundColor: Colors.red[600],
            action: SnackBarAction(
              label: '重试',
              textColor: Colors.white,
              onPressed: _loadWorkflowData,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: _buildContainerDecoration(),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
              SizedBox(height: 16),
              Text(
                '正在加载团队工作流数据...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nodes = _workflowData['nodes'] as List<dynamic>? ?? [];
    final edges = _workflowData['edges'] as List<dynamic>? ?? [];

    if (nodes.isEmpty) {
      return Container(
        decoration: _buildContainerDecoration(),
        child: _buildEmptyState(),
      );
    }

    return Container(
      decoration: _buildContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 增强的标题栏
          _buildTitleBar(nodes.length, edges.length),

          // 图例（如果启用）
          if (widget.showLegend) _buildLegend(),

          const Divider(height: 1),

          // 工作流图主体
          Expanded(
            child: Stack(
              children: [
                // 主要的工作流图
                InteractiveViewer(
                  minScale: 0.3,
                  maxScale: 3.0,
                  constrained: false,
                  child: Container(
                    width: math.max(800, MediaQuery.of(context).size.width),
                    height:
                        math.max(600, MediaQuery.of(context).size.height * 0.8),
                    padding: const EdgeInsets.all(40),
                    child: CustomPaint(
                      painter: EnhancedWorkflowPainter(
                        nodes: nodes,
                        edges: edges,
                        selectedTaskId: _selectedTaskId,
                        isEditable: widget.isEditable,
                      ),
                      child: GestureDetector(
                        onTapDown: (details) => _handleTapDown(details, nodes),
                        child: Container(),
                      ),
                    ),
                  ),
                ),

                // 右下角操作按钮
                if (widget.isEditable) _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_tree,
              size: 64,
              color: Color(0xFF667eea),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${widget.team?.name ?? '该团队'}暂无工作流数据',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当前团队还没有创建任何任务\n创建任务后即可看到工作流图',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          if (widget.isEditable) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('创建任务功能开发中...')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('创建第一个任务'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleBar(int nodeCount, int edgeCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF667eea),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.team?.name ?? '团队工作流图',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$nodeCount 个任务 • $edgeCount 个依赖关系',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (widget.team != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '成员: ${widget.team!.memberIds.length + 1} 人',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showStatistics)
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  color: Colors.white,
                  tooltip: '查看统计',
                  onPressed: _showStatistics,
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                color: Colors.white,
                tooltip: '刷新数据',
                onPressed: _loadWorkflowData,
              ),
              if (widget.enableRealTimeUpdates)
                IconButton(
                  icon: Icon(
                    _isRealTimeEnabled ? Icons.sync : Icons.sync_disabled,
                  ),
                  color: Colors.white,
                  tooltip: _isRealTimeEnabled ? '关闭实时更新' : '开启实时更新',
                  onPressed: _toggleRealTimeUpdates,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildLegendItem('待处理', const Color(0xFFED8936)),
          _buildLegendItem('进行中', const Color(0xFF4299E1)),
          _buildLegendItem('已完成', const Color(0xFF48BB78)),
          _buildLegendItem('受阻', const Color(0xFFE53E3E)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('适应窗口功能开发中...')),
              );
            },
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF667eea),
            tooltip: '适应窗口',
            child: const Icon(Icons.fit_screen),
          ),
          const SizedBox(height: 8),
          if (widget.isEditable)
            FloatingActionButton.small(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('添加任务功能开发中...')),
                );
              },
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              tooltip: '添加任务',
              child: const Icon(Icons.add),
            ),
        ],
      ),
    );
  }

  void _handleTapDown(TapDownDetails details, List<dynamic> nodes) {
    if (nodes.isEmpty) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    // 简单的点击检测逻辑
    for (final node in nodes) {
      setState(() {
        _selectedTaskId = node['id'];
      });

      if (widget.onTaskTap != null) {
        widget.onTaskTap!(node['id']);
      }
      break; // 只处理第一个节点
    }
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('工作流统计'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('团队: ${widget.team?.name ?? '未知'}'),
            const SizedBox(height: 8),
            Text('任务总数: ${_workflowData['nodes']?.length ?? 0}'),
            Text('依赖关系: ${_workflowData['edges']?.length ?? 0}'),
            const SizedBox(height: 8),
            const Text('详细统计功能开发中...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _toggleRealTimeUpdates() {
    setState(() {
      _isRealTimeEnabled = !_isRealTimeEnabled;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRealTimeEnabled ? '实时更新已开启' : '实时更新已关闭'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 增强版工作流图绘制器
class EnhancedWorkflowPainter extends CustomPainter {
  final List<dynamic> nodes;
  final List<dynamic> edges;
  final String? selectedTaskId;
  final bool isEditable;

  EnhancedWorkflowPainter({
    required this.nodes,
    required this.edges,
    this.selectedTaskId,
    this.isEditable = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // 改进的布局算法 - 层次化布局
    final nodePositions = _calculateNodePositions(size);

    // 绘制连接线（边）
    _drawEdges(canvas, nodePositions);

    // 绘制节点
    _drawNodes(canvas, nodePositions);
  }

  Map<String, Offset> _calculateNodePositions(Size size) {
    const spacing = Offset(180, 120);

    final positions = <String, Offset>{};

    // 简单的网格布局（后续可以改进为层次布局）
    final cols = (size.width / spacing.dx).floor().clamp(1, nodes.length);

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final row = i ~/ cols;
      final col = i % cols;

      final x = col * spacing.dx + 80;
      final y = row * spacing.dy + 100;

      positions[node['id']] = Offset(x, y);
    }

    return positions;
  }

  void _drawEdges(Canvas canvas, Map<String, Offset> nodePositions) {
    const nodeSize = Size(140, 80);

    for (final edge in edges) {
      final sourceId = edge['source'];
      final targetId = edge['target'];

      final sourcePos = nodePositions[sourceId];
      final targetPos = nodePositions[targetId];

      if (sourcePos != null && targetPos != null) {
        _drawSingleEdge(canvas, sourcePos, targetPos, nodeSize);
      }
    }
  }

  void _drawSingleEdge(Canvas canvas, Offset start, Offset end, Size nodeSize) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 从节点中心计算连线点
    final startPoint = Offset(
      start.dx + nodeSize.width / 2,
      start.dy + nodeSize.height,
    );
    final endPoint = Offset(
      end.dx + nodeSize.width / 2,
      end.dy,
    );

    // 绘制直线（后续可以改进为贝塞尔曲线）
    canvas.drawLine(startPoint, endPoint, paint);

    // 绘制箭头
    _drawArrowHead(canvas, startPoint, endPoint);
  }

  void _drawArrowHead(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const arrowLength = 12.0;
    const arrowAngle = 0.5;

    final direction = (end - start).direction;

    final arrowHead1 = Offset(
      end.dx - arrowLength * math.cos(direction - arrowAngle),
      end.dy - arrowLength * math.sin(direction - arrowAngle),
    );

    final arrowHead2 = Offset(
      end.dx - arrowLength * math.cos(direction + arrowAngle),
      end.dy - arrowLength * math.sin(direction + arrowAngle),
    );

    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(arrowHead1.dx, arrowHead1.dy);
    path.moveTo(end.dx, end.dy);
    path.lineTo(arrowHead2.dx, arrowHead2.dy);

    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas, Map<String, Offset> nodePositions) {
    const nodeSize = Size(140, 80);

    for (final node in nodes) {
      final position = nodePositions[node['id']];
      if (position != null) {
        _drawSingleNode(canvas, node, position, nodeSize);
      }
    }
  }

  void _drawSingleNode(Canvas canvas, Map<String, dynamic> node,
      Offset position, Size nodeSize) {
    final isSelected = node['id'] == selectedTaskId;
    final statusColor = _getStatusColor(node['status']);

    // 绘制节点背景
    final backgroundPaint = Paint()
      ..color = statusColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? const Color(0xFF667eea) : statusColor
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(position.dx, position.dy, nodeSize.width, nodeSize.height),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect, backgroundPaint);
    canvas.drawRRect(rect, borderPaint);

    // 绘制进度条
    final progress = (node['progress'] as double? ?? 0.0).clamp(0.0, 1.0);
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = statusColor
        ..style = PaintingStyle.fill;

      final progressRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx + 8,
          position.dy + nodeSize.height - 12,
          (nodeSize.width - 16) * progress,
          4,
        ),
        const Radius.circular(2),
      );

      canvas.drawRRect(progressRect, progressPaint);
    }

    // 绘制状态图标
    _drawStatusIcon(canvas, node['status'], position, statusColor);

    // 绘制文本
    _drawNodeText(canvas, node, position, nodeSize, progress);
  }

  void _drawStatusIcon(
      Canvas canvas, String status, Offset position, Color color) {
    IconData iconData;
    switch (status) {
      case 'pending':
        iconData = Icons.hourglass_empty;
        break;
      case 'inProgress':
        iconData = Icons.play_circle_filled;
        break;
      case 'completed':
        iconData = Icons.check_circle;
        break;
      case 'blocked':
        iconData = Icons.block;
        break;
      default:
        iconData = Icons.help_outline;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontFamily: iconData.fontFamily,
          fontSize: 16,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx + 8, position.dy + 8));
  }

  void _drawNodeText(Canvas canvas, Map<String, dynamic> node, Offset position,
      Size nodeSize, double progress) {
    final title = node['title']?.toString() ?? '未命名任务';

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          color: Color(0xFF2D3748),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      textAlign: TextAlign.left,
    );

    titlePainter.layout(maxWidth: nodeSize.width - 32);

    final titleOffset = Offset(
      position.dx + 8,
      position.dy + 28,
    );

    titlePainter.paint(canvas, titleOffset);

    // 绘制进度百分比
    final progressPainter = TextPainter(
      text: TextSpan(
        text: '${(progress * 100).toInt()}%',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    progressPainter.layout();

    final progressOffset = Offset(
      position.dx + nodeSize.width - progressPainter.width - 8,
      position.dy + 8,
    );

    progressPainter.paint(canvas, progressOffset);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFED8936); // 橙色
      case 'inProgress':
        return const Color(0xFF4299E1); // 蓝色
      case 'completed':
        return const Color(0xFF48BB78); // 绿色
      case 'blocked':
        return const Color(0xFFE53E3E); // 红色
      default:
        return Colors.grey;
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedWorkflowPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.edges != edges ||
        oldDelegate.selectedTaskId != selectedTaskId ||
        oldDelegate.isEditable != isEditable;
  }
}
