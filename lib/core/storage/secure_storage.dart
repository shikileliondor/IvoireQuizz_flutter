import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'onboarding_done';

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> setToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<bool> isOnboardingDone() async {
    final val = await _storage.read(key: _onboardingKey);
    return val != null;
  }

  Future<void> setOnboardingDone() =>
      _storage.write(key: _onboardingKey, value: 'true');

  Future<void> clearAll() => _storage.deleteAll();
}

final secureStorageProvider = Provider<SecureStorageService>(
  (_) => const SecureStorageService(FlutterSecureStorage()),
);
