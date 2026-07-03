import 'package:uuid/uuid.dart';

import '../../../core/utils/json_utils.dart';

class PosCategory {
  const PosCategory({required this.id, required this.uuid, required this.name});

  final int id;
  final String uuid;
  final String name;

  factory PosCategory.fromJson(Map<String, dynamic> json) {
    return PosCategory(
      id: parseJsonInt(json['id']),
      uuid: parseJsonString(json['uuid']),
      name: parseJsonString(json['name']),
    );
  }
}

class ProductModifier {
  const ProductModifier({
    required this.id,
    required this.name,
    required this.priceAdjustment,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final double priceAdjustment;
  final bool isDefault;

  factory ProductModifier.fromJson(Map<String, dynamic> json) {
    return ProductModifier(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      priceAdjustment: parseJsonDouble(json['price_adjustment']),
      isDefault: parseJsonBool(json['is_default']),
    );
  }
}

class ProductModifierGroup {
  const ProductModifierGroup({
    required this.id,
    required this.name,
    required this.isRequired,
    required this.minSelect,
    required this.maxSelect,
    required this.modifiers,
  });

  final int id;
  final String name;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final List<ProductModifier> modifiers;

  factory ProductModifierGroup.fromJson(Map<String, dynamic> json) {
    return ProductModifierGroup(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      isRequired: parseJsonBool(json['is_required']),
      minSelect: parseJsonInt(json['min_select']),
      maxSelect: parseJsonInt(json['max_select'], fallback: 1),
      modifiers: (json['modifiers'] as List<dynamic>? ?? [])
          .map((e) => ProductModifier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PosProduct {
  const PosProduct({
    required this.id,
    required this.uuid,
    required this.name,
    required this.sku,
    required this.basePrice,
    this.barcode,
    this.imageUrl,
    this.category,
    this.totalStock = 0,
    this.trackStock = false,
    this.modifierGroups = const [],
  });

  final int id;
  final String uuid;
  final String name;
  final String sku;
  final String? barcode;
  final String? imageUrl;
  final double basePrice;
  final PosCategory? category;
  final double totalStock;
  final bool trackStock;
  final List<ProductModifierGroup> modifierGroups;

  factory PosProduct.fromJson(Map<String, dynamic> json) {
    return PosProduct(
      id: parseJsonInt(json['id']),
      uuid: parseJsonString(json['uuid']),
      name: parseJsonString(json['name']),
      sku: parseJsonString(json['sku']),
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      basePrice: parseJsonDouble(json['base_price']),
      category: json['category'] != null
          ? PosCategory(
              id: parseJsonInt((json['category'] as Map)['id']),
              uuid: '',
              name: parseJsonString((json['category'] as Map)['name']),
            )
          : null,
      totalStock: parseJsonDouble(json['total_stock']),
      trackStock: parseJsonBool(json['track_stock']),
      modifierGroups: (json['modifier_groups'] as List<dynamic>? ?? [])
          .map((e) => ProductModifierGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
  });

  final int id;
  final String code;
  final String name;
  final String type;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: parseJsonInt(json['id']),
      code: parseJsonString(json['code']),
      name: parseJsonString(json['name']),
      type: parseJsonString(json['type'], fallback: 'cash'),
    );
  }
}

class Shift {
  const Shift({
    required this.id,
    required this.shiftNumber,
    required this.status,
    required this.openingCash,
    this.totalSales = 0,
    this.totalTransactions = 0,
    this.outlet,
  });

  final int id;
  final String shiftNumber;
  final String status;
  final double openingCash;
  final double totalSales;
  final int totalTransactions;
  final Map<String, dynamic>? outlet;

  bool get isOpen => status == 'open';

  /// Shift disimpan lokal saat offline (id <= 0 tidak dikirim ke server).
  bool get isLocalShift => id <= 0;

  int? get serverShiftId => id > 0 ? id : null;

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: parseJsonInt(json['id']),
      shiftNumber: parseJsonString(json['shift_number']),
      status: parseJsonString(json['status'], fallback: 'open'),
      openingCash: parseJsonDouble(json['opening_cash']),
      totalSales: parseJsonDouble(json['total_sales']),
      totalTransactions: parseJsonInt(json['total_transactions']),
      outlet: json['outlet'] as Map<String, dynamic>?,
    );
  }
}

class SelectedModifier {
  const SelectedModifier({
    required this.modifierId,
    required this.groupId,
    required this.groupName,
    required this.name,
    required this.priceAdjustment,
  });

  final int modifierId;
  final int groupId;
  final String groupName;
  final String name;
  final double priceAdjustment;
}

class CartItem {
  CartItem({
    required this.key,
    required this.product,
    required this.quantity,
    required this.modifiers,
    required this.unitPrice,
    this.notes,
  });

  final String key;
  final PosProduct product;
  final double quantity;
  final List<SelectedModifier> modifiers;
  final double unitPrice;
  final String? notes;

  double get subtotal => unitPrice * quantity;

  Map<String, dynamic> toTransactionItem() {
    return {
      'product_id': product.id,
      'quantity': quantity,
      if (modifiers.isNotEmpty)
        'modifiers': modifiers.map((m) => m.modifierId).toList(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}

String buildCartItemKey(int productId, List<SelectedModifier> modifiers) {
  final ids = modifiers.map((m) => m.modifierId).toList()..sort();
  return '$productId:${ids.join(',')}';
}

double calcUnitPrice(double basePrice, List<SelectedModifier> modifiers) {
  return basePrice +
      modifiers.fold<double>(0, (sum, m) => sum + m.priceAdjustment);
}

class TransactionListItem {
  const TransactionListItem({
    required this.id,
    required this.uuid,
    required this.transactionNumber,
    required this.grandTotal,
    required this.status,
    this.outletName,
    this.completedAt,
  });

  final int id;
  final String uuid;
  final String transactionNumber;
  final double grandTotal;
  final String status;
  final String? outletName;
  final DateTime? completedAt;

  factory TransactionListItem.fromJson(Map<String, dynamic> json) {
    final outlet = json['outlet'] as Map<String, dynamic>?;
    return TransactionListItem(
      id: parseJsonInt(json['id']),
      uuid: parseJsonString(json['uuid']),
      transactionNumber: parseJsonString(json['transaction_number']),
      grandTotal: parseJsonDouble(json['grand_total']),
      status: parseJsonString(json['status'], fallback: 'completed'),
      outletName: outlet?['name'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}

class PosTransaction {
  const PosTransaction({
    required this.uuid,
    required this.transactionNumber,
    required this.grandTotal,
    required this.status,
  });

  final String uuid;
  final String transactionNumber;
  final double grandTotal;
  final String status;

  factory PosTransaction.fromJson(Map<String, dynamic> json) {
    return PosTransaction(
      uuid: parseJsonString(json['uuid']),
      transactionNumber: parseJsonString(json['transaction_number']),
      grandTotal: parseJsonDouble(json['grand_total']),
      status: parseJsonString(json['status'], fallback: 'completed'),
    );
  }
}

class HeldBill {
  const HeldBill({
    required this.id,
    required this.referenceName,
    required this.subtotal,
    required this.itemCount,
    this.heldAt,
  });

  final int id;
  final String referenceName;
  final double subtotal;
  final int itemCount;
  final String? heldAt;

  factory HeldBill.fromJson(Map<String, dynamic> json) {
    return HeldBill(
      id: parseJsonInt(json['id']),
      referenceName: parseJsonString(json['reference_name']),
      subtotal: parseJsonDouble(json['subtotal']),
      itemCount: parseJsonInt(json['item_count']),
      heldAt: json['held_at'] as String?,
    );
  }
}

class HeldBillResume {
  const HeldBillResume({
    required this.id,
    required this.referenceName,
    required this.items,
    this.memberId,
  });

  final int id;
  final String referenceName;
  final List<HeldBillItem> items;
  final int? memberId;

  factory HeldBillResume.fromJson(Map<String, dynamic> json) {
    return HeldBillResume(
      id: parseJsonInt(json['id']),
      referenceName: parseJsonString(json['reference_name']),
      memberId: json['member_id'] != null ? parseJsonInt(json['member_id']) : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => HeldBillItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class HeldBillItem {
  const HeldBillItem({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.productName,
    this.sku,
    this.modifiers = const [],
    this.product,
  });

  final int productId;
  final double quantity;
  final double unitPrice;
  final String? productName;
  final String? sku;
  final List<dynamic> modifiers;
  final PosProduct? product;

  factory HeldBillItem.fromJson(Map<String, dynamic> json) {
    return HeldBillItem(
      productId: parseJsonInt(json['product_id']),
      quantity: parseJsonDouble(json['quantity']),
      unitPrice: parseJsonDouble(json['unit_price']),
      productName: json['product_name'] as String?,
      sku: json['sku'] as String?,
      modifiers: json['modifiers'] as List<dynamic>? ?? [],
      product: json['product'] != null
          ? PosProduct.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}

String newIdempotencyKey() => const Uuid().v4();