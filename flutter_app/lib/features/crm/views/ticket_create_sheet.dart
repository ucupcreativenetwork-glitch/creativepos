import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crm_repository.dart';

class TicketCreateSheet extends ConsumerStatefulWidget {
  const TicketCreateSheet({super.key});

  @override
  ConsumerState<TicketCreateSheet> createState() => _TicketCreateSheetState();
}

class _TicketCreateSheetState extends ConsumerState<TicketCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _priority = 'medium';
  String _channel = 'phone';
  bool _loading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(crmRepositoryProvider).createTicket({
        'subject': _subjectController.text.trim(),
        'priority': _priority,
        'channel': _channel,
        if (_nameController.text.trim().isNotEmpty)
          'customer_name': _nameController.text.trim(),
        if (_phoneController.text.trim().isNotEmpty)
          'customer_phone': _phoneController.text.trim(),
        if (_messageController.text.trim().isNotEmpty)
          'message': _messageController.text.trim(),
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
                'Buat Tiket Support',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subjek'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Subjek wajib' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioritas'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Rendah')),
                  DropdownMenuItem(value: 'medium', child: Text('Sedang')),
                  DropdownMenuItem(value: 'high', child: Text('Tinggi')),
                  DropdownMenuItem(value: 'critical', child: Text('Kritis')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? 'medium'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _channel,
                decoration: const InputDecoration(labelText: 'Channel'),
                items: const [
                  DropdownMenuItem(value: 'phone', child: Text('Telepon')),
                  DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                  DropdownMenuItem(value: 'email', child: Text('Email')),
                  DropdownMenuItem(value: 'website', child: Text('Website')),
                ],
                onChanged: (v) => setState(() => _channel = v ?? 'phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama pelanggan'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telepon'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(labelText: 'Pesan awal'),
                maxLines: 3,
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
                    : const Text('Buat Tiket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}