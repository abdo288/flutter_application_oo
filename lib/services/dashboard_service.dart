import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/database_enhancements.dart';
import '../database/drift_database.dart';
import '../models/dashboard_stats.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../providers/riverpod/stream_product_riverpod_provider.dart';

/// خدمة حساب إحصائيات لوحة التحكم
class DashboardService {
  DashboardService({
    required WidgetRef ref,
  }) : _ref = ref;
  final WidgetRef _ref;

  /// حساب إحصائيات لوحة التحكم
  Future<DashboardStats> calculateDashboardStats() async {
    try {
      // جلب البيانات من Riverpod providers
      final ProductsState productsState = _ref.read(productsControllerProvider);
      final List<Product> products = productsState.products;

      // حساب إجمالي المنتجات
      final int totalProducts = products.length;

      // حساب إجمالي القيمة المالية للمنتجات (سعر التجزئة)
      final double totalProductsValue = products
          .map((Product product) => product.retailPrice.toDouble())
          .fold<double>(0.0, (double sum, double value) => sum + value);

      // حساب عدد المنتجات المختلفة (أسماء فريدة)
      final int uniqueProductNames =
          products.map((Product product) => product.name).toSet().length;

      // حساب المبيعات اليومية والشهرية
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      final DateTime monthStart = DateTime(now.year, now.month);

      final int todaySales = products
          .where((Product product) =>
              product.savedAt.isAfter(today) &&
              product.savedAt.isBefore(today.add(const Duration(days: 1))))
          .length;

      final int monthlySales = products
          .where((Product product) =>
              product.savedAt.isAfter(monthStart) &&
              product.savedAt.isBefore(now))
          .length;

      // حساب إجمالي الأرباح
      final double totalProfit = products
          .map((Product product) => product.calculateProfit().toDouble())
          .fold<double>(0.0, (double sum, double profit) => sum + profit);

      // حساب تاريخ الأرباح (آخر 30 يوم)
      final List<ProfitData> profitHistory =
          await _calculateProfitHistory(products);

      return DashboardStats(
        totalProducts: totalProducts,
        totalProductsValue: totalProductsValue,
        uniqueProductNames: uniqueProductNames,
        todaySales: todaySales,
        monthlySales: monthlySales,
        totalProfit: totalProfit,
        profitHistory: profitHistory,
      );
    } on Exception catch (e) {
      debugPrint('خطأ في حساب إحصائيات لوحة التحكم: $e');
      return DashboardStats.empty();
    }
  }

  /// حساب تاريخ الأرباح للرسم البياني
  static Future<List<ProfitData>> _calculateProfitHistory(
      List<Product> products) async {
    try {
      final DateTime now = DateTime.now();
      final Map<DateTime, double> last30Days = <DateTime, double>{};

      // إنشاء خريطة للأيام الـ 30 الماضية
      for (int i = 29; i >= 0; i--) {
        final DateTime date = DateTime(now.year, now.month, now.day - i);
        last30Days[date] = 0.0;
      }

      // تجميع الأرباح حسب التاريخ
      for (final Product product in products) {
        final DateTime productDate = DateTime(
          product.savedAt.year,
          product.savedAt.month,
          product.savedAt.day,
        );

        if (last30Days.containsKey(productDate)) {
          last30Days[productDate] =
              last30Days[productDate]! + product.calculateProfit().toDouble();
        }
      }

      // تحويل إلى قائمة ProfitData
      return last30Days.entries
          .map((MapEntry<DateTime, double> entry) => ProfitData(
                date: entry.key,
                profit: entry.value,
              ))
          .toList()
        ..sort((ProfitData a, ProfitData b) => a.date.compareTo(b.date));
    } on Exception catch (e) {
      debugPrint('خطأ في حساب تاريخ الأرباح: $e');
      return <ProfitData>[];
    }
  }

