import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_interceptor.dart';
import '../../../core/network/providers.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<bool> hasSession() async => (await _storage.readRefreshToken()) != null;

  Future<UserProfile> login(String email, String password) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
        options: Options(extra: {AuthInterceptor.skipAuthKey: true}),
      );
      final login = LoginResponse.fromJson(res.data!);
      await _storage.save(
        accessToken: login.accessToken,
        refreshToken: login.refreshToken,
      );
      return login.user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserProfile> me() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/users/me');
      return UserProfile.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// Always clears local tokens, even if the server call fails.
  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException {
      // Ignore: the local session is removed regardless.
    } finally {
      await _storage.clear();
    }
  }

  Future<void> clearLocalSession() => _storage.clear();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
