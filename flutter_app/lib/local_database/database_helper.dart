import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'creativepos_mobile.db';
  static const _dbVersion = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createV1Tables(db);
        await _createV2Tables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
      },
    );
  }

  Future<void> _createV1Tables(Database db) async {
    await db.execute('''
      CREATE TABLE offline_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        idempotency_key TEXT NOT NULL UNIQUE,
        payload TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        error_message TEXT,
        created_at TEXT NOT NULL,
        synced_at TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_offline_status ON offline_transactions(status)',
    );
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        sku TEXT NOT NULL,
        barcode TEXT,
        base_price REAL NOT NULL DEFAULT 0,
        stock REAL NOT NULL DEFAULT 0,
        min_stock INTEGER NOT NULL DEFAULT 0,
        track_stock INTEGER NOT NULL DEFAULT 1,
        category_name TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_products_barcode ON local_products(barcode)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_local_products_sku ON local_products(sku)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS local_stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES local_products(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_movements_product ON local_stock_movements(product_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_stock_movements_created ON local_stock_movements(created_at)',
    );
  }
}