  /// حساب إحصائيات المبيعات لفترة محددة
  Future<Map<String, int>> getSalesStats(
      DateTime startDate, DateTime endDate) async {
    try {
      final ProductsState productsState = _ref.read(productsControllerProvider);
      final List<Product> products = productsState.products;

      final Iterable<Product> filteredProducts = products.where(
          (Product product) =>
              product.savedAt.isAfter(startDate) &&
              product.savedAt.isBefore(endDate));

      final int totalSales = filteredProducts.length;
      final int totalProfit = filteredProducts
          .map((Product product) => product.calculateProfit())
          .fold<int>(0, (int sum, int profit) => sum + profit);

      return <String, int>{
        'totalSales': totalSales,
        'totalProfit': totalProfit,
      };
    } on Exception catch (e) {
      debugPrint('خطأ في حساب إحصائيات المبيعات: $e');
      return <String, int>{'totalSales': 0, 'totalProfit': 0};
    }
  }

  /// حساب إحصائيات المخزون
  Future<Map<String, dynamic>> getInventoryStats() async {
    try {
      final InventoryState inventoryState =
          _ref.read(inventoryControllerProvider);
      final List<InventoryItem> inventoryItems = inventoryState.inventoryItems;

      final int totalItems = inventoryItems.length;
      final double totalValue = inventoryItems
          .map((InventoryItem item) => item.getTotalValue().toDouble())
          .fold<double>(0.0, (double sum, double value) => sum + value);

      final int outOfStockItems = inventoryItems
          .where((InventoryItem item) => item.isOutOfStock())
          .length;

      final int lowStockItems = inventoryItems
          .where((InventoryItem item) =>
              !item.isOutOfStock() && item.quantity <= 5)
          .length;

      return <String, dynamic>{
        'totalItems': totalItems,
        'totalValue': totalValue,
        'outOfStockItems': outOfStockItems,
        'lowStockItems': lowStockItems,
      };
    } on Exception catch (e) {
      debugPrint('خطأ في حساب إحصائيات المخزون: $e');
      return <String, dynamic>{
        'totalItems': 0,
        'totalValue': 0.0,
        'outOfStockItems': 0,
        'lowStockItems': 0,
      };
    }
  }

