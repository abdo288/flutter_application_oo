import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'drift_database.dart';

/// تحسينات إضافية لقاعدة البيانات
extension DatabaseEnhancements on AppDatabase {
  /// البحث في المنتجات بالاسم مع دعم النص العربي
  Future<List<ProductsTableData>> searchProductsByName(String name) =>
      (select(productsTable)
            ..where(($ProductsTableTable t) => t.name.like('%$name%')))
          .get();

  /// البحث في المنتجات بالباركود
  Future<ProductsTableData?> getProductByBarcode(String barcode) =>
      (select(productsTable)
            ..where(($ProductsTableTable t) => t.barcode.equals(barcode)))
          .getSingleOrNull();

  /// الحصول على المنتجات حسب الفئة
  Future<List<ProductsTableData>> getProductsByCategory(String category) =>
      (select(productsTable)
            ..where(($ProductsTableTable t) => t.category.equals(category)))
          .get();

  /// الحصول على المنتجات النشطة فقط
  Future<List<ProductsTableData>> getActiveProducts() => (select(productsTable)
        ..where(($ProductsTableTable t) => t.isActive.equals(true)))
      .get();

  /// مراقبة المنتجات النشطة
  Stream<List<ProductsTableData>> watchActiveProducts() =>
      (select(productsTable)
            ..where(($ProductsTableTable t) => t.isActive.equals(true)))
          .watch();

  /// البحث في المخزون بالاسم
  Future<List<InventoryTableData>> searchInventoryByName(String name) =>
      (select(inventoryTable)
            ..where(($InventoryTableTable t) => t.name.like('%$name%')))
          .get();

  /// البحث في المخزون بالباركود
  Future<InventoryTableData?> getInventoryByBarcode(String barcode) =>
      (select(inventoryTable)
            ..where(($InventoryTableTable t) => t.barcode.equals(barcode)))
          .getSingleOrNull();

  /// الحصول على عناصر المخزون منخفضة الكمية
  Future<List<InventoryTableData>> getLowStockItems(int threshold) =>
      (select(inventoryTable)
            ..where(($InventoryTableTable t) =>
                t.quantity.isSmallerThanValue(threshold)))
          .get();

  /// مراقبة عناصر المخزون منخفضة الكمية
  Stream<List<InventoryTableData>> watchLowStockItems(int threshold) =>
      (select(inventoryTable)
            ..where(($InventoryTableTable t) =>
                t.quantity.isSmallerThanValue(threshold)))
          .watch();

  /// الحصول على المبيعات حسب التاريخ
  Future<List<SalesTableData>> getSalesByDateRange(
          DateTime start, DateTime end) =>
      (select(salesTable)
            ..where(($SalesTableTable t) =>
                t.saleDate.isBiggerOrEqualValue(start.toIso8601String()) &
                t.saleDate.isSmallerOrEqualValue(end.toIso8601String())))
          .get();

