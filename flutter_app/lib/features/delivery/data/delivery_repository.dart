import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/delivery_models.dart';

class DeliveryRepository {
  DeliveryRepository(this._dio);

  final Dio _dio;

  Future<({List<DeliveryOrderModel> items, PaginationMeta meta})> listOrders({
    int? outletId,
    String? status,
    int? driverId,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.deliveryOrders,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (driverId != null) 'driver_id': driverId,
        'page': page,
        'per_page': 20,
      },
    );
    final parsed = ApiResponse.fromJson(
      response.data ?? {},
      (data) => (data as List<dynamic>)
          .map((e) => DeliveryOrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (parsed.success == false && parsed.message.isNotEmpty) {
      throw ServerException(parsed.message);
    }
    return (
      items: parsed.data ?? [],
      meta: PaginationMeta.fromJson(parsed.meta ?? {}),
    );
  }

  Future<DeliveryOrderModel> getOrder(String uuid) async {
    final response = await _dio.getApi<DeliveryOrderModel>(
      '${ApiPaths.deliveryOrders}/$uuid',
      parser: (data) =>
          DeliveryOrderModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<DeliveryOrderModel> updateStatus(
    String uuid, {
    required String status,
    String? notes,
  }) async {
    final response = await _dio.patchApi<DeliveryOrderModel>(
      '${ApiPaths.deliveryOrders}/$uuid/status',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
      },
      parser: (data) =>
          DeliveryOrderModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<DeliveryOrderModel> recordLocation(
    String uuid, {
    required double latitude,
    required double longitude,
    int? driverId,
  }) async {
    final response = await _dio.postApi<DeliveryOrderModel>(
      '${ApiPaths.deliveryOrders}/$uuid/location',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (driverId != null) 'driver_id': driverId,
      },
      parser: (data) =>
          DeliveryOrderModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<List<DeliveryDriver>> listDrivers({
    int? outletId,
    bool availableOnly = true,
  }) async {
    final response = await _dio.getApi<List<DeliveryDriver>>(
      ApiPaths.deliveryDrivers,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        if (availableOnly) 'available_only': 1,
      },
      parser: (data) => (data as List<dynamic>)
          .map((e) => DeliveryDriver.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<DeliveryOrderModel> assignDriver(
    String uuid, {
    required int driverId,
  }) async {
    final response = await _dio.postApi<DeliveryOrderModel>(
      ApiPaths.deliveryAssign(uuid),
      data: {'driver_id': driverId},
      parser: (data) =>
          DeliveryOrderModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }
}

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.watch(dioProvider));
});