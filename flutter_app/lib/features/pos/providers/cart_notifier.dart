import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/json_utils.dart';
import '../models/pos_models.dart';

class CartState {
  const CartState({
    this.items = const [],
    this.notes,
    this.discountType,
    this.discountValue = 0,
    this.memberId,
    this.memberUuid,
    this.memberName,
    this.memberCode,
    this.pointsRedeem,
  });

  final List<CartItem> items;
  final String? notes;
  final String? discountType;
  final double discountValue;
  final int? memberId;
  final String? memberUuid;
  final String? memberName;
  final String? memberCode;
  final int? pointsRedeem;

  double get subtotal => items.fold<double>(0, (sum, i) => sum + i.subtotal);

  int get itemCount =>
      items.fold<int>(0, (sum, i) => sum + i.quantity.round());

  CartState copyWith({
    List<CartItem>? items,
    String? notes,
    String? discountType,
    double? discountValue,
    int? memberId,
    String? memberUuid,
    String? memberName,
    String? memberCode,
    int? pointsRedeem,
    bool clearDiscount = false,
    bool clearMember = false,
    bool clearPointsRedeem = false,
  }) {
    return CartState(
      items: items ?? this.items,
      notes: notes ?? this.notes,
      discountType: clearDiscount ? null : (discountType ?? this.discountType),
      discountValue: clearDiscount ? 0 : (discountValue ?? this.discountValue),
      memberId: clearMember ? null : (memberId ?? this.memberId),
      memberUuid: clearMember ? null : (memberUuid ?? this.memberUuid),
      memberName: clearMember ? null : (memberName ?? this.memberName),
      memberCode: clearMember ? null : (memberCode ?? this.memberCode),
      pointsRedeem:
          clearMember || clearPointsRedeem ? null : (pointsRedeem ?? this.pointsRedeem),
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  bool _wouldExceedStock(PosProduct product, double newQty) {
    return product.trackStock && newQty > product.totalStock;
  }

  void addProduct(
    PosProduct product, {
    List<SelectedModifier> modifiers = const [],
    double quantity = 1,
    String? notes,
  }) {
    final unitPrice = calcUnitPrice(product.basePrice, modifiers);
    final key = buildCartItemKey(product.id, modifiers);
    final existing = state.items.indexWhere((i) => i.key == key);

    if (existing >= 0) {
      final updated = [...state.items];
      final item = updated[existing];
      final newQty = item.quantity + quantity;
      if (_wouldExceedStock(product, newQty)) return;
      updated[existing] = CartItem(
        key: item.key,
        product: item.product,
        quantity: newQty,
        modifiers: item.modifiers,
        unitPrice: item.unitPrice,
        notes: notes ?? item.notes,
      );
      state = state.copyWith(items: updated);
      return;
    }

    if (_wouldExceedStock(product, quantity)) return;

    state = state.copyWith(
      items: [
        ...state.items,
        CartItem(
          key: key,
          product: product,
          quantity: quantity,
          modifiers: modifiers,
          unitPrice: unitPrice,
          notes: notes,
        ),
      ],
    );
  }

  bool updateQuantity(String key, double quantity) {
    if (quantity <= 0) {
      removeItem(key);
      return true;
    }
    final index = state.items.indexWhere((i) => i.key == key);
    if (index < 0) return false;
    final item = state.items[index];
    if (_wouldExceedStock(item.product, quantity)) return false;
    state = state.copyWith(
      items: state.items
          .map(
            (item) => item.key == key
                ? CartItem(
                    key: item.key,
                    product: item.product,
                    quantity: quantity,
                    modifiers: item.modifiers,
                    unitPrice: item.unitPrice,
                    notes: item.notes,
                  )
                : item,
          )
          .toList(),
    );
    return true;
  }

  void removeItem(String key) {
    state = state.copyWith(
      items: state.items.where((i) => i.key != key).toList(),
    );
  }

  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  void setDiscount({String? type, double value = 0}) {
    state = state.copyWith(
      discountType: type,
      discountValue: value,
      clearDiscount: type == null,
    );
  }

  List<SelectedModifier> _parseHeldModifiers(List<dynamic> raw) {
    return raw.map((entry) {
      if (entry is int) {
        return SelectedModifier(
          modifierId: entry,
          groupId: 0,
          groupName: '',
          name: '',
          priceAdjustment: 0,
        );
      }
      final m = entry as Map<String, dynamic>;
      return SelectedModifier(
        modifierId: parseJsonInt(m['modifier_id']),
        groupId: parseJsonInt(m['group_id']),
        groupName: m['group_name'] as String? ?? '',
        name: m['name'] as String? ?? '',
        priceAdjustment: (m['price_adjustment'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  void setMember({
    required int id,
    required String uuid,
    required String name,
    String? code,
  }) {
    state = state.copyWith(
      memberId: id,
      memberUuid: uuid,
      memberName: name,
      memberCode: code,
      clearPointsRedeem: true,
    );
  }

  void clearMember() => state = state.copyWith(clearMember: true);

  void setPointsRedeem(int? points) =>
      state = state.copyWith(pointsRedeem: points, clearPointsRedeem: points == null);

  void loadFromHeld(List<HeldBillItem> heldItems, {int? memberId}) {
    final items = heldItems.map((held) {
      final product = held.product ??
          PosProduct(
            id: held.productId,
            uuid: '',
            name: held.productName ?? 'Produk',
            sku: held.sku ?? '',
            basePrice: held.unitPrice,
          );
      final modifiers = _parseHeldModifiers(held.modifiers);
      return CartItem(
        key: buildCartItemKey(product.id, modifiers),
        product: product,
        quantity: held.quantity,
        modifiers: modifiers,
        unitPrice: held.unitPrice,
      );
    }).toList();
    state = state.copyWith(items: items, memberId: memberId);
  }

  void clear() => state = const CartState();

  Map<String, dynamic> buildCheckoutPayload({
    required int outletId,
    int? shiftId,
    int? memberId,
  }) {
    final payload = <String, dynamic>{
      'outlet_id': outletId,
      if (shiftId != null && shiftId > 0) 'shift_id': shiftId,
      if ((memberId ?? state.memberId) != null)
        'member_id': memberId ?? state.memberId,
      'order_type': 'quick_sale',
      'items': state.items.map((i) => i.toTransactionItem()).toList(),
      if (state.notes != null && state.notes!.isNotEmpty) 'notes': state.notes,
    };

    if (state.discountType != null && state.discountValue > 0) {
      payload['discounts'] = [
        {
          'type': state.discountType,
          'value': state.discountValue,
          'name': 'Diskon',
        },
      ];
    }

    if (state.pointsRedeem != null && state.pointsRedeem! > 0) {
      payload['points_redeem'] = state.pointsRedeem;
    }

    return payload;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());