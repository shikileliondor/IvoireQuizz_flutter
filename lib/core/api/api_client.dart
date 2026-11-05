import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      _LogInterceptor(),
      _ErrorInterceptor(_storage),
    ]);
  }

  final SecureStorageService _storage;
  late final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response =
          await _dio.get<dynamic>(path, queryParameters: queryParameters);
      return _parse(response.data, parser);
    } on DioException catch (error) {
      _rethrowApiError(error);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post<dynamic>(path, data: data);
      return _parse(response.data, parser);
    } on DioException catch (error) {
      _rethrowApiError(error);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.put<dynamic>(path, data: data);
      return _parse(response.data, parser);
    } on DioException catch (error) {
      _rethrowApiError(error);
    }
  }

  Future<void> delete(String path) async {
    try {
      await _dio.delete<dynamic>(path);
    } on DioException catch (error) {
      _rethrowApiError(error);
    }
  }

  T _parse<T>(dynamic raw, T Function(dynamic)? parser) {
    if (parser != null) return parser(raw);
    return raw as T;
  }

  Never _rethrowApiError(DioException error) {
    if (error.error case final ApiException apiError) throw apiError;
    final connectionIssue = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.receiveTimeout;
    throw ApiException(
      connectionIssue
          ? 'Serveur inaccessible. Vérifie la connexion et l’adresse API.'
          : 'Erreur réseau ou serveur.',
      statusCode: error.response?.statusCode,
    );
  }
}

class _AuthInterceptor extends Interceptor {
  const _AuthInterceptor(this._storage);
  final SecureStorageService _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _LogInterceptor extends Interceptor {
  static const _key = 'api_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_key] = Stopwatch()..start();
    debugPrint('[API] → ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) {
    _log(
      error.requestOptions,
      error.response?.statusCode,
      error: error.type.name,
    );
    handler.next(error);
  }

  void _log(RequestOptions options, int? statusCode, {String? error}) {
    final stopwatch = options.extra[_key] as Stopwatch?;
    stopwatch?.stop();
    final status = statusCode?.toString() ?? error ?? '?';
    debugPrint(
      '[API] ← ${options.method} ${options.uri} $status '
      '${stopwatch?.elapsedMilliseconds ?? -1}ms',
    );
  }
}

class _ErrorInterceptor extends Interceptor {
  const _ErrorInterceptor(this._storage);
  final SecureStorageService _storage;

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final response = error.response;
    final body = response?.data;
    if (response?.statusCode == 401) await _storage.deleteToken();

    final exception = body is Map
        ? ApiException(
            body['message']?.toString() ?? 'Erreur API',
            statusCode: response?.statusCode,
            errors: body['errors'] is Map
                ? Map<String, dynamic>.from(body['errors'] as Map)
                : null,
          )
        : ApiException(
            'Erreur réseau ou serveur.',
            statusCode: response?.statusCode,
          );
    handler.reject(error.copyWith(error: exception));
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(secureStorageProvider));
});
