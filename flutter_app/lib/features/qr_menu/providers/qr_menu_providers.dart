import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/public_menu_repository.dart';
import '../models/qr_menu_models.dart';

class QrMenuQuery {
  const QrMenuQuery({
    required this.tenantSlug,
    required this.outletSlug,
    this.tableToken,
  });

  final String tenantSlug;
  final String outletSlug;
  final String? tableToken;

  @override
  bool operator ==(Object other) =>
      other is QrMenuQuery &&
      other.tenantSlug == tenantSlug &&
      other.outletSlug == outletSlug &&
      other.tableToken == tableToken;

  @override
  int get hashCode => Object.hash(tenantSlug, outletSlug, tableToken);
}

final publicMenuProvider = FutureProvider.autoDispose
    .family<PublicMenuData, QrMenuQuery>((ref, query) async {
  final repo = ref.watch(publicMenuRepositoryProvider);
  if (query.tableToken != null && query.tableToken!.isNotEmpty) {
    return repo.getTableMenu(
      tenantSlug: query.tenantSlug,
      outletSlug: query.outletSlug,
      tableToken: query.tableToken!,
    );
  }
  return repo.getMenu(
    tenantSlug: query.tenantSlug,
    outletSlug: query.outletSlug,
  );
});

final publicOrderTrackProvider =
    FutureProvider.autoDispose.family<PublicOrderTrack, String>(
  (ref, uuid) async {
    return ref.watch(publicMenuRepositoryProvider).trackOrder(uuid);
  },
);