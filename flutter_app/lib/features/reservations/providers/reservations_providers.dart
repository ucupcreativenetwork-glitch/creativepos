import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reservations_repository.dart';
import '../models/reservation_models.dart';

class ReservationsQuery {
  const ReservationsQuery({this.outletId, this.status, this.date});

  final int? outletId;
  final String? status;
  final String? date;

  @override
  bool operator ==(Object other) =>
      other is ReservationsQuery &&
      other.outletId == outletId &&
      other.status == status &&
      other.date == date;

  @override
  int get hashCode => Object.hash(outletId, status, date);
}

final reservationsListProvider = FutureProvider.autoDispose
    .family<List<ReservationModel>, ReservationsQuery>((ref, query) async {
  final result = await ref.watch(reservationsRepositoryProvider).listReservations(
        outletId: query.outletId,
        status: query.status,
        date: query.date,
      );
  return result.items;
});

final reservationSlotsProvider = FutureProvider.autoDispose
    .family<List<ReservationSlot>, ({int outletId, String date})>(
  (ref, params) async {
    return ref.watch(reservationsRepositoryProvider).getSlots(
          outletId: params.outletId,
          date: params.date,
        );
  },
);