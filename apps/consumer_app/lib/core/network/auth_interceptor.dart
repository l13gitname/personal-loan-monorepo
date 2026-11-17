import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

/// Adds the bearer token and transparently refreshes it on 401.
///
/// It is a [QueuedInterceptor], so concurrent 401s are handled one at a time:
/// the first refreshes the token, the others notice the token already changed
/// and just retry. The refresh call and the retry use a separate plain [Dio]
/// (no interceptors) which avoids deadlocking the interceptor queue.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenStorage storage,
    required Future<void> Function() onSessionExpired,
  })  : _storage = storage,
        _onSessionExpired = onSessionExpired,
        _plain = Dio(
          BaseOptions(
            baseUrl: dio.options.baseUrl,
            connectTimeout: dio.options.connectTimeout,
            receiveTimeout: dio.options.receiveTimeout,
            headers: {'Content-Type': 'application/json'},
          ),
        );

  /// Pass in `options.extra` to skip auth handling (login, refresh).
  static const skipAuthKey = 'skipAuth';

  final TokenStorage _storage;
  final Future<void> Function() _onSessionExpired;
  final Dio _plain;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await _storage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    if (err.response?.statusCode != 401 || request.extra[skipAuthKey] == true) {
      return handler.next(err);
    }

    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) {
      await _onSessionExpired();
      return handler.next(err);
    }

    // Another queued request may already have refreshed the token.
    var accessToken = await _storage.readAccessToken();
    final sentWith = request.headers['Authorization'];
    if (accessToken == null || sentWith == 'Bearer $accessToken') {
      accessToken = await _refresh(refreshToken);
      if (accessToken == null) {
        await _onSessionExpired();
        return handler.next(err);
      }
    }

    // A multipart body can only be sent once; let the caller rebuild it.
    if (request.data is FormData) return handler.next(err);

    try {
      request.headers['Authorization'] = 'Bearer $accessToken';
      handler.resolve(await _plain.fetch<dynamic>(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refresh(String refreshToken) async {
    try {
      final res = await _plain.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final access = res.data?['accessToken'] as String?;
      final refresh = res.data?['refreshToken'] as String?;
      if (access == null || refresh == null) return null;
      await _storage.save(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException {
      return null;
    }
  }
}
