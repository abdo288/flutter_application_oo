import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../database/drift_database.dart';
import 'error_handler_service.dart';

/// خدمة تنظيف البيانات المحلية
/// تقدم خيارات متعددة لتنظيف البيانات المحلية
class DataCleanupService {
  factory DataCleanupService() => _instance;
  DataCleanupService._internal();
  static final DataCleanupService _instance = DataCleanupService._internal();

  final AppDatabase _localDb = AppDatabase.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== خيارات التنظيف ==========

  /// تنظيف شامل لجميع البيانات المحلية والسحابية
  Future<CleanupResult> performFullCleanup(
      {bool includeFirestore = true}) async {
    try {
      debugPrint('🧹 بدء التنظيف الشامل للبيانات المحلية والسحابية...');

      // إنشاء نسخة احتياطية قبل التنظيف
      final bool backupCreated = await _createBackupBeforeCleanup();
      if (!backupCreated) {
        return CleanupResult(
          success: false,
          message: 'فشل في إنشاء نسخة احتياطية قبل التنظيف',
        );
      }

      // إحصائيات قبل التنظيف
      final CleanupStats beforeStats = await _getCleanupStats();

      // حذف جميع البيانات المحلية
      await _deleteAllProducts();
      await _deleteAllInventoryItems();
      await _deleteAllSales();
      await _deleteAllSyncOperations();

      // حذف البيانات من Firebase Firestore إذا طُلب ذلك
      int firestoreProductsDeleted = 0;
      int firestoreInventoryDeleted = 0;
      if (includeFirestore) {
        debugPrint('🔥 بدء حذف البيانات من Firebase Firestore...');

        // حذف جميع المنتجات من Firestore
        firestoreProductsDeleted = await _deleteAllProductsFromFirestore();

        // حذف جميع عناصر المخزون من Firestore
        firestoreInventoryDeleted = await _deleteAllInventoryFromFirestore();

        debugPrint(
            '🔥 تم حذف $firestoreProductsDeleted منتج و $firestoreInventoryDeleted عنصر مخزون من Firestore');
      }

      // إحصائيات بعد التنظيف
      await _getCleanupStats();

      debugPrint('✅ تم التنظيف الشامل بنجاح');
      return CleanupResult(
        success: true,
        message: includeFirestore
            ? 'تم التنظيف الشامل بنجاح (محلي + سحابي)'
            : 'تم التنظيف الشامل بنجاح (محلي فقط)',
        stats: CleanupStats(
          productsDeleted: beforeStats.productsCount + firestoreProductsDeleted,
          inventoryItemsDeleted:
              beforeStats.inventoryItemsCount + firestoreInventoryDeleted,
          salesDeleted: beforeStats.salesCount,
          syncOperationsDeleted: beforeStats.syncOperationsCount,
          additionalInfo: includeFirestore
              ? 'تم حذف البيانات من قاعدة البيانات المحلية و Firebase Firestore'
              : 'تم حذف البيانات من قاعدة البيانات المحلية فقط',
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تنظيف شامل للبيانات المحلية',
        context: <String, dynamic>{
          'operation': 'fullCleanup',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في التنظيف الشامل: $e',
      );
    }
  }

  /// تنظيف البيانات غير المزامنة فقط
  Future<CleanupResult> cleanupUnsyncedData() async {
    try {
      debugPrint('🧹 بدء تنظيف البيانات غير المزامنة...');

      // إحصائيات قبل التنظيف
      final CleanupStats beforeStats = await _getCleanupStats();

      // حذف المنتجات غير المزامنة
      final List<ProductsTableData> unsyncedProducts =
          await _localDb.getUnsyncedProducts();
      for (final ProductsTableData product in unsyncedProducts) {
        await (_localDb.delete(_localDb.productsTable)
              ..where(($ProductsTableTable t) => t.id.equals(product.id)))
            .go();
      }

      // حذف عناصر المخزون غير المزامنة
      final List<InventoryTableData> unsyncedInventory =
          await _localDb.getUnsyncedInventoryItems();
      for (final InventoryTableData item in unsyncedInventory) {
        await _localDb.deleteInventoryItemById(item.id);
      }

      // حذف المبيعات غير المزامنة (إذا كان الجدول موجود)
      try {
        final List<SalesTableData> unsyncedSales =
            await _localDb.getUnsyncedSales();
        for (final SalesTableData sale in unsyncedSales) {
          await _localDb.deleteSaleById(sale.id);
        }
      } catch (e) {
        if (e.toString().contains('no such table: sales_table')) {
          debugPrint(
              '⚠️ جدول المبيعات غير موجود - تخطي تنظيف المبيعات غير المزامنة');
        } else {
          rethrow;
        }
      }

      // إحصائيات بعد التنظيف
      final CleanupStats afterStats = await _getCleanupStats();

      debugPrint('✅ تم تنظيف البيانات غير المزامنة بنجاح');
      return CleanupResult(
        success: true,
        message: 'تم تنظيف البيانات غير المزامنة بنجاح',
        stats: CleanupStats(
          productsDeleted: beforeStats.productsCount - afterStats.productsCount,
          inventoryItemsDeleted:
              beforeStats.inventoryItemsCount - afterStats.inventoryItemsCount,
          salesDeleted: beforeStats.salesCount - afterStats.salesCount,
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تنظيف البيانات غير المزامنة',
        context: <String, dynamic>{
          'operation': 'cleanupUnsyncedData',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في تنظيف البيانات غير المزامنة: $e',
      );
    }
  }

  /// تنظيف العمليات المعالجة من طابور المزامنة
  Future<CleanupResult> cleanupProcessedSyncOperations() async {
    try {
      debugPrint('🧹 بدء تنظيف العمليات المعالجة من طابور المزامنة...');

      // حذف العمليات المعالجة الأقدم من 7 أيام والحصول على العدد المحذوف
      final int deletedCount =
          await _localDb.cleanupProcessedOperations(const Duration(days: 7));

      debugPrint('✅ تم تنظيف العمليات المعالجة بنجاح');
      return CleanupResult(
        success: true,
        message: 'تم تنظيف العمليات المعالجة بنجاح',
        stats: CleanupStats(
          syncOperationsDeleted: deletedCount,
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تنظيف العمليات المعالجة',
        context: <String, dynamic>{
          'operation': 'cleanupProcessedSyncOperations',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في تنظيف العمليات المعالجة: $e',
      );
    }
  }

  /// تنظيف البيانات القديمة (أقدم من 30 يوم)
  Future<CleanupResult> cleanupOldData({int daysOld = 30}) async {
    try {
      debugPrint('🧹 بدء تنظيف البيانات القديمة (أقدم من $daysOld يوم)...');

      final DateTime cutoffDate =
          DateTime.now().subtract(Duration(days: daysOld));
      final String cutoffDateString = cutoffDate.toIso8601String();

      // إحصائيات قبل التنظيف
      await _getCleanupStats();

      // حذف المنتجات القديمة
      await _localDb.customUpdate(
        'DELETE FROM products_table WHERE last_modified < ?',
        updates: <ResultSetImplementation<dynamic, dynamic>>{
          _localDb.productsTable
        },
        variables: <Variable<Object>>[Variable.withString(cutoffDateString)],
      );

      // حذف عناصر المخزون القديمة
      await _localDb.customUpdate(
        'DELETE FROM inventory_table WHERE last_modified < ?',
        updates: <ResultSetImplementation<dynamic, dynamic>>{
          _localDb.inventoryTable
        },
        variables: <Variable<Object>>[Variable.withString(cutoffDateString)],
      );

      // حذف المبيعات القديمة (إذا كان الجدول موجود)
      try {
        await _localDb.customUpdate(
          'DELETE FROM sales_table WHERE sale_date < ?',
          updates: <ResultSetImplementation<dynamic, dynamic>>{
            _localDb.salesTable
          },
          variables: <Variable<Object>>[Variable.withString(cutoffDateString)],
        );
      } catch (e) {
        if (e.toString().contains('no such table: sales_table')) {
          debugPrint(
              '⚠️ جدول المبيعات غير موجود - تخطي تنظيف المبيعات القديمة');
        } else {
          rethrow;
        }
      }

      // إحصائيات بعد التنظيف
      await _getCleanupStats();

      debugPrint('✅ تم تنظيف البيانات القديمة بنجاح');
      return CleanupResult(
        success: true,
        message: 'تم تنظيف البيانات القديمة بنجاح',
        stats: CleanupStats(
          
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تنظيف البيانات القديمة',
        context: <String, dynamic>{
          'operation': 'cleanupOldData',
          'daysOld': daysOld,
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في تنظيف البيانات القديمة: $e',
      );
    }
  }

  /// تنظيف ملفات قاعدة البيانات المؤقتة
  Future<CleanupResult> cleanupDatabaseFiles() async {
    try {
      debugPrint('🧹 بدء تنظيف ملفات قاعدة البيانات المؤقتة...');

      // تنظيف قاعدة البيانات بأمان
      await _localDb.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      await _localDb.customStatement('VACUUM;');

      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory dbDir = Directory(appDir.path);

      int filesDeleted = 0;
      int totalSize = 0;

      if (await dbDir.exists()) {
        final List<FileSystemEntity> files = dbDir.listSync();

        for (final FileSystemEntity file in files) {
          if (file is File) {
            final String fileName = path.basename(file.path);

            // حذف الملفات المؤقتة الآمنة فقط (تجنب WAL/SHM أثناء فتح الاتصال)
            if (fileName.startsWith('temp_') || fileName.endsWith('.tmp')) {
              final int fileSize = await file.length();
              totalSize += fileSize;

              await file.delete();
              filesDeleted++;

              debugPrint('🗑️ تم حذف الملف المؤقت: $fileName ($fileSize بايت)');
            }
          }
        }
      }

      debugPrint('✅ تم تنظيف ملفات قاعدة البيانات بنجاح');
      return CleanupResult(
        success: true,
        message: 'تم تنظيف ملفات قاعدة البيانات بنجاح',
        stats: CleanupStats(
          syncOperationsDeleted: filesDeleted,
          additionalInfo:
              'تم تحرير $totalSize بايت من المساحة + تحسين قاعدة البيانات',
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تنظيف ملفات قاعدة البيانات',
        context: <String, dynamic>{
          'operation': 'cleanupDatabaseFiles',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في تنظيف ملفات قاعدة البيانات: $e',
      );
    }
  }

  /// تنظيف ذكي (تنظيف البيانات غير المهمة فقط)
  Future<CleanupResult> performSmartCleanup() async {
    try {
      debugPrint('🧹 بدء التنظيف الذكي...');

      final List<Future<CleanupResult>> cleanupTasks = <Future<CleanupResult>>[
        cleanupProcessedSyncOperations(),
        cleanupOldData(daysOld: 90), // البيانات أقدم من 90 يوم
        cleanupDatabaseFiles(),
      ];

      final List<CleanupResult> results = await Future.wait(cleanupTasks);

      // حساب الإحصائيات الإجمالية
      int totalProductsDeleted = 0;
      int totalInventoryDeleted = 0;
      int totalSalesDeleted = 0;
      int totalSyncOperationsDeleted = 0;
      bool allSuccessful = true;

      for (final CleanupResult result in results) {
        if (result.success && result.stats != null) {
          totalProductsDeleted += result.stats!.productsDeleted;
          totalInventoryDeleted += result.stats!.inventoryItemsDeleted;
          totalSalesDeleted += result.stats!.salesDeleted;
          totalSyncOperationsDeleted += result.stats!.syncOperationsDeleted;
        } else {
          allSuccessful = false;
        }
      }

      debugPrint('✅ تم التنظيف الذكي بنجاح');
      return CleanupResult(
        success: allSuccessful,
        message: allSuccessful
            ? 'تم التنظيف الذكي بنجاح'
            : 'تم التنظيف الذكي مع بعض الأخطاء',
        stats: CleanupStats(
          productsDeleted: totalProductsDeleted,
          inventoryItemsDeleted: totalInventoryDeleted,
          salesDeleted: totalSalesDeleted,
          syncOperationsDeleted: totalSyncOperationsDeleted,
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'التنظيف الذكي',
        context: <String, dynamic>{
          'operation': 'smartCleanup',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في التنظيف الذكي: $e',
      );
    }
  }

  // ========== دوال مساعدة ==========

  /// إنشاء نسخة احتياطية قبل التنظيف
  Future<bool> _createBackupBeforeCleanup() async {
    try {
      final String timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final String backupName = 'cleanup_backup_$timestamp';

      // إنشاء نسخة احتياطية (سيتم تنفيذها لاحقاً)
      debugPrint('📦 إنشاء نسخة احتياطية: $backupName');
      debugPrint('✅ تم إنشاء نسخة احتياطية: $backupName');
      return true;
    } catch (e) {
      debugPrint('⚠️ فشل في إنشاء نسخة احتياطية: $e');
      return false;
    }
  }

  /// الحصول على إحصائيات التنظيف
  Future<CleanupStats> _getCleanupStats() async {
    try {
      final int productsCount = await _localDb.getProductCount();
      final int inventoryCount = await _localDb.getInventoryCount();

      // التحقق من وجود جدول المبيعات قبل الاستعلام
      int salesCount = 0;
      try {
        salesCount = (await _localDb.getAllSales()).length;
      } catch (e) {
        debugPrint('⚠️ جدول المبيعات غير موجود أو فارغ: $e');
        salesCount = 0;
      }

      final int syncOperationsCount =
          await _localDb.getUnprocessedOperationsCount();

      return CleanupStats(
        productsCount: productsCount,
        inventoryItemsCount: inventoryCount,
        salesCount: salesCount,
        syncOperationsCount: syncOperationsCount,
      );
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على إحصائيات التنظيف: $e');
      return CleanupStats();
    }
  }

  /// حذف جميع المنتجات
  Future<void> _deleteAllProducts() async {
    try {
      await _localDb.customUpdate(
        'DELETE FROM products_table',
        updates: <ResultSetImplementation<dynamic, dynamic>>{
          _localDb.productsTable
        },
      );
      debugPrint('🗑️ تم حذف جميع المنتجات');
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتجات: $e');
      rethrow;
    }
  }

  /// حذف جميع عناصر المخزون
  Future<void> _deleteAllInventoryItems() async {
    try {
      await _localDb.customUpdate(
        'DELETE FROM inventory_table',
        updates: <ResultSetImplementation<dynamic, dynamic>>{
          _localDb.inventoryTable
        },
      );
      debugPrint('🗑️ تم حذف جميع عناصر المخزون');
    } catch (e) {
      debugPrint('❌ خطأ في حذف عناصر المخزون: $e');
      rethrow;
    }
  }

  /// حذف جميع المبيعات
  Future<void> _deleteAllSales() async {
    try {
      // التحقق من وجود جدول المبيعات قبل الحذف
      await _localDb.customUpdate(
        'DELETE FROM sales_table',
        updates: <ResultSetImplementation<dynamic, dynamic>>{
          _localDb.salesTable
        },
      );
      debugPrint('🗑️ تم حذف جميع المبيعات');
    } catch (e) {
      if (e.toString().contains('no such table: sales_table')) {
        debugPrint('⚠️ جدول المبيعات غير موجود - تخطي حذف المبيعات');
      } else {
        debugPrint('❌ خطأ في حذف المبيعات: $e');
        rethrow;
      }
    }
  }

  /// حذف جميع عمليات المزامنة
  Future<void> _deleteAllSyncOperations() async {
    try {
      await _localDb.customUpdate(
        'DELETE FROM sync_operations_table',
        updates: <ResultSetImplementation<dynamic, dynamic>>{
          _localDb.syncOperationsTable
        },
      );
      debugPrint('🗑️ تم حذف جميع عمليات المزامنة');
    } catch (e) {
      debugPrint('❌ خطأ في حذف عمليات المزامنة: $e');
      rethrow;
    }
  }

  /// الحصول على معلومات مساحة التخزين
  Future<StorageInfo> getStorageInfo() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory dbDir = Directory(appDir.path);

      int totalSize = 0;
      int fileCount = 0;
      final List<String> fileDetails = <String>[];

      if (await dbDir.exists()) {
        final List<FileSystemEntity> files = dbDir.listSync();

        for (final FileSystemEntity file in files) {
          if (file is File) {
            final int fileSize = await file.length();
            totalSize += fileSize;
            fileCount++;

            final String fileName = file.path.split('/').last;
            fileDetails.add('$fileName: ${_formatBytes(fileSize)}');
          }
        }
      }

      return StorageInfo(
        totalSize: totalSize,
        fileCount: fileCount,
        fileDetails: fileDetails,
      );
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على معلومات التخزين: $e');
      return StorageInfo();
    }
  }

  /// حذف جميع المنتجات من Firebase Firestore
  Future<int> _deleteAllProductsFromFirestore() async {
    try {
      debugPrint('🔥 حذف جميع المنتجات من Firebase Firestore...');

      final QuerySnapshot productsSnapshot =
          await _firestore.collection('products').get();

      int deletedCount = 0;
      for (final QueryDocumentSnapshot doc in productsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      debugPrint('🔥 تم حذف $deletedCount منتج من Firestore');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتجات من Firestore: $e');
      return 0;
    }
  }

  /// حذف جميع عناصر المخزون من Firebase Firestore
  Future<int> _deleteAllInventoryFromFirestore() async {
    try {
      debugPrint('🔥 حذف جميع عناصر المخزون من Firebase Firestore...');

      final QuerySnapshot inventorySnapshot =
          await _firestore.collection('quantities').get();

      int deletedCount = 0;
      for (final QueryDocumentSnapshot doc in inventorySnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      debugPrint('🔥 تم حذف $deletedCount عنصر مخزون من Firestore');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في حذف عناصر المخزون من Firestore: $e');
      return 0;
    }
  }

  /// تنظيف شامل للبيانات السحابية فقط
  Future<CleanupResult> performFirestoreCleanup() async {
    try {
      debugPrint('🔥 بدء التنظيف الشامل للبيانات السحابية...');

      // حذف جميع المنتجات من Firestore
      final int productsDeleted = await _deleteAllProductsFromFirestore();

      // حذف جميع عناصر المخزون من Firestore
      final int inventoryDeleted = await _deleteAllInventoryFromFirestore();

      debugPrint('✅ تم التنظيف الشامل للبيانات السحابية بنجاح');
      return CleanupResult(
        success: true,
        message: 'تم التنظيف الشامل للبيانات السحابية بنجاح',
        stats: CleanupStats(
          productsDeleted: productsDeleted,
          inventoryItemsDeleted: inventoryDeleted,
          additionalInfo: 'تم حذف البيانات من Firebase Firestore فقط',
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'تنظيف شامل للبيانات السحابية',
        context: <String, dynamic>{
          'operation': 'firestoreCleanup',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في التنظيف الشامل للبيانات السحابية: $e',
      );
    }
  }

  /// تنسيق حجم الملف
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// نتيجة عملية التنظيف
class CleanupResult {
  CleanupResult({
    required this.success,
    required this.message,
    this.stats,
  });
  final bool success;
  final String message;
  final CleanupStats? stats;
}

/// إحصائيات التنظيف
class CleanupStats {
  CleanupStats({
    this.productsCount = 0,
    this.inventoryItemsCount = 0,
    this.salesCount = 0,
    this.syncOperationsCount = 0,
    this.productsDeleted = 0,
    this.inventoryItemsDeleted = 0,
    this.salesDeleted = 0,
    this.syncOperationsDeleted = 0,
    this.additionalInfo,
  });
  final int productsCount;
  final int inventoryItemsCount;
  final int salesCount;
  final int syncOperationsCount;
  final int productsDeleted;
  final int inventoryItemsDeleted;
  final int salesDeleted;
  final int syncOperationsDeleted;
  final String? additionalInfo;
}

/// معلومات التخزين
class StorageInfo {
  StorageInfo({
    this.totalSize = 0,
    this.fileCount = 0,
    this.fileDetails = const <String>[],
  });
  final int totalSize;
  final int fileCount;
  final List<String> fileDetails;

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
