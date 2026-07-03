import '../../../core/utils/json_utils.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.uuid,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.status = 'active',
    this.roles = const [],
  });

  final int id;
  final String uuid;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String status;
  final List<String> roles;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: parseJsonInt(json['id']),
      uuid: parseJsonString(json['uuid']),
      name: parseJsonString(json['name']),
      email: parseJsonString(json['email']),
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      status: json['status'] as String? ?? 'active',
      roles: (json['roles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}

class TenantModel {
  const TenantModel({
    required this.id,
    required this.name,
    required this.slug,
    this.currency = 'IDR',
    this.timezone = 'Asia/Jakarta',
  });

  final int id;
  final String name;
  final String slug;
  final String currency;
  final String timezone;

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: parseJsonInt(json['id']),
      name: parseJsonString(json['name']),
      slug: parseJsonString(json['slug']),
      currency: json['currency'] as String? ?? 'IDR',
      timezone: json['timezone'] as String? ?? 'Asia/Jakarta',
    );
  }
}

class AuthSession {
  const AuthSession({
    this.token,
    required this.user,
    this.tenant,
    this.permissions = const [],
    this.requires2fa = false,
    this.pendingToken,
    this.twoFactorMethod,
  });

  final String? token;
  final UserModel user;
  final TenantModel? tenant;
  final List<String> permissions;
  final bool requires2fa;
  final String? pendingToken;
  final String? twoFactorMethod;

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: json['token'] as String?,
      requires2fa: json['requires_2fa'] == true,
      pendingToken: json['pending_token'] as String?,
      twoFactorMethod: json['two_factor_method'] as String?,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tenant: json['tenant'] != null
          ? TenantModel.fromJson(json['tenant'] as Map<String, dynamic>)
          : null,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}