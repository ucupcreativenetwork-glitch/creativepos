import '../../../core/utils/json_utils.dart';

class InventoryCategory {
  const InventoryCategory({
    required this.id,
    required this.name,
    this.uuid,
  });

  final int id;
  final String name;
  final String? uuid;

  factory InventoryCategory.fromJson(Map<String, dynamic> json) {
    return InventoryCategory(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      uuid: json['uuid'] as String?,
    );
  }
}

class Warehouse {
  const Warehouse({
    required this.id,
    required this.name,
    required this.code,
    this.outletId,
  });

  final int id;
  final String name;
  final String code;
  final int? outletId;

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      code: parseJsonString(json['code']),
      outletId: parseJsonIntOrNull(json['outlet_id']),
    );
  }
}

class ProductStockLevel {
  const ProductStockLevel({
    required this.warehouseId,
    required this.quantity,
    this.warehouseName,
    this.warehouseCode,
  });

  final int warehouseId;
  final double quantity;
  final String? warehouseName;
  final String? warehouseCode;

  factory ProductStockLevel.fromJson(Map<String, dynamic> json) {
    final warehouse = json['warehouse'] as Map<String, dynamic>?;
    return ProductStockLevel(
      warehouseId: parseJsonInt(json['warehouse_id'] ?? warehouse?['id']),
      quantity: parseJsonDouble(json['quantity']),
      warehouseName: warehouse?['name'] as String?,
      warehouseCode: warehouse?['code'] as String?,
    );
  }
}

class InventoryProduct {
  const InventoryProduct({
    required this.id,
    required this.uuid,
    required this.name,
    required this.sku,
    required this.basePrice,
    this.barcode,
    this.imageUrl,
    this.category,
    this.totalStock = 0,
    this.minStock = 0,
    this.trackStock = false,
    this.isActive = true,
    this.isAvailable = true,
    this.stocks = const [],
  });

  final int id;
  final String uuid;
  final String name;
  final String sku;
  final String? barcode;
  final String? imageUrl;
  final double basePrice;
  final Map<String, dynamic>? category;
  final double totalStock;
  final int minStock;
  final bool trackStock;
  final bool isActive;
  final bool isAvailable;
  final List<ProductStockLevel> stocks;

  double stockForWarehouse(int warehouseId) {
    for (final stock in stocks) {
      if (stock.warehouseId == warehouseId) return stock.quantity;
    }
    return 0;
  }

  factory InventoryProduct.fromJson(Map<String, dynamic> json) {
    return InventoryProduct(
      id: parseJsonInt(json['id']),
      uuid: parseJsonString(json['uuid']),
      name: parseJsonString(json['name']),
      sku: parseJsonString(json['sku']),
      barcode: json['barcode'] as String?,
      imageUrl: json['image_url'] as String?,
      basePrice: parseJsonDouble(json['base_price']),
      category: json['category'] as Map<String, dynamic>?,
      totalStock: parseJsonDouble(json['total_stock']),
      minStock: parseJsonInt(json['min_stock']),
      trackStock: parseJsonBool(json['track_stock']),
      isActive: json['is_active'] != false,
      isAvailable: json['is_available'] != false,
      stocks: (json['stocks'] as List<dynamic>? ?? [])
          .map((e) => ProductStockLevel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StockRow {
  const StockRow({
    required this.id,
    required this.quantity,
    required this.isLow,
    required this.product,
    required this.warehouse,
  });

  final int id;
  final double quantity;
  final bool isLow;
  final Map<String, dynamic> product;
  final Map<String, dynamic> warehouse;

  factory StockRow.fromJson(Map<String, dynamic> json) {
    return StockRow(
      id: parseJsonInt(json['id']),
      quantity: parseJsonDouble(json['quantity']),
      isLow: parseJsonBool(json['is_low']),
      product: json['product'] as Map<String, dynamic>? ?? {},
      warehouse: json['warehouse'] as Map<String, dynamic>? ?? {},
    );
  }
}

class StockAlert {
  const StockAlert({
    required this.quantity,
    required this.deficit,
    required this.product,
    required this.warehouse,
  });

  final double quantity;
  final double deficit;
  final Map<String, dynamic> product;
  final Map<String, dynamic> warehouse;

  factory StockAlert.fromJson(Map<String, dynamic> json) {
    return StockAlert(
      quantity: parseJsonDouble(json['quantity']),
      deficit: parseJsonDouble(json['deficit']),
      product: json['product'] as Map<String, dynamic>? ?? {},
      warehouse: json['warehouse'] as Map<String, dynamic>? ?? {},
    );
  }
}