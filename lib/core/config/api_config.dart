import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://laravelquizz.studiobeyam.net',
  );
  static const String apiBaseUrl = '$baseUrl/api';

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  static Dio createDio({String? authToken}) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
      ),
    );

    dio.interceptors.add(_ApiDurationLogInterceptor());
    return dio;
  }
}

class _ApiDurationLogInterceptor extends Interceptor {
  static const String _startedAtKey = 'api_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = Stopwatch()..start();
    debugPrint('[API] → ${options.method} ${_safePath(options.uri)}');
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log(
      options: response.requestOptions,
      statusCode: response.statusCode,
      contentLength: response.headers.value('content-length'),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(
      options: err.requestOptions,
      statusCode: err.response?.statusCode,
      error: err.type.name,
      contentLength: err.response?.headers.value('content-length'),
    );
    handler.next(err);
  }

  void _log({
    required RequestOptions options,
    required int? statusCode,
    String? error,
    String? contentLength,
  }) {
    final Stopwatch? stopwatch = options.extra[_startedAtKey] as Stopwatch?;
    stopwatch?.stop();
    final int elapsedMs = stopwatch?.elapsedMilliseconds ?? -1;
    final String status = statusCode?.toString() ?? error ?? 'no-status';
    final int? responseBytes = int.tryParse(contentLength ?? '');
    debugPrint(
      '[API] ← ${options.method} ${_safePath(options.uri)} $status ${elapsedMs}ms '
      'response_bytes=${responseBytes?.toString() ?? 'unknown'}',
    );
  }

  String _safePath(Uri uri) {
    final uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final segments = uri.pathSegments.map((segment) {
      final looksLikeOpaqueId =
          segment.length >= 20 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(segment);
      return int.tryParse(segment) != null ||
              uuid.hasMatch(segment) ||
              looksLikeOpaqueId
          ? ':id'
          : segment;
    });

    return '/${segments.join('/')}';
  }
}
