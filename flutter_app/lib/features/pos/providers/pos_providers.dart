import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_cache_service.dart';
import '../../standalone/providers/standalone_providers.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';

Future<bool> _serverReachable(Ref ref) async {
  final server = ref.read(serverUrlProvider);
  if (server == null || server.isEmpty) return false;
  return ref
      .read(connectivityServiceProvider)
      .isServerReachable(ref.read(apiBaseUrlProvider));
}

final posCatalogProvider = FutureProvider.autoDispose
    .family<PosCatalogData, PosCatalogQuery>((ref, query) async {
  final cache = ref.watch(offlineCacheServiceProvider);

  if (ref.read(authControllerProvider).status == AuthStatus.standalone) {
    await ref.read(standaloneServiceProvider).refreshPosCatalog();
    final cached = await cache.loadCatalog();
    if (cached != null) {
      return _filterCatalog(cached, query);
    }
    return const PosCatalogData(
      products: [],
      categories: [],
      paymentMethods: [
        PaymentMethod(id: 1, code: 'cash', name: 'Tunai', type: 'cash'),
      ],
    );
  }

  final repo = ref.watch(posRepositoryProvider);
  final serverUp = await _serverReachable(ref);

  if (serverUp) {
    try {
      final results = await Future.wait([
        repo.getProducts(search: query.search, categoryId: query.categoryId),
        repo.getCategories(),
        repo.getPaymentMethods(),
      ]);
      final products = results[0] as List<PosProduct>;
      final categories = results[1] as List<PosCategory>;
      final methods = results[2] as List<PaymentMethod>;

      if ((query.search == null || query.search!.isEmpty) &&
          query.categoryId == null) {
        await cache.saveCatalog(
          products: products,
          categories: categories,
          methods: methods,
        );
      }

      return PosCatalogData(
        products: products,
        categories: categories,
        paymentMethods: methods,
      );
    } catch (_) {
      final cached = await cache.loadCatalog();
      if (cached != null) {
        return _filterCatalog(cached, query);
      }
      rethrow;
    }
  }

  final cached = await cache.loadCatalog();
  if (cached != null) {
    return _filterCatalog(cached, query);
  }

  throw Exception(
    'Mode lokal: buka POS sekali saat server terhubung untuk mengunduh katalog produk.',
  );
});

PosCatalogData _filterCatalog(
  ({
    List<PosProduct> products,
    List<PosCategory> categories,
    List<PaymentMethod> paymentMethods,
  }) cached,
  PosCatalogQuery query,
) {
  var products = cached.products;
  if (query.categoryId != null) {
    products = products
        .where((p) => p.category?.id == query.categoryId)
        .toList();
  }
  final search = query.search?.trim().toLowerCase() ?? '';
  if (search.isNotEmpty) {
    products = products
        .where(
          (p) =>
              p.name.toLowerCase().contains(search) ||
              p.sku.toLowerCase().contains(search) ||
              (p.barcode?.toLowerCase().contains(search) ?? false),
        )
        .toList();
  }
  return PosCatalogData(
    products: products,
    categories: cached.categories,
    paymentMethods: cached.paymentMethods,
  );
}

class PosCatalogQuery {
  const PosCatalogQuery({this.search, this.categoryId});

  final String? search;
  final int? categoryId;

  @override
  bool operator ==(Object other) =>
      other is PosCatalogQuery &&
      other.search == search &&
      other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(search, categoryId);
}

class PosCatalogData {
  const PosCatalogData({
    required this.products,
    required this.categories,
    required this.paymentMethods,
  });

  final List<PosProduct> products;
  final List<PosCategory> categories;
  final List<PaymentMethod> paymentMethods;
}

final currentShiftProvider =
    FutureProvider.autoDispose.family<Shift?, int?>((ref, outletId) async {
  if (outletId == null) return null;

  final cache = ref.watch(offlineCacheServiceProvider);
  final serverUp = await _serverReachable(ref);

  if (serverUp) {
    try {
      final shift =
          await ref.watch(posRepositoryProvider).getCurrentShift(outletId: outletId);
      if (shift != null) {
        await cache.saveShift(outletId, shift);
      } else {
        await cache.clearShift(outletId);
      }
      return shift;
    } catch (_) {
      return cache.loadShift(outletId);
    }
  }

  return cache.loadShift(outletId);
});

final heldBillsProvider =
    FutureProvider.autoDispose.family<List<HeldBill>, int?>((ref, outletId) async {
  if (!await _serverReachable(ref)) return [];
  return ref.watch(posRepositoryProvider).getHeldBills(outletId: outletId);
});

final settingsOutletsProvider = FutureProvider.autoDispose((ref) async {
  if (ref.read(authControllerProvider).status == AuthStatus.standalone) {
    final profile = await ref.read(standaloneServiceProvider).getProfile();
    if (profile != null) {
      return ref.read(standaloneServiceProvider).defaultOutlets(profile);
    }
    return [
      {'id': 1, 'uuid': 'local-outlet-1', 'name': 'Toko Utama', 'is_active': true},
    ];
  }

  final dio = ref.watch(dioProvider);
  final cache = ref.watch(offlineCacheServiceProvider);
  final serverUp = await _serverReachable(ref);

  if (serverUp) {
    try {
      final response = await dio.getApi<List<Map<String, dynamic>>>(
        '/settings/outlets',
        parser: (data) => (data as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );
      final outlets = response.data ?? [];
      if (outlets.isNotEmpty) {
        await cache.saveOutlets(outlets);
      }
      return outlets;
    } catch (_) {
      final cached = await cache.loadOutlets();
      if (cached != null) return cached;
      rethrow;
    }
  }

  final cached = await cache.loadOutlets();
  if (cached != null) return cached;
  return [];
});