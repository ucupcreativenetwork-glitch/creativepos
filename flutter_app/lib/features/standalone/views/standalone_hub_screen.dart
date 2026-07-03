import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../models/local_product.dart';
import '../providers/standalone_providers.dart';
import 'local_product_form_sheet.dart';
import 'stock_receive_sheet.dart';

class StandaloneHubScreen extends ConsumerStatefulWidget {
  const StandaloneHubScreen({super.key});

  @override
  ConsumerState<StandaloneHubScreen> createState() => _StandaloneHubScreenState();
}

class _StandaloneHubScreenState extends ConsumerState<StandaloneHubScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _search = value.trim());
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(localProductsProvider);
    ref.invalidate(localInventoryStatsProvider);
    ref.invalidate(standaloneProfileProvider);
  }

  Future<void> _addProduct() async {
    final ok = await showLocalProductFormSheet(context: context);
    if (ok == true) await _refresh();
  }

  Future<void> _receiveStock() async {
    final ok = await showStockReceiveSheet(context);
    if (ok == true) await _refresh();
  }

  Future<void> _editProduct(LocalProduct product) async {
    final ok = await showLocalProductFormSheet(context: context, product: product);
    if (ok == true) await _refresh();
  }

  Future<void> _deleteProduct(LocalProduct product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus produk?'),
        content: Text('${product.name} akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(localInventoryRepositoryProvider).deleteProduct(product.id);
      await ref.read(standaloneServiceProvider).refreshPosCatalog();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(standaloneProfileProvider);
    final stats = ref.watch(localInventoryStatsProvider);
    final products = ref.watch(localProductsProvider(_search.isEmpty ? null : _search));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: AppColors.posGreen,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: profile.maybeWhen(
                  data: (p) => Text(
                    p?.businessName ?? 'Toko Mandiri',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  orElse: () => const Text('Toko Mandiri'),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.posGreen, AppColors.posGreenDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: stats.when(
                  data: (s) => _StatsRow(stats: s),
                  loading: () => const SizedBox(
                    height: 88,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: _refresh,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan Stok',
                        color: AppColors.posGreen,
                        onTap: _receiveStock,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_box_outlined,
                        label: 'Tambah Produk',
                        color: AppColors.primary,
                        onTap: _addProduct,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, SKU, atau barcode...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Daftar Produk',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            products.when(
              data: (list) {
                if (list.isEmpty) {
                  final isSearching = _search.isNotEmpty;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: isSearching
                          ? Icons.search_off
                          : Icons.inventory_2_outlined,
                      title: isSearching
                          ? 'Produk tidak ditemukan'
                          : 'Belum ada produk',
                      subtitle: isSearching
                          ? 'Coba kata kunci atau scan barcode lain'
                          : 'Tambah produk manual atau scan barcode untuk mulai.',
                      actionLabel: isSearching ? null : 'Tambah Produk',
                      onAction: isSearching ? null : _addProduct,
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final p = list[index];
                      return _ProductTile(
                        product: p,
                        onTap: () => _editProduct(p),
                        onDelete: () => _deleteProduct(p),
                      );
                    },
                    childCount: list.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorView(message: e.toString(), onRetry: _refresh),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final LocalInventoryStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Produk',
                value: '${stats.totalProducts}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Stok Rendah',
                value: '${stats.lowStockCount}',
                icon: Icons.warning_amber_outlined,
                accent: stats.lowStockCount > 0 ? AppColors.warning : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Nilai Stok',
                value: Formatters.compact(stats.totalStockValue),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Stok Masuk Hari Ini',
                value: stats.todayStockIn.toStringAsFixed(0),
                icon: Icons.trending_up,
                accent: AppColors.posGreenDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.posGreenDark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  final LocalProduct product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: product.isLowStock ? AppColors.warning.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          onLongPress: onDelete,
          leading: CircleAvatar(
            backgroundColor: product.isLowStock
                ? AppColors.warning.withValues(alpha: 0.15)
                : AppColors.posGreenLight,
            child: Icon(
              product.isLowStock ? Icons.warning_amber : Icons.inventory_2_outlined,
              color: product.isLowStock ? AppColors.warning : AppColors.posGreen,
              size: 20,
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            'SKU ${product.sku}'
            '${product.barcode != null ? ' • ${product.barcode}' : ''}'
            '${product.categoryName != null ? ' • ${product.categoryName}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(product.basePrice),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    product.trackStock
                        ? 'Stok ${product.stock.toStringAsFixed(0)}'
                        : 'Tanpa stok',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          product.isLowStock ? AppColors.warning : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.danger,
                tooltip: 'Hapus',
                onPressed: onDelete,
              ),
            ],
          ),
          isThreeLine: false,
        ),
      ),
    );
  }
}