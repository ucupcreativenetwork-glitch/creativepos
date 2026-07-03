import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/pos/models/pos_models.dart';
import 'package:creativepos_mobile/features/pos/providers/cart_notifier.dart';

void main() {
  test('CartNotifier adds and updates items', () {
    final notifier = CartNotifier();
    final product = PosProduct(
      id: 1,
      uuid: 'p1',
      name: 'Kopi',
      sku: 'K001',
      basePrice: 15000,
    );

    notifier.addProduct(product, quantity: 2);
    expect(notifier.state.items.length, 1);
    expect(notifier.state.subtotal, 30000);

    final key = notifier.state.items.first.key;
    notifier.updateQuantity(key, 3);
    expect(notifier.state.subtotal, 45000);

    notifier.removeItem(key);
    expect(notifier.state.items, isEmpty);
  });
}