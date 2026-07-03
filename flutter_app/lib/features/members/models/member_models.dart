import '../../../core/utils/json_utils.dart';

class MemberModel {
  const MemberModel({
    required this.id,
    required this.uuid,
    required this.memberCode,
    required this.name,
    required this.phone,
    this.email,
    this.qrToken,
    this.status = 'active',
    this.totalSpend = 0,
    this.visitCount = 0,
    this.tier,
    this.points,
    this.wallet,
  });

  final int id;
  final String uuid;
  final String memberCode;
  final String name;
  final String phone;
  final String? email;
  final String? qrToken;
  final String status;
  final double totalSpend;
  final int visitCount;
  final MemberTier? tier;
  final MemberPoints? points;
  final MemberWallet? wallet;

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: parseJsonInt(json['id']),
      uuid: parseJsonString(json['uuid']),
      memberCode: parseJsonString(json['member_code']),
      name: parseJsonString(json['name']),
      phone: parseJsonString(json['phone']),
      email: json['email'] as String?,
      qrToken: json['qr_token'] as String?,
      status: parseJsonString(json['status'], fallback: 'active'),
      totalSpend: parseJsonDouble(json['total_spend']),
      visitCount: parseJsonInt(json['visit_count']),
      tier: json['tier'] != null
          ? MemberTier.fromJson(json['tier'] as Map<String, dynamic>)
          : null,
      points: json['points'] != null
          ? MemberPoints.fromJson(json['points'] as Map<String, dynamic>)
          : null,
      wallet: json['wallet'] != null
          ? MemberWallet.fromJson(json['wallet'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MemberTier {
  const MemberTier({
    required this.id,
    required this.name,
    required this.slug,
    this.minSpend = 0,
    this.pointMultiplier = 1,
  });

  final int id;
  final String name;
  final String slug;
  final double minSpend;
  final double pointMultiplier;

  factory MemberTier.fromJson(Map<String, dynamic> json) {
    return MemberTier(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      slug: json['slug'] as String? ?? '',
      minSpend: _toDouble(json['min_spend']),
      pointMultiplier: _toDouble(json['point_multiplier'], fallback: 1),
    );
  }
}

class MemberPoints {
  const MemberPoints({
    required this.balance,
    this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0,
  });

  final int balance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;

  factory MemberPoints.fromJson(Map<String, dynamic> json) {
    return MemberPoints(
      balance: json['balance'] as int? ?? 0,
      lifetimeEarned: json['lifetime_earned'] as int? ?? 0,
      lifetimeRedeemed: json['lifetime_redeemed'] as int? ?? 0,
    );
  }
}

class MemberWallet {
  const MemberWallet({
    required this.balance,
    this.lifetimeTopup = 0,
    this.lifetimeSpent = 0,
    this.status = 'active',
  });

  final double balance;
  final double lifetimeTopup;
  final double lifetimeSpent;
  final String status;

  factory MemberWallet.fromJson(Map<String, dynamic> json) {
    return MemberWallet(
      balance: _toDouble(json['balance']),
      lifetimeTopup: _toDouble(json['lifetime_topup']),
      lifetimeSpent: _toDouble(json['lifetime_spent']),
      status: json['status'] as String? ?? 'active',
    );
  }
}

class PointConfig {
  const PointConfig({
    this.redeemPoints = 100,
    this.redeemValue = 10000,
    this.minRedeemPoints = 100,
  });

  final int redeemPoints;
  final double redeemValue;
  final int minRedeemPoints;

  double discountForPoints(int points) {
    if (redeemPoints <= 0) return 0;
    return (points / redeemPoints) * redeemValue;
  }

  factory PointConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PointConfig();
    return PointConfig(
      redeemPoints: json['redeem_points'] as int? ?? 100,
      redeemValue: _toDouble(json['redeem_value']),
      minRedeemPoints: json['min_redeem_points'] as int? ?? 100,
    );
  }
}

class PointBalanceDetail {
  const PointBalanceDetail({
    required this.balance,
    this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0,
    this.config,
    this.history = const [],
  });

  final int balance;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final PointConfig? config;
  final List<PointTransaction> history;

  factory PointBalanceDetail.fromJson(Map<String, dynamic> json) {
    return PointBalanceDetail(
      balance: json['balance'] as int? ?? 0,
      lifetimeEarned: json['lifetime_earned'] as int? ?? 0,
      lifetimeRedeemed: json['lifetime_redeemed'] as int? ?? 0,
      config: json['config'] != null
          ? PointConfig.fromJson(json['config'] as Map<String, dynamic>)
          : null,
      history: (json['history'] as List<dynamic>? ?? [])
          .map((e) => PointTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.description,
    this.createdAt,
  });

  final int id;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String? createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: parseJsonInt(json['id']),
      type: parseJsonString(json['type']),
      amount: _toDouble(json['amount']),
      balanceBefore: _toDouble(json['balance_before']),
      balanceAfter: _toDouble(json['balance_after']),
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

class PointTransaction {
  const PointTransaction({
    required this.type,
    required this.points,
    required this.balanceAfter,
    this.description,
    this.createdAt,
  });

  final String type;
  final int points;
  final int balanceAfter;
  final String? description;
  final String? createdAt;

  factory PointTransaction.fromJson(Map<String, dynamic> json) {
    return PointTransaction(
      type: json['type'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      balanceAfter: json['balance_after'] as int? ?? 0,
      description: json['description'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

