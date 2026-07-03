import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/pos_models.dart';

class PosRepository {
  PosRepository(this._dio);

  final Dio _dio;

  Future<List<PosProduct>> getProducts({
    String? search,
    int? categoryId,
  }) async {
    final response = await _dio.getApi<List<PosProduct>>(
      ApiPaths.posCatalogProducts,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (categoryId != null) 'category_id': categoryId,
      },
      parser: (data) => (data as List<dynamic>)
          .map((e) => PosProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<PosCategory>> getCategories() async {
    final response = await _dio.getApi<List<PosCategory>>(
      ApiPaths.posCatalogCategories,
      parser: (data) => (data as List<dynamic>)
          .map((e) => PosCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _dio.getApi<List<PaymentMethod>>(
      ApiPaths.posPaymentMethods,
      parser: (data) => (data as List<dynamic>)
          .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<Shift?> getCurrentShift({int? outletId}) async {
    final response = await _dio.getApi<Shift?>(
      ApiPaths.posShiftCurrent,
      queryParameters: outletId != null ? {'outlet_id': outletId} : null,
      parser: (data) =>
          data == null ? null : Shift.fromJson(data as Map<String, dynamic>),
    );
    return response.data;
  }

  Future<Shift> openShift({
    required int outletId,
    required double openingCash,
  }) async {
    final response = await _dio.postApi<Shift>(
      ApiPaths.posShiftOpen,
      data: {'outlet_id': outletId, 'opening_cash': openingCash},
      parser: (data) => Shift.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<Shift> closeShift({
    required int shiftId,
    required double closingCash,
    String? notes,
  }) async {
    final response = await _dio.postApi<Shift>(
      '${ApiPaths.posShiftClose}/$shiftId/close',
      data: {
        'closing_cash': closingCash,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
      parser: (data) => Shift.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<({List<TransactionListItem> items, PaginationMeta meta})>
      listTransactions({
    int? outletId,
    String? search,
    int page = 1,
  }) async {
    return _dio.getPaginatedApi<TransactionListItem>(
      ApiPaths.posTransactions,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': 30,
      },
      itemParser: TransactionListItem.fromJson,
    );
  }

  Future<PosTransaction> createTransaction({
    required Map<String, dynamic> payload,
    required String idempotencyKey,
  }) async {
    final response = await _dio.postApi<PosTransaction>(
      ApiPaths.posTransactions,
      data: payload,
      headers: {'X-Idempotency-Key': idempotencyKey},
      parser: (data) => PosTransaction.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> voidTransaction(String uuid, {String? reason}) async {
    await _dio.postApi(
      '${ApiPaths.posTransactions}/$uuid/void',
      data: {if (reason != null) 'reason': reason},
    );
  }

  Future<List<HeldBill>> getHeldBills({int? outletId}) async {
    final response = await _dio.getApi<List<HeldBill>>(
      ApiPaths.posHeld,
      queryParameters: outletId != null ? {'outlet_id': outletId} : null,
      parser: (data) => (data as List<dynamic>)
          .map((e) => HeldBill.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<HeldBill> holdBill(Map<String, dynamic> payload) async {
    final response = await _dio.postApi<HeldBill>(
      ApiPaths.posHeld,
      data: payload,
      parser: (data) => HeldBill.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<HeldBillResume> resumeHeldBill(int id) async {
    final response = await _dio.postApi<HeldBillResume>(
      '${ApiPaths.posHeld}/$id/resume',
      parser: (data) => HeldBillResume.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> deleteHeldBill(int id) async {
    await _dio.deleteApi('${ApiPaths.posHeld}/$id');
  }

  Future<Map<String, dynamic>> getShiftReport(int shiftId) async {
    final response = await _dio.getApi<Map<String, dynamic>>(
      '${ApiPaths.posShiftClose}/$shiftId/report',
      parser: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getReceipt(String uuid) async {
    final response = await _dio.getApi<Map<String, dynamic>>(
      '${ApiPaths.posTransactions}/$uuid/receipt',
      parser: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? {};
  }

  Future<PosProduct?> findProductByBarcode(String code) async {
    final response = await _dio.getApi<PosProduct>(
      '${ApiPaths.inventoryProductBarcode}/$code',
      parser: (data) => PosProduct.fromJson(data as Map<String, dynamic>),
    );
    return response.data;
  }
}

final posRepositoryProvider = Provider<PosRepository>((ref) {
  return PosRepository(ref.watch(dioProvider));
});