import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/offline_cache_service.dart';
import '../../../services/standalone_service.dart';
import '../data/local_inventory_repository.dart';
import '../models/local_product.dart';

final localInventoryRepositoryProvider = Provider<LocalInventoryRepository>((ref) {
  return LocalInventoryRepository(
    cache: ref.watch(offlineCacheServiceProvider),
  );
});

final standaloneServiceProvider = Provider<StandaloneService>((ref) {
  return StandaloneService(
    inventory: ref.watch(localInventoryRepositoryProvider),
    cache: ref.watch(offlineCacheServiceProvider),
  );
});

final standaloneModeProvider = FutureProvider<bool>((ref) async {
  return ref.watch(standaloneServiceProvider).isEnabled();
});

final standaloneProfileProvider = FutureProvider<StandaloneProfile?>((ref) async {
  return ref.watch(standaloneServiceProvider).getProfile();
});

final localProductsProvider =
    FutureProvider.autoDispose.family<List<LocalProduct>, String?>((ref, search) async {
  return ref.watch(localInventoryRepositoryProvider).listProducts(search: search);
});

final localInventoryStatsProvider = FutureProvider.autoDispose<LocalInventoryStats>((ref) async {
  return ref.watch(localInventoryRepositoryProvider).getStats();
});