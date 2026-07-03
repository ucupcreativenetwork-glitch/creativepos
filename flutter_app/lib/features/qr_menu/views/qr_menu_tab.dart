import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/outlet_utils.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/outlet_dropdown.dart';
import '../../auth/providers/auth_providers.dart';
import '../../pos/providers/pos_providers.dart';
import '../../pos/views/barcode_scanner_screen.dart';
import '../models/qr_menu_models.dart';
import '../data/public_menu_repository.dart';
import '../providers/qr_cart_notifier.dart';
import '../providers/qr_menu_providers.dart';
import 'qr_menu_cart_sheet.dart';

class QrMenuTab extends ConsumerStatefulWidget {
  const QrMenuTab({super.key});

  @override
  ConsumerState<QrMenuTab> createState() => _QrMenuTabState();
}

class _QrMenuTabState extends ConsumerState<QrMenuTab> {
  int? _outletId;
  String? _tableToken;
  int? _categoryFilter;

  String? _resolveTenantSlug() {
    return ref.read(authControllerProvider).session?.tenant?.slug;
  }

  String? _resolveOutletSlug(List<Map<String, dynamic>> outlets, int? outletId) {
    final outlet = findOutletById(outlets, outletId);
    if (outlet == null) return null;
    final code = outlet['code'] as String? ?? '';
    return code.toLowerCase();
  }

  Future<void> _scanTableQr() async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (token == null) return;
    setState(() => _tableToken = token);
    ref.read(qrCartProvider.notifier).setTableToken(token);
  }

  Future<void> _staffAction({
    required String tenantSlug,
    required String outletSlug,
    required bool isBill,
  }) async {
    final token = _tableToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scan QR meja terlebih dahulu')),
      );
      return;
    }
    try {
      final repo = ref.read(publicMenuRepositoryProvider);
      if (isBill) {
        await repo.requestBill(
          tenantSlug: tenantSlug,
          outletSlug: outletSlug,
          tableToken: token,
        );
      } else {
        await repo.callWaiter(
          tenantSlug: tenantSlug,
          outletSlug: outletSlug,
          tableToken: token,
        );
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isBill ? 'Permintaan tagihan terkirim' : 'Pelayan dipanggil',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _openCart(String tenantSlug, String outletSlug) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => QrMenuCartSheet(
        tenantSlug: tenantSlug,
        outletSlug: outletSlug,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantSlug = _resolveTenantSlug();
    final outletsAsync = ref.watch(settingsOutletsProvider);
    final cart = ref.watch(qrCartProvider);

    return outletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(settingsOutletsProvider),
      ),
      data: (outlets) {
        final outletList = outlets.cast<Map<String, dynamic>>().toList();
        final resolvedOutletId = resolveOutletId(outletList, _outletId);
        if (resolvedOutletId != null && resolvedOutletId != _outletId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _outletId = resolvedOutletId);
          });
        }

        if (tenantSlug == null) {
          return const Center(child: Text('Tenant tidak tersedia'));
        }

        final outletSlug = _resolveOutletSlug(outletList, resolvedOutletId);
        if (outletSlug == null) {
          return const Center(child: Text('Pilih outlet terlebih dahulu'));
        }

        final menu = ref.watch(
          publicMenuProvider(
            QrMenuQuery(
              tenantSlug: tenantSlug,
              outletSlug: outletSlug,
              tableToken: _tableToken,
            ),
          ),
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutletDropdown(
                      outlets: outletList,
                      value: resolvedOutletId,
                      onChanged: (v) => setState(() {
                        _outletId = v;
                        _tableToken = null;
                        ref.read(qrCartProvider.notifier).setTableToken(null);
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _scanTableQr,
                    icon: const Icon(Icons.table_bar),
                    tooltip: 'Scan QR Meja',
                  ),
                  if (cart.itemCount > 0)
                    Badge(
                      label: Text('${cart.itemCount}'),
                      child: IconButton.filled(
                        onPressed: () => _openCart(tenantSlug, outletSlug),
                        icon: const Icon(Icons.shopping_cart),
                      ),
                    ),
                ],
              ),
            ),
            if (_tableToken != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.table_bar, size: 18),
                      label: Text('Meja aktif · $_tableToken'),
                      onDeleted: () {
                        setState(() => _tableToken = null);
                        ref.read(qrCartProvider.notifier).setTableToken(null);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _staffAction(
                              tenantSlug: tenantSlug,
                              outletSlug: outletSlug,
                              isBill: false,
                            ),
                            icon: const Icon(Icons.room_service_outlined),
                            label: const Text('Panggil Pelayan'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () => _staffAction(
                              tenantSlug: tenantSlug,
                              outletSlug: outletSlug,
                              isBill: true,
                            ),
                            icon: const Icon(Icons.receipt_long_outlined),
                            label: const Text('Minta Tagihan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Expanded(
              child: menu.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(
                    publicMenuProvider(
                      QrMenuQuery(
                        tenantSlug: tenantSlug,
                        outletSlug: outletSlug,
                        tableToken: _tableToken,
                      ),
                    ),
                  ),
                ),
                data: (data) => _MenuBody(
                  menu: data,
                  categoryFilter: _categoryFilter,
                  onCategoryChanged: (v) =>
                      setState(() => _categoryFilter = v),
                  onAdd: (product) {
                    HapticFeedback.lightImpact();
                    ref.read(qrCartProvider.notifier).addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} ditambahkan'),
                        duration: const Duration(milliseconds: 900),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  showPrices: data.settings.showPrices,
                  allowOrder: data.settings.allowGuestOrder,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuBody extends StatelessWidget {
  const _MenuBody({
    required this.menu,
    required this.categoryFilter,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.showPrices,
    required this.allowOrder,
  });

  final PublicMenuData menu;
  final int? categoryFilter;
  final ValueChanged<int?> onCategoryChanged;
  final void Function(PublicMenuProduct product) onAdd;
  final bool showPrices;
  final bool allowOrder;

  @override
  Widget build(BuildContext context) {
    final products = categoryFilter == null
        ? menu.products
        : menu.products
            .where((p) => p.categoryId == categoryFilter)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (menu.settings.welcomeMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Text(
              menu.settings.welcomeMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        if (menu.table != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Chip(
              avatar: const Icon(Icons.table_bar, size: 16),
              label: Text(
                'Meja ${menu.table!.tableNumber}${menu.table!.area != null ? ' · ${menu.table!.area}' : ''}',
              ),
            ),
          ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              FilterChip(
                label: const Text('Semua'),
                selected: categoryFilter == null,
                onSelected: (_) => onCategoryChanged(null),
              ),
              ...menu.categories.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(c.name),
                    selected: categoryFilter == c.id,
                    onSelected: (_) => onCategoryChanged(c.id),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('Menu kosong'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Material(
                      elevation: 1,
                      borderRadius: BorderRadius.circular(12),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: allowOrder ? () => onAdd(product) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.posGreenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    color: AppColors.posGreen,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              if (product.categoryName != null)
                                Text(
                                  product.categoryName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const Spacer(),
                              Row(
                                children: [
                                  if (showPrices)
                                    Expanded(
                                      child: Text(
                                        Formatters.currency(product.basePrice),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.posGreenDark,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  if (allowOrder)
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.posGreen,
                                      child: const Icon(
                                        Icons.add,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}