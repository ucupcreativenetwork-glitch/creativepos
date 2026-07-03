import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/local_database/models/offline_transaction.dart';

void main() {
  group('OfflineTransaction', () {
    test('detects pending statuses', () {
      const pending = OfflineTransaction(
        id: 1,
        idempotencyKey: 'key-abc',
        payload: {},
        status: 'pending',
        createdAt: '2026-07-01T10:00:00',
      );
      const failed = OfflineTransaction(
        id: 2,
        idempotencyKey: 'key-def',
        payload: {},
        status: 'failed',
        createdAt: '2026-07-01T10:00:00',
      );
      const synced = OfflineTransaction(
        id: 3,
        idempotencyKey: 'key-ghi',
        payload: {},
        status: 'synced',
        createdAt: '2026-07-01T10:00:00',
      );

      expect(pending.isPending, isTrue);
      expect(failed.isPending, isTrue);
      expect(synced.isPending, isFalse);
    });

    test('copyWithPayload preserves fields', () {
      const tx = OfflineTransaction(
        id: 1,
        idempotencyKey: 'uuid-1',
        payload: {},
        status: 'pending',
        createdAt: '2026-07-01T10:00:00',
      );
      final updated = tx.copyWithPayload({'outlet_id': 1, 'items': []});

      expect(updated.idempotencyKey, 'uuid-1');
      expect(updated.payload['outlet_id'], 1);
    });
  });
}