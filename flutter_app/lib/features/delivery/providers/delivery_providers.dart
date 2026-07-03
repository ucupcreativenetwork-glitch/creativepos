import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/delivery_repository.dart';
import '../models/delivery_models.dart';

class DeliveryQuery {
  const DeliveryQuery({this.outletId, this.status});

  final int? outletId;
  final String? status;

  @override
  bool operator ==(Object other) =>
      other is DeliveryQuery &&
      other.outletId == outletId &&
      other.status == status;

  @override
  int get hashCode => Object.hash(outletId, status);
}

final deliveryOrdersProvider = FutureProvider.autoDispose
    .family<List<DeliveryOrderModel>, DeliveryQuery>((ref, query) async {
  final result = await ref.watch(deliveryRepositoryProvider).listOrders(
        outletId: query.outletId,
        status: query.status,
      );
  return result.items;
});

final deliveryDetailProvider =
    FutureProvider.autoDispose.family<DeliveryOrderModel, String>(
  (ref, uuid) async {
    return ref.watch(deliveryRepositoryProvider).getOrder(uuid);
  },
);