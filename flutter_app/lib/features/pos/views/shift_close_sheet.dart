import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/offline_cache_service.dart';
import '../data/pos_repository.dart';
import '../models/pos_models.dart';
import '../providers/pos_providers.dart';

Future<bool?> showShiftCloseSheet({
  required BuildContext context,
  required int outletId,
  required Shift shift,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ShiftCloseSheet(outletId: outletId, shift: shift),
  );
}

class ShiftCloseSheet extends ConsumerStatefulWidget {
  const ShiftCloseSheet({
    super.key,
    required this.outletId,
    required this.shift,
  });

  final int outletId;
  final Shift shift;

  @override
  ConsumerState<ShiftCloseSheet> createState() => _ShiftCloseSheetState();
}

class _ShiftCloseSheetState extends ConsumerState<ShiftCloseSheet> {
  final _cashController = TextEditingController();
  final _notesController = TextEditingController();
  var _submitting = false;
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (widget.shift.isLocalShift) return;

    final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
          ref.read(apiBaseUrlProvider),
        );
    if (!serverUp) return;

    try {
      final report = await ref
          .read(posRepositoryProvider)
          .getShiftReport(widget.shift.id);
      if (mounted) setState(() => _report = report);
    } catch (_) {}
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _closeLocally({
    required double cash,
    required String notes,
  }) async {
    final cache = ref.read(offlineCacheServiceProvider);

    if (widget.shift.serverShiftId != null) {
      await cache.enqueueShiftClose(
        outletId: widget.outletId,
        shiftId: widget.shift.serverShiftId!,
        shiftNumber: widget.shift.shiftNumber,
        closingCash: cash,
        notes: notes.isEmpty ? null : notes,
      );
    }

    await cache.clearShift(widget.outletId);
    ref.invalidate(currentShiftProvider(widget.outletId));
  }

  Future<void> _submit() async {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final notes = _notesController.text.trim();
    setState(() => _submitting = true);

    try {
      final serverUp = await ref.read(connectivityServiceProvider).isServerReachable(
            ref.read(apiBaseUrlProvider),
          );

      if (!serverUp || widget.shift.isLocalShift) {
        await _closeLocally(cash: cash, notes: notes);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                serverUp
                    ? 'Shift lokal ditutup'
                    : 'Shift ditutup (lokal) — akan disinkronkan saat server aktif',
              ),
            ),
          );
        }
        return;
      }

      await ref.read(posRepositoryProvider).closeShift(
            shiftId: widget.shift.id,
            closingCash: cash,
            notes: notes.isEmpty ? null : notes,
          );
      await ref.read(offlineCacheServiceProvider).clearShift(widget.outletId);
      await ref
          .read(offlineCacheServiceProvider)
          .removeShiftClose(widget.outletId);
      ref.invalidate(currentShiftProvider(widget.outletId));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal tutup shift: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isOffline = ref.watch(connectivityModeProvider).valueOrNull !=
        ConnectivityMode.online;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tutup Shift', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Shift: ${widget.shift.shiftNumber}'),
          Text('Penjualan: ${Formatters.currency(widget.shift.totalSales)}'),
          Text('Transaksi: ${widget.shift.totalTransactions}'),
          if (_report != null) ...[
            const SizedBox(height: 8),
            if (_report!['cash_sales'] != null)
              Text(
                'Tunai: ${Formatters.currency((_report!['cash_sales'] as num).toDouble())}',
              ),
            if (_report!['non_cash_sales'] != null)
              Text(
                'Non-tunai: ${Formatters.currency((_report!['non_cash_sales'] as num).toDouble())}',
              ),
          ],
          if (isOffline) ...[
            const SizedBox(height: 8),
            Text(
              widget.shift.isLocalShift
                  ? 'Mode lokal — shift ditutup di perangkat.'
                  : 'Mode lokal — penutupan shift disimpan & disinkronkan saat server aktif.',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kas akhir',
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }
}