  /// الحصول على أفضل المنتجات ربحية
  Future<List<Map<String, dynamic>>> getTopProfitableProducts(
      {int limit = 5}) async {
    try {
      final ProductsState productsState = _ref.read(productsControllerProvider);
      final List<Product> products = productsState.products;

      final List<Map<String, Object>> productsWithProfit = products
          .map((Product product) => <String, Object>{
                'name': product.name,
                'profit': product.calculateProfit(),
                'profitPercentage': product.calculateProfitPercentage(),
                'retailPrice': product.retailPrice,
                'wholesalePrice': product.wholesalePrice,
              })
          .toList()
        ..sort((Map<String, Object> a, Map<String, Object> b) =>
            (b['profit'] as int).compareTo(a['profit'] as int));

      return productsWithProfit.take(limit).toList();
    } on Exception catch (e) {
      debugPrint('خطأ في جلب أفضل المنتجات ربحية: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// الحصول على إحصائيات المبيعات الأسبوعية
  Future<List<Map<String, dynamic>>> getWeeklySalesStats() async {
    try {
      final DateTime now = DateTime.now();
      final List<Map<String, dynamic>> weeklyStats = <Map<String, dynamic>>[];

      for (int i = 6; i >= 0; i--) {
        final DateTime date = now.subtract(Duration(days: i));
        final DateTime dayStart = DateTime(date.year, date.month, date.day);
        final DateTime dayEnd = dayStart.add(const Duration(days: 1));

        final ProductsState productsState =
            _ref.read(productsControllerProvider);
        final List<Product> products = productsState.products;
        final Iterable<Product> dayProducts = products.where(
            (Product product) =>
                product.savedAt.isAfter(dayStart) &&
                product.savedAt.isBefore(dayEnd));

        final int daySales = dayProducts.length;
        final int dayProfit = dayProducts
            .map((Product product) => product.calculateProfit())
            .fold<int>(0, (int sum, int profit) => sum + profit);

        weeklyStats.add(<String, dynamic>{
          'date': dayStart,
          'dayName': DateFormat('E', 'ar').format(dayStart),
          'sales': daySales,
          'profit': dayProfit,
        });
      }

      return weeklyStats;
    } on Exception catch (e) {
      debugPrint('خطأ في حساب إحصائيات المبيعات الأسبوعية: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // ========== دوال ثابتة للتوافق مع الكود الحالي ==========

  /// إنشاء مثيل من الخدمة مع المزودات المطلوبة
  static DashboardService create({
    required WidgetRef ref,
  }) =>
      DashboardService(
        ref: ref,
      );

  /// حساب إحصائيات لوحة التحكم (دالة ثابتة للتوافق)
  static Future<DashboardStats> calculateDashboardStatsStatic({
    required WidgetRef ref,
  }) async {
    final DashboardService service = DashboardService(
      ref: ref,
    );
    return await service.calculateDashboardStats();
  }

  /// الحصول على أفضل المنتجات ربحية (دالة ثابتة للتوافق)
  static Future<List<Map<String, dynamic>>> getTopProfitableProductsStatic({
    required WidgetRef ref,
    int limit = 5,
  }) async {
    final DashboardService service = DashboardService(
      ref: ref,
    );
    return await service.getTopProfitableProducts(limit: limit);
  }

  /// حساب إحصائيات المبيعات لفترة محددة (دالة ثابتة للتوافق)
  static Future<Map<String, int>> getSalesStatsStatic({
    required WidgetRef ref,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DashboardService service = DashboardService(
      ref: ref,
    );
    return await service.getSalesStats(startDate, endDate);
  }

  /// حساب إحصائيات المخزون (دالة ثابتة للتوافق)
  static Future<Map<String, dynamic>> getInventoryStatsStatic({
    required WidgetRef ref,
  }) async {
    final DashboardService service = DashboardService(
      ref: ref,
    );
    return await service.getInventoryStats();
  }

  /// الحصول على إحصائيات المبيعات الأسبوعية (دالة ثابتة للتوافق)
  static Future<List<Map<String, dynamic>>> getWeeklySalesStatsStatic({
    required WidgetRef ref,
  }) async {
    final DashboardService service = DashboardService(
      ref: ref,
    );
    return await service.getWeeklySalesStats();
  }

  // ========== New Methods for Riverpod Controllers ==========

  /// حساب إحصائيات لوحة التحكم (دالة ثابتة للـ States)
  static Future<DashboardStats> calculateDashboardStatsForStates({
    required ProductsState productsState,
    required InventoryState inventoryState,
  }) async {
    try {
      // جلب البيانات من States
      final List<Product> products = productsState.products;
      // final List<InventoryItem> inventoryItems =
      //     inventoryController.state.inventoryItems as List<InventoryItem>;

      // حساب إجمالي المنتجات
      final int totalProducts = products.length;

      // حساب إجمالي القيمة المالية للمنتجات (سعر التجزئة)
      final double totalProductsValue = products.fold(
          0.0, (double sum, Product product) => sum + product.retailPrice);

      // حساب إجمالي الربح المتوقع
      final double totalExpectedProfit = products.fold(0.0,
          (double sum, Product product) => sum + product.calculateProfit());

      // حساب الأسماء الفريدة للمنتجات
      final int uniqueProductNames =
          products.map((Product p) => p.name).toSet().length;

      // حساب المبيعات اليومية والشهرية من قاعدة البيانات
      final DateTime now = DateTime.now();
      final DateTime todayStart = DateTime(now.year, now.month, now.day);
      final DateTime todayEnd = todayStart.add(const Duration(days: 1));
      final DateTime monthStart = DateTime(now.year, now.month);
      final DateTime monthEnd = DateTime(now.year, now.month + 1);

      // جلب المبيعات من قاعدة البيانات
      final AppDatabase db = AppDatabase.instance;
      final List<SalesTableData> todaySalesData =
          await db.getSalesByDateRange(todayStart, todayEnd);
      final List<SalesTableData> monthlySalesData =
          await db.getSalesByDateRange(monthStart, monthEnd);

      // حساب عدد المبيعات اليومية والشهرية
      final int todaySales = todaySalesData.length;
      final int monthlySales = monthlySalesData.length;

      // حساب إجمالي الربح من المبيعات الفعلية
      final double totalProfitFromSales = monthlySalesData.fold<double>(
          0.0,
          (double sum, SalesTableData sale) =>
              sum + sale.totalProfit.toDouble());

      // استخدام الربح من المبيعات إذا كان متاحاً، وإلا استخدم الربح المتوقع
      final double totalProfit = totalProfitFromSales > 0
          ? totalProfitFromSales
          : totalExpectedProfit;

      // حساب تاريخ الأرباح من بيانات المبيعات (آخر 30 يوم)
      final List<ProfitData> profitHistory =
          await _calculateProfitHistoryFromSales();

      return DashboardStats(
        totalProducts: totalProducts,
        totalProductsValue: totalProductsValue,
        uniqueProductNames: uniqueProductNames,
        todaySales: todaySales,
        monthlySales: monthlySales,
        totalProfit: totalProfit,
        profitHistory: profitHistory,
      );
    } catch (e) {
      debugPrint('❌ خطأ في حساب إحصائيات لوحة التحكم: $e');
      rethrow;
    }
  }

  /// حساب تاريخ الأرباح من بيانات المبيعات (آخر 30 يوم)
  static Future<List<ProfitData>> _calculateProfitHistoryFromSales() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startDate = now.subtract(const Duration(days: 30));
      final Map<DateTime, double> dailyProfits = <DateTime, double>{};

      // إنشاء خريطة للأيام الـ 30 الماضية
      for (int i = 29; i >= 0; i--) {
        final DateTime date = DateTime(now.year, now.month, now.day - i);
        dailyProfits[date] = 0.0;
      }

      // جلب المبيعات من قاعدة البيانات
      final AppDatabase db = AppDatabase.instance;
      final List<SalesTableData> sales =
          await db.getSalesByDateRange(startDate, now);

      // تجميع الأرباح حسب التاريخ
      for (final SalesTableData sale in sales) {
        try {
          final DateTime saleDate = DateTime.parse(sale.saleDate);
          final DateTime saleDay = DateTime(
            saleDate.year,
            saleDate.month,
            saleDate.day,
          );

          if (dailyProfits.containsKey(saleDay)) {
            dailyProfits[saleDay] =
                dailyProfits[saleDay]! + (sale.totalProfit.toDouble());
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في تحليل تاريخ البيع: $e');
          continue;
        }
      }

      // تحويل إلى قائمة ProfitData
      return dailyProfits.entries
          .map((MapEntry<DateTime, double> entry) => ProfitData(
                date: entry.key,
                profit: entry.value,
              ))
          .toList()
        ..sort((ProfitData a, ProfitData b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('❌ خطأ في حساب تاريخ الأرباح من المبيعات: $e');
      return <ProfitData>[];
    }
  }

  /// حساب الاتجاهات من البيانات التاريخية
  static Future<Map<String, double>> calculateTrends({
    required double currentTotalProfit,
    required double currentProductsValue,
    required int currentTodaySales,
    required int currentMonthlySales,
  }) async {
    try {
      final DateTime now = DateTime.now();
      final AppDatabase db = AppDatabase.instance;

      // حساب الربح للفترة السابقة (الشهر الماضي)
      final DateTime lastMonthStart = DateTime(now.year, now.month - 1);
      final DateTime lastMonthEnd = DateTime(now.year, now.month);
      final List<SalesTableData> lastMonthSales =
          await db.getSalesByDateRange(lastMonthStart, lastMonthEnd);
      final double lastMonthProfit = lastMonthSales.fold<double>(
          0.0,
          (double sum, SalesTableData sale) =>
              sum + sale.totalProfit.toDouble());

      // حساب المبيعات اليومية للأمس
      final DateTime yesterdayStart =
          DateTime(now.year, now.month, now.day - 1);
      final DateTime yesterdayEnd = yesterdayStart.add(const Duration(days: 1));
      final List<SalesTableData> yesterdaySales =
          await db.getSalesByDateRange(yesterdayStart, yesterdayEnd);
      final int yesterdaySalesCount = yesterdaySales.length;

      // حساب المبيعات الشهرية للشهر الماضي
      final int lastMonthSalesCount = lastMonthSales.length;

      // حساب الاتجاهات كنسبة مئوية
      final double totalProfitTrend = lastMonthProfit > 0
          ? ((currentTotalProfit - lastMonthProfit) / lastMonthProfit) * 100
          : (currentTotalProfit > 0 ? 100.0 : 0.0);

      // قيمة المنتجات - مقارنة مع الشهر الماضي (استخدام نفس المنطق)
      final double productsValueTrend = lastMonthProfit > 0
          ? ((currentProductsValue - (lastMonthProfit * 0.8)) /
                  (lastMonthProfit * 0.8)) *
              100
          : (currentProductsValue > 0 ? 100.0 : 0.0);

      // المبيعات اليومية - مقارنة مع الأمس
      final double todayTrend = yesterdaySalesCount > 0
          ? ((currentTodaySales - yesterdaySalesCount) /
                  yesterdaySalesCount) *
              100
          : (currentTodaySales > 0 ? 100.0 : 0.0);

      // المبيعات الشهرية - مقارنة مع الشهر الماضي
      final double monthlyTrend = lastMonthSalesCount > 0
          ? ((currentMonthlySales - lastMonthSalesCount) /
                  lastMonthSalesCount) *
              100
          : (currentMonthlySales > 0 ? 100.0 : 0.0);

      return <String, double>{
        'totalProfitTrend': totalProfitTrend,
        'productsValueTrend': productsValueTrend,
        'todayTrend': todayTrend,
        'monthlyTrend': monthlyTrend,
      };
    } catch (e) {
      debugPrint('⚠️ خطأ في حساب الاتجاهات: $e');
      // إرجاع قيم افتراضية في حالة الخطأ
      return <String, double>{
        'totalProfitTrend': 0.0,
        'productsValueTrend': 0.0,
        'todayTrend': 0.0,
        'monthlyTrend': 0.0,
      };
    }
  }

  /// الحصول على أكثر المنتجات ربحية (دالة ثابتة للـ States)
  static Future<List<Map<String, dynamic>>>
      getTopProfitableProductsForStates({
    required ProductsState productsState,
    required InventoryState inventoryState,
    int limit = 5,
  }) async {
    try {
      // جلب البيانات من States
      final List<Product> products = productsState.products;
      final List<InventoryItem> inventoryItems = inventoryState.inventoryItems;

      // التحقق من وجود منتجات
      if (products.isEmpty) {
        debugPrint('⚠️ لا توجد منتجات متاحة لحساب الأرباح');
        return <Map<String, dynamic>>[];
      }

      // إنشاء قائمة بالمنتجات مع ربحها
      final List<Map<String, dynamic>> productsWithProfit =
          products.map((Product product) {
        final InventoryItem? inventoryItem = inventoryItems
            .where((InventoryItem item) => item.barcode == product.barcode)
            .firstOrNull;

        final double profit = product.calculateProfit().toDouble();
        final double totalProfit = profit * (inventoryItem?.quantity ?? 0);
        final double profitPercentage = product.retailPrice > 0
            ? (profit / product.retailPrice) * 100
            : 0.0;

        return <String, dynamic>{
          'name': product.name.isNotEmpty ? product.name : 'منتج غير معروف',
          'profit': totalProfit,
          'profitPercentage': profitPercentage,
          'quantity': inventoryItem?.quantity ?? 0,
          'retailPrice': product.retailPrice,
          'wholesalePrice': product.wholesalePrice,
        };
      }).toList();

      // ترتيب حسب الربح الإجمالي
      productsWithProfit.sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (b['profit'] as double).compareTo(a['profit'] as double));

      return productsWithProfit.take(limit).toList();
    } catch (e) {
      debugPrint('❌ خطأ في الحصول على أكثر المنتجات ربحية: $e');
      return <Map<String, dynamic>>[];
    }
  }
}
