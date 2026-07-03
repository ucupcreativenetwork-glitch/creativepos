import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/models/api_response.dart';
import '../models/member_detail_key.dart';
import '../models/member_models.dart';

class MembersRepository {
  MembersRepository(this._dio);

  final Dio _dio;

  Future<({List<MemberModel> items, PaginationMeta meta})> listMembers({
    String? search,
    String? status,
    int page = 1,
  }) async {
    return _dio.getPaginatedApi<MemberModel>(
      ApiPaths.members,
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        'page': page,
        'per_page': 20,
      },
      itemParser: MemberModel.fromJson,
    );
  }

  Future<MemberModel> getMemberDetail({
    required int id,
    String? uuid,
  }) async {
    final identifier = uuid != null && uuid.isNotEmpty ? uuid : id.toString();
    final response = await _dio.getApi<MemberModel>(
      '${ApiPaths.members}/$identifier',
      parser: (data) => MemberModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<MemberModel> findByCode(String code) async {
    final response = await _dio.getApi<MemberModel>(
      '${ApiPaths.members}/code/$code',
      parser: (data) => MemberModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<MemberModel> findByQrToken(String token) async {
    final response = await _dio.getApi<MemberModel>(
      '${ApiPaths.members}/qr/$token',
      parser: (data) => MemberModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<MemberModel> createMember(Map<String, dynamic> payload) async {
    final response = await _dio.postApi<MemberModel>(
      ApiPaths.members,
      data: payload,
      parser: (data) => MemberModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<MemberModel> updateMember(
    String uuid,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.putApi<MemberModel>(
      '${ApiPaths.members}/$uuid',
      data: payload,
      parser: (data) => MemberModel.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<PointBalanceDetail> getPoints(MemberDetailKey key) async {
    final response = await _dio.getApi<PointBalanceDetail>(
      '${ApiPaths.members}/${key.pathSegment}/points',
      parser: (data) =>
          PointBalanceDetail.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<void> redeemPoints(
    MemberDetailKey key, {
    required int points,
    String? description,
  }) async {
    await _dio.postApi(
      '${ApiPaths.members}/${key.pathSegment}/points/redeem',
      data: {
        'points': points,
        if (description != null) 'description': description,
      },
    );
  }

  Future<MemberWallet> getWallet(String memberUuid) async {
    final response = await _dio.getApi<MemberWallet>(
      ApiPaths.walletMember(memberUuid),
      parser: (data) {
        final m = data as Map<String, dynamic>;
        return MemberWallet(
          balance: _toDouble(m['balance']),
          status: m['status'] as String? ?? 'active',
        );
      },
    );
    return response.data ?? const MemberWallet(balance: 0, status: 'inactive');
  }

  Future<List<WalletTransaction>> getWalletTransactions(
    MemberDetailKey key, {
    int page = 1,
  }) async {
    final result = await _dio.getPaginatedApi<WalletTransaction>(
      ApiPaths.walletTransactions(key.pathSegment),
      queryParameters: {'page': page, 'per_page': 20},
      itemParser: WalletTransaction.fromJson,
    );
    return result.items;
  }

  Future<MemberTier> updateTier(
    int tierId, {
    String? name,
    double? minSpend,
    double? pointMultiplier,
  }) async {
    final response = await _dio.putApi<MemberTier>(
      ApiPaths.loyaltyTier(tierId),
      data: {
        if (name != null) 'name': name,
        if (minSpend != null) 'min_spend': minSpend,
        if (pointMultiplier != null) 'point_multiplier': pointMultiplier,
      },
      parser: (data) => MemberTier.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<List<MemberTier>> getTiers() async {
    final response = await _dio.getApi<List<MemberTier>>(
      ApiPaths.membersTiers,
      parser: (data) => (data as List<dynamic>)
          .map((e) => MemberTier.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? [];
  }

  Future<MemberWallet> topupWallet({
    required int memberId,
    required double amount,
    String? description,
  }) async {
    final response = await _dio.postApi<Map<String, dynamic>>(
      '${ApiPaths.wallet}/topup',
      data: {
        'member_id': memberId,
        'amount': amount,
        if (description != null) 'description': description,
      },
      parser: (data) => data as Map<String, dynamic>,
    );
    final data = response.data ?? {};
    return MemberWallet(
      balance: _toDouble(data['balance']),
      status: 'active',
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

final membersRepositoryProvider = Provider<MembersRepository>((ref) {
  return MembersRepository(ref.watch(dioProvider));
});