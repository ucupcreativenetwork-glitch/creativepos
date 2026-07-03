class DeliveryOrderModel {
  const DeliveryOrderModel({
    required this.id,
    required this.uuid,
    required this.deliveryNumber,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    this.outletId,
    this.driverId,
    this.outlet,
    this.driver,
    this.deliveryAddress,
    this.deliveryCity,
    this.deliveryNotes,
    this.subtotal = 0,
    this.shippingFee = 0,
    this.totalAmount = 0,
    this.distanceKm,
    this.estimatedMinutes,
    this.items = const [],
    this.trackingPoints = const [],
    this.createdAt,
  });

  final int id;
  final String uuid;
  final String deliveryNumber;
  final String customerName;
  final String customerPhone;
  final String status;
  final int? outletId;
  final int? driverId;
  final DeliveryOutlet? outlet;
  final DeliveryDriver? driver;
  final String? deliveryAddress;
  final String? deliveryCity;
  final String? deliveryNotes;
  final double subtotal;
  final double shippingFee;
  final double totalAmount;
  final double? distanceKm;
  final int? estimatedMinutes;
  final List<DeliveryItem> items;
  final List<TrackingPoint> trackingPoints;
  final String? createdAt;

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    return DeliveryOrderModel(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      deliveryNumber: json['delivery_number'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? '',
      status: json['status'] as String? ?? 'waiting',
      outletId: json['outlet_id'] as int?,
      driverId: json['driver_id'] as int?,
      outlet: json['outlet'] != null
          ? DeliveryOutlet.fromJson(json['outlet'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? DeliveryDriver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryCity: json['delivery_city'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
      subtotal: _toDouble(json['subtotal']),
      shippingFee: _toDouble(json['shipping_fee']),
      totalAmount: _toDouble(json['total_amount'] ?? json['grand_total']),
      distanceKm: json['distance_km'] != null
          ? _toDouble(json['distance_km'])
          : null,
      estimatedMinutes: json['estimated_minutes'] as int?,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => DeliveryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      trackingPoints: (json['tracking_points'] as List<dynamic>? ?? [])
          .map((e) => TrackingPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String?,
    );
  }
}

class DeliveryOutlet {
  const DeliveryOutlet({required this.id, required this.name, this.code});

  final int id;
  final String name;
  final String? code;

  factory DeliveryOutlet.fromJson(Map<String, dynamic> json) {
    return DeliveryOutlet(
      id: json['id'] as int,
      name: json['name'] as String,
      code: json['code'] as String?,
    );
  }
}

class DeliveryDriver {
  const DeliveryDriver({
    required this.id,
    required this.uuid,
    this.vehicleType,
    this.vehiclePlate,
    this.user,
  });

  final int id;
  final String uuid;
  final String? vehicleType;
  final String? vehiclePlate;
  final DeliveryDriverUser? user;

  factory DeliveryDriver.fromJson(Map<String, dynamic> json) {
    return DeliveryDriver(
      id: json['id'] as int,
      uuid: json['uuid'] as String,
      vehicleType: json['vehicle_type'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      user: json['user'] != null
          ? DeliveryDriverUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DeliveryDriverUser {
  const DeliveryDriverUser({
    required this.id,
    required this.name,
    this.phone,
  });

  final int id;
  final String name;
  final String? phone;

  factory DeliveryDriverUser.fromJson(Map<String, dynamic> json) {
    return DeliveryDriverUser(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );
  }
}

class DeliveryItem {
  const DeliveryItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.notes,
  });

  final int id;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double subtotal;
  final String? notes;

  factory DeliveryItem.fromJson(Map<String, dynamic> json) {
    return DeliveryItem(
      id: json['id'] as int,
      productName: json['product_name'] as String? ?? '',
      quantity: _toDouble(json['quantity']),
      unitPrice: _toDouble(json['unit_price']),
      subtotal: _toDouble(json['subtotal']),
      notes: json['notes'] as String?,
    );
  }
}

class TrackingPoint {
  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final String? recordedAt;

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      recordedAt: json['recorded_at'] as String?,
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}