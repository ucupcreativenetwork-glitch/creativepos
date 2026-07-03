import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';

final remoteAgentRepositoryProvider = Provider<RemoteAgentRepository>((ref) {
  return RemoteAgentRepository(ref.watch(dioProvider));
});

class RemoteAgentRepository {
  RemoteAgentRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final response = await _dio.post('/remote/register', data: payload);
    return Map<String, dynamic>.from(response.data['data'] as Map);
  }

  Future<void> heartbeat(Map<String, dynamic> payload) async {
    await _dio.post('/remote/heartbeat', data: payload);
  }

  Future<List<Map<String, dynamic>>> pendingCommands(String fingerprint) async {
    final response = await _dio.get(
      '/remote/commands',
      queryParameters: {'fingerprint': fingerprint},
    );
    final data = response.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> completeCommand({
    required int commandId,
    required String fingerprint,
    required String status,
    String? result,
  }) async {
    await _dio.post(
      '/remote/commands/$commandId/complete',
      data: {
        'fingerprint': fingerprint,
        'status': status,
        if (result != null) 'result': result,
      },
    );
  }

  Future<void> uploadDiagnostics({
    required String fingerprint,
    required String type,
    required String content,
    String? title,
    Map<String, dynamic>? metadata,
  }) async {
    await _dio.post(
      '/remote/diagnostics',
      data: {
        'fingerprint': fingerprint,
        'type': type,
        'content': content,
        if (title != null) 'title': title,
        if (metadata != null) 'metadata': metadata,
      },
    );
  }
}