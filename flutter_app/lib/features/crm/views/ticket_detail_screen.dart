import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_message.dart';
import '../../../shared/widgets/error_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/crm_repository.dart';
import '../providers/crm_providers.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.uuid});

  final String uuid;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(crmRepositoryProvider).sendMessage(
            widget.uuid,
            message: text,
            senderType: 'agent',
          );
      _messageController.clear();
      ref.invalidate(ticketDetailProvider(widget.uuid));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _assignToMe() async {
    final userId = ref.read(authControllerProvider).session?.user.id;
    if (userId == null) return;
    try {
      await ref.read(crmRepositoryProvider).assignTicket(
            widget.uuid,
            assignedTo: userId,
          );
      ref.invalidate(ticketDetailProvider(widget.uuid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket ditugaskan ke Anda')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e))),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ref.read(crmRepositoryProvider).updateStatus(
            widget.uuid,
            status: status,
          );
      ref.invalidate(ticketDetailProvider(widget.uuid));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status: $status')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = ref.watch(ticketDetailProvider(widget.uuid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Tugaskan ke saya',
            onPressed: _assignToMe,
          ),
        ],
      ),
      body: ticket.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(ticketDetailProvider(widget.uuid)),
        ),
        data: (t) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(ticketDetailProvider(widget.uuid)),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(t.subject, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${t.ticketNumber} · ${t.status} · ${t.priority}'),
                    if (t.customerName != null)
                      Text('Pelanggan: ${t.customerName}'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _nextStatuses(t.status).map((s) {
                        return ActionChip(
                          label: Text(s),
                          onPressed: () => _updateStatus(s),
                        );
                      }).toList(),
                    ),
                    const Divider(height: 32),
                    ...t.messages.where((m) => !m.isInternal).map((m) {
                      final isAgent = m.senderType == 'agent';
                      return Align(
                        alignment: isAgent
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isAgent
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                m.sender?.name ?? m.senderType,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(m.message),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Balas sebagai agent...',
                          isDense: true,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending ? null : _sendMessage,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _nextStatuses(String current) {
    return switch (current) {
      'open' => ['assigned', 'pending'],
      'assigned' => ['pending', 'resolved'],
      'pending' => ['resolved', 'closed'],
      'resolved' => ['closed'],
      _ => [],
    };
  }
}