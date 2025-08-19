// API 服务基类
// 为后端接口预留统一的网络请求处理
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'storage_service.dart';

class ApiService {
  static late Dio _dio;
  // 支持多个可能的后端地址
  static const List<String> _possibleBaseUrls = [
    'http://47.95.200.35:8081', // 生产环境服务器
    'http://127.0.0.1:8081', // 本地回环地址
    'http://localhost:8081', // localhost
    'http://10.0.2.2:8081', // Android 模拟器访问宿主机
    'http://192.168.1.100:8081', // 可能的局域网地址（需根据实际情况调整）
  ];
  static String _currentBaseUrl = _possibleBaseUrls.first;

  // 初始化网络请求配置
  static void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _currentBaseUrl,
        connectTimeout: const Duration(seconds: 15), // 增加超时时间
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // 添加CORS相关头部
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET,PUT,POST,DELETE,OPTIONS',
          'Access-Control-Allow-Headers':
              'Origin,X-Requested-With,Content-Type,Accept,Authorization',
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
          print('[REQUEST HEADERS] ${options.headers}');
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
          print('[ERROR TYPE] ${error.type}');
          if (error.response != null) {
            print('[ERROR RESPONSE] ${error.response?.statusCode}');
            print('[ERROR DATA] ${error.response?.data}');
          }
          // 特殊处理连接错误
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            print('[网络错误] 无法连接到服务器 $_currentBaseUrl');
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
    print('ApiService.post 调用: $path');
    print('请求数据: $data');
    print('运行环境: ${kIsWeb ? 'Web' : 'Native'}');

    // Web环境下的特殊处理
    if (kIsWeb) {
      print('检测到Web环境，使用特殊的CORS处理...');
      return await _handleWebRequest<T>(path, data, queryParameters, options);
    }

    // 原生环境下的处理
    return await _handleNativeRequest<T>(path, data, queryParameters, options);
  }

  // Web环境的请求处理
  static Future<Response<T>> _handleWebRequest<T>(
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  ) async {
    try {
      // Web环境下，先发送OPTIONS请求进行预检
      print('Web环境：发送预检请求...');
      try {
        await _dio.request(path, options: Options(method: 'OPTIONS'));
        print('预检请求成功');
      } catch (preflightError) {
        print('预检请求失败，但继续尝试POST请求: $preflightError');
      }

      // Web环境下使用特殊的头部配置
      final webOptions = Options(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Web环境不需要设置CORS头部，这些应该由服务器设置
        },
        // 关键：Web环境下需要发送凭据
        extra: {'withCredentials': false},
      );

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: webOptions,
      );

      print('Web POST请求成功: ${response.statusCode}');
      return response;
    } catch (e) {
      print('Web POST请求失败: $e');

      // Web环境下的错误通常是CORS问题，提供更好的错误信息
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        throw DioException(
          requestOptions: e.requestOptions,
          message: 'Web环境下无法连接到服务器，这通常是由于CORS（跨源资源共享）限制造成的。'
              '请确保后端服务器正确配置了CORS头部以允许来自Web应用的请求。',
          type: DioExceptionType.connectionError,
        );
      }
      rethrow;
    }
  }

  // 原生环境的请求处理（带重试机制）
  static Future<Response<T>> _handleNativeRequest<T>(
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  ) async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final response = await _dio.post<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: options?.copyWith(
                headers: {
                  ...?options.headers,
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  // 添加更多CORS头部
                  'Access-Control-Request-Method': 'POST',
                  'Access-Control-Request-Headers': 'Content-Type',
                },
              ) ??
              Options(
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Access-Control-Request-Method': 'POST',
                  'Access-Control-Request-Headers': 'Content-Type',
                },
              ),
        );
        print('Native POST请求成功: ${response.statusCode}');
        return response;
      } catch (e) {
        print('Native POST请求失败 (尝试 ${retryCount + 1}/$maxRetries): $e');

        // 如果是连接错误，尝试重新测试连接并切换URL
        if (e is DioException &&
            (e.type == DioExceptionType.connectionError ||
                e.type == DioExceptionType.connectionTimeout)) {
          print('检测到连接错误，尝试智能连接测试...');
          final connectionSuccess = await testConnection();

          if (connectionSuccess && retryCount < maxRetries - 1) {
            print('连接测试成功，使用新URL重试: $_currentBaseUrl');
            retryCount++;
            continue;
          }
        }

        // 如果重试失败或不是连接错误，直接抛出异常
        print('Native POST请求最终失败: $e');
        rethrow;
      }
    }

    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: '经过$maxRetries次重试后仍然失败',
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

  // 获取当前基础URL
  static String get currentBaseUrl => _currentBaseUrl;

  // 获取所有可能的基础URL
  static List<String> get possibleBaseUrls => _possibleBaseUrls;

  // 测试网络连接
  static Future<bool> testConnection() async {
    // 依次尝试所有可能的基础URL
    for (int i = 0; i < _possibleBaseUrls.length; i++) {
      final testUrl = _possibleBaseUrls[i];
      print('测试网络连接到: $testUrl (${i + 1}/${_possibleBaseUrls.length})');

      try {
        final testDio = Dio(BaseOptions(
          baseUrl: testUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

        // 首先尝试连接到根路径，如果失败则尝试其他已知路径
        try {
          final response = await testDio.get('/',
              options: Options(
                receiveTimeout: const Duration(seconds: 3),
                validateStatus: (status) =>
                    status != null && status < 500, // 接受400-499状态码
              ));
          print('连接测试成功 (根路径): ${response.statusCode}');

          // 更新当前使用的基础URL
          if (_currentBaseUrl != testUrl) {
            print('切换到新的基础URL: $testUrl');
            _currentBaseUrl = testUrl;
            initialize(); // 重新初始化Dio实例
          }
          return true;
        } catch (rootError) {
          print('根路径连接失败，尝试其他路径: $rootError');

          // 尝试已知的API路径
          final testPaths = ['/team/get/999999', '/ping', '/health'];

          for (final path in testPaths) {
            try {
              final response = await testDio.get(path,
                  options: Options(
                    receiveTimeout: const Duration(seconds: 2),
                    validateStatus: (status) => status != null, // 接受任何HTTP响应
                  ));
              print('连接测试成功 ($path): ${response.statusCode}');

              // 更新当前使用的基础URL
              if (_currentBaseUrl != testUrl) {
                print('切换到新的基础URL: $testUrl');
                _currentBaseUrl = testUrl;
                initialize(); // 重新初始化Dio实例
              }
              return true;
            } catch (pathError) {
              print('路径 $path 测试失败: $pathError');
              continue;
            }
          }
        }
      } catch (e) {
        print('URL $testUrl 连接完全失败: $e');
        continue;
      }
    }

    print('所有URL测试失败，无法连接到后端服务');
    return false;
  }
}
