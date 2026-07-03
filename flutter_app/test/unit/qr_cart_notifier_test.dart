import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/qr_menu/models/qr_menu_models.dart';
import 'package:creativepos_mobile/features/qr_menu/providers/qr_cart_notifier.dart';

void main() {
  group('QrCartNotifier', () {
    test('adds and updates cart items', () {
      final notifier = QrCartNotifier();
      const product = PublicMenuProduct(
        id: 1,
        name: 'Nasi Goreng',
        basePrice: 25000,
      );

      notifier.addProduct(product);
      expect(notifier.state.itemCount, 1);
      expect(notifier.state.subtotal, 25000);

      notifier.addProduct(product, quantity: 2);
      expect(notifier.state.items.first.quantity, 3);
      expect(notifier.state.subtotal, 75000);

      notifier.updateQuantity(1, 0);
      expect(notifier.state.items, isEmpty);
    });
  });
}