import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/inventory_repository.dart';

class InventoryQuery {
  const InventoryQuery({this.search, this.page = 1});

  final String? search;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is InventoryQuery && other.search == search && other.page == page;

  @override
  int get hashCode => Object.hash(search, page);
}

final inventoryProductsProvider = FutureProvider.autoDispose
    .family<dynamic, InventoryQuery>((ref, query) async {
  return ref.watch(inventoryRepositoryProvider).getProducts(
        search: query.search,
        page: query.page,
      );
});

final inventoryStocksProvider = FutureProvider.autoDispose
    .family<dynamic, InventoryQuery>((ref, query) async {
  return ref.watch(inventoryRepositoryProvider).getStocks(
        search: query.search,
        page: query.page,
      );
});

final inventoryAlertsProvider =
    FutureProvider.autoDispose((ref) async {
  return ref.watch(inventoryRepositoryProvider).getAlerts();
});