import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage.dart';
import '../data/auth_api.dart';
import '../models/user.dart';

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    final storage = ref.watch(secureStorageProvider);
    final token = await storage.getToken();
    if (token == null) return null;
    try {
      return await ref.read(authApiProvider).getMe();
    } catch (_) {
      await storage.deleteToken();
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(secureStorageProvider);
      final result = await ref.read(authApiProvider).login(
            email: email,
            password: password,
          );
      await storage.setToken(result.token);
      return result.user;
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(secureStorageProvider);
      final result = await ref.read(authApiProvider).register(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
          );
      await storage.setToken(result.token);
      return result.user;
    });
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final storage = ref.read(secureStorageProvider);
      final result = await ref.read(authApiProvider).loginWithGoogle(idToken);
      await storage.setToken(result.token);
      return result.user;
    });
  }

  Future<void> logout() async {
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {}
    await ref.read(secureStorageProvider).clearAll();
    state = const AsyncData(null);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authApiProvider).getMe(),
    );
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);
