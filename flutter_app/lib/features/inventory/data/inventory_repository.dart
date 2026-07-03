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

  Future<InventoryProduct> getProduct(String uuid) async {
    final response = await _dio.getApi<InventoryProduct>(
      '${ApiPaths.inventoryProducts}/$uuid',
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