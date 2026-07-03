import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/delivery/models/delivery_models.dart';

void main() {
  group('DeliveryOrderModel', () {
    test('parses delivery order from API', () {
      final order = DeliveryOrderModel.fromJson({
        'id': 1,
        'uuid': 'del-uuid-1',
        'delivery_number': 'DEL-001',
        'customer_name': 'Andi',
        'customer_phone': '08123',
        'status': 'delivering',
        'subtotal': 100000,
        'shipping_fee': 15000,
        'total_amount': 115000,
        'delivery_address': 'Jl. Merdeka 1',
        'items': [
          {
            'id': 1,
            'product_name': 'Nasi Goreng',
            'quantity': 2,
            'unit_price': 25000,
            'subtotal': 50000,
          },
        ],
        'tracking_points': [
          {
            'latitude': -6.2,
            'longitude': 106.8,
            'recorded_at': '2026-07-01T12:00:00+07:00',
          },
        ],
      });

      expect(order.uuid, 'del-uuid-1');
      expect(order.status, 'delivering');
      expect(order.totalAmount, 115000);
      expect(order.items, hasLength(1));
      expect(order.trackingPoints.first.latitude, -6.2);
    });
  });
}