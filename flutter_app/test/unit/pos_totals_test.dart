import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/core/utils/pos_totals.dart';

void main() {
  test('calculatePosTotals applies tax and service charge', () {
    final totals = calculatePosTotals(
      subtotal: 100000,
      taxRate: 11,
      serviceRate: 5,
    );

    expect(totals.taxTotal, 11000);
    expect(totals.serviceCharge, 5000);
    expect(totals.grandTotal, 116000);
  });
}