import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/pos_repository.dart';
import '../providers/cart_notifier.dart';
import '../providers/pos_providers.dart';

class HeldBillsSheet extends ConsumerWidget {
  const HeldBillsSheet({
    super.key,
    required this.outletId,
  });

  final int outletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final held = ref.watch(heldBillsProvider(outletId));

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Bill Ditahan', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Expanded(
                child: held.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ErrorView(
                    message: friendlyError(e),
                    onRetry: () => ref.invalidate(heldBillsProvider(outletId)),
                  ),
                  data: (bills) {
                    if (bills.isEmpty) {
                      return const EmptyState(
                        icon: Icons.pause_circle_outline,
                        title: 'Tidak ada bill ditahan',
                        subtitle: 'Bill yang ditahan akan muncul di sini',
                      );
                    }
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(bill.referenceName),
                            subtitle: Text('${bill.itemCount} item'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  Formatters.currency(bill.subtotal),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hapus bill?'),
                                        content: Text(
                                          'Hapus "${bill.referenceName}" secara permanen?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Batal'),
                                          ),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (ok != true) return;
                                    try {
                                      await ref
                                          .read(posRepositoryProvider)
                                          .deleteHeldBill(bill.id);
                                      ref.invalidate(heldBillsProvider(outletId));
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Gagal hapus: ${friendlyError(e)}',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () async {
                              try {
                                final resume = await ref
                                    .read(posRepositoryProvider)
                                    .resumeHeldBill(bill.id);
                                ref.read(cartProvider.notifier).loadFromHeld(
                                      resume.items,
                                      memberId: resume.memberId,
                                    );
                                if (context.mounted) Navigator.of(context).pop();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Gagal lanjutkan: ${friendlyError(e)}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}