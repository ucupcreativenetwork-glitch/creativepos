import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
    String deviceName = 'CreativePOS Android',
  }) async {
    final response = await _dio.postApi<AuthSession>(
      ApiPaths.login,
      data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      },
      parser: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<AuthSession> verifyTwoFactor({
    required String pendingToken,
    required String code,
    String deviceName = 'CreativePOS Android',
  }) async {
    final response = await _dio.postApi<AuthSession>(
      ApiPaths.login2fa,
      data: {
        'pending_token': pendingToken,
        'code': code,
        'device_name': deviceName,
      },
      parser: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<AuthSession> me() async {
    final response = await _dio.getApi<AuthSession>(
      ApiPaths.me,
      parser: (data) => AuthSession.fromJson(data as Map<String, dynamic>),
    );
    if (!response.success || response.data == null) {
      throw Exception(response.message);
    }
    return response.data!;
  }

  Future<void> logout() async {
    await _dio.postApi(ApiPaths.logout);
  }

  Future<bool> healthCheck() async {
    final response = await _dio.getApi(ApiPaths.health);
    return response.success;
  }
}