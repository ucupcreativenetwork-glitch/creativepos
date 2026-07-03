import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../features/auth/providers/auth_providers.dart';
import '../features/pos/data/pos_repository.dart';
import '../local_database/offline_queue_repository.dart';
import 'connectivity_service.dart' show connectivityServiceProvider;
import 'offline_cache_service.dart';

class SyncResult {
  const SyncResult({
    required this.synced,
    required this.failed,
    required this.skipped,
  });

  final int synced;
  final int failed;
  final int skipped;

  bool get hasWork => synced > 0 || failed > 0;
}

class SyncService {
  SyncService(this._ref);

  final Ref _ref;
  bool _running = false;
  Timer? _pollTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<bool> _canSync() async {
    final apiBaseUrl = _ref.read(apiBaseUrlProvider);
    final server = _ref.read(serverUrlProvider);
    if (server == null || server.isEmpty) return false;
    return _ref.read(connectivityServiceProvider).isServerReachable(apiBaseUrl);
  }

  Future<SyncResult> syncPending() async {
    if (_running) {
      return const SyncResult(synced: 0, failed: 0, skipped: 0);
    }

    if (!await _canSync()) {
      return const SyncResult(synced: 0, failed: 0, skipped: 0);
    }

    _running = true;
    var synced = 0;
    var failed = 0;

    try {
      final queue = _ref.read(offlineQueueRepositoryProvider);
      await queue.resetStuckSyncing();
      final pending = await queue.listPending();
      final repo = _ref.read(posRepositoryProvider);

      for (final item in pending) {
        if (item.status == 'syncing') continue;

        await queue.markSyncing(item.id);
        try {
          final payload = Map<String, dynamic>.from(item.payload);
          final outletId = payload['outlet_id'] as int?;
          if (outletId != null && payload['shift_id'] == null) {
            final shift = await repo.getCurrentShift(outletId: outletId);
            if (shift != null) {
              payload['shift_id'] = shift.id;
            } else {
              await queue.markFailed(
                item.id,
                'Shift tidak aktif. Buka shift di outlet terkait lalu sync ulang.',
                retryCount: item.retryCount + 1,
              );
              failed++;
              continue;
            }
          }

          await repo.createTransaction(
            payload: payload,
            idempotencyKey: item.idempotencyKey,
          );
          await queue.markSynced(item.id);
          synced++;
        } on DioException catch (e) {
          final message = e.message ?? 'Sync gagal';
          await queue.markFailed(
            item.id,
            message,
            retryCount: item.retryCount + 1,
          );
          failed++;
        } on AppException catch (e) {
          await queue.markFailed(
            item.id,
            e.message,
            retryCount: item.retryCount + 1,
          );
          failed++;
        } catch (e) {
          await queue.markFailed(
            item.id,
            e.toString(),
            retryCount: item.retryCount + 1,
          );
          failed++;
        }
      }

      await queue.deleteSynced();
      await _syncPendingShiftCloses(repo);
    } finally {
      _running = false;
    }

    return SyncResult(synced: synced, failed: failed, skipped: 0);
  }

  Future<void> _syncPendingShiftCloses(PosRepository repo) async {
    final cache = _ref.read(offlineCacheServiceProvider);
    final pending = await cache.listPendingShiftCloses();
    if (pending.isEmpty) return;

    final queue = _ref.read(offlineQueueRepositoryProvider);
    final txPending = await queue.pendingCount();
    if (txPending > 0) return;

    for (final item in pending) {
      final shiftId = item['shift_id'] as int?;
      if (shiftId == null || shiftId <= 0) {
        await cache.removeShiftClose(item['outlet_id'] as int);
        continue;
      }
      try {
        await repo.closeShift(
          shiftId: shiftId,
          closingCash: (item['closing_cash'] as num?)?.toDouble() ?? 0,
          notes: item['notes'] as String?,
        );
        await cache.removeShiftClose(item['outlet_id'] as int);
        debugPrint('Shift close synced: ${item['shift_number']}');
      } catch (e) {
        debugPrint('Shift close sync failed: $e');
      }
    }
  }

  void startAutoSync() {
    _connectivitySub?.cancel();
    _pollTimer?.cancel();

    final connectivity = _ref.read(connectivityServiceProvider);
    _connectivitySub = connectivity.onConnectivityChanged.listen((_) async {
      connectivity.invalidateServerCache();
      if (await _canSync()) {
        final result = await syncPending();
        if (result.hasWork) {
          debugPrint('Auto-sync: ${result.synced} synced, ${result.failed} failed');
        }
      }
    });

    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (await _canSync()) {
        final result = await syncPending();
        if (result.hasWork) {
          debugPrint('Poll-sync: ${result.synced} synced, ${result.failed} failed');
        }
      }
    });

    Future.microtask(() async {
      if (await _canSync()) {
        await syncPending();
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _pollTimer?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});