import '../../../core/config/app_config.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../services/offline_cache_service.dart';
import '../models/user_model.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required SecureStorageService storage,
    required OfflineCacheService cache,
  })  : _api = api,
        _storage = storage,
        _cache = cache;

  final AuthApi _api;
  final SecureStorageService _storage;
  final OfflineCacheService _cache;

  Future<String?> getServerUrl() => _storage.read(StorageKeys.serverUrl);

  Future<void> saveServerUrl(String url) {
    final normalized = AppConfig.normalizeServerUrl(url);
    return _storage.write(StorageKeys.serverUrl, normalized);
  }

  Future<String?> getToken() => _storage.read(StorageKeys.authToken);

  Future<void> saveToken(String token) =>
      _storage.write(StorageKeys.authToken, token);

  Future<void> clearToken() => _storage.delete(StorageKeys.authToken);

  Future<String?> getRememberedEmail() =>
      _storage.read(StorageKeys.rememberEmail);

  Future<void> saveRememberedEmail(String email) =>
      _storage.write(StorageKeys.rememberEmail, email);

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(StorageKeys.biometricEnabled);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      StorageKeys.biometricEnabled,
      enabled ? 'true' : 'false',
    );
  }

  Future<void> saveSelectedOutletId(int outletId) =>
      _storage.write(StorageKeys.selectedOutletId, outletId.toString());

  Future<int?> getStoredOutletId() async {
    final raw = await _storage.read(StorageKeys.selectedOutletId);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<bool> hasStoredToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> healthCheck() => _api.healthCheck();

  Future<void> persistServerUrl(String serverUrl) async {
    await saveServerUrl(AppConfig.normalizeServerUrl(serverUrl));
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    final session = await _api.login(email: email, password: password);
    if (session.requires2fa) return session;
    if (session.token != null) {
      await saveToken(session.token!);
      await _cache.saveSession(
        AuthSession(
          token: session.token,
          user: session.user,
          tenant: session.tenant,
          permissions: session.permissions,
        ),
      );
    }
    if (remember) {
      await saveRememberedEmail(email);
    }
    return session;
  }

  Future<AuthSession> completeTwoFactor({
    required String pendingToken,
    required String code,
  }) async {
    final session = await _api.verifyTwoFactor(
      pendingToken: pendingToken,
      code: code,
    );
    if (session.token != null) {
      await saveToken(session.token!);
      await _cache.saveSession(
        AuthSession(
          token: session.token,
          user: session.user,
          tenant: session.tenant,
          permissions: session.permissions,
        ),
      );
    }
    return session;
  }

  Future<AuthSession?> restoreSession({bool preferCache = false}) async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;

    if (preferCache) {
      final cached = await _cache.loadSession();
      if (cached != null) return cached;
    }

    try {
      final session = await _api.me();
      final restored = AuthSession(
        token: token,
        user: session.user,
        tenant: session.tenant,
        permissions: session.permissions,
      );
      await _cache.saveSession(restored);
      return restored;
    } catch (_) {
      return _cache.loadSession();
    }
  }

  Future<AuthSession?> restoreSessionFromCache() => _cache.loadSession();

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await clearToken();
      await _cache.clearSession();
    }
  }
}