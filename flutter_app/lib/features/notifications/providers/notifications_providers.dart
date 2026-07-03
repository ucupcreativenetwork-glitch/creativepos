import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_repository.dart';
import '../models/notification_models.dart';

final notificationsListProvider =
    FutureProvider.autoDispose<List<AppNotificationModel>>((ref) async {
  final result = await ref.watch(notificationsRepositoryProvider).list();
  return result.items;
});

final unreadNotificationsProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(notificationsRepositoryProvider).unreadCount();
});