import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/app_exception.dart';
import '../../shared/models/api_response.dart';
import 'api_interceptor.dart';
import '../../features/auth/providers/auth_providers.dart';

final dioProvider = Provider<Dio>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(ApiInterceptor(ref));
  return dio;
});

extension DioApi on Dio {
  Future<ApiResponse<T>> getApi<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic value)? parser,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return _parseApiResponse(response.data ?? {}, parser);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> postApi<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    T Function(dynamic value)? parser,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return _parseApiResponse(response.data ?? {}, parser);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> putApi<T>(
    String path, {
    Object? data,
    T Function(dynamic value)? parser,
  }) async {
    try {
      final response = await put<Map<String, dynamic>>(path, data: data);
      return _parseApiResponse(response.data ?? {}, parser);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> patchApi<T>(
    String path, {
    Object? data,
    T Function(dynamic value)? parser,
  }) async {
    try {
      final response = await patch<Map<String, dynamic>>(path, data: data);
      return _parseApiResponse(response.data ?? {}, parser);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<T>> deleteApi<T>(
    String path, {
    T Function(dynamic value)? parser,
  }) async {
    try {
      final response = await delete<Map<String, dynamic>>(path);
      return _parseApiResponse(response.data ?? {}, parser);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<({List<T> items, PaginationMeta meta})> getPaginatedApi<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic> json) itemParser,
  }) async {
    try {
      final response = await get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final parsed = _parseApiResponse<List<T>>(
        response.data ?? {},
        (data) => (data as List<dynamic>)
            .map((e) => itemParser(e as Map<String, dynamic>))
            .toList(),
      );
      return (
        items: parsed.data ?? [],
        meta: PaginationMeta.fromJson(parsed.meta ?? {}),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }
}

ApiResponse<T> _parseApiResponse<T>(
  Map<String, dynamic> json,
  T Function(dynamic value)? parser,
) {
  final result = ApiResponse.fromJson(json, parser);
  if (result.success == false && result.message.isNotEmpty) {
    throw ServerException(result.message);
  }
  return result;
}

Never _mapError(DioException e) {
  if (e.error is AppException) {
    throw e.error as AppException;
  }
  final message = e.response?.data is Map
      ? (e.response!.data['message']?.toString() ?? 'Permintaan gagal')
      : 'Permintaan gagal';
  throw ServerException(message);
}