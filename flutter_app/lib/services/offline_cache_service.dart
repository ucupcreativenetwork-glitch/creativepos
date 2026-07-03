import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../features/auth/models/user_model.dart';
import '../features/pos/models/pos_models.dart';
import '../features/settings/data/settings_repository.dart';
import '../local_database/offline_queue.dart';

class OfflineCacheService {
  OfflineCacheService({Box? box}) : _box = box;

  Box? _box;

  Future<Box> _open() async {
    _box ??= await Hive.openBox(OfflineQueue.hiveBoxName);
    return _box!;
  }

  static const _sessionKey = 'cached_session';
  static const _catalogKey = 'cached_pos_catalog';
  static const _settingsKey = 'cached_tenant_settings';
  static const _outletsKey = 'cached_outlets';
  static const _shiftKeyPrefix = 'cached_shift_';
  static const _shiftCloseQueueKey = 'pending_shift_closes';

  Future<void> saveSession(AuthSession session) async {
    final box = await _open();
    await box.put(_sessionKey, jsonEncode({
      'token': session.token,
      'user': {
        'id': session.user.id,
        'uuid': session.user.uuid,
        'name': session.user.name,
        'email': session.user.email,
        'phone': session.user.phone,
        'avatar_url': session.user.avatarUrl,
        'status': session.user.status,
        'roles': session.user.roles,
      },
      if (session.tenant != null)
        'tenant': {
          'id': session.tenant!.id,
          'name': session.tenant!.name,
          'slug': session.tenant!.slug,
          'currency': session.tenant!.currency,
          'timezone': session.tenant!.timezone,
        },
      'permissions': session.permissions,
      'cached_at': DateTime.now().toIso8601String(),
    }));
  }

