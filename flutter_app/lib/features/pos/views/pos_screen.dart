import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/outlet_utils.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_bootstrap_service.dart';
import '../../../services/offline_cache_service.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/outlet_dropdown.dart';
import '../../auth/providers/auth_providers.dart';
import '../../standalone/providers/standalone_providers.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';
import '../providers/cart_notifier.dart';
import '../providers/pos_providers.dart';
import 'barcode_scanner_screen.dart';
import 'checkout_sheet.dart';
import '../../../shared/widgets/empty_state.dart';
import 'cart_sheet.dart';
import 'held_bills_sheet.dart';
import 'modifier_sheet.dart';
import '../../settings/views/receipt_template_screen.dart';
import 'shift_close_sheet.dart';
import 'shift_open_sheet.dart';
import 'member_picker_sheet.dart';
import 'transaction_receipt_sheet.dart';
import 'transactions_screen.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  int? _categoryId;
  String _search = '';
  int? _outletId;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapPos());
  }

  Future<void> _bootstrapPos() async {
    final isStandalone =
        ref.read(authControllerProvider).status == AuthStatus.standalone;

    if (isStandalone) {
      await ref.read(standaloneServiceProvider).refreshPosCatalog();
    } else {
      final bootstrap = ref.read(offlineBootstrapServiceProvider);
      if (!await bootstrap.hasMinimumPosData()) {
        await bootstrap.warmCache();
      }
    }

    if (mounted) {
      ref.invalidate(settingsOutletsProvider);
      ref.invalidate(posCatalogProvider(PosCatalogQuery()));
      await _ensureShift();
    }
  }

  void _syncOutletSelection(List<Map<String, dynamic>> outletList) {
    final resolved = resolveOutletId(
      outletList,
      _outletId ?? ref.read(selectedOutletIdProvider),
    );
    if (resolved == null) return;

    final changed = _outletId != resolved ||
        ref.read(selectedOutletIdProvider) != resolved;

    if (_outletId != resolved) {
      setState(() => _outletId = resolved);
    }
    if (ref.read(selectedOutletIdProvider) != resolved) {
      ref.read(selectedOutletIdProvider.notifier).state = resolved;
      unawaited(ref.read(authRepositoryProvider).saveSelectedOutletId(resolved));
    }
    if (changed) {
      _ensureShift();
    }
  }

  Future<void> _ensureShift() async {
    final outletId = _outletId ?? ref.read(selectedOutletIdProvider);
    if (outletId == null) return;

    final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
          ref.read(apiBaseUrlProvider),
        );
    if (!serverUp) {
      final cached = await ref.read(offlineCacheServiceProvider).loadShift(outletId);
      if (cached != null && cached.isOpen) return;
      if (mounted) {
        await showShiftOpenSheet(context: context, outletId: outletId);
      }
      return;
    }

    try {
      final shift = await ref.read(posRepositoryProvider).getCurrentShift(
            outletId: outletId,
          );
      if (!mounted || shift != null) return;
      await showShiftOpenSheet(context: context, outletId: outletId);
    } catch (_) {}
  }

  Future<void> _openShift(int outletId) async {
    final opened = await showShiftOpenSheet(
      context: context,
      outletId: outletId,
    );
    if (opened == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift dibuka')),
      );
    }
  }

  Future<void> _closeShift(int outletId, Shift shift) async {
    final closed = await showShiftCloseSheet(
      context: context,
      outletId: outletId,
      shift: shift,
    );
    if (closed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shift ditutup')),
      );
    }
  }

  Future<void> _newTransaction() async {
    final cart = ref.read(cartProvider);
    if (cart.items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siap untuk transaksi baru')),
        );
      }
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaksi Baru'),
        content: const Text('Keranjang akan dikosongkan. Lanjutkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Kosongkan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(cartProvider.notifier).clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keranjang dikosongkan')),
        );
      }
    }
  }

  Future<void> _addProduct(PosProduct product) async {
    HapticFeedback.lightImpact();
    if (product.trackStock && product.totalStock <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} stok habis')),
        );
      }
      return;
    }
    if (product.modifierGroups.isNotEmpty) {
      final modifiers = await showModalBottomSheet<List<SelectedModifier>>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => ModifierSheet(
          product: product,
          onConfirm: (mods) => Navigator.pop(ctx, mods),
        ),
      );
      if (modifiers == null) return;
      ref.read(cartProvider.notifier).addProduct(product, modifiers: modifiers);
      return;
    }
    ref.read(cartProvider.notifier).addProduct(product);
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;

    final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
          ref.read(apiBaseUrlProvider),
        );

    PosProduct? product;
    if (serverUp) {
      try {
        product = await ref.read(posRepositoryProvider).findProductByBarcode(code);
      } catch (_) {}
    }
    product ??=
        await ref.read(offlineCacheServiceProvider).findProductByBarcode(code);

    if (product != null) {
      await _addProduct(product);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak ditemukan: $code')),
      );
    }
  }

  Future<void> _holdBill() async {
    final cart = ref.read(cartProvider);
    final outletId = _outletId;
    if (outletId == null || cart.items.isEmpty) return;

    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tahan Bill'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama referensi'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok != true) {
      nameController.dispose();
      return;
    }

    try {
      final memberId = ref.read(cartProvider).memberId;
      await ref.read(posRepositoryProvider).holdBill({
        'outlet_id': outletId,
        if (memberId != null) 'member_id': memberId,
        'reference_name': nameController.text.trim().isEmpty
            ? 'Bill ${DateTime.now().hour}:${DateTime.now().minute}'
            : nameController.text.trim(),
        'items': cart.items
            .map(
              (item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'unit_price': item.unitPrice,
                'product_name': item.product.name,
                'sku': item.product.sku,
                if (item.modifiers.isNotEmpty)
                  'modifiers': item.modifiers
                      .map(
                        (m) => {
                          'modifier_id': m.modifierId,
                          'name': m.name,
                          'price_adjustment': m.priceAdjustment,
                        },
                      )
                      .toList(),
              },
            )
            .toList(),
      });
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(heldBillsProvider(outletId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill ditahan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tahan bill: $e')),
        );
      }
    } finally {
      nameController.dispose();
    }
  }

  Future<void> _openCheckout(List<PaymentMethod> methods, int? shiftId) async {
    final outletId = _outletId;
    if (outletId == null) return;

    final isStandalone =
        ref.read(authControllerProvider).status == AuthStatus.standalone;
    final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
          ref.read(apiBaseUrlProvider),
        );
    if (!isStandalone && serverUp && shiftId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buka shift terlebih dahulu')),
        );
      }
      return;
    }
    if (methods.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isStandalone
                  ? 'Belum ada produk — tambah di tab Toko dulu'
                  : serverUp
                      ? 'Metode pembayaran belum tersedia'
                      : 'Buka POS sekali saat server terhubung untuk mengunduh katalog',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CheckoutSheet(
        outletId: outletId,
        shiftId: shiftId,
        paymentMethods: methods,
        onSuccess: (info) {
          showTransactionReceiptSheet(context: context, info: info);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final auth = ref.watch(authControllerProvider);
    final isStandalone = auth.status == AuthStatus.standalone;
    final server = ref.watch(serverUrlProvider);
    final session = auth.session;
    final outlets = ref.watch(settingsOutletsProvider);
    final catalogQuery = PosCatalogQuery(search: _search, categoryId: _categoryId);
    final catalog = ref.watch(posCatalogProvider(catalogQuery));
    final isCashierLayout = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      backgroundColor: AppColors.posProductBg,
      body: outlets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(settingsOutletsProvider),
        ),
        data: (rawOutletList) {
          final outletList =
              rawOutletList.cast<Map<String, dynamic>>().toList();
          final preferredOutletId =
              _outletId ?? ref.watch(selectedOutletIdProvider);
          final resolvedOutletId = resolveOutletId(outletList, preferredOutletId);

          if (outletList.isNotEmpty && resolvedOutletId != null) {
            final needsSync = resolvedOutletId != _outletId ||
                ref.read(selectedOutletIdProvider) != resolvedOutletId;
            if (needsSync) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _syncOutletSelection(outletList);
              });
            }
          }

          if (outletList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isStandalone
                          ? 'Profil toko belum siap. Buka ulang aplikasi atau atur di Pengaturan.'
                          : 'Data outlet belum tersedia di perangkat.',
                      textAlign: TextAlign.center,
                    ),
                    if (!isStandalone) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await ref
                              .read(offlineBootstrapServiceProvider)
                              .warmCache(force: true);
                          ref.invalidate(settingsOutletsProvider);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Data outlet & katalog diunduh'
                                      : 'Gagal — pastikan server terhubung lalu coba lagi',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Unduh Data POS'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          final outletId = resolvedOutletId;
          final shift = outletId != null
              ? ref.watch(currentShiftProvider(outletId))
              : const AsyncValue<Shift?>.data(null);

          return catalog.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () async {
                await ref
                    .read(offlineBootstrapServiceProvider)
                    .warmCache(force: true);
                ref.invalidate(posCatalogProvider(catalogQuery));
              },
            ),
            data: (data) {
              void checkout() => _openCheckout(
                    data.paymentMethods,
                    shift.valueOrNull?.serverShiftId,
                  );

              final productArea = _MekariProductArea(
                outletList: outletList,
                outletId: outletId,
                shift: shift,
                categories: data.categories,
                products: data.products,
                server: server,
                cashierName: session?.user.name,
                isStandalone: isStandalone,
                businessName: session?.tenant?.name,
                searchController: _searchController,
                categoryId: _categoryId,
                onSearchChanged: _onSearchChanged,
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => _search = '');
                },
                onCategorySelected: (id) => setState(() => _categoryId = id),
                onOutletChanged: (v) {
                  setState(() => _outletId = v);
                  ref.read(selectedOutletIdProvider.notifier).state = v;
                  if (v != null) {
                    unawaited(
                      ref.read(authRepositoryProvider).saveSelectedOutletId(v),
                    );
                  }
                  ref.invalidate(currentShiftProvider(v));
                  _ensureShift();
                },
                onOpenShift: outletId != null ? () => _openShift(outletId) : null,
                onCloseShift: outletId != null
                    ? (s) => _closeShift(outletId, s)
                    : null,
                onRetryShift: outletId != null
                    ? () => ref.invalidate(currentShiftProvider(outletId))
                    : null,
                onNewTransaction: _newTransaction,
                onScan: _scanBarcode,
                onHistory: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionsScreen(outletId: _outletId),
                  ),
                ),
                onHeldBills: !isStandalone && _outletId != null
                    ? () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => HeldBillsSheet(outletId: _outletId!),
                        )
                    : null,
                onReceiptSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ReceiptTemplateScreen(),
                  ),
                ),
                onProductTap: _addProduct,
                isWide: isCashierLayout,
                hasSearch: _search.isNotEmpty,
              );

              final cartPanel = _MekariCartPanel(
                onCheckout: checkout,
                onHold: _holdBill,
                onNewTransaction: _newTransaction,
                showMember: !isStandalone,
                showHold: !isStandalone,
              );

              if (isCashierLayout) {
                return Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: productArea),
                          const VerticalDivider(width: 1, thickness: 1),
                          SizedBox(width: 380, child: cartPanel),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(child: productArea),
                  _MekariMobilePayBar(
                    itemCount: cart.itemCount,
                    subtotal: cart.subtotal,
                    onTapCart: () => showCartSheet(
                      context: context,
                      onCheckout: checkout,
                      onHold: isStandalone ? () {} : _holdBill,
                      showHold: !isStandalone,
                    ),
                    onCheckout: checkout,
                    onHold: isStandalone ? () {} : _holdBill,
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MekariProductArea extends StatelessWidget {
  const _MekariProductArea({
    required this.outletList,
    required this.outletId,
    required this.shift,
    required this.categories,
    required this.products,
    required this.server,
    required this.cashierName,
    required this.searchController,
    required this.categoryId,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategorySelected,
    required this.onOutletChanged,
    required this.onOpenShift,
    required this.onCloseShift,
    required this.onRetryShift,
    required this.onNewTransaction,
    required this.onScan,
    required this.onHistory,
    required this.onHeldBills,
    required this.onReceiptSettings,
    required this.onProductTap,
    required this.isWide,
    required this.hasSearch,
    this.isStandalone = false,
    this.businessName,
  });

  final List<Map<String, dynamic>> outletList;
  final int? outletId;
  final AsyncValue<Shift?> shift;
  final List<PosCategory> categories;
  final List<PosProduct> products;
  final String? server;
  final String? cashierName;
  final bool isStandalone;
  final String? businessName;
  final TextEditingController searchController;
  final int? categoryId;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<int?> onCategorySelected;
  final ValueChanged<int?> onOutletChanged;
  final VoidCallback? onOpenShift;
  final void Function(Shift shift)? onCloseShift;
  final VoidCallback? onRetryShift;
  final VoidCallback onNewTransaction;
  final VoidCallback onScan;
  final VoidCallback onHistory;
  final VoidCallback? onHeldBills;
  final VoidCallback onReceiptSettings;
  final Future<void> Function(PosProduct) onProductTap;
  final bool isWide;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    final cols = isWide ? 4 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MekariPosHeader(
          outletList: outletList,
          outletId: outletId,
          shift: shift,
          cashierName: cashierName,
          isStandalone: isStandalone,
          businessName: businessName,
          onOutletChanged: onOutletChanged,
          onOpenShift: onOpenShift,
          onCloseShift: onCloseShift,
          onRetryShift: onRetryShift,
          onNewTransaction: onNewTransaction,
          onScan: onScan,
          onHistory: onHistory,
          onHeldBills: onHeldBills,
          onReceiptSettings: onReceiptSettings,
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari nama produk atau SKU...',
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.posGreen),
              suffixIcon: hasSearch
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClearSearch,
                    )
                  : IconButton(
                      icon: const Icon(Icons.qr_code_scanner, size: 22),
                      color: AppColors.posGreen,
                      onPressed: onScan,
                      tooltip: 'Scan barcode',
                    ),
              filled: true,
              fillColor: AppColors.posCartBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: onSearchChanged,
            onSubmitted: onSearchChanged,
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _MekariCategoryChip(
                label: 'Semua',
                selected: categoryId == null,
                onTap: () => onCategorySelected(null),
              ),
              ...categories.map(
                (cat) => _MekariCategoryChip(
                  label: cat.name,
                  selected: categoryId == cat.id,
                  onTap: () => onCategorySelected(cat.id),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: hasSearch || categoryId != null
                      ? 'Produk tidak ditemukan'
                      : isStandalone
                          ? 'Belum ada produk'
                          : 'Belum ada produk POS',
                  subtitle: hasSearch || categoryId != null
                      ? 'Coba kata kunci atau kategori lain'
                      : isStandalone
                          ? 'Buka tab Toko untuk tambah produk atau scan barcode'
                          : 'Aktifkan "Tampil di POS" di pengaturan web',
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isWide ? 0.88 : 0.78,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _MekariProductCard(
                      product: product,
                      server: server,
                      onTap: () => onProductTap(product),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MekariPosHeader extends StatelessWidget {
  const _MekariPosHeader({
    required this.outletList,
    required this.outletId,
    required this.shift,
    required this.cashierName,
    this.isStandalone = false,
    this.businessName,
    required this.onOutletChanged,
    required this.onOpenShift,
    required this.onCloseShift,
    required this.onRetryShift,
    required this.onNewTransaction,
    required this.onScan,
    required this.onHistory,
    required this.onHeldBills,
    required this.onReceiptSettings,
  });

  final List<Map<String, dynamic>> outletList;
  final int? outletId;
  final AsyncValue<Shift?> shift;
  final String? cashierName;
  final bool isStandalone;
  final String? businessName;
  final ValueChanged<int?> onOutletChanged;
  final VoidCallback? onOpenShift;
  final void Function(Shift shift)? onCloseShift;
  final VoidCallback? onRetryShift;
  final VoidCallback onNewTransaction;
  final VoidCallback onScan;
  final VoidCallback onHistory;
  final VoidCallback? onHeldBills;
  final VoidCallback onReceiptSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.posGreen,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.point_of_sale,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mesin Kasir',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          cashierName ?? 'Kasir',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (outletId != null)
                    shift.when(
                      data: (s) {
                        final isOpen = s?.isOpen == true;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HeaderChip(
                              icon: isOpen ? Icons.lock_open : Icons.lock,
                              label: isOpen ? 'Shift Aktif' : 'Shift Tutup',
                              onTap: isOpen
                                  ? () => onCloseShift?.call(s!)
                                  : onOpenShift,
                            ),
                            const SizedBox(width: 6),
                            _HeaderIconBtn(
                              icon: Icons.add_circle_outline,
                              tooltip: 'Transaksi Baru',
                              onTap: onNewTransaction,
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      error: (_, __) => _HeaderIconBtn(
                        icon: Icons.refresh,
                        tooltip: 'Muat ulang shift',
                        onTap: onRetryShift,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isStandalone
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.storefront,
                                    size: 18,
                                    color: AppColors.posGreenDark,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      businessName ?? 'Toko Mandiri',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : OutletDropdown(
                              outlets: outletList,
                              value: outletId,
                              onChanged: onOutletChanged,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _HeaderIconBtn(
                    icon: Icons.qr_code_scanner,
                    tooltip: 'Scan',
                    onTap: onScan,
                    light: true,
                  ),
                  _HeaderIconBtn(
                    icon: Icons.history,
                    tooltip: 'Riwayat',
                    onTap: onHistory,
                    light: true,
                  ),
                  if (onHeldBills != null)
                    _HeaderIconBtn(
                      icon: Icons.pause_circle_outline,
                      tooltip: 'Bill Ditahan',
                      onTap: onHeldBills!,
                      light: true,
                    ),
                  _HeaderIconBtn(
                    icon: Icons.receipt_long_outlined,
                    tooltip: 'Atur Struk',
                    onTap: onReceiptSettings,
                    light: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.light = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: light ? AppColors.posGreen : Colors.white,
        size: 22,
      ),
      style: light
          ? IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            )
          : null,
    );
  }
}

class _MekariCategoryChip extends StatelessWidget {
  const _MekariCategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.posGreen : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: selected ? 0 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.posGreen : AppColors.border,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MekariProductCard extends StatelessWidget {
  const _MekariProductCard({
    required this.product,
    required this.server,
    required this.onTap,
  });

  final PosProduct product;
  final String? server;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = resolveMediaUrl(product.imageUrl, server);
    final outOfStock = product.trackStock && product.totalStock <= 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: outOfStock ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: outOfStock ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                  child: ColoredBox(
                    color: AppColors.posCartBg,
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Formatters.currency(product.basePrice),
                        style: const TextStyle(
                          color: AppColors.posGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (product.trackStock)
                        Text(
                          outOfStock
                              ? 'Habis'
                              : 'Stok ${product.totalStock.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight:
                                outOfStock ? FontWeight.w700 : FontWeight.normal,
                            color: outOfStock
                                ? AppColors.danger
                                : AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Text(
        product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.posGreen,
        ),
      ),
    );
  }
}

class _MekariCartPanel extends ConsumerWidget {
  const _MekariCartPanel({
    required this.onCheckout,
    required this.onHold,
    required this.onNewTransaction,
    this.showMember = true,
    this.showHold = true,
  });

  final VoidCallback onCheckout;
  final VoidCallback onHold;
  final VoidCallback onNewTransaction;
  final bool showMember;
  final bool showHold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return ColoredBox(
      color: AppColors.posCartBg,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.posGreen, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pesanan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.posGreenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.itemCount} item',
                    style: const TextStyle(
                      color: AppColors.posGreenDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (cart.items.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.danger,
                    tooltip: 'Kosongkan',
                    onPressed: onNewTransaction,
                  ),
                ],
              ],
            ),
          ),
          if (showMember) ...[
            const Divider(height: 1),
            Material(
              color: Colors.white,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline, color: AppColors.posGreen),
                title: Text(
                  cart.memberName ?? 'Hubungkan member',
                  style: TextStyle(
                    fontWeight:
                        cart.memberName != null ? FontWeight.w600 : FontWeight.normal,
                    color: cart.memberName != null
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                subtitle: cart.memberCode != null ? Text(cart.memberCode!) : null,
                trailing: cart.memberId != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () =>
                            ref.read(cartProvider.notifier).clearMember(),
                      )
                    : const Icon(Icons.chevron_right, size: 20),
                onTap: () => showMemberPickerSheet(context),
              ),
            ),
          ],
          const Divider(height: 1),
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada pesanan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap produk untuk menambah',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 14, endIndent: 14),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _MekariCartLine(
                        item: item,
                        onDecrement: () => ref
                            .read(cartProvider.notifier)
                            .updateQuantity(item.key, item.quantity - 1),
                        onIncrement: () {
                          final ok = ref
                              .read(cartProvider.notifier)
                              .updateQuantity(item.key, item.quantity + 1);
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Stok ${item.product.name} tidak mencukupi',
                                ),
                              ),
                            );
                          }
                        },
                        onRemove: () =>
                            ref.read(cartProvider.notifier).removeItem(item.key),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      Formatters.currency(cart.subtotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: cart.items.isEmpty ? null : onCheckout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.posGreen,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'BAYAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                if (showHold) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: cart.items.isEmpty ? null : onHold,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.posGreenDark,
                      side: const BorderSide(color: AppColors.posGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Tahan Bill'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MekariCartLine extends StatelessWidget {
  const _MekariCartLine({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final lineTotal = item.unitPrice * item.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (item.modifiers.isNotEmpty)
                      ...item.modifiers.map(
                        (m) => Text(
                          '+ ${m.name}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    Text(
                      Formatters.currency(item.unitPrice),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.currency(lineTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _QtyBtn(icon: Icons.remove, onTap: onDecrement),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  item.quantity.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              _QtyBtn(icon: Icons.add, onTap: onIncrement, filled: true),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textMuted,
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.posGreen : Colors.white,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: filled ? null : Border.all(color: AppColors.border),
          ),
          child: Icon(
            icon,
            size: 18,
            color: filled ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MekariMobilePayBar extends StatelessWidget {
  const _MekariMobilePayBar({
    required this.itemCount,
    required this.subtotal,
    required this.onTapCart,
    required this.onCheckout,
    required this.onHold,
  });

  final int itemCount;
  final double subtotal;
  final VoidCallback onTapCart;
  final VoidCallback onCheckout;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: onTapCart,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.posCartBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Badge(
                          isLabelVisible: itemCount > 0,
                          backgroundColor: AppColors.posGreen,
                          label: Text('$itemCount'),
                          child: const Icon(
                            Icons.receipt_long,
                            color: AppColors.posGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$itemCount pesanan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                Formatters.currency(subtotal),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_up),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: itemCount == 0 ? null : onCheckout,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.posGreen,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'BAYAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}