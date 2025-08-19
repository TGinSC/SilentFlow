// 临时脚本：测试服务器连接
import 'dart:convert';
import 'dart:io';

Future<void> testServerConnection() async {
  final serverUrl = '47.95.200.35:8081';

  print('=== 测试服务器连接 ===');
  print('服务器: $serverUrl');
  print('时间: ${DateTime.now()}');
  print('');

  // 测试基本连接
  try {
    print('1. 测试基本连接 (/)...');
    final client = HttpClient();
    final request = await client.get(serverUrl, 8081, '/');
    final response = await request.close();

    print('   状态码: ${response.statusCode}');
    print('   头部: ${response.headers}');

    if (response.statusCode == 404) {
      print('   ✅ 服务器可达 (404是正常的，根路径未定义)');
    }

    client.close();
  } catch (e) {
    print('   ❌ 连接失败: $e');
  }

  // 测试API端点
  try {
    print('\n2. 测试API端点 (/team/get/999999)...');
    final client = HttpClient();
    final request = await client.get(serverUrl, 8081, '/team/get/999999');
    final response = await request.close();

    print('   状态码: ${response.statusCode}');
    final body = await response.transform(utf8.decoder).join();
    print(
        '   响应: ${body.length > 100 ? body.substring(0, 100) + '...' : body}');

    client.close();
  } catch (e) {
    print('   ❌ API测试失败: $e');
  }

  // 测试POST请求（创建团队）
  try {
    print('\n3. 测试POST请求 (/team/create)...');
    final client = HttpClient();
    final request = await client.post(serverUrl, 8081, '/team/create');
    request.headers.set('Content-Type', 'application/json');

    final testData = {
      'teamUID': 888888,
      'teamPassword': '1234',
      'teamLeader': 123456,
    };

    request.write(json.encode(testData));

    final response = await request.close();
    print('   状态码: ${response.statusCode}');

    final body = await response.transform(utf8.decoder).join();
    print(
        '   响应: ${body.length > 100 ? body.substring(0, 100) + '...' : body}');

    client.close();
  } catch (e) {
    print('   ❌ POST测试失败: $e');
  }

  print('\n=== 测试完成 ===');
}

void main() async {
  await testServerConnection();
}
