import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../local_database/models/offline_transaction.dart';
import '../../../local_database/offline_queue_repository.dart';
import '../../../services/sync_service.dart';

final offlineQueueListProvider =
    FutureProvider.autoDispose<List<OfflineTransaction>>((ref) async {
  return ref.watch(offlineQueueRepositoryProvider).listAll();
});

final pendingSyncCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(offlineQueueRepositoryProvider).pendingCount();
});

final syncControllerProvider =
    AsyncNotifierProvider<SyncController, SyncResult?>(SyncController.new);

class SyncController extends AsyncNotifier<SyncResult?> {
  @override
  Future<SyncResult?> build() async => null;

  Future<SyncResult> syncNow() async {
    state = const AsyncLoading();
    final result = await ref.read(syncServiceProvider).syncPending();
    ref.invalidate(offlineQueueListProvider);
    ref.invalidate(pendingSyncCountProvider);
    state = AsyncData(result);
    return result;
  }
}