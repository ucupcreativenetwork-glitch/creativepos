import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/members_repository.dart';
import '../providers/members_providers.dart';
import 'member_edit_sheet.dart';

class MemberDetailScreen extends ConsumerWidget {
  const MemberDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref.watch(memberDetailProvider(uuid));
    final points = ref.watch(memberPointsProvider(uuid));
    final walletTx = ref.watch(memberWalletTransactionsProvider(uuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Member'),
        actions: [
          member.maybeWhen(
            data: (m) => IconButton(
              onPressed: () async {
                final ok = await showMemberEditSheet(context, member: m);
                if (ok == true) {
                  ref.invalidate(memberDetailProvider(uuid));
                }
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit member',
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: member.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () {
            ref.invalidate(memberDetailProvider(uuid));
            ref.invalidate(memberPointsProvider(uuid));
          },
        ),
        data: (m) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(memberDetailProvider(uuid));
            ref.invalidate(memberPointsProvider(uuid));
            ref.invalidate(memberWalletTransactionsProvider(uuid));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 28,
                  child: Text(
                    m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(m.name, style: Theme.of(context).textTheme.headlineSmall),
                subtitle: Text('${m.memberCode} · ${m.status}'),
              ),
              const SizedBox(height: 8),
              _InfoRow(label: 'Telepon', value: m.phone),
              if (m.email != null) _InfoRow(label: 'Email', value: m.email!),
              _InfoRow(
                label: 'Total Belanja',
                value: Formatters.currency(m.totalSpend),
              ),
              _InfoRow(label: 'Kunjungan', value: '${m.visitCount}x'),
              if (m.tier != null)
                _InfoRow(label: 'Tier', value: m.tier!.name),
              const Divider(height: 32),
              Text('Poin', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              points.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(e.toString()),
                data: (p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Saldo', value: '${p.balance} poin'),
                    _InfoRow(
                      label: 'Total diperoleh',
                      value: '${p.lifetimeEarned} poin',
                    ),
                    if (p.history.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Riwayat terakhir',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      ...p.history.take(5).map(
                            (h) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(h.description ?? h.type),
                              subtitle: Text(h.createdAt ?? ''),
                              trailing: Text(
                                '${h.points > 0 ? '+' : ''}${h.points}',
                              ),
                            ),
                          ),
                    ],
                  ],
                ),
              ),
              if (m.wallet != null) ...[
                const Divider(height: 32),
                Text('Wallet', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Saldo',
                  value: Formatters.currency(m.wallet!.balance),
                ),
                _InfoRow(
                  label: 'Status',
                  value: m.wallet!.status,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _topupWallet(context, ref, m.id),
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: const Text('Top-up Wallet'),
                ),
                const SizedBox(height: 12),
                walletTx.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(e.toString()),
                  data: (txs) {
                    if (txs.isEmpty) {
                      return Text(
                        'Belum ada riwayat wallet',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat wallet',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        ...txs.take(10).map(
                              (t) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(t.description ?? t.type),
                                subtitle: Text(t.createdAt ?? ''),
                                trailing: Text(
                                  '${t.amount >= 0 ? '+' : ''}${Formatters.currency(t.amount)}',
                                ),
                              ),
                            ),
                      ],
                    );
                  },
                ),
              ],
              if (m.points != null && m.points!.balance > 0) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _redeemPoints(context, ref, uuid, m.points!.balance),
                  icon: const Icon(Icons.redeem_outlined),
                  label: const Text('Tukar Poin'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _topupWallet(
    BuildContext context,
    WidgetRef ref,
    int memberId,
  ) async {
    final amountController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Top-up Wallet'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah (min Rp 1.000)',
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Top-up'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final amount = double.tryParse(amountController.text.replaceAll('.', ''));
    if (amount == null || amount < 1000) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jumlah minimal Rp 1.000')),
        );
      }
      return;
    }

    try {
      await ref.read(membersRepositoryProvider).topupWallet(
            memberId: memberId,
            amount: amount,
          );
      ref.invalidate(memberDetailProvider(uuid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Top-up berhasil')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _redeemPoints(
    BuildContext context,
    WidgetRef ref,
    String memberUuid,
    int maxPoints,
  ) async {
    final pointsController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tukar Poin'),
        content: TextField(
          controller: pointsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Jumlah poin (max $maxPoints)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final points = int.tryParse(pointsController.text);
    if (points == null || points < 1 || points > maxPoints) return;

    try {
      await ref.read(membersRepositoryProvider).redeemPoints(
            memberUuid,
            points: points,
          );
      ref.invalidate(memberDetailProvider(uuid));
      ref.invalidate(memberPointsProvider(uuid));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poin berhasil ditukar')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}