  Future<AuthSession?> loadSession() async {
    final box = await _open();
    final raw = box.get(_sessionKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final token = map['token'] as String?;
      if (token == null || token.isEmpty) return null;
      return AuthSession(
        token: token,
        user: UserModel.fromJson(map['user'] as Map<String, dynamic>),
        tenant: map['tenant'] != null
            ? TenantModel.fromJson(map['tenant'] as Map<String, dynamic>)
            : null,
        permissions: (map['permissions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    final box = await _open();
    await box.delete(_sessionKey);
  }

  Future<void> saveCatalog({
    required List<PosProduct> products,
    required List<PosCategory> categories,
    required List<PaymentMethod> methods,
  }) async {
    final box = await _open();
    await box.put(_catalogKey, jsonEncode({
      'products': products.map(_productToJson).toList(),
      'categories': categories
          .map((c) => {'id': c.id, 'uuid': c.uuid, 'name': c.name})
          .toList(),
      'payment_methods': methods.map(_paymentMethodToJson).toList(),
      'cached_at': DateTime.now().toIso8601String(),
    }));
  }

  Future<
      ({
        List<PosProduct> products,
        List<PosCategory> categories,
        List<PaymentMethod> paymentMethods,
      })?> loadCatalog() async {
    final box = await _open();
    final raw = box.get(_catalogKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final products = (map['products'] as List<dynamic>)
          .map((e) => PosProduct.fromJson(e as Map<String, dynamic>))
          .toList();
      final categories = (map['categories'] as List<dynamic>)
          .map((e) => PosCategory.fromJson(e as Map<String, dynamic>))
          .toList();
      final methods = (map['payment_methods'] as List<dynamic>)
          .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        products: products,
        categories: categories,
        paymentMethods: methods,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTenantSettings(TenantSettings settings) async {
    final box = await _open();
    await box.put(_settingsKey, jsonEncode({
      ...settings.toMap(),
      'cached_at': DateTime.now().toIso8601String(),
    }));
  }

  Future<TenantSettings?> loadTenantSettings() async {
    final box = await _open();
    final raw = box.get(_settingsKey);
    if (raw == null) return null;
    try {
      return TenantSettings.fromJson(
        jsonDecode(raw as String) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOutlets(List<Map<String, dynamic>> outlets) async {
    final box = await _open();
    await box.put(_outletsKey, jsonEncode(outlets));
  }

  Future<List<Map<String, dynamic>>?> loadOutlets() async {
    final box = await _open();
    final raw = box.get(_outletsKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw as String) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveShift(int outletId, Shift shift) async {
    final box = await _open();
    await box.put('$_shiftKeyPrefix$outletId', jsonEncode(_shiftToJson(shift)));
  }

  Future<Shift?> loadShift(int outletId) async {
    final box = await _open();
    final raw = box.get('$_shiftKeyPrefix$outletId');
    if (raw == null) return null;
    try {
      return Shift.fromJson(jsonDecode(raw as String) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearShift(int outletId) async {
    final box = await _open();
    await box.delete('$_shiftKeyPrefix$outletId');
  }

  Future<void> recordOfflineSale({
    required int outletId,
    required double amount,
  }) async {
    final shift = await loadShift(outletId);
    if (shift == null || !shift.isOpen) return;
    await saveShift(
      outletId,
      Shift(
        id: shift.id,
        shiftNumber: shift.shiftNumber,
        status: shift.status,
        openingCash: shift.openingCash,
        totalSales: shift.totalSales + amount,
        totalTransactions: shift.totalTransactions + 1,
        outlet: shift.outlet,
      ),
    );
  }

  Future<void> enqueueShiftClose({
    required int outletId,
    required int shiftId,
    required String shiftNumber,
    required double closingCash,
    String? notes,
  }) async {
    final box = await _open();
    final raw = box.get(_shiftCloseQueueKey);
    final list = <Map<String, dynamic>>[];
    if (raw != null) {
      try {
        list.addAll(
          (jsonDecode(raw as String) as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      } catch (_) {}
    }
    list.removeWhere((e) => e['outlet_id'] == outletId);
    list.add({
      'outlet_id': outletId,
      'shift_id': shiftId,
      'shift_number': shiftNumber,
      'closing_cash': closingCash,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
    await box.put(_shiftCloseQueueKey, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> listPendingShiftCloses() async {
    final box = await _open();
    final raw = box.get(_shiftCloseQueueKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw as String) as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> removeShiftClose(int outletId) async {
    final box = await _open();
    final pending = await listPendingShiftCloses();
    final filtered =
        pending.where((e) => e['outlet_id'] != outletId).toList();
    if (filtered.isEmpty) {
      await box.delete(_shiftCloseQueueKey);
    } else {
      await box.put(_shiftCloseQueueKey, jsonEncode(filtered));
    }
  }

  Future<PosProduct?> findProductByBarcode(String code) async {
    final cached = await loadCatalog();
    if (cached == null) return null;
    final normalized = code.trim().toLowerCase();
    for (final product in cached.products) {
      final barcode = product.barcode?.trim().toLowerCase();
      if (barcode != null && barcode == normalized) return product;
      if (product.sku.trim().toLowerCase() == normalized) return product;
    }
    return null;
  }

  Map<String, dynamic> _shiftToJson(Shift shift) => {
        'id': shift.id,
        'shift_number': shift.shiftNumber,
        'status': shift.status,
        'opening_cash': shift.openingCash,
        'total_sales': shift.totalSales,
        'total_transactions': shift.totalTransactions,
        if (shift.outlet != null) 'outlet': shift.outlet,
      };

  Map<String, dynamic> _productToJson(PosProduct p) => {
        'id': p.id,
        'uuid': p.uuid,
        'name': p.name,
        'sku': p.sku,
        'barcode': p.barcode,
        'image_url': p.imageUrl,
        'base_price': p.basePrice,
        'total_stock': p.totalStock,
        'track_stock': p.trackStock,
        if (p.category != null)
          'category': {'id': p.category!.id, 'name': p.category!.name},
        'modifier_groups': p.modifierGroups
            .map(
              (g) => {
                'id': g.id,
                'name': g.name,
                'is_required': g.isRequired,
                'min_select': g.minSelect,
                'max_select': g.maxSelect,
                'modifiers': g.modifiers
                    .map(
                      (m) => {
                        'id': m.id,
                        'name': m.name,
                        'price_adjustment': m.priceAdjustment,
                        'is_default': m.isDefault,
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      };

  Map<String, dynamic> _paymentMethodToJson(PaymentMethod m) => {
        'id': m.id,
        'name': m.name,
        'code': m.code,
        'type': m.type,
      };
}

final offlineCacheServiceProvider = Provider<OfflineCacheService>((ref) {
  return OfflineCacheService();
});