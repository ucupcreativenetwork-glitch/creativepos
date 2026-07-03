import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/json_utils.dart';
import '../../../core/utils/media_url.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/skeleton_box.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/inventory_models.dart';
import '../providers/inventory_providers.dart';
import 'product_detail_screen.dart';
import 'product_form_sheet.dart';
import 'stock_movement_sheet.dart';
import 'stock_receive_sheet.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openStockFromRow(StockRow row, StockMovementAction action) async {
    final productId = parseJsonInt(row.product['id']);
    final warehouseId = parseJsonInt(row.warehouse['id']);
    final productName = row.product['name']?.toString() ?? 'Produk';

    final ok = await showStockMovementSheet(
      context: context,
      action: action,
      productId: productId,
      productName: productName,
      currentStockByWarehouse: {warehouseId: row.quantity},
      initialWarehouseId: warehouseId,
    );

    if (ok == true && mounted) {
      ref.invalidate(inventoryProductsProvider(InventoryQuery(search: _search)));
      ref.invalidate(inventoryStocksProvider(InventoryQuery(search: _search)));
      ref.invalidate(inventoryAlertsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil diperbarui')),
      );
    }
  }

  Future<void> _openAddProduct() async {
    final ok = await showProductFormSheet(context);
    if (ok == true && mounted) {
      ref.invalidate(inventoryProductsProvider(InventoryQuery(search: _search)));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil ditambahkan')),
      );
    }
  }

  Future<void> _openAddStock() async {
    final ok = await showInventoryStockReceiveSheet(context);
    if (ok == true && mounted) {
      ref.invalidate(inventoryProductsProvider(InventoryQuery(search: _search)));
      ref.invalidate(inventoryStocksProvider(InventoryQuery(search: _search)));
      ref.invalidate(inventoryAlertsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil diperbarui')),
      );
    }
  }

  Widget? _buildFab(AuthSession? session) {
    if (_tabs.index == 0 && sessionCan(session, 'inventory.create')) {
      return FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      );
    }

    if (_tabs.index == 1 && sessionCan(session, 'inventory.stock.adjust')) {
      return FloatingActionButton.extended(
        onPressed: _openAddStock,
        icon: const Icon(Icons.add_box_outlined),
        label: const Text('Tambah Stok'),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(serverUrlProvider);
    final session = ref.watch(authControllerProvider).session;
    final products = ref.watch(inventoryProductsProvider(InventoryQuery(search: _search)));
    final stocks = ref.watch(inventoryStocksProvider(InventoryQuery(search: _search)));
    final alerts = ref.watch(inventoryAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventori'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Produk'),
            Tab(text: 'Stok'),
            Tab(text: 'Alert'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(session),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk / SKU...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
              ),
              onChanged: (v) => setState(() => _search = v.trim()),
              onSubmitted: (v) => setState(() => _search = v.trim()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                products.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(count: 6),
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(
                      inventoryProductsProvider(InventoryQuery(search: _search)),
                    ),
                  ),
                  data: (result) {
                    final items = result.items as List<InventoryProduct>;
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: _search.isNotEmpty ? 'Produk tidak ditemukan' : 'Belum ada produk',
                        subtitle: _search.isNotEmpty
                            ? 'Coba kata kunci lain'
                            : sessionCan(session, 'inventory.create')
                                ? 'Tekan Tambah Produk untuk membuat produk baru'
                                : 'Belum ada produk di inventori',
                        actionLabel: _search.isEmpty &&
                                sessionCan(session, 'inventory.create')
                            ? 'Tambah Produk'
                            : null,
                        onAction: _search.isEmpty &&
                                sessionCan(session, 'inventory.create')
                            ? _openAddProduct
                            : null,
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(
                        inventoryProductsProvider(InventoryQuery(search: _search)),
                      ),
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final product = items[index];
                          final image = resolveMediaUrl(product.imageUrl, server);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  image.isNotEmpty ? NetworkImage(image) : null,
                              child: image.isEmpty
                                  ? const Icon(Icons.inventory_2_outlined, size: 18)
                                  : null,
                            ),
                            title: Text(product.name),
                            subtitle: Text('${product.sku} · Stok ${product.totalStock}'),
                            trailing: Text(Formatters.currency(product.basePrice)),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                  productId: product.id,
                                  productUuid: product.uuid.isNotEmpty
                                      ? product.uuid
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                stocks.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonList(count: 6),
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(
                      inventoryStocksProvider(InventoryQuery(search: _search)),
                    ),
                  ),
                  data: (result) {
                    final items = result.items as List<StockRow>;
                    if (items.isEmpty) {
                      return EmptyState(
                        icon: Icons.warehouse_outlined,
                        title: _search.isNotEmpty ? 'Stok tidak ditemukan' : 'Belum ada data stok',
                        subtitle: _search.isNotEmpty
                            ? 'Coba kata kunci lain'
                            : 'Data stok akan muncul setelah produk memiliki gudang',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(
                        inventoryStocksProvider(InventoryQuery(search: _search)),
                      ),
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final row = items[index];
                          return ListTile(
                            title: Text(row.product['name']?.toString() ?? '-'),
                            subtitle: Text(
                              '${row.warehouse['name'] ?? '-'} · SKU ${row.product['sku'] ?? ''}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      row.quantity.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: row.isLow
                                            ? AppColors.danger
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    if (row.isLow)
                                      const Text(
                                        'Menipis',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                  ],
                                ),
                                PopupMenuButton<StockMovementAction>(
                                  onSelected: (action) =>
                                      _openStockFromRow(row, action),
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: StockMovementAction.stockIn,
                                      child: Text('Tambah stok'),
                                    ),
                                    PopupMenuItem(
                                      value: StockMovementAction.stockOut,
                                      child: Text('Kurang stok'),
                                    ),
                                    PopupMenuItem(
                                      value: StockMovementAction.adjustment,
                                      child: Text('Sesuaikan stok'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                alerts.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(inventoryAlertsProvider),
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const EmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'Stok aman',
                        subtitle: 'Tidak ada peringatan stok menipis',
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(inventoryAlertsProvider),
                      child: ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final alert = items[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.warning_amber,
                              color: AppColors.warning,
                            ),
                            title: Text(alert.product['name']?.toString() ?? '-'),
                            subtitle: Text(alert.warehouse['name']?.toString() ?? '-'),
                            trailing: Text('-${alert.deficit.toStringAsFixed(0)}'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}