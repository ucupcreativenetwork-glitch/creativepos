import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/reservation_models.dart';

class ReservationsRepository {
  ReservationsRepository(this._dio);

  final Dio _dio;

  Future<({List<ReservationModel> items, PaginationMeta meta})> listReservations({
    int? outletId,
    String? status,
    String? date,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.reservations,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        if (status != null && status.isNotEmpty) 'status': status,
        if (date != null && date.isNotEmpty) 'date': date,
        'page': page,
        'per_page': 20,
      },
    );
    final parsed = ApiResponse.fromJson(
      response.data ?? {},
      (data) => (data as List<dynamic>)
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
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

  Future<ReservationModel> getReservation(String uuid) async {
    final response = await _dio.getApi<ReservationModel>(
      '${ApiPaths.reservations}/$uuid',
      parser: (data) =>
          ReservationModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<ReservationModel> createReservation(Map<String, dynamic> payload) async {
    final response = await _dio.postApi<ReservationModel>(
      ApiPaths.reservations,
      data: payload,
      parser: (data) =>
          ReservationModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<ReservationModel> updateReservation(
    String uuid,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.putApi<ReservationModel>(
      '${ApiPaths.reservations}/$uuid',
      data: payload,
      parser: (data) =>
          ReservationModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<ReservationModel> updateStatus(
    String uuid, {
    required String status,
    String? notes,
  }) async {
    final response = await _dio.patchApi<ReservationModel>(
      '${ApiPaths.reservations}/$uuid/status',
      data: {
        'status': status,
        if (notes != null) 'notes': notes,
      },
      parser: (data) =>
          ReservationModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<List<ReservationSlot>> getSlots({
    required int outletId,
    required String date,
  }) async {
    final response = await _dio.getApi<List<ReservationSlot>>(
      ApiPaths.reservationSlots,
      queryParameters: {'outlet_id': outletId, 'date': date},
      parser: (data) => (data as List<dynamic>)
          .map((e) => ReservationSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }
}

final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  return ReservationsRepository(ref.watch(dioProvider));
});