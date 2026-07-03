import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/outlet_utils.dart';
import '../../../shared/widgets/outlet_dropdown.dart';
import '../data/reservations_repository.dart';
import '../models/reservation_models.dart';
import '../providers/reservations_providers.dart';

class ReservationFormSheet extends ConsumerStatefulWidget {
  const ReservationFormSheet({
    super.key,
    required this.outlets,
    this.initialOutletId,
  });

  final List<Map<String, dynamic>> outlets;
  final int? initialOutletId;

  @override
  ConsumerState<ReservationFormSheet> createState() =>
      _ReservationFormSheetState();
}

class _ReservationFormSheetState extends ConsumerState<ReservationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _guestController = TextEditingController(text: '2');
  final _notesController = TextEditingController();

  int? _outletId;
  DateTime _date = DateTime.now();
  String? _time;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _outletId = resolveOutletId(widget.outlets, widget.initialOutletId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _guestController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _time = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_outletId == null || _time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih outlet dan waktu')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(reservationsRepositoryProvider).createReservation({
        'outlet_id': _outletId,
        'customer_name': _nameController.text.trim(),
        'customer_phone': _phoneController.text.trim(),
        if (_emailController.text.trim().isNotEmpty)
          'customer_email': _emailController.text.trim(),
        'guest_count': int.parse(_guestController.text),
        'reservation_date': _dateStr,
        'reservation_time': _time,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final slots = _outletId != null
        ? ref.watch(
            reservationSlotsProvider((outletId: _outletId!, date: _dateStr)),
          )
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Buat Reservasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              OutletDropdown(
                outlets: widget.outlets,
                value: _outletId,
                label: 'Outlet',
                onChanged: (v) => setState(() {
                  _outletId = v;
                  _time = null;
                }),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama pelanggan'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Nama wajib' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telepon'),
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Telepon wajib' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email (opsional)'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _guestController,
                decoration: const InputDecoration(labelText: 'Jumlah tamu'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1) return 'Minimal 1 tamu';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tanggal'),
                subtitle: Text(DateFormat('d MMM yyyy', 'id_ID').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),
              if (slots == null)
                const Text('Pilih outlet untuk melihat slot')
              else
                slots.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(e.toString()),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Text('Tidak ada slot tersedia');
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: items.map((ReservationSlot slot) {
                        final label =
                            '${slot.startTime}–${slot.endTime} (${slot.available} slot)';
                        return ChoiceChip(
                          label: Text(label),
                          selected: _time == slot.startTime,
                          onSelected: slot.isAvailable
                              ? (_) => setState(() => _time = slot.startTime)
                              : null,
                        );
                      }).toList(),
                    );
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Catatan'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Reservasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}