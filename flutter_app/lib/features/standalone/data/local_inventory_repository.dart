import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../features/pos/models/pos_models.dart';
import '../../../local_database/database_helper.dart';
import '../../../services/offline_cache_service.dart';
import '../models/local_product.dart';

class LocalInventoryRepository {
  LocalInventoryRepository({
    DatabaseHelper? dbHelper,
    OfflineCacheService? cache,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _cache = cache;

  final DatabaseHelper _dbHelper;
  final OfflineCacheService? _cache;

  Future<List<LocalProduct>> listProducts({
    String? search,
    bool lowStockOnly = false,
  }) async {
    final db = await _dbHelper.database;
    final where = <String>[];
    final args = <Object?>[];

    final q = search?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      where.add(
        '(LOWER(name) LIKE ? OR LOWER(sku) LIKE ? OR LOWER(barcode) LIKE ?)',
      );
      args.addAll(['%$q%', '%$q%', '%$q%']);
    }
    if (lowStockOnly) {
      where.add('track_stock = 1 AND stock <= min_stock');
    }

    final rows = await db.query(
      'local_products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(LocalProduct.fromMap).toList();
  }

  Future<LocalProduct?> findById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'local_products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalProduct.fromMap(rows.first);
  }

  Future<LocalProduct?> findByBarcodeOrSku(String code) async {
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final db = await _dbHelper.database;
    final rows = await db.query(
      'local_products',
      where:
          'LOWER(barcode) = ? OR LOWER(sku) = ?',
      whereArgs: [normalized, normalized],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LocalProduct.fromMap(rows.first);
  }

  Future<LocalProduct> createProduct(LocalProduct draft) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final product = draft.copyWith(
      uuid: draft.uuid.isEmpty ? const Uuid().v4() : draft.uuid,
      createdAt: now,
      updatedAt: now,
    );

    final id = await db.insert('local_products', {
      'uuid': product.uuid,
      'name': product.name.trim(),
      'sku': product.sku.trim(),
      'barcode': product.barcode?.trim(),
      'base_price': product.basePrice,
      'stock': product.stock,
      'min_stock': product.minStock,
      'track_stock': product.trackStock ? 1 : 0,
      'category_name': product.categoryName,
      'created_at': product.createdAt,
      'updated_at': product.updatedAt,
    });

    if (product.stock > 0) {
      await _recordMovement(
        db: db,
        productId: id,
        quantity: product.stock,
        type: 'in',
        note: 'Stok awal',
      );
    }

    return (await findById(id))!;
  }

  Future<LocalProduct> updateProduct(LocalProduct product) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    await db.update(
      'local_products',
      {
        'name': product.name.trim(),
        'sku': product.sku.trim(),
        'barcode': product.barcode?.trim(),
        'base_price': product.basePrice,
        'stock': product.stock,
        'min_stock': product.minStock,
        'track_stock': product.trackStock ? 1 : 0,
        'category_name': product.categoryName,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [product.id],
    );
    return (await findById(product.id))!;
  }

  Future<void> deleteProduct(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'local_stock_movements',
      where: 'product_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'local_products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<LocalProduct> addStock({
    required int productId,
    required double quantity,
    String? note,
    String type = 'in',
  }) async {
    if (quantity == 0) {
      return (await findById(productId))!;
    }

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'local_products',
        where: 'id = ?',
        whereArgs: [productId],
        limit: 1,
      );
      if (rows.isEmpty) return;

      final current = LocalProduct.fromMap(rows.first);
      final newStock = current.stock + quantity;
      if (newStock < 0) {
        throw StateError('Stok tidak mencukupi');
      }

      await txn.update(
        'local_products',
        {
          'stock': newStock,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      await _recordMovement(
        db: txn,
        productId: productId,
        quantity: quantity,
        type: type,
        note: note,
      );
    });

    return (await findById(productId))!;
  }

  Future<void> deductStockForSale({
    required List<({int productId, double quantity})> items,
  }) async {
    for (final item in items) {
      final product = await findById(item.productId);
      if (product == null || !product.trackStock) continue;
      await addStock(
        productId: item.productId,
        quantity: -item.quantity,
        type: 'sale',
        note: 'Penjualan POS',
      );
    }
  }

  Future<LocalInventoryStats> getStats() async {
    final db = await _dbHelper.database;
    final productRows = await db.query('local_products');
    final products = productRows.map(LocalProduct.fromMap).toList();

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day)
        .toIso8601String();

    final movementRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity), 0) as total
      FROM local_stock_movements
      WHERE type = 'in' AND created_at >= ?
      ''',
      [todayStart],
    );
    final todayStockIn =
        (movementRows.first['total'] as num?)?.toDouble() ?? 0;

    var lowStock = 0;
    var stockValue = 0.0;
    for (final p in products) {
      if (p.isLowStock) lowStock++;
      stockValue += p.stock * p.basePrice;
    }

    return LocalInventoryStats(
      totalProducts: products.length,
      lowStockCount: lowStock,
      totalStockValue: stockValue,
      todayStockIn: todayStockIn,
    );
  }

  Future<void> syncCatalogToCache({OfflineCacheService? cache}) async {
    final target = cache ?? _cache;
    if (target == null) return;

    final products = await listProducts();
    final categories = <String, PosCategory>{};
    var categoryId = 1;

    final posProducts = <PosProduct>[];
    for (final p in products) {
      PosCategory? category;
      final catName = p.categoryName?.trim();
      if (catName != null && catName.isNotEmpty) {
        category = categories.putIfAbsent(
          catName.toLowerCase(),
          () => PosCategory(id: categoryId++, uuid: const Uuid().v4(), name: catName),
        );
      }

      posProducts.add(
        PosProduct(
          id: p.id,
          uuid: p.uuid,
          name: p.name,
          sku: p.sku,
          barcode: p.barcode,
          basePrice: p.basePrice,
          category: category,
          totalStock: p.stock,
          trackStock: p.trackStock,
        ),
      );
    }

    const cashMethod = PaymentMethod(
      id: 1,
      code: 'cash',
      name: 'Tunai',
      type: 'cash',
    );

    await target.saveCatalog(
      products: posProducts,
      categories: categories.values.toList(),
      methods: const [cashMethod],
    );
  }

  Future<void> _recordMovement({
    required DatabaseExecutor db,
    required int productId,
    required double quantity,
    required String type,
    String? note,
  }) async {
    await db.insert('local_stock_movements', {
      'product_id': productId,
      'quantity': quantity,
      'type': type,
      if (note != null && note.isNotEmpty) 'note': note,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}