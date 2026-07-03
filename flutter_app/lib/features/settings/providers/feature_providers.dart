import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';

class TenantFeatures {
  const TenantFeatures({
    this.hasLoyalty = true,
    this.hasWallet = false,
    this.hasDelivery = false,
    this.hasReservation = false,
    this.hasCrm = false,
    this.hasQrMenu = true,
    this.packageName,
  });

  final bool hasLoyalty;
  final bool hasWallet;
  final bool hasDelivery;
  final bool hasReservation;
  final bool hasCrm;
  final bool hasQrMenu;
  final String? packageName;

  static TenantFeatures from(TenantSettings settings, SubscriptionInfo? sub) {
    final pkg = sub?.packageFeatures ?? const <String, String>{};
    bool pkgHas(String key) => pkg.containsKey(key);

    return TenantFeatures(
      hasLoyalty: pkgHas('loyalty'),
      hasWallet: pkgHas('wallet'),
      hasDelivery: pkgHas('delivery') && settings.featureDelivery,
      hasReservation: pkgHas('reservation') && settings.featureReservations,
      hasCrm: pkgHas('crm'),
      hasQrMenu: settings.featureQrMenu,
      packageName: sub?.packageName,
    );
  }
}

final tenantFeaturesProvider =
    FutureProvider.autoDispose<TenantFeatures>((ref) async {
  final settings = await ref.watch(tenantSettingsProvider.future);
  SubscriptionInfo? subscription;
  try {
    subscription =
        await ref.watch(settingsRepositoryProvider).getSubscription();
  } catch (_) {}
  return TenantFeatures.from(settings, subscription);
});

/// Resolves operations hub tab index from a stable tab key.
int resolveOperationsTab(TenantFeatures f, String key) {
  var index = 0;
  if (key == 'delivery') return f.hasDelivery ? 0 : -1;
  if (f.hasDelivery) index++;
  if (key == 'crm') return f.hasCrm ? index : -1;
  if (f.hasCrm) index++;
  if (key == 'notifications') return index;
  return 0;
}

String operationsPath(String tabKey) => '/operations?tab=$tabKey';