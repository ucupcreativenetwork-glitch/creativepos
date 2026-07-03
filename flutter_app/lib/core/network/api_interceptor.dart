import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import '../../features/auth/providers/auth_providers.dart';

class ApiInterceptor extends Interceptor {
  ApiInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authTokenProvider);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    final tenantId = _ref.read(authControllerProvider).session?.tenant?.id;
    if (tenantId != null) {
      options.headers['X-Tenant-ID'] = tenantId.toString();
    }

    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.headers.putIfAbsent('Content-Type', () => 'application/json');
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;
    if (response?.statusCode == 401) {
      unawaited(_ref.read(authControllerProvider.notifier).handleUnauthorized());
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const UnauthorizedException(),
        ),
      );
      return;
    }

    if (response?.statusCode == 403) {
      final data = response?.data;
      final message = data is Map
          ? data['message']?.toString() ??
              'Fitur ini tidak tersedia di paket langganan Anda'
          : 'Akses ditolak';
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: FeatureNotAvailableException(message),
        ),
      );
      return;
    }

    if (response?.statusCode == 422) {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final errors = <String, List<String>>{};
        final raw = data['errors'];
        if (raw is Map) {
          raw.forEach((key, value) {
            if (value is List) {
              errors[key.toString()] = value.map((e) => e.toString()).toList();
            }
          });
        }
        handler.reject(
          DioException(
            requestOptions: err.requestOptions,
            error: ValidationException(
              data['message']?.toString() ?? 'Validasi gagal',
              fieldErrors: errors,
            ),
          ),
        );
        return;
      }
    }

    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(),
        ),
      );
      return;
    }

    handler.next(err);
  }
}