import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../pos/views/barcode_scanner_screen.dart';
import '../models/local_product.dart';
import '../providers/standalone_providers.dart';
import 'local_product_form_sheet.dart';

Future<bool?> showStockReceiveSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const StockReceiveSheet(),
  );
}

class StockReceiveSheet extends ConsumerStatefulWidget {
  const StockReceiveSheet({super.key});

  @override
  ConsumerState<StockReceiveSheet> createState() => _StockReceiveSheetState();
}

class _StockReceiveSheetState extends ConsumerState<StockReceiveSheet> {
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController();
  LocalProduct? _product;
  var _isScanning = false;
  var _isSaving = false;
  String? _error;
  String? _lastScanned;

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (!mounted) return;
    setState(() => _isScanning = false);

    if (code == null || code.isEmpty) return;
    await _lookup(code);
  }

  Future<void> _lookup(String code) async {
    setState(() {
      _lastScanned = code;
      _error = null;
    });

    final product =
        await ref.read(localInventoryRepositoryProvider).findByBarcodeOrSku(code);

    if (!mounted) return;
    if (product != null) {
      setState(() => _product = product);
    } else {
      setState(() {
        _product = null;
        _error = 'Produk tidak ditemukan — buat produk baru?';
      });
    }
  }

  Future<void> _createProduct() async {
    final created = await showLocalProductFormSheet(
      context: context,
      initialBarcode: _lastScanned,
      initialSku: _lastScanned,
    );
    if (created == true && _lastScanned != null) {
      await _lookup(_lastScanned!);
    }
  }

  Future<void> _confirm() async {
    final product = _product;
    if (product == null) return;

    final qty = double.tryParse(_qtyController.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) {
      setState(() => _error = 'Jumlah stok harus lebih dari 0');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(localInventoryRepositoryProvider).addStock(
            productId: product.id,
            quantity: qty,
            note: _noteController.text.trim().isEmpty
                ? 'Terima stok'
                : _noteController.text.trim(),
          );
      await ref.read(standaloneServiceProvider).refreshPosCatalog();
      ref.invalidate(localProductsProvider);
      ref.invalidate(localInventoryStatsProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final product = _product;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terima Stok',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isScanning ? null : _scan,
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_scanner),
            label: Text(_isScanning ? 'Membuka kamera...' : 'Scan Barcode / SKU'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.posGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (_lastScanned != null) ...[
            const SizedBox(height: 12),
            Text(
              'Kode: $_lastScanned',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
          if (product != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.posGreenLight,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('SKU: ${product.sku}'),
                    if (product.barcode != null) Text('Barcode: ${product.barcode}'),
                    const SizedBox(height: 4),
                    Text(
                      'Stok saat ini: ${product.stock.toStringAsFixed(0)} • '
                      '${Formatters.currency(product.basePrice)}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Jumlah ditambahkan',
                prefixIcon: Icon(Icons.add_circle_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _confirm,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tambah Stok'),
            ),
          ] else if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.warning)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _createProduct,
              icon: const Icon(Icons.add_box_outlined),
              label: const Text('Buat Produk Baru'),
            ),
          ],
        ],
      ),
    );
  }
}