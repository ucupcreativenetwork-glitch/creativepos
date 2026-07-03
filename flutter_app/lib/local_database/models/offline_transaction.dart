class OfflineTransaction {
  const OfflineTransaction({
    required this.id,
    required this.idempotencyKey,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.errorMessage,
    this.syncedAt,
    this.retryCount = 0,
  });

  final int id;
  final String idempotencyKey;
  final Map<String, dynamic> payload;
  final String status;
  final String? errorMessage;
  final String createdAt;
  final String? syncedAt;
  final int retryCount;

  bool get isPending => status == 'pending' || status == 'failed';

  factory OfflineTransaction.fromMap(Map<String, dynamic> map) {
    return OfflineTransaction(
      id: map['id'] as int,
      idempotencyKey: map['idempotency_key'] as String,
      payload: {},
      status: map['status'] as String? ?? 'pending',
      errorMessage: map['error_message'] as String?,
      createdAt: map['created_at'] as String,
      syncedAt: map['synced_at'] as String?,
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  OfflineTransaction copyWithPayload(Map<String, dynamic> payload) {
    return OfflineTransaction(
      id: id,
      idempotencyKey: idempotencyKey,
      payload: payload,
      status: status,
      errorMessage: errorMessage,
      createdAt: createdAt,
      syncedAt: syncedAt,
      retryCount: retryCount,
    );
  }
}