import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/api_paths.dart';
import '../features/auth/providers/auth_providers.dart';

enum ConnectivityMode {
  online,
  noNetwork,
  serverUnreachable,
}

class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  String? _lastCheckUrl;
  bool? _lastReachable;
  DateTime? _lastCheckAt;
  static const _cacheDuration = Duration(seconds: 5);

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<bool> get hasNetwork async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<bool> isServerReachable(
    String apiBaseUrl, {
    bool force = false,
  }) async {
    if (!await hasNetwork) return false;
    if (apiBaseUrl.isEmpty) return false;

    if (!force &&
        _lastCheckUrl == apiBaseUrl &&
        _lastCheckAt != null &&
        DateTime.now().difference(_lastCheckAt!) < _cacheDuration) {
      return _lastReachable ?? false;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final response = await dio.get<Map<String, dynamic>>(ApiPaths.health);
      final ok = response.statusCode == 200;
      _lastCheckUrl = apiBaseUrl;
      _lastReachable = ok;
      _lastCheckAt = DateTime.now();
      return ok;
    } catch (_) {
      _lastCheckUrl = apiBaseUrl;
      _lastReachable = false;
      _lastCheckAt = DateTime.now();
      return false;
    }
  }

  void invalidateServerCache() {
    _lastCheckAt = null;
    _lastReachable = null;
    _lastCheckUrl = null;
  }

  Future<ConnectivityMode> resolveMode(String apiBaseUrl) async {
    if (!await hasNetwork) return ConnectivityMode.noNetwork;
    if (!await isServerReachable(apiBaseUrl)) {
      return ConnectivityMode.serverUnreachable;
    }
    return ConnectivityMode.online;
  }

  /// True when server is reachable (not merely network interface up).
  Future<bool> isOnline(String apiBaseUrl) => isServerReachable(apiBaseUrl);
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final hasNetworkProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.hasNetwork;
  await for (final _ in service.onConnectivityChanged) {
    service.invalidateServerCache();
    yield await service.hasNetwork;
  }
});

final connectivityModeProvider = StreamProvider<ConnectivityMode>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  final apiBaseUrl = ref.watch(apiBaseUrlProvider);

  Future<ConnectivityMode> check() => service.resolveMode(apiBaseUrl);

  yield await check();
  await for (final _ in service.onConnectivityChanged) {
    service.invalidateServerCache();
    yield await check();
  }
});

final isServerReachableProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  final apiBaseUrl = ref.watch(apiBaseUrlProvider);

  Future<bool> check() async {
    final server = ref.read(serverUrlProvider);
    if (server == null || server.isEmpty) return false;
    return service.isServerReachable(apiBaseUrl);
  }

  yield await check();
  await for (final _ in service.onConnectivityChanged) {
    service.invalidateServerCache();
    yield await check();
  }
});

/// Server reachable — used for sync and live API calls.
final isOnlineProvider = isServerReachableProvider;