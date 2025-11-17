import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/src/ffi/api.dart';

import 'database_config.dart';

part 'drift_database.g.dart';

// ========== Drift Tables ==========

class ProductsTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get wholesalePrice => integer().withDefault(const Constant(0))();
  IntColumn get retailPrice => integer().withDefault(const Constant(0))();
  TextColumn get savedAt => text()(); // ISO8601
  TextColumn get userId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get lastModified => text()();

  // حقول جديدة محسنة
  TextColumn get description => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get supplier => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get images => text().nullable()(); // JSON string
  TextColumn get tags => text().nullable()(); // JSON string
  RealColumn get weight => real().nullable()();
  TextColumn get dimensions => text().nullable()();
  IntColumn get minimumStock => integer().nullable()();
  IntColumn get maximumStock => integer().nullable()();
  RealColumn get taxRate => real().nullable()();
  RealColumn get discountRate => real().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};
}

class InventoryTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  IntColumn get wholesalePrice => integer().withDefault(const Constant(0))();
  IntColumn get retailPrice => integer().withDefault(const Constant(0))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get originalQuantity => integer().withDefault(const Constant(0))();
  TextColumn get addedDate => text()(); // ISO8601
  TextColumn get addedTime => text()(); // ISO8601
  TextColumn get userId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get lastModified => text()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};
}

class SyncOperationsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();
  // Avoid name clash with Table.tableName
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get data => text()();
  TextColumn get timestamp => text()();
  TextColumn get createdAt => text()();
  BoolColumn get isProcessed => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

class SalesTable extends Table {
  TextColumn get id => text()();
  TextColumn get items => text()(); // JSON string of CartItem list
  IntColumn get totalAmount => integer().withDefault(const Constant(0))();
  IntColumn get totalProfit => integer().withDefault(const Constant(0))();
  TextColumn get saleDate => text()(); // ISO8601
  TextColumn get customerName => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get paymentMethod => text().withDefault(const Constant('نقدي'))();
  IntColumn get discount => integer().withDefault(const Constant(0))();
  TextColumn get userId => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get lastModified => text()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(tables: <Type>[
  ProductsTable,
  InventoryTable,
  SyncOperationsTable,
  SalesTable
])
class AppDatabase extends _$AppDatabase {
  factory AppDatabase() => _instance;

