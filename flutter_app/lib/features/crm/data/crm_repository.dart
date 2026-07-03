import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/crm_models.dart';

class CrmRepository {
  CrmRepository(this._dio);

  final Dio _dio;

  Future<({List<SupportTicketModel> items, PaginationMeta meta})> listTickets({
    String? status,
    String? priority,
    String? search,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.crmTickets,
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (priority != null && priority.isNotEmpty) 'priority': priority,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'per_page': 20,
      },
    );
    final parsed = ApiResponse.fromJson(
      response.data ?? {},
      (data) => (data as List<dynamic>)
          .map((e) => SupportTicketModel.fromJson(e as Map<String, dynamic>))
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

  Future<SupportTicketModel> getTicket(String uuid) async {
    final response = await _dio.getApi<SupportTicketModel>(
      '${ApiPaths.crmTickets}/$uuid',
      parser: (data) =>
          SupportTicketModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SupportTicketModel> createTicket(Map<String, dynamic> payload) async {
    final response = await _dio.postApi<SupportTicketModel>(
      ApiPaths.crmTickets,
      data: payload,
      parser: (data) =>
          SupportTicketModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SupportTicketModel> sendMessage(
    String uuid, {
    required String message,
    String senderType = 'agent',
    bool isInternal = false,
  }) async {
    final response = await _dio.postApi<SupportTicketModel>(
      '${ApiPaths.crmTickets}/$uuid/messages',
      data: {
        'message': message,
        'sender_type': senderType,
        'is_internal': isInternal,
      },
      parser: (data) =>
          SupportTicketModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SupportTicketModel> updateStatus(
    String uuid, {
    required String status,
  }) async {
    final response = await _dio.patchApi<SupportTicketModel>(
      '${ApiPaths.crmTickets}/$uuid/status',
      data: {'status': status},
      parser: (data) =>
          SupportTicketModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<SupportTicketModel> assignTicket(
    String uuid, {
    required int assignedTo,
  }) async {
    final response = await _dio.patchApi<SupportTicketModel>(
      '${ApiPaths.crmTickets}/$uuid/assign',
      data: {'assigned_to': assignedTo},
      parser: (data) =>
          SupportTicketModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<List<FaqModel>> getFaqs() async {
    final response = await _dio.getApi<List<FaqModel>>(
      ApiPaths.crmFaqs,
      parser: (data) => (data as List<dynamic>)
          .map((e) => FaqModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }
}

final crmRepositoryProvider = Provider<CrmRepository>((ref) {
  return CrmRepository(ref.watch(dioProvider));
});