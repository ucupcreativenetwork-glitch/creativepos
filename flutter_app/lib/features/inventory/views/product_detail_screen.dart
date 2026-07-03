import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/inventory_repository.dart';
import '../models/inventory_models.dart';
import '../providers/inventory_providers.dart';
import 'stock_movement_sheet.dart';

class ProductDetailKey {
  const ProductDetailKey({required this.id, this.uuid});

  final int id;
  final String? uuid;

  @override
  bool operator ==(Object other) =>
      other is ProductDetailKey && other.id == id && other.uuid == uuid;

  @override
  int get hashCode => Object.hash(id, uuid);
}

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productUuid,
  });

  final int productId;
  final String? productUuid;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

final productDetailProvider = FutureProvider.autoDispose
    .family<InventoryProduct, ProductDetailKey>((ref, key) async {
  return ref.watch(inventoryRepositoryProvider).getProductDetail(
        id: key.id,
        uuid: key.uuid,
      );
});

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductDetailKey get _detailKey => ProductDetailKey(
        id: widget.productId,
        uuid: widget.productUuid,
      );

  Future<void> _openStockSheet(
    InventoryProduct product,
    StockMovementAction action,
  ) async {
    if (!product.trackStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk ini tidak melacak stok')),
      );
      return;
    }

    final stockMap = {
      for (final stock in product.stocks) stock.warehouseId: stock.quantity,
    };

    final ok = await showStockMovementSheet(
      context: context,
      action: action,
      productId: product.id,
      productName: product.name,
      currentStockByWarehouse: stockMap,
      initialWarehouseId: product.stocks.isNotEmpty
          ? product.stocks.first.warehouseId
          : null,
    );

    if (ok == true && mounted) {
      ref.invalidate(productDetailProvider(_detailKey));
      ref.invalidate(inventoryProductsProvider);
      ref.invalidate(inventoryStocksProvider);
      ref.invalidate(inventoryAlertsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil diperbarui')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: ref.watch(productDetailProvider(_detailKey)).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString().contains('Resource not found')
              ? 'Produk tidak ditemukan. Coba refresh daftar produk.'
              : e.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(_detailKey)),
        ),
        data: (product) {
          final image = resolveMediaUrl(product.imageUrl, server);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (image.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(image, height: 180, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text('SKU: ${product.sku}'),
              if (product.barcode != null) Text('Barcode: ${product.barcode}'),
              const SizedBox(height: 12),
              Text(
                Formatters.currency(product.basePrice),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('Stok total: ${product.totalStock}')),
                  Chip(label: Text('Min: ${product.minStock}')),
                  Chip(
                    label: Text(product.isActive ? 'Aktif' : 'Nonaktif'),
                  ),
                  Chip(
                    label: Text(
                      product.trackStock ? 'Lacak stok' : 'Tanpa lacak stok',
                    ),
                  ),
                ],
              ),
              if (product.stocks.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Stok per gudang',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...product.stocks.map(
                  (stock) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(stock.warehouseName ?? 'Gudang ${stock.warehouseId}'),
                    subtitle: stock.warehouseCode != null
                        ? Text(stock.warehouseCode!)
                        : null,
                    trailing: Text(
                      stock.quantity.toStringAsFixed(
                        stock.quantity.truncateToDouble() == stock.quantity ? 0 : 2,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (product.trackStock) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      _openStockSheet(product, StockMovementAction.stockIn),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Tambah Stok'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _openStockSheet(product, StockMovementAction.stockOut),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Kurang Stok'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      _openStockSheet(product, StockMovementAction.adjustment),
                  icon: const Icon(Icons.tune),
                  label: const Text('Sesuaikan Stok'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}