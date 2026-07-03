import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/receipt_builder.dart';
import '../../../services/receipt_template.dart';
import '../../settings/data/settings_repository.dart';

class ReceiptTemplateScreen extends ConsumerStatefulWidget {
  const ReceiptTemplateScreen({super.key});

  @override
  ConsumerState<ReceiptTemplateScreen> createState() =>
      _ReceiptTemplateScreenState();
}

class _ReceiptTemplateScreenState extends ConsumerState<ReceiptTemplateScreen> {
  final _storeTitleController = TextEditingController();
  final _headerController = TextEditingController();
  final _footerController = TextEditingController();
  ReceiptTemplate _template = const ReceiptTemplate();
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _storeTitleController.dispose();
    _headerController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final template =
        await ref.read(receiptTemplateServiceProvider).getTemplate();
    if (!mounted) return;
    setState(() {
      _template = template;
      _storeTitleController.text = template.storeTitle;
      _headerController.text = template.headerLine;
      _footerController.text = template.footerMessage;
      _loading = false;
    });
  }

  ReceiptTemplate _currentTemplate() {
    return _template.copyWith(
      storeTitle: _storeTitleController.text.trim(),
      headerLine: _headerController.text.trim(),
      footerMessage: _footerController.text.trim(),
    );
  }

  ReceiptData _sampleReceipt(String businessName) {
    return ReceiptData(
      businessName: businessName,
      outletName: 'Outlet Demo',
      cashierName: 'Kasir Demo',
      transactionNumber: 'TRX-PREVIEW',
      items: const [
        ReceiptItem(
          name: 'Kopi Susu',
          quantity: 2,
          unitPrice: 18000,
          subtotal: 36000,
        ),
        ReceiptItem(
          name: 'Roti Bakar',
          quantity: 1,
          unitPrice: 15000,
          subtotal: 15000,
        ),
      ],
      subtotal: 51000,
      taxTotal: 5100,
      grandTotal: 56100,
      payments: const [ReceiptPayment(name: 'Tunai', amount: 56100)],
      completedAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = _currentTemplate();
      await ref.read(receiptTemplateServiceProvider).saveTemplate(updated);
      ref.invalidate(receiptTemplateProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template struk disimpan')),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(tenantSettingsProvider);
    final businessName = settings.maybeWhen(
      data: (s) => s.businessName,
      orElse: () => 'CreativePOS',
    ) ?? 'CreativePOS';
    final preview = ReceiptBuilder.buildPreviewText(
      data: _sampleReceipt(businessName),
      template: _currentTemplate(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Atur Struk / Nota')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Pratinjau',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    preview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Header',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _storeTitleController,
                  decoration: InputDecoration(
                    labelText: 'Judul toko',
                    hintText: businessName,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _headerController,
                  decoration: const InputDecoration(
                    labelText: 'Baris tambahan (alamat, telp, dll)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text(
                  'Footer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _footerController,
                  decoration: const InputDecoration(
                    labelText: 'Pesan penutup',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text(
                  'Tampilkan di struk',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SwitchListTile(
                  title: const Text('Nama outlet'),
                  value: _template.showOutlet,
                  onChanged: (v) => setState(() => _template = _template.copyWith(showOutlet: v)),
                ),
                SwitchListTile(
                  title: const Text('Nama kasir'),
                  value: _template.showCashier,
                  onChanged: (v) => setState(() => _template = _template.copyWith(showCashier: v)),
                ),
                SwitchListTile(
                  title: const Text('Tanggal & waktu'),
                  value: _template.showDateTime,
                  onChanged: (v) => setState(() => _template = _template.copyWith(showDateTime: v)),
                ),
                SwitchListTile(
                  title: const Text('Nomor transaksi'),
                  value: _template.showTransactionNumber,
                  onChanged: (v) => setState(
                    () => _template = _template.copyWith(showTransactionNumber: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Subtotal'),
                  value: _template.showSubtotal,
                  onChanged: (v) => setState(() => _template = _template.copyWith(showSubtotal: v)),
                ),
                SwitchListTile(
                  title: const Text('Rincian pajak & diskon'),
                  value: _template.showTaxBreakdown,
                  onChanged: (v) => setState(
                    () => _template = _template.copyWith(showTaxBreakdown: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Detail pembayaran'),
                  value: _template.showPaymentDetails,
                  onChanged: (v) => setState(
                    () => _template = _template.copyWith(showPaymentDetails: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Garis pemisah'),
                  value: _template.showSeparatorLines,
                  onChanged: (v) => setState(
                    () => _template = _template.copyWith(showSeparatorLines: v),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Total besar'),
                  value: _template.largeTotal,
                  onChanged: (v) => setState(() => _template = _template.copyWith(largeTotal: v)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan Template'),
                ),
              ],
            ),
    );
  }
}