  /// الحصول على المبيعات اليوم
  Future<List<SalesTableData>> getTodaySales() {
    final DateTime today = DateTime.now();
    final DateTime startOfDay = DateTime(today.year, today.month, today.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    return getSalesByDateRange(startOfDay, endOfDay);
  }

  /// مراقبة المبيعات اليوم
  Stream<List<SalesTableData>> watchTodaySales() {
    final DateTime today = DateTime.now();
    final DateTime startOfDay = DateTime(today.year, today.month, today.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(salesTable)
          ..where(($SalesTableTable t) =>
              t.saleDate.isBiggerOrEqualValue(startOfDay.toIso8601String()) &
              t.saleDate.isSmallerOrEqualValue(endOfDay.toIso8601String())))
        .watch();
  }

  /// الحصول على إحصائيات المنتجات
  Future<Map<String, int>> getProductStats() async {
    try {
      final int activeCount = await (select(productsTable)
            ..where(($ProductsTableTable t) => t.isActive.equals(true)))
          .get()
          .then((List<ProductsTableData> list) => list.length);

      final int syncedCount = await (select(productsTable)
            ..where(($ProductsTableTable t) => t.isSynced.equals(true)))
          .get()
          .then((List<ProductsTableData> list) => list.length);

      final int totalCount = await getProductCount();

      return <String, int>{
        'total': totalCount,
        'active': activeCount,
        'synced': syncedCount,
        'unsynced': totalCount - syncedCount,
      };
    } catch (e) {
      debugPrint('Error in getProductStats: $e');
      return <String, int>{
        'total': 0,
        'active': 0,
        'synced': 0,
        'unsynced': 0,
      };
    }
  }

  /// الحصول على إحصائيات المخزون
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final int totalCount = await getInventoryCount();

      final int lowStockCount = await (select(inventoryTable)
            ..where(
                ($InventoryTableTable t) => t.quantity.isSmallerThanValue(10)))
          .get()
          .then((List<InventoryTableData> list) => list.length);

      final int syncedCount = await (select(inventoryTable)
            ..where(($InventoryTableTable t) => t.isSynced.equals(true)))
          .get()
          .then((List<InventoryTableData> list) => list.length);

      // حساب إجمالي القيمة
      final int totalValue = await customSelect(
              'SELECT SUM(wholesale_price * quantity) as total FROM inventory_table')
          .get()
          .then((List<QueryRow> result) => result.first.data['total'] as int? ?? 0);

      return <String, dynamic>{
        'total': totalCount,
        'lowStock': lowStockCount,
        'synced': syncedCount,
        'unsynced': totalCount - syncedCount,
        'totalValue': totalValue,
      };
    } catch (e) {
      debugPrint('Error in getInventoryStats: $e');
      return <String, dynamic>{
        'total': 0,
        'lowStock': 0,
        'synced': 0,
        'unsynced': 0,
        'totalValue': 0,
      };
    }
  }

  /// الحصول على إحصائيات المبيعات
  Future<Map<String, dynamic>> getSalesStats() async {
    try {
      final List<SalesTableData> totalSales = await getAllSales();
      final int totalAmount =
          totalSales.fold<int>(0, (int sum, SalesTableData sale) => sum + sale.totalAmount);
      final int totalProfit =
          totalSales.fold<int>(0, (int sum, SalesTableData sale) => sum + sale.totalProfit);
      final int totalDiscount =
          totalSales.fold<int>(0, (int sum, SalesTableData sale) => sum + sale.discount);

      final int syncedCount = await (select(salesTable)
            ..where(($SalesTableTable t) => t.isSynced.equals(true)))
          .get()
          .then((List<SalesTableData> list) => list.length);

      return <String, dynamic>{
        'totalSales': totalSales.length,
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'totalDiscount': totalDiscount,
        'averageAmount':
            totalSales.isNotEmpty ? totalAmount / totalSales.length : 0,
        'averageProfit':
            totalSales.isNotEmpty ? totalProfit / totalSales.length : 0,
        'synced': syncedCount,
        'unsynced': totalSales.length - syncedCount,
      };
    } catch (e) {
      debugPrint('Error in getSalesStats: $e');
      return <String, dynamic>{
        'totalSales': 0,
        'totalAmount': 0,
        'totalProfit': 0,
        'totalDiscount': 0,
        'averageAmount': 0,
        'averageProfit': 0,
        'synced': 0,
        'unsynced': 0,
      };
    }
  }

  /// الحصول على إحصائيات المبيعات اليوم
  Future<Map<String, dynamic>> getTodaySalesStats() async {
    try {
      final List<SalesTableData> todaySales = await getTodaySales();
      final int totalAmount =
          todaySales.fold<int>(0, (int sum, SalesTableData sale) => sum + sale.totalAmount);
      final int totalProfit =
          todaySales.fold<int>(0, (int sum, SalesTableData sale) => sum + sale.totalProfit);

      return <String, dynamic>{
        'salesCount': todaySales.length,
        'totalAmount': totalAmount,
        'totalProfit': totalProfit,
        'averageAmount':
            todaySales.isNotEmpty ? totalAmount / todaySales.length : 0,
        'averageProfit':
            todaySales.isNotEmpty ? totalProfit / todaySales.length : 0,
      };
    } catch (e) {
      debugPrint('Error in getTodaySalesStats: $e');
      return <String, dynamic>{
        'salesCount': 0,
        'totalAmount': 0,
        'totalProfit': 0,
        'averageAmount': 0,
        'averageProfit': 0,
      };
    }
  }

  /// تحديث كمية المخزون
  Future<void> updateInventoryQuantity(String id, int newQuantity) async {
    try {
      await (update(inventoryTable)
            ..where(($InventoryTableTable t) => t.id.equals(id)))
          .write(InventoryTableCompanion(
        quantity: Value(newQuantity),
        lastModified: Value(DateTime.now().toIso8601String()),
      ));
    } catch (e) {
      if (!e.toString().contains('connection was closed')) {
        debugPrint('Error updating inventory quantity: $e');
        rethrow;
      }
    }
  }

  /// تحديث كميات المخزون المجمعة
  Future<void> bulkUpdateQuantities(Map<String, int> quantityUpdates) async {
    await transaction(() async {
      for (final MapEntry<String, int> entry in quantityUpdates.entries) {
        await updateInventoryQuantity(entry.key, entry.value);
      }
    });
  }

  /// الحصول على أفضل المنتجات مبيعاً
  Future<List<Map<String, dynamic>>> getTopSellingProducts(
      {int limit = 10}) async {
    try {
      // استخدام استعلام بسيط بدلاً من customSelect المعقد
      final List<SalesTableData> sales = await getAllSales();
      sales.sort((SalesTableData a, SalesTableData b) => b.totalAmount.compareTo(a.totalAmount));

      return sales
          .take(limit)
          .map((SalesTableData sale) => <String, Object>{
                'items': sale.items,
                'total_amount': sale.totalAmount,
                'sale_date': sale.saleDate,
              })
          .toList();
    } catch (e) {
      debugPrint('Error in getTopSellingProducts: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// تنظيف البيانات القديمة
  Future<Map<String, int>> cleanupOldData() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // تنظيف عمليات المزامنة المعالجة القديمة
      final int cleanedSyncOps =
          await cleanupProcessedOperations(const Duration(days: 7));

      // تنظيف المبيعات القديمة (أكثر من 30 يوم)
      final int cleanedSales = await (delete(salesTable)
            ..where(($SalesTableTable t) =>
                t.saleDate.isSmallerThanValue(thirtyDaysAgo.toIso8601String())))
          .go();

      return <String, int>{
        'syncOperations': cleanedSyncOps,
        'sales': cleanedSales,
      };
    } catch (e) {
      debugPrint('Error in cleanupOldData: $e');
      return <String, int>{
        'syncOperations': 0,
        'sales': 0,
      };
    }
  }

  /// تحسين قاعدة البيانات
  Future<void> optimizeDatabase() async {
    try {
      await customStatement('PRAGMA optimize;');
      await customStatement('PRAGMA analyze;');
      await customStatement('VACUUM;');
      debugPrint('Database optimized successfully');
    } catch (e) {
      debugPrint('Error optimizing database: $e');
    }
  }

  /// الحصول على معلومات قاعدة البيانات
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    try {
      final int productCount = await getProductCount();
      final int inventoryCount = await getInventoryCount();
      final int salesCount = await getAllSales().then((List<SalesTableData> list) => list.length);
      final int unprocessedOps = await getUnprocessedOperationsCount();

      return <String, dynamic>{
        'products': productCount,
        'inventory': inventoryCount,
        'sales': salesCount,
        'unprocessedOperations': unprocessedOps,
        'schemaVersion': schemaVersion,
      };
    } catch (e) {
      debugPrint('Error getting database info: $e');
      return <String, dynamic>{
        'products': 0,
        'inventory': 0,
        'sales': 0,
        'unprocessedOperations': 0,
        'schemaVersion': 0,
      };
    }
  }

  /// اختبار أداء البحث مع الفهارس المحسنة
  Future<Map<String, dynamic>> testSearchPerformance() async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();

      // اختبار البحث بالاسم
      stopwatch.reset();
      await searchProductsByName('test');
      final int nameSearchTime = stopwatch.elapsedMicroseconds;

      // اختبار البحث بالباركود
      stopwatch.reset();
      await getProductByBarcode('123456789');
      final int barcodeSearchTime = stopwatch.elapsedMicroseconds;

      // اختبار البحث في المخزون
      stopwatch.reset();
      await searchInventoryByName('test');
      final int inventorySearchTime = stopwatch.elapsedMicroseconds;

      // اختبار الحصول على المنتجات النشطة
      stopwatch.reset();
      await getActiveProducts();
      final int activeProductsTime = stopwatch.elapsedMicroseconds;

      // اختبار الحصول على المخزون المنخفض
      stopwatch.reset();
      await getLowStockItems(10);
      final int lowStockTime = stopwatch.elapsedMicroseconds;

      stopwatch.stop();

      return <String, dynamic>{
        'nameSearchTime': nameSearchTime,
        'barcodeSearchTime': barcodeSearchTime,
        'inventorySearchTime': inventorySearchTime,
        'activeProductsTime': activeProductsTime,
        'lowStockTime': lowStockTime,
        'totalTestTime': stopwatch.elapsedMicroseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error in testSearchPerformance: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// اختبار أداء الاستعلامات المعقدة
  Future<Map<String, dynamic>> testComplexQueryPerformance() async {
    try {
      final Stopwatch stopwatch = Stopwatch()..start();

      // اختبار إحصائيات المنتجات
      stopwatch.reset();
      await getProductStats();
      final int productStatsTime = stopwatch.elapsedMicroseconds;

      // اختبار إحصائيات المخزون
      stopwatch.reset();
      await getInventoryStats();
      final int inventoryStatsTime = stopwatch.elapsedMicroseconds;

      // اختبار إحصائيات المبيعات
      stopwatch.reset();
      await getSalesStats();
      final int salesStatsTime = stopwatch.elapsedMicroseconds;

      // اختبار إحصائيات المبيعات اليوم
      stopwatch.reset();
      await getTodaySalesStats();
      final int todaySalesStatsTime = stopwatch.elapsedMicroseconds;

      // اختبار أفضل المنتجات مبيعاً
      stopwatch.reset();
      await getTopSellingProducts();
      final int topSellingTime = stopwatch.elapsedMicroseconds;

      stopwatch.stop();

      return <String, dynamic>{
        'productStatsTime': productStatsTime,
        'inventoryStatsTime': inventoryStatsTime,
        'salesStatsTime': salesStatsTime,
        'todaySalesStatsTime': todaySalesStatsTime,
        'topSellingTime': topSellingTime,
        'totalComplexQueryTime': stopwatch.elapsedMicroseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error in testComplexQueryPerformance: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// تحليل أداء قاعدة البيانات الشامل
  Future<Map<String, dynamic>> analyzeDatabasePerformance() async {
    try {
      final Map<String, dynamic> searchPerformance = await testSearchPerformance();
      final Map<String, dynamic> complexQueryPerformance = await testComplexQueryPerformance();
      final Map<String, dynamic> databaseInfo = await getDatabaseInfo();
      final Map<String, dynamic> performanceStats = await getPerformanceStats();

      return <String, dynamic>{
        'searchPerformance': searchPerformance,
        'complexQueryPerformance': complexQueryPerformance,
        'databaseInfo': databaseInfo,
        'performanceStats': performanceStats,
        'analysisTimestamp': DateTime.now().toIso8601String(),
        'recommendations': _generatePerformanceRecommendations(
            searchPerformance, complexQueryPerformance),
      };
    } catch (e) {
      debugPrint('Error in analyzeDatabasePerformance: $e');
      return <String, dynamic>{
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// توليد توصيات الأداء
  List<String> _generatePerformanceRecommendations(
    Map<String, dynamic> searchPerformance,
    Map<String, dynamic> complexQueryPerformance,
  ) {
    final List<String> recommendations = <String>[];

    // تحليل أداء البحث
    final int nameSearchTime = searchPerformance['nameSearchTime'] as int? ?? 0;
    final int barcodeSearchTime =
        searchPerformance['barcodeSearchTime'] as int? ?? 0;

    if (nameSearchTime > 10000) {
      // أكثر من 10ms
      recommendations.add('البحث بالاسم بطيء - تحقق من فهرس الاسم');
    }

    if (barcodeSearchTime > 5000) {
      // أكثر من 5ms
      recommendations.add('البحث بالباركود بطيء - تحقق من فهرس الباركود');
    }

    // تحليل أداء الاستعلامات المعقدة
    final int productStatsTime =
        complexQueryPerformance['productStatsTime'] as int? ?? 0;
    final int salesStatsTime =
        complexQueryPerformance['salesStatsTime'] as int? ?? 0;

    if (productStatsTime > 50000) {
      // أكثر من 50ms
      recommendations.add('إحصائيات المنتجات بطيئة - تحقق من الفهارس المركبة');
    }

    if (salesStatsTime > 100000) {
      // أكثر من 100ms
      recommendations.add('إحصائيات المبيعات بطيئة - تحقق من فهارس المبيعات');
    }

    if (recommendations.isEmpty) {
      recommendations.add('الأداء ممتاز - جميع الاستعلامات تعمل بسرعة مناسبة');
    }

    return recommendations;
  }
}
