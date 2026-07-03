import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/error_message.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/interactive_card.dart';
import '../../../shared/widgets/load_more_list_view.dart';
import '../data/crm_repository.dart';
import '../models/crm_models.dart';
import '../providers/crm_providers.dart';
import 'ticket_create_sheet.dart';
import 'ticket_detail_screen.dart';

class CrmTab extends ConsumerStatefulWidget {
  const CrmTab({super.key});

  @override
  ConsumerState<CrmTab> createState() => _CrmTabState();
}

class _CrmTabState extends ConsumerState<CrmTab> {
  String? _statusFilter;
  final _searchController = TextEditingController();
  String _search = '';
  var _section = 0;
  var _listKey = 0;

  void _bumpList() => setState(() => _listKey++);

  Future<({List<SupportTicketModel> items, int lastPage})> _loadTickets(
    int page,
  ) async {
    final result = await ref.read(crmRepositoryProvider).listTickets(
          status: _statusFilter,
          search: _search.isEmpty ? null : _search,
          page: page,
        );
    return (items: result.items, lastPage: result.meta.lastPage);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createTicket() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TicketCreateSheet(),
    );
    if (created == true) _bumpList();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = ref.watch(faqsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Tiket')),
              ButtonSegment(value: 1, label: Text('FAQ')),
            ],
            selected: {_section},
            onSelectionChanged: (v) => setState(() => _section = v.first),
          ),
        ),
        if (_section == 0) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari tiket...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onSubmitted: (v) {
                      setState(() => _search = v.trim());
                      _bumpList();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _createTicket,
                  icon: const Icon(Icons.add),
                  tooltip: 'Buat tiket',
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
                    onSelected: (_) {
                      setState(() => _statusFilter = null);
                      _bumpList();
                    },
                  ),
                  ...['open', 'assigned', 'pending', 'resolved', 'closed'].map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(_statusLabel(s)),
                        selected: _statusFilter == s,
                        onSelected: (_) {
                          setState(() => _statusFilter = s);
                          _bumpList();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LoadMoreListView<SupportTicketModel>(
              key: ValueKey('crm-$_listKey-$_statusFilter-$_search'),
              loader: _loadTickets,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              empty: const EmptyState(
                icon: Icons.support_agent_outlined,
                title: 'Belum ada tiket',
                subtitle: 'Buat tiket baru untuk menangani keluhan pelanggan',
              ),
              itemBuilder: (context, ticket, index) {
                return InteractiveCard(
                  margin: EdgeInsets.zero,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          TicketDetailScreen(uuid: ticket.uuid),
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(_priorityIcon(ticket.priority)),
                    title: Text(
                      ticket.subject,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${ticket.ticketNumber} · ${_statusLabel(ticket.status)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        ticket.priority,
                        style: const TextStyle(fontSize: 11),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                );
              },
            ),
          ),
        ] else
          Expanded(
            child: faqs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorView(
                message: friendlyError(e),
                onRetry: () => ref.invalidate(faqsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.quiz_outlined,
                    title: 'FAQ kosong',
                    subtitle: 'Panduan pelanggan akan tampil di sini',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(faqsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final faq = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ExpansionTile(
                          title: Text(
                            faq.question,
                            style: const TextStyle(fontSize: 14),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(faq.answer),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'open' => 'Terbuka',
    'assigned' => 'Ditugaskan',
    'pending' => 'Pending',
    'resolved' => 'Selesai',
    'closed' => 'Ditutup',
    _ => status,
  };
}

IconData _priorityIcon(String priority) {
  return switch (priority) {
    'critical' => Icons.priority_high,
    'high' => Icons.arrow_upward,
    'low' => Icons.arrow_downward,
    _ => Icons.support_agent,
  };
}