import 'package:flutter_test/flutter_test.dart';
import 'package:creativepos_mobile/features/reservations/models/reservation_models.dart';

void main() {
  group('ReservationModel', () {
    test('parses reservation from API response', () {
      final reservation = ReservationModel.fromJson({
        'id': 5,
        'uuid': 'res-uuid-1',
        'reservation_number': 'RSV-2026-0001',
        'customer_name': 'Ani Wijaya',
        'customer_phone': '08129998877',
        'customer_email': 'ani@demo.com',
        'guest_count': 4,
        'reservation_date': '2026-07-01',
        'reservation_time': '18:30',
        'status': 'confirmed',
        'notes': 'Dekat jendela',
        'outlet': {'id': 1, 'name': 'Cabang Pusat', 'code': 'HQ'},
        'table': {'id': 3, 'table_number': 'A3', 'name': 'Meja A3'},
      });

      expect(reservation.uuid, 'res-uuid-1');
      expect(reservation.reservationNumber, 'RSV-2026-0001');
      expect(reservation.outlet?.name, 'Cabang Pusat');
      expect(reservation.table?.tableNumber, 'A3');
      expect(reservation.status, 'confirmed');
    });
  });

  group('ReservationSlot', () {
    test('parses available slot', () {
      final slot = ReservationSlot.fromJson({
        'id': 1,
        'start_time': '18:00',
        'end_time': '19:00',
        'capacity': 10,
        'booked': 3,
        'available': 7,
        'is_available': true,
      });

      expect(slot.startTime, '18:00');
      expect(slot.endTime, '19:00');
      expect(slot.available, 7);
      expect(slot.isAvailable, isTrue);
    });
  });
}