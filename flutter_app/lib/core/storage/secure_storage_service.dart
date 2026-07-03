import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract final class StorageKeys {
  static const serverUrl = 'creativepos_server_url';
  static const authToken = 'creativepos_auth_token';
  static const rememberEmail = 'creativepos_remember_email';
  static const selectedOutletId = 'creativepos_outlet_id';
  static const biometricEnabled = 'creativepos_biometric_enabled';
}

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.authToken);
  }

  Future<void> clearAll() => _storage.deleteAll();
}