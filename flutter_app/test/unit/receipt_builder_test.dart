import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/services/receipt_builder.dart';

void main() {
  group('ReceiptBuilder', () {
    test('fromCart builds receipt data', () {
      final data = ReceiptBuilder.fromCart(
        lines: const [
          (name: 'Kopi Susu', qty: 2, unitPrice: 18000),
          (name: 'Roti Bakar', qty: 1, unitPrice: 15000),
        ],
        transactionNumber: 'TRX-001',
        subtotal: 51000,
        grandTotal: 56100,
        paymentMethodName: 'Tunai',
        taxTotal: 5100,
      );

      expect(data.transactionNumber, 'TRX-001');
      expect(data.items, hasLength(2));
      expect(data.grandTotal, 56100);
      expect(data.payments.first.name, 'Tunai');
    });

    test('sanitize trims and limits text for thermal printers', () {
      expect(ReceiptBuilder.sanitize('  Kopi Susu  '), 'Kopi Susu');
      expect(
        ReceiptBuilder.sanitize('A' * 40, maxLen: 10).length,
        lessThanOrEqualTo(10),
      );
    });

    test('fromApiReceipt parses backend receipt', () {
      final data = ReceiptBuilder.fromApiReceipt({
        'transaction_number': 'TRX-99',
        'outlet': {'name': 'Toko Demo'},
        'cashier': {'name': 'Kasir A'},
        'subtotal': 100000,
        'tax_total': 11000,
        'service_charge': 5000,
        'grand_total': 116000,
        'items': [
          {
            'product_name': 'Nasi Goreng',
            'quantity': 2,
            'unit_price': 25000,
            'subtotal': 50000,
          },
        ],
        'payments': [
          {
            'amount': 116000,
            'payment_method': {'name': 'QRIS'},
          },
        ],
      });

      expect(data.transactionNumber, 'TRX-99');
      expect(data.outletName, 'Toko Demo');
      expect(data.cashierName, 'Kasir A');
      expect(data.items.first.name, 'Nasi Goreng');
      expect(data.payments.first.name, 'QRIS');
    });
  });
}