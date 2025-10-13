import 'package:drift/drift.dart';

import 'drift_database.dart';

/// Drift-backed local repository providing the same API used by SimpleDatabase
class LocalRepository {
  LocalRepository._();
  static LocalRepository? _instance;
  static LocalRepository get instance => _instance ??= LocalRepository._();

  final AppDatabase _db = AppDatabase();

  // ========== Products ==========
  Future<String> insertProduct(Map<String, dynamic> product) async {
    final String id = product['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _db.upsertProduct(ProductsTableCompanion(
      id: Value(id),
      name: Value(product['name']?.toString() ?? ''),
      wholesalePrice: Value((product['wholesalePrice'] as num?)?.toInt() ?? 0),
      retailPrice: Value((product['retailPrice'] as num?)?.toInt() ?? 0),
      savedAt: Value(
          product['savedAt']?.toString() ?? DateTime.now().toIso8601String()),
      userId: Value(product['userId']?.toString()),
      isSynced: const Value(false),
      lastModified: Value(product['lastModified']?.toString() ??
          DateTime.now().toIso8601String()),
    ));
    return id;
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    await _db.upsertProduct(ProductsTableCompanion(
      id: Value(product['id']?.toString() ?? ''),
      name: Value(product['name']?.toString() ?? ''),
      wholesalePrice: Value((product['wholesalePrice'] as num?)?.toInt() ?? 0),
      retailPrice: Value((product['retailPrice'] as num?)?.toInt() ?? 0),
      savedAt: Value(
          product['savedAt']?.toString() ?? DateTime.now().toIso8601String()),
      userId: Value(product['userId']?.toString()),
      isSynced: const Value(false),
      lastModified: Value(product['lastModified']?.toString() ??
          DateTime.now().toIso8601String()),
    ));
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final List<ProductsTableData> rows = await _db.getAllProducts();
    return rows
        .map((ProductsTableData e) => <String, dynamic>{
              'id': e.id,
              'name': e.name,
              'wholesalePrice': e.wholesalePrice,
              'retailPrice': e.retailPrice,
              'savedAt': e.savedAt,
              'userId': e.userId,
              'isSynced': e.isSynced,
              'lastModified': e.lastModified,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    final List<ProductsTableData> rows = await _db.getUnsyncedProducts();
    return rows
        .map((ProductsTableData e) => <String, dynamic>{
              'id': e.id,
              'name': e.name,
              'wholesalePrice': e.wholesalePrice,
              'retailPrice': e.retailPrice,
              'savedAt': e.savedAt,
              'userId': e.userId,
              'isSynced': e.isSynced,
              'lastModified': e.lastModified,
            })
        .toList();
  }

  Future<void> markProductAsSynced(String productId) =>
      _db.markProductAsSynced(productId);

  // ========== Inventory ==========
  Future<String> insertInventoryItem(Map<String, dynamic> item) async {
    final String id = item['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    await _db.upsertInventoryItem(InventoryTableCompanion(
      id: Value(id),
      name: Value(item['name']?.toString() ?? ''),
      barcode: Value(item['barcode']?.toString()),
      wholesalePrice: Value((item['wholesalePrice'] as num?)?.toInt() ?? 0),
      retailPrice: Value((item['retailPrice'] as num?)?.toInt() ?? 0),
      quantity: Value((item['quantity'] as num?)?.toInt() ?? 0),
      originalQuantity: Value((item['originalQuantity'] as num?)?.toInt() ?? 0),
      addedDate: Value(
          item['addedDate']?.toString() ?? DateTime.now().toIso8601String()),
      addedTime: Value(
          item['addedTime']?.toString() ?? DateTime.now().toIso8601String()),
      userId: Value(item['userId']?.toString()),
      isSynced: const Value(false),
      lastModified: Value(
          item['lastModified']?.toString() ?? DateTime.now().toIso8601String()),
    ));
    return id;
  }

