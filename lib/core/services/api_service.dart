import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

class ApiService {
  static ApiService? _instance;
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final _log     = Logger();

  ApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ));

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      _LogInterceptor(_log),
    ]);
  }

  factory ApiService() => _instance ??= ApiService._();

  Dio get dio => _dio;

  // ── Auth helpers ──────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: 'auth_token', value: token);

  Future<void> clearToken() =>
      _storage.delete(key: 'auth_token');

  Future<String?> getToken() =>
      _storage.read(key: 'auth_token');

  // ── Generic request wrappers ──────────────────────────────────────

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? params,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(path,
        queryParameters: params);
    return res.data!;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(path,
        data: data, queryParameters: params);
    return res.data!;
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(path, data: data);
    return res.data!;
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
  }) async {
    final res = await _dio.patch<Map<String, dynamic>>(path, data: data);
    return res.data!;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _dio.delete<Map<String, dynamic>>(path);
    return res.data!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interceptor: inject Bearer token dari secure storage
// ─────────────────────────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Interceptor: logging di debug mode
// ─────────────────────────────────────────────────────────────────────────────
class _LogInterceptor extends Interceptor {
  final Logger _log;
  _LogInterceptor(this._log);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e('[API Error] ${err.response?.statusCode} ${err.message}');
    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API Exception wrapper
// ─────────────────────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors; // validation errors

  const ApiException(this.message, {this.statusCode, this.errors});

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    final msg  = (data is Map ? data['message'] : null) ?? e.message ?? 'Terjadi kesalahan';
    final errs = (data is Map ? data['errors'] : null) as Map<String, dynamic>?;
    return ApiException(msg, statusCode: e.response?.statusCode, errors: errs);
  }

  @override
  String toString() => message;
}
