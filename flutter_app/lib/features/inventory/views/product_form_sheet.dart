import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_models.dart';
import '../providers/inventory_providers.dart';

Future<bool?> showProductFormSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const ProductFormSheet(),
  );
}

class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key});

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');

  List<InventoryCategory> _categories = [];
  int? _categoryId;
  var _trackStock = true;
  var _loadingCategories = true;
  var _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories =
          await ref.read(inventoryRepositoryProvider).getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
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

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ref.read(inventoryRepositoryProvider).createProduct(
            name: name,
            sku: sku,
            basePrice: price,
            barcode: barcode.isEmpty ? null : barcode,
            categoryId: _categoryId,
            minStock: minStock,
            trackStock: _trackStock,
            initialStock: _trackStock ? stock : 0,
          );

      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(inventoryStocksProvider);
      ref.invalidate(inventoryAlertsProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = e.toString();
      });
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
                  'Tambah Produk',
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
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Harga Jual *',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingCategories)
            const LinearProgressIndicator()
          else if (_categories.isNotEmpty)
            DropdownButtonFormField<int?>(
              key: ValueKey(_categoryId),
              initialValue: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tanpa kategori'),
                ),
                ..._categories.map(
                  (cat) => DropdownMenuItem<int>(
                    value: cat.id,
                    child: Text(cat.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _stockController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Stok Awal',
              prefixIcon: Icon(Icons.layers_outlined),
            ),
          ),
          const SizedBox(height: 12),
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
                : const Text('Simpan Produk'),
          ),
        ],
      ),
    );
  }
}