import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/local_product.dart';
import '../providers/standalone_providers.dart';

Future<bool?> showLocalProductFormSheet({
  required BuildContext context,
  LocalProduct? product,
  String? initialBarcode,
  String? initialSku,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => LocalProductFormSheet(
      product: product,
      initialBarcode: initialBarcode,
      initialSku: initialSku,
    ),
  );
}

class LocalProductFormSheet extends ConsumerStatefulWidget {
  const LocalProductFormSheet({
    super.key,
    this.product,
    this.initialBarcode,
    this.initialSku,
  });

  final LocalProduct? product;
  final String? initialBarcode;
  final String? initialSku;

  @override
  ConsumerState<LocalProductFormSheet> createState() =>
      _LocalProductFormSheetState();
}

class _LocalProductFormSheetState extends ConsumerState<LocalProductFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _minStockController;
  late final TextEditingController _categoryController;
  late bool _trackStock;
  var _isSaving = false;
  String? _error;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(
      text: p?.sku ?? widget.initialSku ?? '',
    );
    _barcodeController = TextEditingController(
      text: p?.barcode ?? widget.initialBarcode ?? '',
    );
    _priceController = TextEditingController(
      text: p != null ? p.basePrice.toStringAsFixed(0) : '',
    );
    _stockController = TextEditingController(
      text: p != null ? p.stock.toStringAsFixed(0) : '0',
    );
    _minStockController = TextEditingController(
      text: p != null ? '${p.minStock}' : '0',
    );
    _categoryController = TextEditingController(text: p?.categoryName ?? '');
    _trackStock = p?.trackStock ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final sku = _skuController.text.trim();
    if (name.isEmpty || sku.isEmpty) {
      setState(() => _error = 'Nama dan SKU wajib diisi');
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0;
    final stock = double.tryParse(_stockController.text.replaceAll(',', '.')) ?? 0;
    final minStock = int.tryParse(_minStockController.text) ?? 0;
    final barcode = _barcodeController.text.trim();
    final category = _categoryController.text.trim();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final repo = ref.read(localInventoryRepositoryProvider);
      if (_isEdit) {
        await repo.updateProduct(
          widget.product!.copyWith(
            name: name,
            sku: sku,
            barcode: barcode.isEmpty ? null : barcode,
            basePrice: price,
            stock: stock,
            minStock: minStock,
            trackStock: _trackStock,
            categoryName: category.isEmpty ? null : category,
          ),
        );
      } else {
        await repo.createProduct(
          LocalProduct.draft(
            name: name,
            sku: sku,
            barcode: barcode.isEmpty ? null : barcode,
            basePrice: price,
            stock: stock,
          ).copyWith(
            minStock: minStock,
            trackStock: _trackStock,
            categoryName: category.isEmpty ? null : category,
          ),
        );
      }

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
                  _isEdit ? 'Edit Produk' : 'Tambah Produk',
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
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nama Produk *',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _skuController,
                  decoration: const InputDecoration(
                    labelText: 'SKU *',
                    prefixIcon: Icon(Icons.tag_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode',
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual',
                    prefixText: 'Rp ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!_isEdit)
            TextField(
              controller: _stockController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Stok Awal',
                prefixIcon: Icon(Icons.layers_outlined),
              ),
            ),
          if (_isEdit) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Stok Minimum',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lacak stok', style: TextStyle(fontSize: 13)),
                  value: _trackStock,
                  onChanged: (v) => setState(() => _trackStock = v),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.posGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Produk'),
          ),
        ],
      ),
    );
  }
}