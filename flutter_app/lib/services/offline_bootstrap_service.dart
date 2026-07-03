import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../shared/models/api_response.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/pos/data/pos_repository.dart';
import '../features/pos/models/pos_models.dart';
import '../features/settings/data/settings_repository.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';

class OfflineBootstrapService {
  OfflineBootstrapService(this._ref);

  final Ref _ref;

  Future<bool> warmCache({bool force = false}) async {
    final server = _ref.read(serverUrlProvider);
    if (server == null || server.isEmpty) return false;

    final apiBaseUrl = _ref.read(apiBaseUrlProvider);
    final connectivity = _ref.read(connectivityServiceProvider);
    if (!force &&
        !await connectivity.isServerReachable(apiBaseUrl, force: true)) {
      return false;
    }

    final cache = _ref.read(offlineCacheServiceProvider);
    final posRepo = _ref.read(posRepositoryProvider);
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final dio = _ref.read(dioProvider);

    try {
      final results = await Future.wait([
        dio.getApi<List<Map<String, dynamic>>>(
          '/settings/outlets',
          parser: (data) => (data as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList(),
        ),
        posRepo.getProducts(),
        posRepo.getCategories(),
        posRepo.getPaymentMethods(),
        settingsRepo.getTenantSettings(cache: cache, online: true),
      ]);

      final outlets =
          (results[0] as ApiResponse<List<Map<String, dynamic>>>).data ?? [];
      if (outlets.isNotEmpty) {
        await cache.saveOutlets(outlets);
        final storedOutlet = await _ref.read(authRepositoryProvider).getStoredOutletId();
        if (storedOutlet == null) {
          final firstId = outlets.first['id'];
          if (firstId is int) {
            await _ref
                .read(authRepositoryProvider)
                .saveSelectedOutletId(firstId);
            _ref.read(selectedOutletIdProvider.notifier).state = firstId;
          }
        }
      }

      await cache.saveCatalog(
        products: results[1] as List<PosProduct>,
        categories: results[2] as List<PosCategory>,
        methods: results[3] as List<PaymentMethod>,
      );

      for (final outlet in outlets) {
        final outletId = outlet['id'];
        if (outletId is! int) continue;
        try {
          final shift = await posRepo.getCurrentShift(outletId: outletId);
          if (shift != null && shift.id > 0) {
            await cache.saveShift(outletId, shift);
          }
        } catch (_) {}
      }

      debugPrint('OfflineBootstrap: cache warmed (${outlets.length} outlets)');
      return true;
    } catch (e) {
      debugPrint('OfflineBootstrap: warm failed — $e');
      return false;
    }
  }

  Future<bool> hasMinimumPosData() async {
    final cache = _ref.read(offlineCacheServiceProvider);
    final catalog = await cache.loadCatalog();
    final outlets = await cache.loadOutlets();
    return catalog != null &&
        catalog.paymentMethods.isNotEmpty &&
        catalog.products.isNotEmpty &&
        outlets != null &&
        outlets.isNotEmpty;
  }
}

final offlineBootstrapServiceProvider = Provider<OfflineBootstrapService>((ref) {
  return OfflineBootstrapService(ref);
});