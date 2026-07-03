import 'package:uuid/uuid.dart';

class LocalProduct {
  const LocalProduct({
    required this.id,
    required this.uuid,
    required this.name,
    required this.sku,
    required this.basePrice,
    this.barcode,
    this.stock = 0,
    this.minStock = 0,
    this.trackStock = true,
    this.categoryName,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String uuid;
  final String name;
  final String sku;
  final String? barcode;
  final double basePrice;
  final double stock;
  final int minStock;
  final bool trackStock;
  final String? categoryName;
  final String? createdAt;
  final String? updatedAt;

  bool get isLowStock => trackStock && stock <= minStock;

  LocalProduct copyWith({
    int? id,
    String? uuid,
    String? name,
    String? sku,
    String? barcode,
    double? basePrice,
    double? stock,
    int? minStock,
    bool? trackStock,
    String? categoryName,
    String? createdAt,
    String? updatedAt,
  }) {
    return LocalProduct(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      basePrice: basePrice ?? this.basePrice,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      trackStock: trackStock ?? this.trackStock,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LocalProduct.fromMap(Map<String, dynamic> map) {
    return LocalProduct(
      id: map['id'] as int,
      uuid: map['uuid'] as String,
      name: map['name'] as String,
      sku: map['sku'] as String,
      barcode: map['barcode'] as String?,
      basePrice: (map['base_price'] as num?)?.toDouble() ?? 0,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      minStock: map['min_stock'] as int? ?? 0,
      trackStock: (map['track_stock'] as int? ?? 1) == 1,
      categoryName: map['category_name'] as String?,
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id > 0) 'id': id,
        'uuid': uuid,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'base_price': basePrice,
        'stock': stock,
        'min_stock': minStock,
        'track_stock': trackStock ? 1 : 0,
        'category_name': categoryName,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  static LocalProduct draft({
    String? name,
    String? sku,
    String? barcode,
    double basePrice = 0,
    double stock = 0,
  }) {
    return LocalProduct(
      id: 0,
      uuid: const Uuid().v4(),
      name: name ?? '',
      sku: sku ?? '',
      barcode: barcode,
      basePrice: basePrice,
      stock: stock,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}

class LocalInventoryStats {
  const LocalInventoryStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.totalStockValue,
    required this.todayStockIn,
  });

  final int totalProducts;
  final int lowStockCount;
  final double totalStockValue;
  final double todayStockIn;
}