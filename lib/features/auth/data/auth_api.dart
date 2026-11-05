import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../models/user.dart';

class AuthApi {
  const AuthApi(this._client);
  final ApiClient _client;

  Future<({String token, User user})> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    final data = api.data!;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    final data = api.data!;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> loginWithGoogle(String idToken) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/auth/google',
      data: {'token': idToken},
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    final data = api.data!;
    return (
      token: data['token'] as String,
      user: User.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<User> getMe() async {
    final res = await _client.get<Map<String, dynamic>>(
      '/me',
      parser: (raw) => raw as Map<String, dynamic>,
    );
    final api = ApiResponse.fromJson(res, (d) => d as Map<String, dynamic>);
    final data = api.data!;
    final raw = data.containsKey('user') ? data['user'] : data;
    return User.fromJson(raw as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await _client.post<void>('/auth/logout');
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(ref.watch(apiClientProvider)),
);
