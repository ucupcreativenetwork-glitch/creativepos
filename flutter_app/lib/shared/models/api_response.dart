class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.meta,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic value)? parser,
  ) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: parser != null && json['data'] != null
          ? parser(json['data'])
          : json['data'] as T?,
      meta: json['meta'] as Map<String, dynamic>?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}

class PaginationMeta {
  const PaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      currentPage: json['current_page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 15,
      total: json['total'] as int? ?? 0,
      lastPage: json['last_page'] as int? ?? 1,
    );
  }
}