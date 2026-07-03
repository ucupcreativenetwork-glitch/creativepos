import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/outlet_utils.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/outlet_dropdown.dart';
import '../../pos/providers/pos_providers.dart';
import '../data/reservations_repository.dart';
import '../models/reservation_models.dart';
import '../providers/reservations_providers.dart';
import 'reservation_form_sheet.dart';

class ReservationsTab extends ConsumerStatefulWidget {
  const ReservationsTab({super.key});

  @override
  ConsumerState<ReservationsTab> createState() => _ReservationsTabState();
}

class _ReservationsTabState extends ConsumerState<ReservationsTab> {
  int? _outletId;
  String? _statusFilter;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  ReservationsQuery get _query => ReservationsQuery(
        outletId: _outletId,
        status: _statusFilter,
        date: _dateStr,
      );

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    ref.invalidate(reservationsListProvider(_query));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    ref.invalidate(reservationsListProvider(_query));
  }

  Future<void> _createReservation(List<Map<String, dynamic>> outlets) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReservationFormSheet(
        outlets: outlets,
        initialOutletId: _outletId,
      ),
    );
    if (created == true) {
      ref.invalidate(reservationsListProvider(_query));
    }
  }

  Future<void> _updateStatus(ReservationModel r, String status) async {
    try {
      await ref.read(reservationsRepositoryProvider).updateStatus(
            r.uuid,
            status: status,
          );
      ref.invalidate(reservationsListProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diubah ke ${_statusLabel(status)}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  void _showActions(ReservationModel r) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(r.customerName),
              subtitle: Text(
                '${r.reservationDate} ${r.reservationTime} · ${r.guestCount} tamu',
              ),
            ),
            if (r.status == 'pending')
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Konfirmasi'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(r, 'confirmed');
                },
              ),
            if (r.status == 'confirmed')
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Check-in (Datang)'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(r, 'arrived');
                },
              ),
            if (r.status == 'arrived')
              ListTile(
                leading: const Icon(Icons.done_all),
                title: const Text('Selesai'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(r, 'completed');
                },
              ),
            if (!['completed', 'cancelled', 'no_show'].contains(r.status))
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: const Text('Batalkan'),
                onTap: () {
                  Navigator.pop(ctx);
                  _updateStatus(r, 'cancelled');
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final outletsAsync = ref.watch(settingsOutletsProvider);
    final reservations = ref.watch(reservationsListProvider(_query));

    return outletsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(settingsOutletsProvider),
      ),
      data: (outlets) {
        final outletList = outlets.cast<Map<String, dynamic>>().toList();
        final resolvedOutletId = resolveOutletId(outletList, _outletId);
        if (resolvedOutletId != null && resolvedOutletId != _outletId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _outletId = resolvedOutletId);
          });
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: OutletDropdown(
                      outlets: outletList,
                      value: resolvedOutletId,
                      onChanged: (v) => setState(() => _outletId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _createReservation(outletList),
                    icon: const Icon(Icons.add),
                    tooltip: 'Buat reservasi',
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  FilterChip(
                    label: const Text('Semua'),
                    selected: _statusFilter == null,
                    onSelected: (_) => setState(() => _statusFilter = null),
                  ),
                  ...['pending', 'confirmed', 'arrived', 'completed', 'cancelled']
                      .map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(_statusLabel(s)),
                        selected: _statusFilter == s,
                        onSelected: (_) => setState(() => _statusFilter = s),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _changeDate(-1),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Hari sebelumnya',
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          DateFormat('EEEE, d MMM yyyy', 'id_ID')
                              .format(_selectedDate),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _changeDate(1),
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Hari berikutnya',
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _selectedDate = DateTime.now());
                      ref.invalidate(reservationsListProvider(_query));
                    },
                    icon: const Icon(Icons.today_outlined),
                    tooltip: 'Hari ini',
                  ),
                ],
              ),
            ),
            Expanded(
              child: reservations.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(reservationsListProvider(_query)),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada reservasi pada ${DateFormat('d MMM yyyy', 'id_ID').format(_selectedDate)}',
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(reservationsListProvider(_query)),
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final r = items[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text('${r.guestCount}'),
                          ),
                          title: Text(r.customerName),
                          subtitle: Text(
                            '${r.reservationTime} · ${r.customerPhone}'
                            '${r.table != null ? ' · Meja ${r.table!.tableNumber}' : ''}',
                          ),
                          trailing: Chip(
                            label: Text(
                              _statusLabel(r.status),
                              style: const TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () => _showActions(r),
                          onLongPress: () => _showActions(r),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'pending' => 'Menunggu',
    'confirmed' => 'Dikonfirmasi',
    'arrived' => 'Datang',
    'completed' => 'Selesai',
    'cancelled' => 'Dibatalkan',
    'no_show' => 'Tidak Hadir',
    _ => status,
  };
}