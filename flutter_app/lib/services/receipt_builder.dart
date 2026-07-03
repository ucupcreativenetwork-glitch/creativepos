import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';

import '../core/utils/formatters.dart';
import 'receipt_template.dart';

class ReceiptData {
  const ReceiptData({
    required this.businessName,
    required this.transactionNumber,
    required this.items,
    required this.subtotal,
    required this.grandTotal,
    this.outletName,
    this.cashierName,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.serviceCharge = 0,
    this.payments = const [],
    this.completedAt,
    this.isOffline = false,
  });

  final String businessName;
  final String transactionNumber;
  final String? outletName;
  final String? cashierName;
  final List<ReceiptItem> items;
  final double subtotal;
  final double discountTotal;
  final double taxTotal;
  final double serviceCharge;
  final double grandTotal;
  final List<ReceiptPayment> payments;
  final DateTime? completedAt;
  final bool isOffline;
}

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  final String name;
  final double quantity;
  final double unitPrice;
  final double subtotal;
}

class ReceiptPayment {
  const ReceiptPayment({required this.name, required this.amount});

  final String name;
  final double amount;
}

class ReceiptBuilder {
  static ReceiptTemplate _template(ReceiptTemplate? template) =>
      template ?? const ReceiptTemplate();

  /// Normalisasi teks agar kompatibel dengan printer thermal Bluetooth.
  static String sanitize(String? value, {int maxLen = 32}) {
    if (value == null || value.isEmpty) return '';
    var text = value
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('’', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .trim();
    if (text.length > maxLen) {
      text = '${text.substring(0, maxLen - 1)}…';
    }
    return text;
  }

  static String buildPreviewText({
    required ReceiptData data,
    ReceiptTemplate? template,
  }) {
    final t = _template(template);
    final title =
        t.storeTitle.isNotEmpty ? t.storeTitle : data.businessName;
    final lines = <String>[
      title,
      if (t.headerLine.isNotEmpty) t.headerLine,
      if (t.showSeparatorLines) '--------------------------------',
      if (t.showTransactionNumber) 'No: ${data.transactionNumber}',
      if (t.showCashier && data.cashierName != null)
        'Kasir: ${data.cashierName}',
      if (t.showDateTime)
        DateFormat('d MMM yyyy HH:mm', 'id_ID')
            .format(data.completedAt ?? DateTime.now()),
      if (data.isOffline) '*** OFFLINE - MENUNGGU SYNC ***',
      if (t.showSeparatorLines) '--------------------------------',
    ];

    for (final item in data.items) {
      lines.add(item.name);
      lines.add(
        '  ${item.quantity.toStringAsFixed(0)} x ${Formatters.currency(item.unitPrice)}  ${Formatters.currency(item.subtotal)}',
      );
    }

    if (t.showSeparatorLines) lines.add('--------------------------------');
    if (t.showSubtotal) {
      lines.add('Subtotal  ${Formatters.currency(data.subtotal)}');
    }
    if (t.showTaxBreakdown && data.discountTotal > 0) {
      lines.add('Diskon  -${Formatters.currency(data.discountTotal)}');
    }
    if (t.showTaxBreakdown && data.taxTotal > 0) {
      lines.add('Pajak  ${Formatters.currency(data.taxTotal)}');
    }
    if (t.showTaxBreakdown && data.serviceCharge > 0) {
      lines.add('Service  ${Formatters.currency(data.serviceCharge)}');
    }
    lines.add(
      t.largeTotal
          ? 'TOTAL: ${Formatters.currency(data.grandTotal)}'
          : 'Total  ${Formatters.currency(data.grandTotal)}',
    );

    if (t.showPaymentDetails) {
      for (final payment in data.payments) {
        lines.add(
          'Bayar (${payment.name}): ${Formatters.currency(payment.amount)}',
        );
      }
    }

    if (t.showSeparatorLines) lines.add('--------------------------------');
    if (t.footerMessage.isNotEmpty) lines.add(t.footerMessage);
    if (t.showOutlet && data.outletName != null) lines.add(data.outletName!);

    return lines.join('\n');
  }

  static Future<List<int>> buildBytes({
    required ReceiptData data,
    PaperSize paperSize = PaperSize.mm58,
    ReceiptTemplate? template,
  }) async {
    final t = _template(template);
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    final bytes = <int>[];
    final title =
        t.storeTitle.isNotEmpty ? t.storeTitle : data.businessName;

    bytes.addAll(generator.reset());
    bytes.addAll(generator.text(
      sanitize(title, maxLen: 24),
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2),
    ));
    if (t.headerLine.isNotEmpty) {
      bytes.addAll(generator.text(
        t.headerLine,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }
    if (t.showOutlet && data.outletName != null) {
      bytes.addAll(generator.text(
        data.outletName!,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }
    if (t.showSeparatorLines) bytes.addAll(generator.hr());
    if (t.showTransactionNumber) {
      bytes.addAll(generator.text('No: ${data.transactionNumber}'));
    }
    if (t.showCashier && data.cashierName != null) {
      bytes.addAll(generator.text('Kasir: ${data.cashierName}'));
    }
    if (t.showDateTime) {
      bytes.addAll(generator.text(
        DateFormat('d MMM yyyy HH:mm', 'id_ID')
            .format(data.completedAt ?? DateTime.now()),
      ));
    }
    if (data.isOffline) {
      bytes.addAll(generator.text(
        '*** OFFLINE - MENUNGGU SYNC ***',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ));
    }
    if (t.showSeparatorLines) bytes.addAll(generator.hr());

    for (final item in data.items) {
      final name = sanitize(item.name, maxLen: paperSize == PaperSize.mm58 ? 28 : 40);
      bytes.addAll(generator.text(name, styles: const PosStyles(bold: true)));
      final qtyLine =
          '${item.quantity.toStringAsFixed(0)} x ${_compactCurrency(item.unitPrice)}';
      final subtotalLine = _compactCurrency(item.subtotal);
      bytes.addAll(generator.row([
        PosColumn(text: qtyLine, width: 7),
        PosColumn(
          text: subtotalLine,
          width: 5,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]));
    }

    if (t.showSeparatorLines) bytes.addAll(generator.hr());
    if (t.showSubtotal) {
      bytes.addAll(_totalRow(generator, 'Subtotal', data.subtotal));
    }
    if (t.showTaxBreakdown && data.discountTotal > 0) {
      bytes.addAll(_totalRow(generator, 'Diskon', -data.discountTotal));
    }
    if (t.showTaxBreakdown && data.taxTotal > 0) {
      bytes.addAll(_totalRow(generator, 'Pajak', data.taxTotal));
    }
    if (t.showTaxBreakdown && data.serviceCharge > 0) {
      bytes.addAll(_totalRow(generator, 'Service', data.serviceCharge));
    }
    bytes.addAll(generator.text(
      'TOTAL: ${_compactCurrency(data.grandTotal)}',
      styles: PosStyles(
        bold: true,
        height: t.largeTotal ? PosTextSize.size2 : PosTextSize.size1,
      ),
    ));

    if (t.showPaymentDetails) {
      for (final payment in data.payments) {
        bytes.addAll(generator.text(
          'Bayar (${payment.name}): ${Formatters.currency(payment.amount)}',
        ));
      }
    }

    if (t.showSeparatorLines) bytes.addAll(generator.hr());
    if (t.footerMessage.isNotEmpty) {
      bytes.addAll(generator.text(
        t.footerMessage,
        styles: const PosStyles(align: PosAlign.center),
      ));
    }
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  static String _compactCurrency(double value) {
    final raw = Formatters.currency(value);
    return raw.replaceAll('\u00a0', ' ');
  }

  static List<int> _totalRow(Generator g, String label, double amount) {
    return g.row([
      PosColumn(text: label, width: 7),
      PosColumn(
        text: _compactCurrency(amount),
        width: 5,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
  }

  static ReceiptData fromApiReceipt(Map<String, dynamic> json) {
    final outlet = json['outlet'] as Map<String, dynamic>?;
    final cashier = json['cashier'] as Map<String, dynamic>?;
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return ReceiptItem(
            name: m['product_name'] as String? ?? '',
            quantity: (m['quantity'] as num?)?.toDouble() ?? 0,
            unitPrice: (m['unit_price'] as num?)?.toDouble() ?? 0,
            subtotal: (m['subtotal'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();
    final payments = (json['payments'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          final method = m['payment_method'] as Map<String, dynamic>?;
          return ReceiptPayment(
            name: method?['name'] as String? ?? 'Bayar',
            amount: (m['amount'] as num?)?.toDouble() ?? 0,
          );
        })
        .toList();

    return ReceiptData(
      businessName: outlet?['name'] as String? ?? 'CreativePOS',
      outletName: outlet?['name'] as String?,
      transactionNumber: json['transaction_number'] as String? ?? '',
      cashierName: cashier?['name'] as String?,
      items: items,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountTotal: (json['discount_total'] as num?)?.toDouble() ?? 0,
      taxTotal: (json['tax_total'] as num?)?.toDouble() ?? 0,
      serviceCharge: (json['service_charge'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0,
      payments: payments,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }

  static ReceiptData fromCart({
    required List<({String name, double qty, double unitPrice})> lines,
    required String transactionNumber,
    required double subtotal,
    required double grandTotal,
    required String paymentMethodName,
    double taxTotal = 0,
    double serviceCharge = 0,
    double discountTotal = 0,
    String? businessName,
    String? outletName,
    String? cashierName,
    bool isOffline = false,
  }) {
    final items = lines
        .map(
          (l) => ReceiptItem(
            name: l.name,
            quantity: l.qty,
            unitPrice: l.unitPrice,
            subtotal: l.qty * l.unitPrice,
          ),
        )
        .toList();

    return ReceiptData(
      businessName: businessName ?? 'CreativePOS',
      outletName: outletName,
      cashierName: cashierName,
      transactionNumber: transactionNumber,
      items: items,
      subtotal: subtotal,
      discountTotal: discountTotal,
      taxTotal: taxTotal,
      serviceCharge: serviceCharge,
      grandTotal: grandTotal,
      payments: [ReceiptPayment(name: paymentMethodName, amount: grandTotal)],
      isOffline: isOffline,
    );
  }

  static ReceiptData fromCheckoutPayload({
    required Map<String, dynamic> payload,
    required String transactionNumber,
    required double grandTotal,
    required double subtotal,
    double taxTotal = 0,
    double serviceCharge = 0,
    double discountTotal = 0,
    String? businessName,
    String? paymentMethodName,
    bool isOffline = false,
  }) {
    final items = (payload['items'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          final qty = (m['quantity'] as num?)?.toDouble() ?? 1;
          final price = (m['unit_price'] as num?)?.toDouble() ?? 0;
          return ReceiptItem(
            name: m['product_name'] as String? ?? 'Item',
            quantity: qty,
            unitPrice: price,
            subtotal: qty * price,
          );
        })
        .toList();

    final payments = (payload['payments'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return ReceiptPayment(
            name: paymentMethodName ?? 'Bayar',
            amount: (m['amount'] as num?)?.toDouble() ?? grandTotal,
          );
        })
        .toList();

    return ReceiptData(
      businessName: businessName ?? 'CreativePOS',
      transactionNumber: transactionNumber,
      items: items,
      subtotal: subtotal,
      discountTotal: discountTotal,
      taxTotal: taxTotal,
      serviceCharge: serviceCharge,
      grandTotal: grandTotal,
      payments: payments,
      isOffline: isOffline,
    );
  }
}