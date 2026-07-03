import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../models/table_request_models.dart';

class TableRequestsRepository {
  TableRequestsRepository(this._dio);

  final Dio _dio;

  Future<({List<TableServiceRequestModel> items, int lastPage})> list({
    int? outletId,
    String? status,
    int page = 1,
  }) async {
    final result = await _dio.getPaginatedApi<TableServiceRequestModel>(
      ApiPaths.tableServiceRequests,
      queryParameters: {
        if (outletId != null) 'outlet_id': outletId,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'per_page': 20,
      },
      itemParser: TableServiceRequestModel.fromJson,
    );
    return (items: result.items, lastPage: result.meta.lastPage);
  }

  Future<void> acknowledge(String uuid) async {
    await _dio.patchApi(ApiPaths.tableServiceRequestAcknowledge(uuid));
  }
}

final tableRequestsRepositoryProvider = Provider<TableRequestsRepository>((ref) {
  return TableRequestsRepository(ref.watch(dioProvider));
});