import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../local_database/models/offline_transaction.dart';
import '../../../local_database/offline_queue_repository.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/printer_service.dart';
import '../../../services/receipt_builder.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/interactive_card.dart';
import '../../../shared/widgets/load_more_list_view.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.outletId});

  final int? outletId;

  @override
  ConsumerState<TransactionsScreen> createState() =>
      _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  Future<({List<TransactionListItem> items, int lastPage})> _loadPage(
    int page,
  ) async {
    final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
          ref.read(apiBaseUrlProvider),
        );

    final isStandalone =
        ref.read(authControllerProvider).status == AuthStatus.standalone;

    if (!serverUp || isStandalone) {
      if (page > 1) {
        return (items: <TransactionListItem>[], lastPage: 1);
      }
      final local = await ref.read(offlineQueueRepositoryProvider).listAll();
      final filtered = local.where((tx) {
        if (widget.outletId == null) return true;
        return tx.payload['outlet_id'] == widget.outletId;
      });
      return (
        items: filtered.map(_offlineToListItem).toList(),
        lastPage: 1,
      );
    }

    final result = await ref.read(posRepositoryProvider).listTransactions(
          outletId: widget.outletId,
          page: page,
        );
    return (items: result.items, lastPage: result.meta.lastPage);
  }

  TransactionListItem _offlineToListItem(OfflineTransaction tx) {
    final payments = tx.payload['payments'] as List<dynamic>? ?? [];
    var total = 0.0;
    for (final payment in payments) {
      if (payment is Map) {
        total += (payment['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    final isLocal = tx.status == 'local';
    final status = switch (tx.status) {
      'synced' || 'local' => 'completed',
      'failed' => 'sync_failed',
      _ => 'pending_sync',
    };

    return TransactionListItem(
      id: -tx.id,
      uuid: tx.idempotencyKey,
      transactionNumber: isLocal
          ? 'LOC-${tx.idempotencyKey.substring(0, 8)}'
          : 'OFF-${tx.idempotencyKey.substring(0, 8)}',
      grandTotal: total,
      status: status,
      completedAt: DateTime.tryParse(tx.createdAt),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(connectivityModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          if (mode.valueOrNull != ConnectivityMode.online)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                avatar: Icon(Icons.storage, size: 16),
                label: Text('Lokal', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: LoadMoreListView<TransactionListItem>(
        key: ValueKey('tx-${widget.outletId}-${mode.valueOrNull?.name}'),
        loader: _loadPage,
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        empty: const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Belum ada transaksi',
          subtitle: 'Transaksi POS akan muncul di sini',
        ),
        itemBuilder: (context, tx, index) {
          final statusColor = switch (tx.status) {
            'completed' => Colors.green,
            'voided' => Colors.red,
            'pending_sync' => Colors.orange,
            'sync_failed' => Colors.red.shade700,
            _ => Colors.orange,
          };

          return InteractiveCard(
            margin: EdgeInsets.zero,
            onTap: () {
              HapticFeedback.lightImpact();
              _showDetail(context, tx);
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.12),
                child: Icon(Icons.receipt, color: statusColor, size: 20),
              ),
              title: Text(
                tx.transactionNumber,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                [
                  if (tx.outletName != null) tx.outletName!,
                  if (tx.completedAt != null)
                    Formatters.dateTime(tx.completedAt!),
                ].join(' · '),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.currency(tx.grandTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    tx.status == 'pending_sync'
                        ? 'MENUNGGU SYNC'
                        : tx.status.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: statusColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showDetail(BuildContext context, TransactionListItem tx) async {
    final isLocal = tx.id < 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tx.transactionNumber,
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Total: ${Formatters.currency(tx.grandTotal)}'),
            Text('Status: ${tx.status}'),
            if (isLocal)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Transaksi tersimpan di database lokal. Akan disinkronkan otomatis saat server terdeteksi.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            const SizedBox(height: 16),
            if (!isLocal && tx.status == 'completed') ...[
              FilledButton.icon(
                onPressed: () async {
                  try {
                    final receiptJson = await ref
                        .read(posRepositoryProvider)
                        .getReceipt(tx.uuid);
                    final data = ReceiptBuilder.fromApiReceipt(receiptJson);
                    final result = await ref
                        .read(printerServiceProvider)
                        .printReceipt(data);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(result.message)),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal cetak: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text('Cetak Ulang Struk'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final reason = await _askReason(ctx);
                  if (reason == null) return;
                  try {
                    await ref.read(posRepositoryProvider).voidTransaction(
                          tx.uuid,
                          reason: reason,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Transaksi dibatalkan')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Void Transaksi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Void Transaksi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Alasan'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Void'),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    controller.dispose();
    return ok == true ? (reason.isEmpty ? 'Tanpa alasan' : reason) : null;
  }
}