import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../local_database/offline_queue_repository.dart';
import '../../../shared/widgets/error_view.dart';
import '../providers/sync_providers.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(offlineQueueListProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final syncState = ref.watch(syncControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sinkronisasi Offline')),
      body: Column(
        children: [
          pending.when(
            data: (count) => MaterialBanner(
              content: Text(
                count > 0
                    ? '$count transaksi menunggu sync'
                    : 'Semua transaksi tersinkron',
              ),
              leading: Icon(
                count > 0 ? Icons.cloud_off : Icons.cloud_done,
                color: count > 0 ? Colors.orange : Colors.green,
              ),
              actions: [
                TextButton(
                  onPressed: syncState.isLoading
                      ? null
                      : () async {
                          final result =
                              await ref.read(syncControllerProvider.notifier).syncNow();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sync: ${result.synced} berhasil, ${result.failed} gagal',
                              ),
                            ),
                          );
                        },
                  child: syncState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sync Sekarang'),
                ),
              ],
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Expanded(
            child: queue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(offlineQueueListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('Belum ada transaksi offline'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(offlineQueueListProvider);
                    ref.invalidate(pendingSyncCountProvider);
                  },
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final payments =
                          item.payload['payments'] as List<dynamic>? ?? [];
                      final amount = payments.isNotEmpty
                          ? (payments.first['amount'] as num?)?.toDouble() ?? 0
                          : 0.0;
                      return ListTile(
                        leading: Icon(_statusIcon(item.status)),
                        title: Text(item.idempotencyKey.substring(0, 8)),
                        subtitle: Text(
                          '${_statusLabel(item.status)} · ${DateFormat('d MMM HH:mm').format(DateTime.parse(item.createdAt))}'
                          '${item.errorMessage != null ? '\n${item.errorMessage}' : ''}',
                        ),
                        trailing: Text(Formatters.currency(amount)),
                        onTap: item.status == 'failed'
                            ? () async {
                                await ref
                                    .read(offlineQueueRepositoryProvider)
                                    .resetToPending(item.id);
                                ref.invalidate(offlineQueueListProvider);
                                ref.invalidate(pendingSyncCountProvider);
                              }
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

IconData _statusIcon(String status) {
  return switch (status) {
    'synced' => Icons.check_circle,
    'failed' => Icons.error_outline,
    'syncing' => Icons.sync,
    _ => Icons.schedule,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'pending' => 'Menunggu',
    'syncing' => 'Sync...',
    'synced' => 'Tersinkron',
    'failed' => 'Gagal (tap retry)',
    _ => status,
  };
}