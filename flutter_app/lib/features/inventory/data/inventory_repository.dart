import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/inventory_models.dart';

class InventoryRepository {
  InventoryRepository(this._dio);

  final Dio _dio;

  Future<({List<InventoryProduct> items, PaginationMeta meta})> getProducts({
    String? search,
    int? categoryId,
    int page = 1,
  }) async {
    return _dio.getPaginatedApi<InventoryProduct>(
      ApiPaths.inventoryProducts,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
        'page': page,
        'per_page': 20,
      },
      itemParser: InventoryProduct.fromJson,
    );
  }

  Future<InventoryProduct> getProductDetail({
    required int id,
    String? uuid,
  }) async {
    final identifier =
        uuid != null && uuid.isNotEmpty ? uuid : id.toString();

    final response = await _dio.getApi<InventoryProduct>(
      '${ApiPaths.inventoryProducts}/$identifier',
      parser: (data) =>
          InventoryProduct.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<List<InventoryCategory>> getCategories() async {
    final result = await _dio.getPaginatedApi<InventoryCategory>(
      ApiPaths.inventoryCategories,
      queryParameters: {'per_page': 100},
      itemParser: InventoryCategory.fromJson,
    );
    return result.items;
  }

  Future<InventoryProduct> createProduct({
    required String name,
    required String sku,
    required double basePrice,
    String? barcode,
    int? categoryId,
    double? costPrice,
    int minStock = 0,
    bool trackStock = true,
    double initialStock = 0,
  }) async {
    final response = await _dio.postApi<InventoryProduct>(
      ApiPaths.inventoryProducts,
      data: {
        'name': name,
        'sku': sku,
        'base_price': basePrice,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        if (categoryId != null) 'category_id': categoryId,
        if (costPrice != null) 'cost_price': costPrice,
        'min_stock': minStock,
        'track_stock': trackStock,
        'is_active': true,
        'is_available': true,
        'show_in_pos': true,
        if (initialStock > 0) 'initial_stock': initialStock,
      },
      parser: (data) =>
          InventoryProduct.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<InventoryProduct> findByBarcode(String code) async {
    final response = await _dio.getApi<InventoryProduct>(
      '${ApiPaths.inventoryProductBarcode}/$code',
      parser: (data) =>
          InventoryProduct.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<({List<StockRow> items, PaginationMeta meta})> getStocks({
    String? search,
    int page = 1,
  }) async {
    return _dio.getPaginatedApi<StockRow>(
      ApiPaths.inventoryStocks,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': 20,
      },
      itemParser: StockRow.fromJson,
    );
  }

  Future<List<StockAlert>> getAlerts() async {
    final response = await _dio.getApi<List<StockAlert>>(
      ApiPaths.inventoryStockAlerts,
      parser: (data) => (data as List<dynamic>)
          .map((e) => StockAlert.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<Warehouse>> getWarehouses() async {
    final response = await _dio.getApi<List<Warehouse>>(
      ApiPaths.inventoryWarehouses,
      parser: (data) => (data as List<dynamic>)
          .map((e) => Warehouse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<void> stockIn({
    required int productId,
    required int warehouseId,
    required double quantity,
    String? notes,
  }) async {
    await _dio.postApi(
      ApiPaths.inventoryStockIn,
      data: {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> stockOut({
    required int productId,
    required int warehouseId,
    required double quantity,
    String? notes,
  }) async {
    await _dio.postApi(
      ApiPaths.inventoryStockOut,
      data: {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }

  Future<void> adjustStock({
    required int productId,
    required int warehouseId,
    required double quantity,
    String? notes,
  }) async {
    await _dio.postApi(
      ApiPaths.inventoryStockAdjustment,
      data: {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
  }
}

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(ref.watch(dioProvider));
});