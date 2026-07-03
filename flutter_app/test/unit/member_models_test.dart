import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/members/models/member_models.dart';

void main() {
  group('MemberModel', () {
    test('parses member from API response', () {
      final member = MemberModel.fromJson({
        'id': 1,
        'uuid': 'member-uuid-1',
        'member_code': 'MBR001',
        'name': 'Budi Santoso',
        'phone': '08123456789',
        'email': 'budi@demo.com',
        'status': 'active',
        'total_spend': 1500000,
        'visit_count': 12,
        'tier': {'id': 2, 'name': 'Gold', 'slug': 'gold'},
        'points': {
          'balance': 500,
          'lifetime_earned': 1200,
          'lifetime_redeemed': 700,
        },
        'wallet': {
          'balance': 250000,
          'lifetime_topup': 500000,
          'lifetime_spent': 250000,
          'status': 'active',
        },
      });

      expect(member.uuid, 'member-uuid-1');
      expect(member.memberCode, 'MBR001');
      expect(member.tier?.name, 'Gold');
      expect(member.points?.balance, 500);
      expect(member.wallet?.balance, 250000);
    });
  });

  group('PointBalanceDetail', () {
    test('parses points history', () {
      final detail = PointBalanceDetail.fromJson({
        'balance': 100,
        'lifetime_earned': 200,
        'lifetime_redeemed': 100,
        'history': [
          {
            'type': 'earn',
            'points': 50,
            'balance_after': 100,
            'description': 'Transaksi POS',
            'created_at': '2026-07-01T10:00:00+07:00',
          },
        ],
      });

      expect(detail.balance, 100);
      expect(detail.history, hasLength(1));
      expect(detail.history.first.type, 'earn');
      expect(detail.history.first.points, 50);
    });
  });
}