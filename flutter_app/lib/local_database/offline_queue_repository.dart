import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';
import 'models/offline_transaction.dart';

class OfflineQueueRepository {
  Future<int> enqueue({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('offline_transactions', {
      'idempotency_key': idempotencyKey,
      'payload': jsonEncode(payload),
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Transaksi lokal mode standalone — tidak perlu sync ke server.
  Future<int> enqueueLocal({
    required String idempotencyKey,
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('offline_transactions', {
      'idempotency_key': idempotencyKey,
      'payload': jsonEncode({...payload, 'standalone': true}),
      'status': 'local',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<OfflineTransaction>> listPending() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'offline_transactions',
      where: "status IN ('pending', 'failed', 'syncing')",
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<OfflineTransaction>> listAll({int limit = 50}) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'offline_transactions',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> pendingCount() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM offline_transactions WHERE status IN ('pending', 'failed')",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> markSyncing(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'offline_transactions',
      {'status': 'syncing'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSynced(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'offline_transactions',
      {
        'status': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
        'error_message': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFailed(int id, String error, {int? retryCount}) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'offline_transactions',
      {
        'status': 'failed',
        'error_message': error,
        if (retryCount != null) 'retry_count': retryCount,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> resetStuckSyncing() async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'offline_transactions',
      {'status': 'pending'},
      where: "status = 'syncing'",
    );
  }

  Future<void> resetToPending(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'offline_transactions',
      {'status': 'pending', 'error_message': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSynced({int keepLast = 100}) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawDelete('''
      DELETE FROM offline_transactions
      WHERE status = 'synced' AND id NOT IN (
        SELECT id FROM offline_transactions
        WHERE status = 'synced'
        ORDER BY synced_at DESC
        LIMIT ?
      )
    ''', [keepLast]);
  }

  OfflineTransaction _fromRow(Map<String, dynamic> row) {
    final payloadJson = row['payload'] as String? ?? '{}';
    final payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    return OfflineTransaction.fromMap(row).copyWithPayload(payload);
  }
}

final offlineQueueRepositoryProvider = Provider<OfflineQueueRepository>((ref) {
  return OfflineQueueRepository();
});