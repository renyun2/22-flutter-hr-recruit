import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code, this.extra});
  final String message;
  final int? statusCode;
  final int? code;
  final Map<String, dynamic>? extra;

  @override
  String toString() => message;
}

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._getToken);
  final Future<String?> Function() _getToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final data = err.response?.data;
    var message = '网络请求失败';
    int? code;
    Map<String, dynamic>? extra;
    if (data is Map) {
      message = data['error']?.toString() ?? message;
      code = data['code'] is int ? data['code'] as int : err.response?.statusCode;
      if (data['suggestedSlots'] != null) {
        extra = {'suggestedSlots': data['suggestedSlots']};
      }
    } else if (err.message != null) {
      message = err.message!;
    }
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException(message, statusCode: err.response?.statusCode, code: code, extra: extra),
      ),
    );
  }
}

final tokenStorageProvider = Provider((_) => TokenStorage());

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  final tokenStorage = ref.watch(tokenStorageProvider);
  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage.getToken),
    ErrorInterceptor(),
  ]);
  return dio;
});
