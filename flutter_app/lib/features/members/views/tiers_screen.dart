import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/error_view.dart';
import '../data/members_repository.dart';
import '../models/member_models.dart';
import '../providers/members_providers.dart';

class TiersScreen extends ConsumerWidget {
  const TiersScreen({super.key});

  Future<void> _editTier(
    BuildContext context,
    WidgetRef ref,
    MemberTier tier,
  ) async {
    final nameController = TextEditingController(text: tier.name);
    final minSpendController =
        TextEditingController(text: tier.minSpend.toStringAsFixed(0));
    final multiplierController =
        TextEditingController(text: tier.pointMultiplier.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Tier — ${tier.slug}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: minSpendController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Min. belanja (Rp)',
              ),
            ),
            TextField(
              controller: multiplierController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Multiplier poin'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(membersRepositoryProvider).updateTier(
            tier.id,
            name: nameController.text.trim(),
            minSpend: double.tryParse(minSpendController.text),
            pointMultiplier: double.tryParse(multiplierController.text),
          );
      ref.invalidate(memberTiersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tier diperbarui')),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiers = ref.watch(memberTiersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tier Member')),
      body: tiers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(memberTiersProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Belum ada tier dikonfigurasi'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(memberTiersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final tier = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.posGreenLight,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: AppColors.posGreen),
                      ),
                    ),
                    title: Text(tier.name),
                    subtitle: Text(
                      'Min. belanja ${Formatters.currency(tier.minSpend)} · '
                      'Multiplier ${tier.pointMultiplier}x',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editTier(context, ref, tier),
                    ),
                    onTap: () => _editTier(context, ref, tier),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}