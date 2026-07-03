import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  Future<DashboardKpi> getKpi({int? outletId}) async {
    final response = await _dio.getApi<DashboardKpi>(
      ApiPaths.dashboardKpi,
      queryParameters: outletId != null ? {'outlet_id': outletId} : null,
      parser: (data) => DashboardKpi.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<List<SalesChartPoint>> getSalesChart({int? outletId}) async {
    final response = await _dio.getApi<List<SalesChartPoint>>(
      ApiPaths.dashboardSalesChart,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        'period': 'daily',
      },
      parser: (data) => (data as List<dynamic>)
          .map((e) => SalesChartPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<TopProduct>> getTopProducts({int? outletId}) async {
    final response = await _dio.getApi<List<TopProduct>>(
      ApiPaths.dashboardProducts,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        'limit': 5,
      },
      parser: (data) => (data as List<dynamic>)
          .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<LiveFeedItem>> getLiveFeed({int? outletId}) async {
    final response = await _dio.getApi<List<LiveFeedItem>>(
      ApiPaths.dashboardLiveFeed,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        'limit': 8,
      },
      parser: (data) => (data as List<dynamic>)
          .map((e) => LiveFeedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<List<OutletOption>> getOutlets() async {
    final response = await _dio.getApi<List<OutletOption>>(
      ApiPaths.dashboardOutlets,
      parser: (data) => (data as List<dynamic>)
          .map((e) => OutletOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});