/// Offline POS transaction queue — SQLite-backed sync with idempotency keys.
abstract final class OfflineQueue {
  static const String hiveBoxName = 'offline_meta';
  static const String tableName = 'offline_transactions';
}