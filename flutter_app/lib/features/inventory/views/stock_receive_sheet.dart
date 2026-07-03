import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../pos/views/barcode_scanner_screen.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_models.dart';
import '../providers/inventory_providers.dart';
import 'product_form_sheet.dart';
import 'stock_movement_sheet.dart';

Future<bool?> showInventoryStockReceiveSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const InventoryStockReceiveSheet(),
  );
}

class InventoryStockReceiveSheet extends ConsumerStatefulWidget {
  const InventoryStockReceiveSheet({super.key});

  @override
  ConsumerState<InventoryStockReceiveSheet> createState() =>
      _InventoryStockReceiveSheetState();
}

class _InventoryStockReceiveSheetState
    extends ConsumerState<InventoryStockReceiveSheet> {
  InventoryProduct? _product;
  var _isScanning = false;
  String? _error;
  String? _lastScanned;

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

    try {
      final product =
          await ref.read(inventoryRepositoryProvider).findByBarcode(code);
      if (!mounted) return;
      setState(() => _product = product);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _product = null;
        _error = 'Produk tidak ditemukan — buat produk baru?';
      });
    }
  }

  Future<void> _createProduct() async {
    final created = await showProductFormSheet(context);
    if (created == true && _lastScanned != null) {
      await _lookup(_lastScanned!);
    }
  }

  Future<void> _openStockIn() async {
    final product = _product;
    if (product == null) return;

    final ok = await showStockMovementSheet(
      context: context,
      action: StockMovementAction.stockIn,
      productId: product.id,
      productName: product.name,
      currentStockByWarehouse: {
        for (final stock in product.stocks) stock.warehouseId: stock.quantity,
      },
      initialWarehouseId:
          product.stocks.isNotEmpty ? product.stocks.first.warehouseId : null,
    );

    if (ok == true && mounted) {
      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(inventoryStocksProvider);
      ref.invalidate(inventoryAlertsProvider);
      Navigator.of(context).pop(true);
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
                  'Tambah Stok',
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
          Text(
            'Scan barcode produk atau cari dari daftar produk.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isScanning ? null : _scan,
            icon: _isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.qr_code_scanner),
            label: Text(_lastScanned == null ? 'Scan Barcode' : 'Scan Ulang'),
          ),
          if (product != null) ...[
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                child: Icon(Icons.inventory_2_outlined),
              ),
              title: Text(product.name),
              subtitle: Text('SKU ${product.sku} · Stok ${product.totalStock}'),
              trailing: Text(
                Formatters.currency(product.basePrice),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _openStockIn,
              icon: const Icon(Icons.add_box_outlined),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.posGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: const Text('Tambah Stok'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _createProduct,
              child: const Text('Buat Produk Baru'),
            ),
          ],
        ],
      ),
    );
  }
}