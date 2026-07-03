import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../local_database/offline_queue.dart';

class ReceiptTemplate {
  const ReceiptTemplate({
    this.storeTitle = '',
    this.headerLine = '',
    this.footerMessage = 'Terima kasih atas kunjungan Anda',
    this.showOutlet = true,
    this.showCashier = true,
    this.showDateTime = true,
    this.showTransactionNumber = true,
    this.showSubtotal = true,
    this.showTaxBreakdown = true,
    this.showPaymentDetails = true,
    this.showSeparatorLines = true,
    this.largeTotal = true,
  });

  final String storeTitle;
  final String headerLine;
  final String footerMessage;
  final bool showOutlet;
  final bool showCashier;
  final bool showDateTime;
  final bool showTransactionNumber;
  final bool showSubtotal;
  final bool showTaxBreakdown;
  final bool showPaymentDetails;
  final bool showSeparatorLines;
  final bool largeTotal;

  ReceiptTemplate copyWith({
    String? storeTitle,
    String? headerLine,
    String? footerMessage,
    bool? showOutlet,
    bool? showCashier,
    bool? showDateTime,
    bool? showTransactionNumber,
    bool? showSubtotal,
    bool? showTaxBreakdown,
    bool? showPaymentDetails,
    bool? showSeparatorLines,
    bool? largeTotal,
  }) {
    return ReceiptTemplate(
      storeTitle: storeTitle ?? this.storeTitle,
      headerLine: headerLine ?? this.headerLine,
      footerMessage: footerMessage ?? this.footerMessage,
      showOutlet: showOutlet ?? this.showOutlet,
      showCashier: showCashier ?? this.showCashier,
      showDateTime: showDateTime ?? this.showDateTime,
      showTransactionNumber: showTransactionNumber ?? this.showTransactionNumber,
      showSubtotal: showSubtotal ?? this.showSubtotal,
      showTaxBreakdown: showTaxBreakdown ?? this.showTaxBreakdown,
      showPaymentDetails: showPaymentDetails ?? this.showPaymentDetails,
      showSeparatorLines: showSeparatorLines ?? this.showSeparatorLines,
      largeTotal: largeTotal ?? this.largeTotal,
    );
  }

  Map<String, dynamic> toMap() => {
        'store_title': storeTitle,
        'header_line': headerLine,
        'footer_message': footerMessage,
        'show_outlet': showOutlet,
        'show_cashier': showCashier,
        'show_date_time': showDateTime,
        'show_transaction_number': showTransactionNumber,
        'show_subtotal': showSubtotal,
        'show_tax_breakdown': showTaxBreakdown,
        'show_payment_details': showPaymentDetails,
        'show_separator_lines': showSeparatorLines,
        'large_total': largeTotal,
      };

  factory ReceiptTemplate.fromMap(Map<dynamic, dynamic> map) {
    return ReceiptTemplate(
      storeTitle: map['store_title'] as String? ?? '',
      headerLine: map['header_line'] as String? ?? '',
      footerMessage:
          map['footer_message'] as String? ?? 'Terima kasih atas kunjungan Anda',
      showOutlet: map['show_outlet'] as bool? ?? true,
      showCashier: map['show_cashier'] as bool? ?? true,
      showDateTime: map['show_date_time'] as bool? ?? true,
      showTransactionNumber: map['show_transaction_number'] as bool? ?? true,
      showSubtotal: map['show_subtotal'] as bool? ?? true,
      showTaxBreakdown: map['show_tax_breakdown'] as bool? ?? true,
      showPaymentDetails: map['show_payment_details'] as bool? ?? true,
      showSeparatorLines: map['show_separator_lines'] as bool? ?? true,
      largeTotal: map['large_total'] as bool? ?? true,
    );
  }
}

class ReceiptTemplateService {
  static const _key = 'receipt_template';

  Future<Box> _box() => Hive.openBox(OfflineQueue.hiveBoxName);

  Future<ReceiptTemplate> getTemplate() async {
    final box = await _box();
    final raw = box.get(_key);
    if (raw is Map) return ReceiptTemplate.fromMap(raw);
    return const ReceiptTemplate();
  }

  Future<void> saveTemplate(ReceiptTemplate template) async {
    final box = await _box();
    await box.put(_key, template.toMap());
  }
}

final receiptTemplateServiceProvider = Provider<ReceiptTemplateService>((ref) {
  return ReceiptTemplateService();
});

final receiptTemplateProvider =
    FutureProvider.autoDispose<ReceiptTemplate>((ref) async {
  return ref.watch(receiptTemplateServiceProvider).getTemplate();
});