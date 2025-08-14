// API 服务基类
// 为后端接口预留统一的网络请求处理
import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  static late Dio _dio;
  static const String _baseUrl = 'http://127.0.0.1:1411'; // 后端接口地址

  // 初始化网络请求配置
  static void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 请求拦截器
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 添加认证token
          final token = await StorageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          print('[REQUEST] ${options.method} ${options.uri}');
          print('[REQUEST DATA] ${options.data}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '[RESPONSE] ${response.statusCode} ${response.requestOptions.uri}',
          );
          print('[RESPONSE DATA] ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('[ERROR] ${error.message}');
          if (error.response != null) {
            print('[ERROR DATA] ${error.response?.data}');
          }
          handler.next(error);
        },
      ),
    );
  }

  // 通用GET请求
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // 通用POST请求
  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // 通用PUT请求
  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // 通用DELETE请求
  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
