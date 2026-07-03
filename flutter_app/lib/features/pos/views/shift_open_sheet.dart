import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_cache_service.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';
import '../providers/pos_providers.dart';

Future<bool?> showShiftOpenSheet({
  required BuildContext context,
  required int outletId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShiftOpenSheet(outletId: outletId),
  );
}

class ShiftOpenSheet extends ConsumerStatefulWidget {
  const ShiftOpenSheet({super.key, required this.outletId});

  final int outletId;

  @override
  ConsumerState<ShiftOpenSheet> createState() => _ShiftOpenSheetState();
}

class _ShiftOpenSheetState extends ConsumerState<ShiftOpenSheet> {
  final _cashController = TextEditingController(text: '0');
  var _submitting = false;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_cashController.text) ?? 0;
    setState(() => _submitting = true);
    try {
      final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
            ref.read(apiBaseUrlProvider),
          );

      if (!serverUp) {
        final localNumber =
            'LOKAL-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}';
        final shift = Shift(
          id: 0,
          shiftNumber: localNumber,
          status: 'open',
          openingCash: amount,
        );
        await ref.read(offlineCacheServiceProvider).saveShift(widget.outletId, shift);
        ref.invalidate(currentShiftProvider(widget.outletId));
        if (mounted) Navigator.pop(context, true);
        return;
      }

      final shift = await ref.read(posRepositoryProvider).openShift(
            outletId: widget.outletId,
            openingCash: amount,
          );
      await ref.read(offlineCacheServiceProvider).saveShift(widget.outletId, shift);
      ref.invalidate(currentShiftProvider(widget.outletId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal buka shift: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final mode = ref.watch(connectivityModeProvider).valueOrNull;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Buka Shift', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            mode == ConnectivityMode.online
                ? 'Masukkan modal kas awal sebelum mulai transaksi.'
                : 'Mode lokal — shift disimpan di perangkat dan disinkronkan saat server aktif.',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Modal kas awal',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Nanti'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Buka Shift'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}