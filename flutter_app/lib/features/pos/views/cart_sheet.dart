import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../providers/cart_notifier.dart';

Future<void> showCartSheet({
  required BuildContext context,
  required VoidCallback onCheckout,
  required VoidCallback onHold,
  bool showHold = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => _CartSheetBody(
        scrollController: controller,
        showHold: showHold,
        onCheckout: () {
          Navigator.pop(ctx);
          onCheckout();
        },
        onHold: () {
          Navigator.pop(ctx);
          onHold();
        },
      ),
    ),
  );
}

class _CartSheetBody extends ConsumerWidget {
  const _CartSheetBody({
    required this.scrollController,
    required this.onCheckout,
    required this.onHold,
    this.showHold = true,
  });

  final ScrollController scrollController;
  final VoidCallback onCheckout;
  final VoidCallback onHold;
  final bool showHold;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return ColoredBox(
      color: AppColors.posCartBg,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.posGreen),
                const SizedBox(width: 8),
                const Text(
                  'Pesanan',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${cart.itemCount} item',
                  style: const TextStyle(
                    color: AppColors.posGreenDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: cart.items.isEmpty
                ? const EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Belum ada pesanan',
                    subtitle: 'Tap produk untuk menambahkan',
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      final mods = item.modifiers
                          .map((m) => m.name)
                          .where((n) => n.isNotEmpty)
                          .join(', ');
                      return Dismissible(
                        key: ValueKey(item.key),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            ref.read(cartProvider.notifier).removeItem(item.key),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: AppColors.danger,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
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
                                      ),
                                    ),
                                    if (mods.isNotEmpty)
                                      Text(
                                        mods,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted,
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _QtyBtn(
                                    icon: Icons.remove,
                                    onTap: () => ref
                                        .read(cartProvider.notifier)
                                        .updateQuantity(
                                          item.key,
                                          item.quantity - 1,
                                        ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      item.quantity.toStringAsFixed(0),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  _QtyBtn(
                                    icon: Icons.add,
                                    filled: true,
                                    onTap: () {
                                      final ok = ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            item.key,
                                            item.quantity + 1,
                                          );
                                      if (!ok) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Stok ${item.product.name} tidak mencukupi',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text(
                        Formatters.currency(cart.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: onCheckout,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.posGreen,
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
                      onPressed: onHold,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.posGreenDark,
                        side: const BorderSide(color: AppColors.posGreen),
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