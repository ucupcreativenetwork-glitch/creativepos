import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_cache_service.dart';

class TenantSettings {
  const TenantSettings({
    this.taxRate = 0,
    this.serviceChargeRate = 0,
    this.businessName,
    this.featureReservations = true,
    this.featureDelivery = true,
    this.featureQrMenu = true,
  });

  final double taxRate;
  final double serviceChargeRate;
  final String? businessName;
  final bool featureReservations;
  final bool featureDelivery;
  final bool featureQrMenu;

  factory TenantSettings.fromJson(Map<String, dynamic> json) {
    return TenantSettings(
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0,
      serviceChargeRate: (json['service_charge_rate'] as num?)?.toDouble() ?? 0,
      businessName: json['business_name'] as String?,
      featureReservations: json['feature_reservations'] as bool? ?? true,
      featureDelivery: json['feature_delivery'] as bool? ?? true,
      featureQrMenu: json['feature_qr_menu'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'tax_rate': taxRate,
        'service_charge_rate': serviceChargeRate,
        'business_name': businessName,
        'feature_reservations': featureReservations,
        'feature_delivery': featureDelivery,
        'feature_qr_menu': featureQrMenu,
      };
}

class SubscriptionInfo {
  const SubscriptionInfo({
    this.packageName,
    this.packageFeatures = const {},
  });

  final String? packageName;
  final Map<String, String> packageFeatures;

  factory SubscriptionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubscriptionInfo();
    final pkg = json['package'] as Map<String, dynamic>?;
    final raw = pkg?['features'];
    final features = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) => features[k.toString()] = v.toString());
    }
    return SubscriptionInfo(
      packageName: pkg?['name'] as String?,
      packageFeatures: features,
    );
  }
}

class SettingsRepository {
  SettingsRepository(this._dio);

  final Dio _dio;

  Future<TenantSettings> getTenantSettings({
    OfflineCacheService? cache,
    bool online = true,
  }) async {
    if (online) {
      try {
        final response = await _dio.getApi<TenantSettings>(
          ApiPaths.settingsTenant,
          parser: (data) =>
              TenantSettings.fromJson(data as Map<String, dynamic>),
        );
        final settings = response.data ?? const TenantSettings();
        await cache?.saveTenantSettings(settings);
        return settings;
      } catch (_) {
        final cached = await cache?.loadTenantSettings();
        if (cached != null) return cached;
        rethrow;
      }
    }
    final cached = await cache?.loadTenantSettings();
    return cached ?? const TenantSettings();
  }

  Future<SubscriptionInfo> getSubscription() async {
    final response = await _dio.getApi<SubscriptionInfo>(
      ApiPaths.settingsSubscription,
      parser: (data) =>
          SubscriptionInfo.fromJson(data as Map<String, dynamic>?),
    );
    return response.data ?? const SubscriptionInfo();
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(dioProvider));
});

final tenantSettingsProvider =
    FutureProvider.autoDispose<TenantSettings>((ref) async {
  final server = ref.read(serverUrlProvider);
  final serverUp = server != null &&
      server.isNotEmpty &&
      await ref.read(connectivityServiceProvider).isServerReachable(
            ref.read(apiBaseUrlProvider),
          );
  return ref.watch(settingsRepositoryProvider).getTenantSettings(
        cache: ref.watch(offlineCacheServiceProvider),
        online: serverUp,
      );
});