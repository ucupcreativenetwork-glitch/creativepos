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
            ),
        _memory = null;

  SecureStorageService.memory({Map<String, String>? initial})
      : _storage = null,
        _memory = Map<String, String>.from(initial ?? {});

  final FlutterSecureStorage? _storage;
  final Map<String, String>? _memory;

  Future<void> write(String key, String value) async {
    if (_memory != null) {
      _memory![key] = value;
      return;
    }
    await _storage!.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    if (_memory != null) {
      return _memory![key];
    }
    return _storage!.read(key: key);
  }

  Future<void> delete(String key) async {
    if (_memory != null) {
      _memory!.remove(key);
      return;
    }
    await _storage!.delete(key: key);
  }

  Future<void> clearSession() async {
    await delete(StorageKeys.authToken);
  }

  Future<void> clearAll() async {
    if (_memory != null) {
      _memory!.clear();
      return;
    }
    await _storage!.deleteAll();
  }
}