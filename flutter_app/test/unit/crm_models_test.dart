import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/crm/models/crm_models.dart';

void main() {
  group('SupportTicketModel', () {
    test('parses ticket with messages', () {
      final ticket = SupportTicketModel.fromJson({
        'id': 3,
        'uuid': 'ticket-uuid-1',
        'ticket_number': 'TKT-001',
        'subject': 'Pesanan terlambat',
        'status': 'open',
        'priority': 'high',
        'channel': 'whatsapp',
        'customer_name': 'Siti',
        'messages': [
          {
            'id': 1,
            'sender_type': 'customer',
            'message': 'Pesanan belum sampai',
            'is_internal': false,
          },
          {
            'id': 2,
            'sender_type': 'agent',
            'message': 'Kami cek driver ya',
            'sender': {'id': 5, 'name': 'CS Admin'},
            'is_internal': false,
          },
        ],
      });

      expect(ticket.ticketNumber, 'TKT-001');
      expect(ticket.priority, 'high');
      expect(ticket.messages, hasLength(2));
      expect(ticket.messages.last.sender?.name, 'CS Admin');
    });
  });

  group('FaqModel', () {
    test('parses FAQ entry', () {
      final faq = FaqModel.fromJson({
        'id': 1,
        'question': 'Jam operasional?',
        'answer': '08:00 - 22:00',
        'sort_order': 1,
      });

      expect(faq.question, 'Jam operasional?');
      expect(faq.sortOrder, 1);
    });
  });
}