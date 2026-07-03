class PublicMenuData {
  const PublicMenuData({
    required this.tenant,
    required this.outlet,
    required this.settings,
    required this.categories,
    required this.products,
    this.table,
  });

  final PublicMenuTenant tenant;
  final PublicMenuOutlet outlet;
  final PublicMenuSettings settings;
  final List<PublicMenuCategory> categories;
  final List<PublicMenuProduct> products;
  final PublicMenuTable? table;

  factory PublicMenuData.fromJson(Map<String, dynamic> json) {
    return PublicMenuData(
      tenant: PublicMenuTenant.fromJson(json['tenant'] as Map<String, dynamic>),
      outlet: PublicMenuOutlet.fromJson(json['outlet'] as Map<String, dynamic>),
      settings:
          PublicMenuSettings.fromJson(json['settings'] as Map<String, dynamic>),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => PublicMenuCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: (json['products'] as List<dynamic>? ?? [])
          .map((e) => PublicMenuProduct.fromJson(e as Map<String, dynamic>))
          .toList(),
      table: json['table'] != null
          ? PublicMenuTable.fromJson(json['table'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PublicMenuTenant {
  const PublicMenuTenant({
    required this.name,
    required this.slug,
    this.logoUrl,
  });

  final String name;
  final String slug;
  final String? logoUrl;

  factory PublicMenuTenant.fromJson(Map<String, dynamic> json) {
    return PublicMenuTenant(
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class PublicMenuOutlet {
  const PublicMenuOutlet({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
  });

  final int id;
  final String name;
  final String slug;
  final String? address;

  factory PublicMenuOutlet.fromJson(Map<String, dynamic> json) {
    return PublicMenuOutlet(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String? ?? '',
      address: json['address'] as String?,
    );
  }
}

class PublicMenuSettings {
  const PublicMenuSettings({
    this.themeColor = '#2563EB',
    this.welcomeMessage,
    this.showPrices = true,
    this.allowGuestOrder = true,
  });

  final String themeColor;
  final String? welcomeMessage;
  final bool showPrices;
  final bool allowGuestOrder;

  factory PublicMenuSettings.fromJson(Map<String, dynamic> json) {
    return PublicMenuSettings(
      themeColor: json['theme_color'] as String? ?? '#2563EB',
      welcomeMessage: json['welcome_message'] as String?,
      showPrices: json['show_prices'] as bool? ?? true,
      allowGuestOrder: json['allow_guest_order'] as bool? ?? true,
    );
  }
}

class PublicMenuCategory {
  const PublicMenuCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory PublicMenuCategory.fromJson(Map<String, dynamic> json) {
    return PublicMenuCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class PublicMenuProduct {
  const PublicMenuProduct({
    required this.id,
    required this.name,
    required this.basePrice,
    this.categoryId,
    this.categoryName,
    this.description,
  });

  final int id;
  final String name;
  final double basePrice;
  final int? categoryId;
  final String? categoryName;
  final String? description;

  factory PublicMenuProduct.fromJson(Map<String, dynamic> json) {
    return PublicMenuProduct(
      id: json['id'] as int,
      name: json['name'] as String,
      basePrice: _toDouble(json['base_price']),
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      description: json['description'] as String?,
    );
  }
}

class PublicMenuTable {
  const PublicMenuTable({
    required this.id,
    required this.tableNumber,
    this.name,
    this.area,
  });

  final int id;
  final String tableNumber;
  final String? name;
  final String? area;

  factory PublicMenuTable.fromJson(Map<String, dynamic> json) {
    return PublicMenuTable(
      id: json['id'] as int,
      tableNumber: json['table_number'] as String? ?? '',
      name: json['name'] as String?,
      area: json['area'] as String?,
    );
  }
}

class PublicOrderResult {
  const PublicOrderResult({
    required this.uuid,
    required this.orderNumber,
    required this.status,
    this.subtotal,
  });

  final String uuid;
  final String orderNumber;
  final String status;
  final double? subtotal;

  factory PublicOrderResult.fromJson(Map<String, dynamic> json) {
    return PublicOrderResult(
      uuid: json['uuid'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      subtotal: json['subtotal'] != null ? _toDouble(json['subtotal']) : null,
    );
  }
}

class PublicOrderTrack {
  const PublicOrderTrack({
    required this.uuid,
    required this.orderNumber,
    required this.status,
    this.subtotal,
    this.table,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String uuid;
  final String orderNumber;
  final String status;
  final double? subtotal;
  final PublicMenuTable? table;
  final List<PublicOrderItem> items;
  final String? createdAt;
  final String? updatedAt;

  factory PublicOrderTrack.fromJson(Map<String, dynamic> json) {
    return PublicOrderTrack(
      uuid: json['uuid'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      subtotal: json['subtotal'] != null ? _toDouble(json['subtotal']) : null,
      table: json['table'] != null
          ? PublicMenuTable.fromJson(json['table'] as Map<String, dynamic>)
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => PublicOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}

class PublicOrderItem {
  const PublicOrderItem({
    required this.productName,
    required this.quantity,
    required this.status,
  });

  final String productName;
  final double quantity;
  final String status;

  factory PublicOrderItem.fromJson(Map<String, dynamic> json) {
    return PublicOrderItem(
      productName: json['product_name'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}