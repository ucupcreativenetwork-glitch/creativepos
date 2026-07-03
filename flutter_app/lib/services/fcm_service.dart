import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_messenger.dart';
import '../core/router/app_router.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/providers/notifications_providers.dart';
import '../features/settings/providers/feature_providers.dart';

final fcmServiceProvider = Provider<FcmService>((ref) => FcmService(ref));

class FcmService {
  FcmService(this._ref);

  final Ref _ref;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedMessage);

      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      messaging.onTokenRefresh.listen(_registerToken);
      _initialized = true;
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }
  }

  Future<void> registerIfAuthenticated() async {
    if (!_initialized) {
      await initialize();
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _registerToken(token);
      }
    } catch (_) {}
  }

  void _onForegroundMessage(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi baru';
    final body = message.notification?.body;
    showAppSnackBar(
      body != null ? '$title\n$body' : title,
      action: SnackBarAction(
        label: 'Lihat',
        onPressed: () => _navigateFromMessage(message),
      ),
    );
    _ref.invalidate(notificationsListProvider);
    _ref.invalidate(unreadNotificationsProvider);
  }

  void _onOpenedMessage(RemoteMessage message) {
    _navigateFromMessage(message);
  }

  void _navigateFromMessage(RemoteMessage message) {
    try {
      final router = _ref.read(appRouterProvider);
      final type = message.data['type'] as String?;
      switch (type) {
        case 'delivery':
          router.push(operationsPath('delivery'));
        case 'crm':
        case 'ticket':
          router.push(operationsPath('crm'));
        case 'table_service':
          router.go('/members');
        default:
          router.push(operationsPath('notifications'));
      }
    } catch (e) {
      debugPrint('FCM navigation failed: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      String? fingerprint;
      String platform = 'unknown';

      if (!kIsWeb && Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        fingerprint = info.id;
        platform = 'android';
      }

      await _ref.read(notificationsRepositoryProvider).registerFcmToken(
            token: token,
            fingerprint: fingerprint,
            platform: platform,
          );
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }
}