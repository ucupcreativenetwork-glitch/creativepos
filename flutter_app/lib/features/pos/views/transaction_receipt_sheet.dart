import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../services/printer_service.dart';
import '../../../services/receipt_builder.dart';
import '../../../services/receipt_template.dart';
import '../../settings/views/printer_settings_screen.dart';
import '../../settings/views/receipt_template_screen.dart';
import '../models/transaction_success.dart';

Future<void> showTransactionReceiptSheet({
  required BuildContext context,
  required TransactionSuccessInfo info,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (_) => TransactionReceiptSheet(info: info),
  );
}

class TransactionReceiptSheet extends ConsumerStatefulWidget {
  const TransactionReceiptSheet({super.key, required this.info});

  final TransactionSuccessInfo info;

  @override
  ConsumerState<TransactionReceiptSheet> createState() =>
      _TransactionReceiptSheetState();
}

class _TransactionReceiptSheetState
    extends ConsumerState<TransactionReceiptSheet> {
  var _printing = false;
  String? _lastPrintMessage;
  bool? _lastPrintOk;

  @override
  void initState() {
    super.initState();
    _lastPrintMessage = widget.info.printMessage;
    _lastPrintOk = widget.info.printSucceeded;
  }

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      final result =
          await ref.read(printerServiceProvider).printReceipt(widget.info.receiptData);
      if (!mounted) return;
      setState(() {
        _lastPrintMessage = result.message;
        _lastPrintOk = result.success;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _newTransaction() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Siap untuk transaksi baru')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final config = ref.watch(printerConfigProvider);
    final template = ref.watch(receiptTemplateProvider).valueOrNull;
    final preview = ReceiptBuilder.buildPreviewText(
      data: info.receiptData,
      template: template,
    );
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                info.wasOffline ? Icons.cloud_off : Icons.check_circle,
                color: info.wasOffline ? Colors.orange : Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembayaran Berhasil',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      info.wasOffline
                          ? '${info.transaction.transactionNumber} (offline)'
                          : info.transaction.transactionNumber,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.currency(info.transaction.grandTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          config.when(
            data: (cfg) {
              if (cfg.isConfigured) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: const Text(
                  'Printer belum dikonfigurasi. Hubungkan printer Bluetooth di Pengaturan > Printer.',
                  style: TextStyle(fontSize: 12),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          if (_lastPrintMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: (_lastPrintOk ?? false)
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    (_lastPrintOk ?? false) ? Icons.print : Icons.print_disabled,
                    size: 18,
                    color: (_lastPrintOk ?? false) ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastPrintMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: (_lastPrintOk ?? false)
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              child: Text(
                preview,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _printing ? null : _print,
            icon: _printing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.print),
            label: const Text('Cetak Struk'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrinterSettingsScreen(),
                ),
              );
              ref.invalidate(printerConfigProvider);
            },
            icon: const Icon(Icons.bluetooth),
            label: const Text('Pengaturan Printer'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReceiptTemplateScreen(),
                ),
              );
              ref.invalidate(receiptTemplateProvider);
            },
            icon: const Icon(Icons.tune),
            label: const Text('Atur Bentuk Struk'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: _newTransaction,
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Transaksi Baru'),
          ),
        ],
      ),
    );
  }
}