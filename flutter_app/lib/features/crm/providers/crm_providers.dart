import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/crm_repository.dart';
import '../models/crm_models.dart';

class TicketsQuery {
  const TicketsQuery({this.status, this.priority, this.search});

  final String? status;
  final String? priority;
  final String? search;

  @override
  bool operator ==(Object other) =>
      other is TicketsQuery &&
      other.status == status &&
      other.priority == priority &&
      other.search == search;

  @override
  int get hashCode => Object.hash(status, priority, search);
}

final ticketsListProvider = FutureProvider.autoDispose
    .family<List<SupportTicketModel>, TicketsQuery>((ref, query) async {
  final result = await ref.watch(crmRepositoryProvider).listTickets(
        status: query.status,
        priority: query.priority,
        search: query.search,
      );
  return result.items;
});

final ticketDetailProvider =
    FutureProvider.autoDispose.family<SupportTicketModel, String>(
  (ref, uuid) async {
    return ref.watch(crmRepositoryProvider).getTicket(uuid);
  },
);

final faqsProvider = FutureProvider.autoDispose<List<FaqModel>>((ref) async {
  return ref.watch(crmRepositoryProvider).getFaqs();
});