import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../features/auth/models/user_model.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/standalone/data/local_inventory_repository.dart';
import 'offline_cache_service.dart';

class StandaloneProfile {
  const StandaloneProfile({
    required this.businessName,
    required this.ownerName,
    this.currency = 'IDR',
    this.createdAt,
  });

  final String businessName;
  final String ownerName;
  final String currency;
  final String? createdAt;

  factory StandaloneProfile.fromJson(Map<String, dynamic> json) {
    return StandaloneProfile(
      businessName: json['business_name'] as String? ?? 'Toko Saya',
      ownerName: json['owner_name'] as String? ?? 'Kasir',
      currency: json['currency'] as String? ?? 'IDR',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'business_name': businessName,
        'owner_name': ownerName,
        'currency': currency,
        'created_at': createdAt,
      };
}

class StandaloneService {
  StandaloneService({
    Box? box,
    LocalInventoryRepository? inventory,
    OfflineCacheService? cache,
  })  : _box = box,
        _inventory = inventory ?? LocalInventoryRepository(),
        _cache = cache;

  Box? _box;
  final LocalInventoryRepository _inventory;
  final OfflineCacheService? _cache;

  static const _boxName = 'standalone_config';
  static const _enabledKey = 'standalone_enabled';
  static const _profileKey = 'standalone_profile';

  Future<Box> _open() async {
    _box ??= await Hive.openBox(_boxName);
    return _box!;
  }

  Future<bool> isEnabled() async {
    final box = await _open();
    return box.get(_enabledKey) == true;
  }

  Future<StandaloneProfile?> getProfile() async {
    final box = await _open();
    final raw = box.get(_profileKey);
    if (raw == null) return null;
    try {
      return StandaloneProfile.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateProfile(StandaloneProfile profile) async {
    final box = await _open();
    final current = await getProfile();
    final updated = StandaloneProfile(
      businessName: profile.businessName.trim(),
      ownerName: profile.ownerName.trim(),
      currency: profile.currency,
      createdAt: current?.createdAt ?? DateTime.now().toIso8601String(),
    );
    await box.put(_profileKey, jsonEncode(updated.toJson()));
    await _bootstrapLocalData(updated);
  }

  Future<void> enableStandalone(StandaloneProfile profile) async {
    final box = await _open();
    final enriched = StandaloneProfile(
      businessName: profile.businessName.trim(),
      ownerName: profile.ownerName.trim(),
      currency: profile.currency,
      createdAt: DateTime.now().toIso8601String(),
    );

    await box.put(_enabledKey, true);
    await box.put(_profileKey, jsonEncode(enriched.toJson()));

    await _bootstrapLocalData(enriched);
  }

  Future<void> disableStandalone() async {
    final box = await _open();
    await box.delete(_enabledKey);
    await box.delete(_profileKey);
  }

  AuthSession buildSession(StandaloneProfile profile) {
    const localUserId = -1;
    const localTenantId = -1;

    return AuthSession(
      token: 'standalone-local-token',
      user: UserModel(
        id: localUserId,
        uuid: const Uuid().v4(),
        name: profile.ownerName,
        email: 'standalone@local',
        roles: const ['owner', 'cashier'],
      ),
      tenant: TenantModel(
        id: localTenantId,
        name: profile.businessName,
        slug: 'standalone',
        currency: profile.currency,
      ),
      permissions: const [
        'pos.access',
        'inventory.access',
        'settings.access',
      ],
    );
  }

  List<Map<String, dynamic>> defaultOutlets(StandaloneProfile profile) {
    return [
      {
        'id': 1,
        'uuid': 'local-outlet-1',
        'name': profile.businessName,
        'code': 'MAIN',
        'is_active': true,
      },
    ];
  }

  Future<void> _bootstrapLocalData(StandaloneProfile profile) async {
    final cache = _cache;
    if (cache == null) return;

    await cache.saveOutlets(defaultOutlets(profile));
    await cache.saveTenantSettings(
      TenantSettings(businessName: profile.businessName),
    );
    await _inventory.syncCatalogToCache(cache: cache);

    final session = buildSession(profile);
    await cache.saveSession(session);
  }

  Future<void> refreshPosCatalog() async {
    final cache = _cache;
    if (cache == null) return;
    await _inventory.syncCatalogToCache(cache: cache);
  }
}