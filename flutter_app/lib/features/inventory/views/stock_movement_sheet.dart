import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/inventory_repository.dart';
import '../models/inventory_models.dart';

enum StockMovementAction { stockIn, stockOut, adjustment }

class StockMovementSheet extends ConsumerStatefulWidget {
  const StockMovementSheet({
    super.key,
    required this.action,
    required this.productId,
    required this.productName,
    this.currentStockByWarehouse = const {},
    this.initialWarehouseId,
  });

  final StockMovementAction action;
  final int productId;
  final String productName;
  final Map<int, double> currentStockByWarehouse;
  final int? initialWarehouseId;

  @override
  ConsumerState<StockMovementSheet> createState() => _StockMovementSheetState();
}

class _StockMovementSheetState extends ConsumerState<StockMovementSheet> {
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  List<Warehouse> _warehouses = [];
  int? _warehouseId;
  var _loadingWarehouses = true;
  var _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehouses = await ref.read(inventoryRepositoryProvider).getWarehouses();
      if (!mounted) return;
      final ids = warehouses.map((w) => w.id).toSet();
      final initialId = widget.initialWarehouseId;
      final resolvedId = initialId != null && ids.contains(initialId)
          ? initialId
          : (warehouses.isNotEmpty ? warehouses.first.id : null);

      setState(() {
        _warehouses = warehouses;
        _warehouseId = resolvedId;
        _loadingWarehouses = false;
        _prefillQuantity();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loadingWarehouses = false;
      });
    }
  }

  void _prefillQuantity() {
    if (widget.action != StockMovementAction.adjustment || _warehouseId == null) {
      if (_quantityController.text.isEmpty) {
        _quantityController.text = '1';
      }
      return;
    }

    final current = widget.currentStockByWarehouse[_warehouseId!] ?? 0;
    _quantityController.text = current.toStringAsFixed(
      current.truncateToDouble() == current ? 0 : 2,
    );
  }

  double? _currentStock() {
    if (_warehouseId == null) return null;
    return widget.currentStockByWarehouse[_warehouseId!] ?? 0;
  }

  String get _title => switch (widget.action) {
        StockMovementAction.stockIn => 'Tambah Stok',
        StockMovementAction.stockOut => 'Kurang Stok',
        StockMovementAction.adjustment => 'Sesuaikan Stok',
      };

  String get _quantityLabel => switch (widget.action) {
        StockMovementAction.adjustment => 'Jumlah stok baru',
        _ => 'Jumlah',
      };

  Future<void> _submit() async {
    final warehouseId = _warehouseId;
    if (warehouseId == null) {
      setState(() => _error = 'Pilih gudang terlebih dahulu');
      return;
    }

    final quantity = double.tryParse(_quantityController.text.replaceAll(',', '.'));
    if (quantity == null) {
      setState(() => _error = 'Jumlah tidak valid');
      return;
    }

    if (widget.action == StockMovementAction.adjustment) {
      if (quantity < 0) {
        setState(() => _error = 'Stok baru tidak boleh negatif');
        return;
      }
    } else if (quantity <= 0) {
      setState(() => _error = 'Jumlah harus lebih dari 0');
      return;
    }

    if (widget.action == StockMovementAction.stockOut) {
      final current = _currentStock() ?? 0;
      if (quantity > current) {
        setState(() => _error = 'Stok tidak mencukupi (tersedia: $current)');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final notes = _notesController.text.trim();

      switch (widget.action) {
        case StockMovementAction.stockIn:
          await repo.stockIn(
            productId: widget.productId,
            warehouseId: warehouseId,
            quantity: quantity,
            notes: notes.isEmpty ? null : notes,
          );
        case StockMovementAction.stockOut:
          await repo.stockOut(
            productId: widget.productId,
            warehouseId: warehouseId,
            quantity: quantity,
            notes: notes.isEmpty ? null : notes,
          );
        case StockMovementAction.adjustment:
          await repo.adjustStock(
            productId: widget.productId,
            warehouseId: warehouseId,
            quantity: quantity,
            notes: notes.isEmpty ? null : notes,
          );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final currentStock = _currentStock();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            widget.productName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (_loadingWarehouses)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_warehouses.isEmpty)
            const Text('Belum ada gudang aktif. Tambahkan gudang di pengaturan web.')
          else ...[
            DropdownButtonFormField<int>(
              key: ValueKey(_warehouseId),
              initialValue: _warehouseId,
              decoration: const InputDecoration(
                labelText: 'Gudang',
                isDense: true,
              ),
              items: _warehouses
                  .map(
                    (w) => DropdownMenuItem<int>(
                      value: w.id,
                      child: Text('${w.name} (${w.code})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _warehouseId = v);
                _prefillQuantity();
              },
            ),
            if (currentStock != null) ...[
              const SizedBox(height: 8),
              Text(
                'Stok saat ini di gudang ini: ${currentStock.toStringAsFixed(currentStock.truncateToDouble() == currentStock ? 0 : 2)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _quantityLabel,
                hintText: widget.action == StockMovementAction.adjustment
                    ? 'Masukkan total stok baru'
                    : 'Contoh: 5',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting || _warehouses.isEmpty ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<bool?> showStockMovementSheet({
  required BuildContext context,
  required StockMovementAction action,
  required int productId,
  required String productName,
  Map<int, double> currentStockByWarehouse = const {},
  int? initialWarehouseId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => StockMovementSheet(
      action: action,
      productId: productId,
      productName: productName,
      currentStockByWarehouse: currentStockByWarehouse,
      initialWarehouseId: initialWarehouseId,
    ),
  );
}