  AppDatabase._internal() : super(_openConnection());
  static final AppDatabase _instance = AppDatabase._internal();
  static AppDatabase get instance => _instance;

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createOptimizedIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // إضافة الحقول الجديدة للمنتجات مع معالجة الأخطاء
            try {
              await m.addColumn(productsTable, productsTable.description);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.barcode);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.category);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.supplier);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.status);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.images);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.tags);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.weight);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.dimensions);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.minimumStock);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.maximumStock);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.taxRate);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.discountRate);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.isActive);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
            try {
              await m.addColumn(productsTable, productsTable.notes);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
          }
          if (from < 3) {
            // إضافة حقل createdAt لجدول العمليات مع SQL مباشر
            try {
              await m.database.customStatement(
                  'ALTER TABLE sync_operations_table ADD COLUMN created_at TEXT NOT NULL DEFAULT (datetime(\'now\'))');
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
          }
          if (from < 4) {
            // تحسينات خاصة بـ Windows
            try {
              // إنشاء فهارس محسنة للأداء
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_name_windows ON products_table(name)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_user_id_windows ON products_table(user_id)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_synced_windows ON products_table(is_synced)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_inventory_name_windows ON inventory_table(name)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_inventory_user_id_windows ON inventory_table(user_id)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_inventory_synced_windows ON inventory_table(is_synced)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sales_date_windows ON sales_table(sale_date)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sales_user_id_windows ON sales_table(user_id)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sales_synced_windows ON sales_table(is_synced)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sync_ops_timestamp_windows ON sync_operations_table(timestamp)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sync_ops_processed_windows ON sync_operations_table(is_processed)');
            } catch (e) {
              debugPrint('خطأ في إنشاء الفهارس: $e');
            }
          }
          if (from < 5) {
            // إضافة حقل retailPrice لجدول المخزون
            try {
              await m.addColumn(inventoryTable, inventoryTable.retailPrice);
            } catch (e) {
              if (!e.toString().contains('duplicate column name')) rethrow;
            }
          }
          if (from < 6) {
            // إضافة فهارس مركبة محسنة وإزالة التكرار في PRAGMA
            try {
              // فهارس مركبة للأداء
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_user_synced ON products_table(user_id, is_synced)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_inventory_barcode ON inventory_table(barcode)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_inventory_user_synced ON inventory_table(user_id, is_synced)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sales_user_synced ON sales_table(user_id, is_synced)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_sync_ops_cleanup ON sync_operations_table(is_processed, timestamp)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_category ON products_table(category)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_supplier ON products_table(supplier)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_status ON products_table(status)');
              await m.database.customStatement(
                  'CREATE INDEX IF NOT EXISTS idx_products_active ON products_table(is_active)');
            } catch (e) {
              debugPrint('خطأ في إنشاء الفهارس المركبة: $e');
            }
          }
          if (from < 7) {
            // تحسين شامل للفهارس - إزالة التكرار وإنشاء فهارس محسنة
            try {
              await _createOptimizedIndexes();
              debugPrint('✅ تم إنشاء Database Indexes المحسنة');
            } catch (e) {
              debugPrint('خطأ في إنشاء الفهارس المحسنة: $e');
            }
          }
          if (from < 8) {
            // إصلاح جدول المبيعات المفقود
            try {
              await m.database.customStatement('''
                CREATE TABLE IF NOT EXISTS sales_table (
                  id TEXT PRIMARY KEY,
                  items TEXT NOT NULL,
                  total_amount INTEGER NOT NULL DEFAULT 0,
                  total_profit INTEGER NOT NULL DEFAULT 0,
                  sale_date TEXT NOT NULL,
                  customer_name TEXT,
                  notes TEXT,
                  payment_method TEXT NOT NULL DEFAULT 'نقدي',
                  discount INTEGER NOT NULL DEFAULT 0,
                  user_id TEXT,
                  is_synced INTEGER NOT NULL DEFAULT 0,
                  last_modified TEXT NOT NULL
                )
              ''');
              debugPrint('✅ تم إنشاء جدول المبيعات');
            } catch (e) {
              debugPrint('خطأ في إنشاء جدول المبيعات: $e');
            }
          }
        },
      );

  /// إنشاء فهارس محسنة شاملة لتحسين الأداء
  Future<void> _createOptimizedIndexes() async {
    try {
      // ========== فهارس المنتجات الأساسية ==========

      // فهرس البحث بالاسم (الأهم للبحث السريع)
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_name_optimized ON products_table(name COLLATE NOCASE)');

      // فهرس الباركود للبحث السريع
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_barcode_optimized ON products_table(barcode)');

      // فهرس الفئة للتصفية السريعة
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_category_optimized ON products_table(category)');

      // فهرس المورد للتصفية
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_supplier_optimized ON products_table(supplier)');

      // فهرس الحالة (نشط/غير نشط)
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_status_optimized ON products_table(status)');

      // فهرس النشاط
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_active_optimized ON products_table(is_active)');

      // فهرس تاريخ الحفظ للترتيب الزمني
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_saved_at_optimized ON products_table(saved_at)');

      // فهرس آخر تعديل
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_last_modified_optimized ON products_table(last_modified)');

      // فهارس مركبة للأداء المحسن
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_user_active_synced ON products_table(user_id, is_active, is_synced)');

      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_category_active ON products_table(category, is_active)');

      // ========== فهارس المخزون الأساسية ==========

      // فهرس البحث بالاسم
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_name_optimized ON inventory_table(name COLLATE NOCASE)');

      // فهرس الباركود
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_barcode_optimized ON inventory_table(barcode)');

      // فهرس الكمية للبحث عن المخزون المنخفض
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_quantity_optimized ON inventory_table(quantity)');

      // فهرس تاريخ الإضافة
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_added_date_optimized ON inventory_table(added_date)');

      // فهرس آخر تعديل
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_last_modified_optimized ON inventory_table(last_modified)');

      // فهارس مركبة للمخزون
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_user_synced_optimized ON inventory_table(user_id, is_synced)');

      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_quantity_synced ON inventory_table(quantity, is_synced)');

      // ========== فهارس المبيعات الأساسية ==========

      // فهرس تاريخ البيع للتقارير
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_date_optimized ON sales_table(sale_date)');

      // فهرس المبلغ الإجمالي للترتيب
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_total_amount_optimized ON sales_table(total_amount)');

      // فهرس الربح الإجمالي
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_total_profit_optimized ON sales_table(total_profit)');

      // فهرس طريقة الدفع
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_payment_method_optimized ON sales_table(payment_method)');

      // فهرس آخر تعديل
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_last_modified_optimized ON sales_table(last_modified)');

      // فهارس مركبة للمبيعات
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_user_synced_optimized ON sales_table(user_id, is_synced)');

      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_date_user ON sales_table(sale_date, user_id)');

      // ========== فهارس عمليات المزامنة ==========

      // فهرس المعالجة والوقت للتنظيف
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_ops_processed_timestamp_optimized ON sync_operations_table(is_processed, timestamp)');

      // فهرس نوع العملية
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_ops_operation_optimized ON sync_operations_table(operation)');

      // فهرس الجدول المستهدف
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_ops_target_table_optimized ON sync_operations_table(target_table)');

      // فهرس عدد المحاولات
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_ops_retry_count_optimized ON sync_operations_table(retry_count)');

      // فهرس مركب للعمليات غير المعالجة
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sync_ops_unprocessed_optimized ON sync_operations_table(is_processed, retry_count, timestamp)');

      // ========== فهارس خاصة بالبحث المتقدم ==========

      // فهرس البحث النصي للمنتجات (FTS-like)
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_products_search_text ON products_table(name, description, category, supplier)');

      // فهرس البحث النصي للمخزون
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_search_text ON inventory_table(name, barcode)');

      // ========== فهارس الأداء المتقدم ==========

      // فهرس للتقارير اليومية
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_daily_reports ON sales_table(sale_date, user_id, total_amount)');

      // فهرس للمنتجات الأكثر مبيعاً
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_sales_top_products ON sales_table(items, total_amount)');

      // فهرس للمخزون المنخفض
      await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_inventory_low_stock ON inventory_table(quantity, is_synced)');

      debugPrint('✅ تم إنشاء جميع الفهارس المحسنة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الفهارس المحسنة: $e');
      rethrow;
    }
  }

  // Products CRUD
  Future<void> upsertProduct(ProductsTableCompanion product) async {
    // التحقق من صحة البيانات إذا كان مفعلاً
    if (DatabaseConfig.enableDataValidation) {
      final Map<String, dynamic> data = <String, dynamic>{
        'name': product.name.value,
        'wholesale_price': product.wholesalePrice.value,
        'retail_price': product.retailPrice.value,
      };
      if (!DatabaseConfig.validateAllData(data)) {
        throw ArgumentError(
            'Invalid product data: ${DatabaseConfig.getErrorMessage('invalid_product_name')}');
      }
    }
    await into(productsTable).insertOnConflictUpdate(product);
  }

  Future<List<ProductsTableData>> getAllProducts() =>
      select(productsTable).get();

  // Streaming support for real-time updates
  Stream<List<ProductsTableData>> watchAllProducts() =>
      select(productsTable).watch();
  Future<List<ProductsTableData>> getUnsyncedProducts() =>
      (select(productsTable)
            ..where(($ProductsTableTable t) => t.isSynced.equals(false)))
          .get();
  Future<void> markProductAsSynced(String id) async {
    try {
      await (update(productsTable)
            ..where(($ProductsTableTable t) => t.id.equals(id)))
          .write(ProductsTableCompanion(
        isSynced: const Value(true),
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } catch (e) {
      // Ignore database closed errors
      if (!e.toString().contains('connection was closed')) {
        rethrow;
      }
    }
  }

  // Inventory CRUD
  Future<void> upsertInventoryItem(InventoryTableCompanion item) async {
    // التحقق من صحة البيانات إذا كان مفعلاً
    if (DatabaseConfig.enableDataValidation) {
      final Map<String, dynamic> data = <String, dynamic>{
        'name': item.name.value,
        'wholesale_price': item.wholesalePrice.value,
        'retail_price': item.retailPrice.value,
        'quantity': item.quantity.value,
      };
      if (!DatabaseConfig.validateAllData(data)) {
        throw ArgumentError(
            'Invalid inventory data: ${DatabaseConfig.getErrorMessage('invalid_inventory_name')}');
      }
    }
    await into(inventoryTable).insertOnConflictUpdate(item);
  }

  Future<void> deleteInventoryItemById(String id) => (delete(inventoryTable)
        ..where(($InventoryTableTable tbl) => tbl.id.equals(id)))
      .go();

  Future<void> deleteProductById(String id) => (delete(productsTable)
        ..where(($ProductsTableTable tbl) => tbl.id.equals(id)))
      .go();
  Future<List<InventoryTableData>> getAllInventoryItems() =>
      select(inventoryTable).get();

  // Streaming support for real-time updates
  Stream<List<InventoryTableData>> watchAllInventoryItems() =>
      select(inventoryTable).watch();
  Future<List<InventoryTableData>> getUnsyncedInventoryItems() =>
      (select(inventoryTable)
            ..where(($InventoryTableTable t) => t.isSynced.equals(false)))
          .get();
  Future<void> markInventoryItemAsSynced(String id) async {
    try {
      await (update(inventoryTable)
            ..where(($InventoryTableTable t) => t.id.equals(id)))
          .write(InventoryTableCompanion(
        isSynced: const Value(true),
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } catch (e) {
      // Ignore database closed errors
      if (!e.toString().contains('connection was closed')) {
        rethrow;
      }
    }
  }

  // Sync Operations
  Future<int> addSyncOperation(SyncOperationsTableCompanion op) async {
    try {
      return await into(syncOperationsTable).insert(op);
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return -1; // Return error code
      }
      rethrow;
    }
  }

  Future<List<SyncOperationsTableData>> getUnprocessedOperations() async {
    try {
      return await (select(syncOperationsTable)
            ..where(
                ($SyncOperationsTableTable t) => t.isProcessed.equals(false)))
          .get();
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return <SyncOperationsTableData>[]; // Return empty list
      }
      rethrow;
    }
  }

  Future<void> markOperationAsProcessed(int id) async {
    try {
      await (update(syncOperationsTable)
            ..where(($SyncOperationsTableTable t) => t.id.equals(id)))
          .write(const SyncOperationsTableCompanion(isProcessed: Value(true)));
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return; // Ignore closed connection errors
      }
      rethrow;
    }
  }

  Future<void> incrementRetryCount(int id) async {
    try {
      final SyncOperationsTableData? row = await (select(syncOperationsTable)
            ..where(($SyncOperationsTableTable t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row != null) {
        await (update(syncOperationsTable)
              ..where(($SyncOperationsTableTable t) => t.id.equals(id)))
            .write(SyncOperationsTableCompanion(
                retryCount: Value(row.retryCount + 1)));
      }
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return; // Ignore closed connection errors
      }
      rethrow;
    }
  }

  Future<int> cleanupProcessedOperations(Duration olderThan) async {
    try {
      final DateTime cutoff = DateTime.now().subtract(olderThan);
      final int deletedCount = await (delete(syncOperationsTable)
            ..where(($SyncOperationsTableTable t) =>
                t.isProcessed.equals(true) &
                t.timestamp.isSmallerThanValue(cutoff.toIso8601String())))
          .go();
      return deletedCount;
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return 0; // Return 0 for closed connection errors
      }
      rethrow;
    }
  }

  // Sales CRUD
  Future<void> upsertSale(SalesTableCompanion sale) =>
      into(salesTable).insertOnConflictUpdate(sale);
  Future<void> deleteSaleById(String id) =>
      (delete(salesTable)..where(($SalesTableTable tbl) => tbl.id.equals(id)))
          .go();
  Future<List<SalesTableData>> getAllSales() => select(salesTable).get();
  Future<List<SalesTableData>> getUnsyncedSales() => (select(salesTable)
        ..where(($SalesTableTable t) => t.isSynced.equals(false)))
      .get();
  Future<void> markSaleAsSynced(String id) async {
    try {
      await (update(salesTable)..where(($SalesTableTable t) => t.id.equals(id)))
          .write(SalesTableCompanion(
        isSynced: const Value(true),
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } catch (e) {
      // Ignore database closed errors
      if (!e.toString().contains('connection was closed')) {
        rethrow;
      }
    }
  }

  // Stats
  Future<int> getProductCount() async {
    try {
      return (await customSelect('SELECT COUNT(*) as c FROM products_table')
              .get())
          .first
          .data['c'] as int;
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        debugPrint('Database connection closed in getProductCount: $e');
        return 0;
      }
      debugPrint('Error in getProductCount: $e');
      rethrow;
    }
  }

  Future<int> getInventoryCount() async {
    try {
      return (await customSelect('SELECT COUNT(*) as c FROM inventory_table')
              .get())
          .first
          .data['c'] as int;
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        debugPrint('Database connection closed in getInventoryCount: $e');
        return 0;
      }
      debugPrint('Error in getInventoryCount: $e');
      rethrow;
    }
  }

  Future<int> getUnprocessedOperationsCount() async {
    try {
      return (await customSelect(
                  'SELECT COUNT(*) as c FROM sync_operations_table WHERE is_processed = 0')
              .get())
          .first
          .data['c'] as int;
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        debugPrint(
            'Database connection closed in getUnprocessedOperationsCount: $e');
        return 0;
      }
      debugPrint('Error in getUnprocessedOperationsCount: $e');
      rethrow;
    }
  }

  // Additional helper methods
  Future<bool> productExists(String productId) async {
    try {
      final ProductsTableData? product = await (select(productsTable)
            ..where(($ProductsTableTable t) => t.id.equals(productId)))
          .getSingleOrNull();
      return product != null;
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return false;
      }
      rethrow;
    }
  }

  Future<bool> inventoryItemExists(String itemId) async {
    try {
      final InventoryTableData? item = await (select(inventoryTable)
            ..where(($InventoryTableTable t) => t.id.equals(itemId)))
          .getSingleOrNull();
      return item != null;
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> insertSyncOperation(
      SyncOperationsTableCompanion operation) async {
    try {
      await into(syncOperationsTable).insert(operation);
    } catch (e) {
      if (e.toString().contains('connection was closed')) {
        return; // Ignore closed connection errors
      }
      rethrow;
    }
  }

  // Transaction support for complex operations
  Future<void> processSaleTransaction(SalesTableCompanion sale,
      List<InventoryTableCompanion> inventoryUpdates) async {
    await transaction(() async {
      // إضافة المبيعات
      await upsertSale(sale);

      // تحديث المخزون
      for (final InventoryTableCompanion update in inventoryUpdates) {
        await upsertInventoryItem(update);
      }
    });
  }

  // Transaction for bulk operations
  Future<void> bulkUpdateProducts(List<ProductsTableCompanion> products) async {
    await transaction(() async {
      for (final ProductsTableCompanion product in products) {
        await upsertProduct(product);
      }
    });
  }

  // Transaction for bulk inventory operations
  Future<void> bulkUpdateInventory(List<InventoryTableCompanion> items) async {
    await transaction(() async {
      for (final InventoryTableCompanion item in items) {
        await upsertInventoryItem(item);
      }
    });
  }

  /// تحسين قاعدة البيانات وتحليل الأداء
  Future<Map<String, dynamic>> optimizeDatabasePerformance() async {
    try {
      // تحليل الفهارس الحالية
      final List<QueryRow> indexInfo = await customSelect(
              'SELECT name, sql FROM sqlite_master WHERE type = "index" AND name NOT LIKE "sqlite_%"')
          .get();

      // تحليل حجم الجداول
      final List<QueryRow> tableSizes = await customSelect('''
        SELECT 
          name as table_name,
          (SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = m.name) as row_count
        FROM sqlite_master m 
        WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ''').get();

      // تحليل الأداء
      await customStatement('PRAGMA optimize;');
      await customStatement('PRAGMA analyze;');

      // تنظيف البيانات القديمة
      final int cleanupResult =
          await cleanupProcessedOperations(const Duration(days: 7));

      return <String, dynamic>{
        'indexes': indexInfo
            .map((QueryRow row) => <String, dynamic>{
                  'name': row.data['name'],
                  'sql': row.data['sql'],
                })
            .toList(),
        'tableSizes': tableSizes
            .map((QueryRow row) => <String, dynamic>{
                  'table': row.data['table_name'],
                  'rows': row.data['row_count'],
                })
            .toList(),
        'cleanupResult': cleanupResult,
        'optimizationStatus': 'completed',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('خطأ في تحسين قاعدة البيانات: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'optimizationStatus': 'failed',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// الحصول على إحصائيات الأداء
  Future<Map<String, dynamic>> getPerformanceStats() async {
    try {
      final int productCount = await getProductCount();
      final int inventoryCount = await getInventoryCount();
      final int salesCount =
          await getAllSales().then((List<SalesTableData> list) => list.length);
      final int unprocessedOps = await getUnprocessedOperationsCount();

      // إحصائيات الفهارس
      final int indexCount = await customSelect(
              'SELECT COUNT(*) as count FROM sqlite_master WHERE type = "index" AND name NOT LIKE "sqlite_%"')
          .get()
          .then((List<QueryRow> result) => result.first.data['count'] as int);

      return <String, dynamic>{
        'products': productCount,
        'inventory': inventoryCount,
        'sales': salesCount,
        'unprocessedOperations': unprocessedOps,
        'indexCount': indexCount,
        'schemaVersion': schemaVersion,
        'databaseSize': await _getDatabaseSize(),
        'lastOptimized': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('خطأ في الحصول على إحصائيات الأداء: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// الحصول على حجم قاعدة البيانات
  Future<int> _getDatabaseSize() async {
    try {
      final List<QueryRow> result =
          await customSelect('PRAGMA page_count;').get();
      final int pageCount = result.first.data['page_count'] as int;
      final int pageSize = await customSelect('PRAGMA page_size;').get().then(
          (List<QueryRow> result) => result.first.data['page_size'] as int);
      return pageCount * pageSize;
    } catch (e) {
      debugPrint('خطأ في حساب حجم قاعدة البيانات: $e');
      return 0;
    }
  }
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File(p.join(dir.path, 'app_database.sqlite'));

      // إعدادات خاصة بـ Windows
      if (Platform.isWindows) {
        return NativeDatabase.createInBackground(
          file,
          setup: (Database database) {
            // إعدادات محسنة لـ Windows
            database.execute('PRAGMA journal_mode = WAL;');
            database.execute('PRAGMA synchronous = NORMAL;');
            database
                .execute('PRAGMA cache_size = 2000;'); // زيادة الكاش لـ Windows
            database.execute('PRAGMA temp_store = MEMORY;');
            database
                .execute('PRAGMA mmap_size = 268435456;'); // 256MB لـ Windows
            database.execute('PRAGMA optimize;');
            database.execute('PRAGMA auto_vacuum = INCREMENTAL;');
            database.execute('PRAGMA locking_mode = NORMAL;');
            database.execute('PRAGMA foreign_keys = ON;');
            database.execute('PRAGMA threads = 4;'); // استخدام 4 threads
            database.execute('PRAGMA wal_autocheckpoint = 1000;');
            database.execute('PRAGMA checkpoint_fullfsync = OFF;');
            database.execute('PRAGMA secure_delete = OFF;');
            database.execute('PRAGMA count_changes = OFF;');
            database.execute('PRAGMA recursive_triggers = ON;');
            database.execute('PRAGMA legacy_file_format = OFF;');
            database.execute('PRAGMA read_uncommitted = OFF;');
            database.execute('PRAGMA short_column_names = ON;');
            database.execute('PRAGMA full_column_names = OFF;');
            database.execute('PRAGMA empty_result_callbacks = OFF;');
            database.execute('PRAGMA auto_vacuum = INCREMENTAL;');
            database.execute('PRAGMA incremental_vacuum(10);');
            // تحسينات إضافية لـ Windows
            database.execute('PRAGMA page_size = 4096;');
            database.execute('PRAGMA max_page_count = 1073741824;');
            database.execute('PRAGMA encoding = "UTF-8";');
            database.execute('PRAGMA case_sensitive_like = OFF;');
            database.execute('PRAGMA defer_foreign_keys = ON;');
            database.execute('PRAGMA query_only = OFF;');
            database.execute('PRAGMA quick_check;');
          },
        );
      } else {
        // إعدادات للمنصات الأخرى
        return NativeDatabase.createInBackground(
          file,
          setup: (Database database) {
            database.execute('PRAGMA journal_mode = WAL;');
            database.execute('PRAGMA synchronous = NORMAL;');
            database.execute('PRAGMA cache_size = 1000;');
            database.execute('PRAGMA temp_store = MEMORY;');
            database.execute('PRAGMA mmap_size = 134217728;'); // 128MB
            database.execute('PRAGMA optimize;');
            database.execute('PRAGMA auto_vacuum = INCREMENTAL;');
          },
        );
      }
    });
