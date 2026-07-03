import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_bootstrap_service.dart';
import '../../../services/offline_cache_service.dart';
import '../../../services/standalone_service.dart';
import '../../standalone/providers/standalone_providers.dart';
import '../data/auth_api.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => SecureStorageService(),
);

final serverUrlProvider = StateProvider<String?>((ref) => null);

final apiBaseUrlProvider = Provider<String>((ref) {
  final server = ref.watch(serverUrlProvider);
  if (server == null || server.isEmpty) {
    return 'http://localhost/api/v1';
  }
  return AppConfig.buildApiBaseUrl(server);
});

final authTokenProvider = StateProvider<String?>((ref) => null);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: AuthApi(ref.watch(dioProvider)),
    storage: ref.watch(secureStorageProvider),
    cache: ref.watch(offlineCacheServiceProvider),
  );
});

final selectedOutletIdProvider = StateProvider<int?>((ref) => null);

enum AuthStatus {
  unknown,
  unauthenticated,
  needsServer,
  needs2fa,
  needsBiometric,
  needsPasswordChange,
  authenticated,
  standalone,
}

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.session,
    this.pendingToken,
    this.twoFactorMethod,
    this.isLoading = false,
    this.error,
  });

  final AuthStatus status;
  final AuthSession? session;
  final String? pendingToken;
  final String? twoFactorMethod;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    AuthSession? session,
    String? pendingToken,
    String? twoFactorMethod,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      pendingToken: pendingToken ?? this.pendingToken,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    bootstrap();
  }

  final Ref _ref;

  AuthRepository get _repo => _ref.read(authRepositoryProvider);

  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final standalone = _ref.read(standaloneServiceProvider);
      if (await standalone.isEnabled()) {
        final profile = await standalone.getProfile();
        if (profile != null) {
          final session = standalone.buildSession(profile);
          _ref.read(authTokenProvider.notifier).state = session.token;
          _ref.read(selectedOutletIdProvider.notifier).state = 1;
          await _ref.read(authRepositoryProvider).saveSelectedOutletId(1);
          await standalone.refreshPosCatalog();
          state = state.copyWith(
            status: AuthStatus.standalone,
            session: session,
            isLoading: false,
          );
          return;
        }
        await standalone.disableStandalone();
      }

      final server = await _repo.getServerUrl();
      if (server == null || server.isEmpty) {
        state = state.copyWith(
          status: AuthStatus.needsServer,
          isLoading: false,
        );
        return;
      }
      _ref.read(serverUrlProvider.notifier).state = server;

      final storedOutlet = await _repo.getStoredOutletId();
      if (storedOutlet != null) {
        _ref.read(selectedOutletIdProvider.notifier).state = storedOutlet;
      }

      final hasToken = await _repo.hasStoredToken();
      final biometricEnabled = await _repo.isBiometricEnabled();
      if (hasToken && biometricEnabled) {
        state = state.copyWith(
          status: AuthStatus.needsBiometric,
          isLoading: false,
        );
        return;
      }

      final serverUp = await _ref.read(connectivityServiceProvider).isServerReachable(
            _ref.read(apiBaseUrlProvider),
          );
      final session = await _repo.restoreSession(preferCache: !serverUp);
      if (session != null) {
        _ref.read(authTokenProvider.notifier).state = session.token;
        final nextStatus = _statusForSession(session);
        state = state.copyWith(
          status: nextStatus,
          session: session,
          isLoading: false,
        );
        if (nextStatus == AuthStatus.authenticated) {
          unawaited(_warmOfflineCache());
        }
        return;
      }

      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> configureServer(String url) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final normalized = AppConfig.normalizeServerUrl(url);
      _ref.read(serverUrlProvider.notifier).state = normalized;
      await _repo.persistServerUrl(normalized);

      final ok = await _repo.healthCheck();
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        isLoading: false,
        error: ok
            ? null
            : 'Server belum terjangkau — URL disimpan, login & sync saat server aktif',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
    bool remember = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await _repo.login(
        email: email,
        password: password,
        remember: remember,
      );

      if (session.requires2fa) {
        state = state.copyWith(
          status: AuthStatus.needs2fa,
          pendingToken: session.pendingToken,
          twoFactorMethod: session.twoFactorMethod,
          isLoading: false,
        );
        return true;
      }

      _ref.read(authTokenProvider.notifier).state = session.token;
      final nextStatus = _statusForSession(session);
      state = state.copyWith(
        status: nextStatus,
        session: session,
        isLoading: false,
      );
      if (nextStatus == AuthStatus.authenticated) {
        unawaited(_warmOfflineCache());
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> completeBiometricLogin() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final hasToken = await _repo.hasStoredToken();
      if (!hasToken) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Sesi tidak ditemukan. Masuk dengan email dan password.',
        );
        return false;
      }

      var session = await _repo.restoreSession(preferCache: true);
      session ??= await _repo.restoreSession(preferCache: false);
      if (session == null) {
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false,
          error: 'Sesi tidak ditemukan. Masuk dengan email dan password.',
        );
        return false;
      }

      _ref.read(authTokenProvider.notifier).state = session.token;
      final nextStatus = _statusForSession(session);
      state = state.copyWith(
        status: nextStatus,
        session: session,
        isLoading: false,
      );

      if (nextStatus == AuthStatus.authenticated) {
        unawaited(_refreshSessionInBackground());
        unawaited(_warmOfflineCache());
      }
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.needsBiometric,
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> _refreshSessionInBackground() async {
    try {
      final serverUp = await _ref.read(connectivityServiceProvider).isServerReachable(
            _ref.read(apiBaseUrlProvider),
          );
      if (!serverUp) return;
      final session = await _repo.restoreSession(preferCache: false);
      if (session == null) return;
      _ref.read(authTokenProvider.notifier).state = session.token;
      state = state.copyWith(session: session);
    } catch (_) {}
  }

  Future<bool> verifyTwoFactor(String code) async {
    final pending = state.pendingToken;
    if (pending == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final session = await _repo.completeTwoFactor(
        pendingToken: pending,
        code: code,
      );
      _ref.read(authTokenProvider.notifier).state = session.token;
      final nextStatus = _statusForSession(session);
      state = state.copyWith(
        status: nextStatus,
        session: session,
        isLoading: false,
      );
      if (nextStatus == AuthStatus.authenticated) {
        unawaited(_warmOfflineCache());
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repo.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      final session = state.session;
      if (session == null) {
        state = state.copyWith(isLoading: false, error: 'Sesi tidak ditemukan');
        return false;
      }
      final updated = AuthSession(
        token: session.token,
        user: user,
        tenant: session.tenant,
        permissions: session.permissions,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: updated,
        isLoading: false,
      );
      unawaited(_warmOfflineCache());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void requirePasswordChange() {
    final session = state.session;
    if (session == null) return;
    state = state.copyWith(
      status: AuthStatus.needsPasswordChange,
      session: AuthSession(
        token: session.token,
        user: session.user.copyWith(mustChangePassword: true),
        tenant: session.tenant,
        permissions: session.permissions,
        requires2fa: session.requires2fa,
        pendingToken: session.pendingToken,
        twoFactorMethod: session.twoFactorMethod,
      ),
    );
  }

  AuthStatus _statusForSession(AuthSession session) {
    return session.user.mustChangePassword
        ? AuthStatus.needsPasswordChange
        : AuthStatus.authenticated;
  }

  Future<void> _warmOfflineCache() async {
    await _ref.read(offlineBootstrapServiceProvider).warmCache();
  }

  Future<bool> activateStandalone({
    required String businessName,
    required String ownerName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final standalone = _ref.read(standaloneServiceProvider);
      await standalone.enableStandalone(
        StandaloneProfile(
          businessName: businessName,
          ownerName: ownerName,
        ),
      );

      final profile = await standalone.getProfile();
      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Profil toko gagal dibuat',
        );
        return false;
      }

      final session = standalone.buildSession(profile);
      _ref.read(authTokenProvider.notifier).state = session.token;
      _ref.read(selectedOutletIdProvider.notifier).state = 1;
      await _ref.read(authRepositoryProvider).saveSelectedOutletId(1);
      _ref.invalidate(standaloneModeProvider);
      _ref.invalidate(standaloneProfileProvider);

      state = state.copyWith(
        status: AuthStatus.standalone,
        session: session,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> exitStandaloneMode() async {
    await _ref.read(standaloneServiceProvider).disableStandalone();
    _ref.read(authTokenProvider.notifier).state = null;
    _ref.invalidate(standaloneModeProvider);
    _ref.invalidate(standaloneProfileProvider);
    state = state.copyWith(
      status: AuthStatus.needsServer,
      session: null,
      pendingToken: null,
    );
  }

  Future<void> logout({bool keepBiometric = true}) async {
    if (state.status == AuthStatus.standalone) {
      await exitStandaloneMode();
      return;
    }

    await _repo.logout();
    if (!keepBiometric) {
      await _repo.setBiometricEnabled(false);
    }
    _ref.read(authTokenProvider.notifier).state = null;
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      session: null,
      pendingToken: null,
    );
  }

  Future<void> handleUnauthorized() async {
    final cached = await _repo.restoreSessionFromCache();
    if (cached != null) {
      _ref.read(authTokenProvider.notifier).state = cached.token;
      state = state.copyWith(
        status: AuthStatus.authenticated,
        session: cached,
      );
      return;
    }

    _ref.read(authTokenProvider.notifier).state = null;
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      session: null,
    );
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});