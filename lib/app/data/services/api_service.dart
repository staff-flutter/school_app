import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response, FormData;
import 'package:get_storage/get_storage.dart';

import '../../core/constants/api_constants.dart';

class ApiService extends GetxService {
  late Dio _dio;
  final _storage = GetStorage();
  
  Dio get dio => _dio; // Expose dio instance

  @override
  void onInit() {
    super.onInit();
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storage.read('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          
        } else {
          
        }
        // Only set Content-Type to application/json if data is not FormData
        // FormData will set its own Content-Type with boundary
        if (options.data != null) {
          final dataTypeName = options.data.runtimeType.toString();
          // Don't set Content-Type for FormData - Dio handles it automatically
          if (!dataTypeName.contains('FormData')) {
            options.headers['Content-Type'] = 'application/json';
          }
        } else {
          options.headers['Content-Type'] = 'application/json';
        }
        
        if (options.queryParameters.isNotEmpty) {
          
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        
        handler.next(response);
      },
      onError: (error, handler) {

        if (error.response?.statusCode == 401) {
          
          _storage.remove('token');
          _storage.remove('user');
          _storage.remove('userSchool');
          // Use a delay to avoid navigation conflicts
          Future.delayed(const Duration(milliseconds: 100), () {
            if (Get.currentRoute != '/login') {
              Get.offAllNamed('/login');
            }
          });
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.delete(path, queryParameters: queryParameters);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  // Method to manually set token (useful after login)
  void setToken(String token) {
    _storage.write('token', token);
    
  }

  // Method to get current token
  String? getToken() {
    return _storage.read('token');
  }

  // Method to clear token
  void clearToken() {
    _storage.remove('token');
    _storage.remove('user');
    _storage.remove('userSchool');
    
  }
}