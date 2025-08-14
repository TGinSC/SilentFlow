// 任务项目相关的API服务
// 连接后端任务项目管理接口
import 'api_service.dart';
import 'package:dio/dio.dart';

class ItemService {
  // 获取任务项目信息 - GET /item/:itemuid
  static Future<Map<String, dynamic>?> getItemInfo(String itemId) async {
    try {
      final response = await ApiService.get('/item/$itemId');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['item'] != null) {
          return data['item'];
        }
      }
      return null;
    } on DioException catch (e) {
      print('获取任务项目信息失败: ${e.message}');
      return null;
    } catch (e) {
      print('获取任务项目信息异常: $e');
      return null;
    }
  }

  // 创建任务项目 - POST /item/create/:teamuid
  static Future<String?> createItem({
    required String teamId,
    required String content,
    required int score,
    required int shouldBeCompletedBy,
  }) async {
    try {
      final response = await ApiService.post('/item/create/$teamId', data: {
        'content': content,
        'score': score,
        'shouldBeCompletedBy': shouldBeCompletedBy,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return data['itemUID'].toString();
        } else {
          print('创建任务项目失败: ${data['message'] ?? data['error']}');
        }
      }
      return null;
    } on DioException catch (e) {
      print('创建任务项目失败: ${e.message}');
      return null;
    } catch (e) {
      print('创建任务项目异常: $e');
      return null;
    }
  }

  // 更新任务项目 - POST /item/update/:teamuid
  static Future<bool> updateItem({
    required String teamId,
    required int itemId,
    String? content,
    int? score,
    int? shouldBeCompletedBy,
    int? beCompletedBy,
    bool? isComplete,
  }) async {
    try {
      final data = <String, dynamic>{
        'item': itemId,
      };

      if (content != null) data['content'] = content;
      if (score != null) data['score'] = score;
      if (shouldBeCompletedBy != null)
        data['shouldBeCompletedBy'] = shouldBeCompletedBy;
      if (beCompletedBy != null) data['beCompletedBy'] = beCompletedBy;
      if (isComplete != null) data['isComplete'] = isComplete;

      final response =
          await ApiService.post('/item/update/$teamId', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['error'] == null || responseData['error'].isEmpty) {
          return true;
        } else {
          print(
              '更新任务项目失败: ${responseData['message'] ?? responseData['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('更新任务项目失败: ${e.message}');
      return false;
    } catch (e) {
      print('更新任务项目异常: $e');
      return false;
    }
  }

  // 删除任务项目 - POST /item/delete
  static Future<bool> deleteItem(String itemId) async {
    try {
      final response = await ApiService.post('/item/delete', data: {
        'itemUID': int.parse(itemId),
      });

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['error'] == null || data['error'].isEmpty) {
          return true;
        } else {
          print('删除任务项目失败: ${data['message'] ?? data['error']}');
        }
      }
      return false;
    } on DioException catch (e) {
      print('删除任务项目失败: ${e.message}');
      return false;
    } catch (e) {
      print('删除任务项目异常: $e');
      return false;
    }
  }

  // 完成任务项目（便捷方法）
  static Future<bool> completeItem({
    required String teamId,
    required int itemId,
    required int completedBy,
  }) async {
    return updateItem(
      teamId: teamId,
      itemId: itemId,
      beCompletedBy: completedBy,
      isComplete: true,
    );
  }

  // 取消完成任务项目（便捷方法）
  static Future<bool> uncompleteItem({
    required String teamId,
    required int itemId,
  }) async {
    return updateItem(
      teamId: teamId,
      itemId: itemId,
      beCompletedBy: null,
      isComplete: false,
    );
  }
}
