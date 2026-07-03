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
    final memory = _memory;
    if (memory != null) {
      memory[key] = value;
      return;
    }
    final storage = _storage;
    if (storage == null) return;
    await storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    final memory = _memory;
    if (memory != null) {
      return memory[key];
    }
    final storage = _storage;
    if (storage == null) return null;
    return storage.read(key: key);
  }

  Future<void> delete(String key) async {
    final memory = _memory;
    if (memory != null) {
      memory.remove(key);
      return;
    }
    final storage = _storage;
    if (storage == null) return;
    await storage.delete(key: key);
  }

  Future<void> clearSession() async {
    await delete(StorageKeys.authToken);
  }

  Future<void> clearAll() async {
    final memory = _memory;
    if (memory != null) {
      memory.clear();
      return;
    }
    final storage = _storage;
    if (storage == null) return;
    await storage.deleteAll();
  }
}