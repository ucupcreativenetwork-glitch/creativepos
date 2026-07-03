import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../data/public_menu_repository.dart';
import '../providers/qr_cart_notifier.dart';
import '../providers/qr_menu_providers.dart';

class QrMenuCartSheet extends ConsumerStatefulWidget {
  const QrMenuCartSheet({
    super.key,
    required this.tenantSlug,
    required this.outletSlug,
  });

  final String tenantSlug;
  final String outletSlug;

  @override
  ConsumerState<QrMenuCartSheet> createState() => _QrMenuCartSheetState();
}

class _QrMenuCartSheetState extends ConsumerState<QrMenuCartSheet> {
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = ref.read(qrCartProvider);
    if (cart.items.isEmpty) return;

    setState(() => _submitting = true);
    try {
      final result = await ref.read(publicMenuRepositoryProvider).submitOrder({
        'tenant_slug': widget.tenantSlug,
        'outlet_slug': widget.outletSlug,
        if (cart.tableToken != null) 'table_token': cart.tableToken,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
        'items': cart.items
            .map((i) => {
                  'product_id': i.product.id,
                  'quantity': i.quantity,
                  if (i.notes != null) 'notes': i.notes,
                })
            .toList(),
      });
      ref.read(qrCartProvider.notifier).clear();
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showOrderTrack(result.uuid);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showOrderTrack(String uuid) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _OrderTrackSheet(uuid: uuid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(qrCartProvider);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Keranjang (${cart.itemCount})',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              if (cart.items.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(qrCartProvider.notifier).clear(),
                  child: const Text('Kosongkan'),
                ),
            ],
          ),
          if (cart.tableToken != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Chip(
                avatar: const Icon(Icons.table_bar, size: 16),
                label: Text('Meja: ${cart.tableToken}'),
              ),
            ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cart.items.length,
              itemBuilder: (context, index) {
                final item = cart.items[index];
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(Formatters.currency(item.product.basePrice)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => ref
                            .read(qrCartProvider.notifier)
                            .updateQuantity(
                              item.product.id,
                              item.quantity - 1,
                            ),
                      ),
                      Text(item.quantity.toStringAsFixed(
                          item.quantity == item.quantity.roundToDouble()
                              ? 0
                              : 1)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => ref
                            .read(qrCartProvider.notifier)
                            .updateQuantity(
                              item.product.id,
                              item.quantity + 1,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Catatan pesanan',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(
                Formatters.currency(cart.subtotal),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: cart.items.isEmpty || _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Kirim Pesanan'),
          ),
        ],
      ),
    );
  }
}

class _OrderTrackSheet extends ConsumerWidget {
  const _OrderTrackSheet({required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(publicOrderTrackProvider(uuid));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: track.when(
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(e.toString()),
        data: (order) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pesanan ${order.orderNumber}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Chip(label: Text(_statusLabel(order.status))),
            if (order.table != null)
              Text('Meja ${order.table!.tableNumber}'),
            const SizedBox(height: 12),
            ...order.items.map(
              (i) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(i.productName),
                subtitle: Text(_statusLabel(i.status)),
                trailing: Text('x${i.quantity.toStringAsFixed(0)}'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(publicOrderTrackProvider(uuid)),
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'pending' => 'Menunggu',
      'confirmed' => 'Dikonfirmasi',
      'preparing' => 'Disiapkan',
      'ready' => 'Siap',
      'served' => 'Disajikan',
      'completed' => 'Selesai',
      'cancelled' => 'Dibatalkan',
      _ => status,
    };
  }
}