  Future<void> updateInventoryItem(Map<String, dynamic> item) async {
    await _db.upsertInventoryItem(InventoryTableCompanion(
      id: Value(item['id']?.toString() ?? ''),
      name: Value(item['name']?.toString() ?? ''),
      barcode: Value(item['barcode']?.toString()),
      wholesalePrice: Value((item['wholesalePrice'] as num?)?.toInt() ?? 0),
      retailPrice: Value((item['retailPrice'] as num?)?.toInt() ?? 0),
      quantity: Value((item['quantity'] as num?)?.toInt() ?? 0),
      originalQuantity: Value((item['originalQuantity'] as num?)?.toInt() ?? 0),
      addedDate: Value(
          item['addedDate']?.toString() ?? DateTime.now().toIso8601String()),
      addedTime: Value(
          item['addedTime']?.toString() ?? DateTime.now().toIso8601String()),
      userId: Value(item['userId']?.toString()),
      isSynced: const Value(false),
      lastModified: Value(
          item['lastModified']?.toString() ?? DateTime.now().toIso8601String()),
    ));
  }

  Future<void> deleteInventoryItem(String itemId) =>
      _db.deleteInventoryItemById(itemId);

  Future<List<Map<String, dynamic>>> getAllInventoryItems() async {
    final List<InventoryTableData> rows = await _db.getAllInventoryItems();
    return rows
        .map((InventoryTableData e) => <String, dynamic>{
              'id': e.id,
              'name': e.name,
              'barcode': e.barcode,
              'wholesalePrice': e.wholesalePrice,
              'retailPrice': e.retailPrice,
              'quantity': e.quantity,
              'originalQuantity': e.originalQuantity,
              'addedDate': e.addedDate,
              'addedTime': e.addedTime,
              'userId': e.userId,
              'isSynced': e.isSynced,
              'lastModified': e.lastModified,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> getUnsyncedInventoryItems() async {
    final List<InventoryTableData> rows = await _db.getUnsyncedInventoryItems();
    return rows
        .map((InventoryTableData e) => <String, dynamic>{
              'id': e.id,
              'name': e.name,
              'barcode': e.barcode,
              'wholesalePrice': e.wholesalePrice,
              'retailPrice': e.retailPrice,
              'quantity': e.quantity,
              'originalQuantity': e.originalQuantity,
              'addedDate': e.addedDate,
              'addedTime': e.addedTime,
              'userId': e.userId,
              'isSynced': e.isSynced,
              'lastModified': e.lastModified,
            })
        .toList();
  }

  Future<void> markInventoryItemAsSynced(String itemId) =>
      _db.markInventoryItemAsSynced(itemId);

  // ========== Sync Operations ==========
  Future<int> addSyncOperation(
          String operation, String tableName, String recordId, String data) =>
      _db.addSyncOperation(SyncOperationsTableCompanion(
        operation: Value(operation),
        targetTable: Value(tableName),
        recordId: Value(recordId),
        data: Value(data),
        timestamp: Value(DateTime.now().toIso8601String()),
        createdAt: Value(DateTime.now().toIso8601String()),
        isProcessed: const Value(false),
        retryCount: const Value(0),
      ));

  Future<List<Map<String, dynamic>>> getUnprocessedOperations() async {
    final List<SyncOperationsTableData> rows =
        await _db.getUnprocessedOperations();
    return rows
        .map((SyncOperationsTableData e) => <String, dynamic>{
              'id': e.id,
              'operation': e.operation,
              'tableName': e.targetTable,
              'recordId': e.recordId,
              'data': e.data,
              'timestamp': e.timestamp,
              'isProcessed': e.isProcessed,
              'retryCount': e.retryCount,
            })
        .toList();
  }

  Future<void> markOperationAsProcessed(int id) =>
      _db.markOperationAsProcessed(id);

  Future<void> incrementRetryCount(int id) => _db.incrementRetryCount(id);

  Future<void> cleanupProcessedOperations() =>
      _db.cleanupProcessedOperations(const Duration(days: 7));

  // ========== Stats ==========
  Future<int> getProductCount() => _db.getProductCount();
  Future<int> getInventoryCount() => _db.getInventoryCount();
  Future<int> getUnprocessedOperationsCount() =>
      _db.getUnprocessedOperationsCount();

  // ========== Maintenance ==========
  Future<void> clearAllData() async {
    await _db.customUpdate(
      'DELETE FROM products_table',
      updates: <ResultSetImplementation<dynamic, dynamic>>{_db.productsTable},
    );
    await _db.customUpdate(
      'DELETE FROM inventory_table',
      updates: <ResultSetImplementation<dynamic, dynamic>>{_db.inventoryTable},
    );
    await _db.customUpdate(
      'DELETE FROM sync_operations_table',
      updates: <ResultSetImplementation<dynamic, dynamic>>{
        _db.syncOperationsTable
      },
    );
  }
}
