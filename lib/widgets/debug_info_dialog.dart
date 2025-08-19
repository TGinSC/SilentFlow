import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';
import '../services/team_service.dart';

class DebugInfoDialog extends StatefulWidget {
  const DebugInfoDialog({super.key});

  @override
  State<DebugInfoDialog> createState() => _DebugInfoDialogState();
}

class _DebugInfoDialogState extends State<DebugInfoDialog> {
  String _debugInfo = '点击按钮开始测试...';
  bool _isTesting = false;

  Future<void> _runNetworkTest() async {
    setState(() {
      _isTesting = true;
      _debugInfo = '正在进行网络测试...\n\n';
    });

    final buffer = StringBuffer();
    buffer.writeln('=== 后端服务连接诊断 ===');
    buffer.writeln('时间: ${DateTime.now()}');
    buffer.writeln('运行环境: ${kIsWeb ? 'Web浏览器' : '原生应用'}');
    buffer.writeln('当前URL: ${ApiService.currentBaseUrl}');
    buffer.writeln('可选URLs: ${ApiService.possibleBaseUrls.join(', ')}');
    buffer.writeln('');

    // Web环境的特殊说明
    if (kIsWeb) {
      buffer.writeln('🌐 Web环境特殊说明:');
      buffer.writeln('   Web应用受浏览器同源策略限制');
      buffer.writeln('   POST请求需要后端正确配置CORS头部');
      buffer.writeln('   如果POST失败，这是正常的Web安全限制');
      buffer.writeln('');
    }

    try {
      // 1. 基础连接测试
      buffer.writeln('1️⃣ 智能连接测试');
      final isConnected = await ApiService.testConnection();
      buffer.writeln('   结果: ${isConnected ? '✅ 连接成功' : '❌ 连接失败'}');
      buffer.writeln('   使用URL: ${ApiService.currentBaseUrl}');

      if (isConnected) {
        buffer.writeln('\n2️⃣ API端点测试');

        // 测试team相关API
        try {
          final teamResponse = await TeamService.getTeamInfo('999999');
          buffer.writeln(
              '   /team/get/999999: ${teamResponse != null ? '✅ 响应正常' : '⚠️ 返回空数据'}');
        } catch (e) {
          buffer.writeln(
              '   /team/get/999999: ❌ 请求失败 - ${e.toString().length > 50 ? e.toString().substring(0, 50) + '...' : e.toString()}');
        }

        // 3. 测试团队创建API (Web环境可能失败)
        buffer.writeln('\n3️⃣ 团队创建API测试');
        if (kIsWeb) {
          buffer.writeln('   ⚠️ Web环境下POST请求可能受CORS限制');
        }

        try {
          final testTeamId = await TeamService.createTeam(
            teamId: '888888',
            teamPassword: '1234',
            teamLeader: 'test_user_001',
          );
          buffer.writeln(
              '   结果: ${testTeamId != null ? '✅ 创建成功 (返回ID: $testTeamId)' : '❌ 创建失败 (返回null)'}');
        } catch (e) {
          buffer.writeln('   结果: ❌ 创建失败');
          buffer.writeln(
              '   错误: ${e.toString().length > 80 ? e.toString().substring(0, 80) + '...' : e.toString()}');

          if (kIsWeb && e.toString().contains('CORS')) {
            buffer.writeln('   💡 这是Web环境的正常CORS限制');
          }
        }
      } else {
        buffer.writeln('\n❌ 跳过API测试 (基础连接失败)');
      }

      // 5. 故障排除建议
      buffer.writeln('\n🔧 故障排除建议:');
      if (!isConnected) {
        buffer.writeln('   1. 检查后端服务是否在端口8081运行');
        buffer.writeln('   2. 检查防火墙是否阻止8081端口');
        buffer.writeln('   3. 确认后端服务日志无错误');
        buffer.writeln('   4. 尝试在浏览器访问 http://127.0.0.1:8081');
      } else {
        buffer.writeln('   ✅ 网络连接正常');
        buffer.writeln('   ✅ 后端服务可访问');

        if (kIsWeb) {
          buffer.writeln('\n🌐 Web环境解决方案:');
          buffer.writeln('   1. 后端添加CORS头部:');
          buffer.writeln('      Access-Control-Allow-Origin: *');
          buffer
              .writeln('      Access-Control-Allow-Methods: POST,GET,OPTIONS');
          buffer.writeln('      Access-Control-Allow-Headers: Content-Type');
          buffer.writeln('   2. 或使用Chrome --disable-web-security启动');
          buffer.writeln('   3. 或配置代理服务器转发请求');
        }
      }
    } catch (e) {
      buffer.writeln('\n💥 测试过程异常: $e');
      buffer.writeln('\n请检查:');
      buffer.writeln('   1. 网络连接状态');
      buffer.writeln('   2. 后端服务运行状态');
      buffer.writeln('   3. 应用权限设置');

      if (kIsWeb) {
        buffer.writeln('   4. 浏览器CORS限制');
      }
    }

    setState(() {
      _debugInfo = buffer.toString();
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.orange),
          SizedBox(width: 8),
          Text('网络调试信息'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTesting ? null : _runNetworkTest,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(_isTesting ? '测试中...' : '开始网络测试'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}
