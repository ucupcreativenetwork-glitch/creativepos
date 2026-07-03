import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/notification_models.dart';

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<
      ({
        List<AppNotificationModel> items,
        int unreadCount,
        PaginationMeta meta,
      })> list({
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.notifications,
      queryParameters: {'page': page, 'per_page': 20},
    );
    final parsed = ApiResponse.fromJson(
      response.data ?? {},
      (data) => (data as List<dynamic>)
          .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (parsed.success == false && parsed.message.isNotEmpty) {
      throw ServerException(parsed.message);
    }
    final unread = parsed.meta?['unread_count'] as int? ?? 0;
    return (
      items: parsed.data ?? [],
      unreadCount: unread,
      meta: PaginationMeta.fromJson(parsed.meta ?? {}),
    );
  }

  Future<int> unreadCount() async {
    final response = await _dio.getApi<Map<String, dynamic>>(
      ApiPaths.notificationsUnread,
      parser: (data) => data as Map<String, dynamic>,
    );
    return response.data?['count'] as int? ?? 0;
  }

  Future<void> markRead(int id) async {
    await _dio.patchApi('${ApiPaths.notifications}/$id/read');
  }

  Future<int> markAllRead() async {
    final response = await _dio.postApi<Map<String, dynamic>>(
      ApiPaths.notificationsReadAll,
      parser: (data) => data as Map<String, dynamic>,
    );
    return response.data?['updated'] as int? ?? 0;
  }

  Future<void> registerFcmToken({
    required String token,
    String? deviceName,
    String? fingerprint,
    String platform = 'android',
  }) async {
    await _dio.postApi(
      ApiPaths.fcmToken,
      data: {
        'fcm_token': token,
        'device_name': deviceName ?? 'CreativePOS Mobile',
        'platform': platform,
        if (fingerprint != null) 'fingerprint': fingerprint,
      },
    );
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(dioProvider));
});