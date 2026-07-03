import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/members_repository.dart';
import '../models/member_models.dart';

class MembersQuery {
  const MembersQuery({this.search, this.status});

  final String? search;
  final String? status;

  @override
  bool operator ==(Object other) =>
      other is MembersQuery && other.search == search && other.status == status;

  @override
  int get hashCode => Object.hash(search, status);
}

final membersListProvider = FutureProvider.autoDispose
    .family<({List<MemberModel> items, int total}), MembersQuery>(
  (ref, query) async {
    final result = await ref.watch(membersRepositoryProvider).listMembers(
          search: query.search,
          status: query.status,
        );
    return (items: result.items, total: result.meta.total);
  },
);

final memberDetailProvider =
    FutureProvider.autoDispose.family<MemberModel, String>((ref, uuid) async {
  return ref.watch(membersRepositoryProvider).getMember(uuid);
});

final memberPointsProvider =
    FutureProvider.autoDispose.family<PointBalanceDetail, String>(
  (ref, uuid) async {
    return ref.watch(membersRepositoryProvider).getPoints(uuid);
  },
);

final memberWalletTransactionsProvider =
    FutureProvider.autoDispose.family<List<WalletTransaction>, String>(
  (ref, uuid) async {
    return ref.watch(membersRepositoryProvider).getWalletTransactions(uuid);
  },
);

final memberTiersProvider =
    FutureProvider.autoDispose<List<MemberTier>>((ref) async {
  return ref.watch(membersRepositoryProvider).getTiers();
});