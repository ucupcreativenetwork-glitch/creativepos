import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/public_dio_client.dart';
import '../models/qr_menu_models.dart';

class PublicMenuRepository {
  PublicMenuRepository(this._dio);

  final Dio _dio;

  Future<PublicMenuData> getMenu({
    required String tenantSlug,
    required String outletSlug,
  }) async {
    final response = await _dio.getApi<PublicMenuData>(
      ApiPaths.publicMenu(tenantSlug, outletSlug),
      parser: (data) => PublicMenuData.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<PublicMenuData> getTableMenu({
    required String tenantSlug,
    required String outletSlug,
    required String tableToken,
  }) async {
    final response = await _dio.getApi<PublicMenuData>(
      ApiPaths.publicMenuTable(tenantSlug, outletSlug, tableToken),
      parser: (data) => PublicMenuData.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<PublicOrderResult> submitOrder(Map<String, dynamic> payload) async {
    final response = await _dio.postApi<PublicOrderResult>(
      ApiPaths.publicOrders,
      data: payload,
      parser: (data) => PublicOrderResult.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<PublicOrderTrack> trackOrder(String uuid) async {
    final response = await _dio.getApi<PublicOrderTrack>(
      ApiPaths.publicOrderTrack(uuid),
      parser: (data) => PublicOrderTrack.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> callWaiter({
    required String tenantSlug,
    required String outletSlug,
    required String tableToken,
  }) async {
    await _dio.postApi(
      ApiPaths.publicCallWaiter,
      data: {
        'tenant_slug': tenantSlug,
        'outlet_slug': outletSlug,
        'table_token': tableToken,
      },
    );
  }

  Future<void> requestBill({
    required String tenantSlug,
    required String outletSlug,
    required String tableToken,
  }) async {
    await _dio.postApi(
      ApiPaths.publicRequestBill,
      data: {
        'tenant_slug': tenantSlug,
        'outlet_slug': outletSlug,
        'table_token': tableToken,
      },
    );
  }
}

final publicMenuRepositoryProvider = Provider<PublicMenuRepository>((ref) {
  return PublicMenuRepository(ref.watch(publicDioProvider));
});