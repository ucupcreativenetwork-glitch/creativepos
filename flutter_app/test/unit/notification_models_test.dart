import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/notifications/models/notification_models.dart';

void main() {
  group('AppNotificationModel', () {
    test('parses unread notification', () {
      final n = AppNotificationModel.fromJson({
        'id': 10,
        'type': 'new_order',
        'title': 'Order Baru',
        'body': 'Order #123 masuk',
        'data': {'order_id': 123},
        'read_at': null,
        'created_at': '2026-07-01T09:00:00+07:00',
      });

      expect(n.title, 'Order Baru');
      expect(n.isRead, isFalse);
      expect(n.data?['order_id'], 123);
    });

    test('detects read notification', () {
      final n = AppNotificationModel.fromJson({
        'id': 11,
        'type': 'low_stock',
        'title': 'Stok Rendah',
        'body': 'Produk A hampir habis',
        'read_at': '2026-07-01T10:00:00+07:00',
      });

      expect(n.isRead, isTrue);
    });
  });
}