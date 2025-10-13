import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_stats.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/stream_inventory_provider.dart';
import '../providers/stream_product_provider.dart';

/// خدمة حساب إحصائيات لوحة التحكم
class DashboardService {
  DashboardService({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  })  : _productProvider = productProvider,
        _inventoryProvider = inventoryProvider;
  final StreamProductProvider _productProvider;
  final StreamInventoryProvider _inventoryProvider;

  /// حساب إحصائيات لوحة التحكم
  Future<DashboardStats> calculateDashboardStats() async {
    try {
      // جلب البيانات من المزودات مباشرة
      final List<Product> products = _productProvider.products;

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
      final List<Product> products = _productProvider.products;

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
      final List<InventoryItem> inventoryItems =
          _inventoryProvider.inventoryItems;

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
      final List<Product> products = _productProvider.products;

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

        final List<Product> products = _productProvider.products;
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
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) =>
      DashboardService(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );

  /// حساب إحصائيات لوحة التحكم (دالة ثابتة للتوافق)
  static Future<DashboardStats> calculateDashboardStatsStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    final DashboardService service = DashboardService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.calculateDashboardStats();
  }

  /// الحصول على أفضل المنتجات ربحية (دالة ثابتة للتوافق)
  static Future<List<Map<String, dynamic>>> getTopProfitableProductsStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    int limit = 5,
  }) async {
    final DashboardService service = DashboardService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.getTopProfitableProducts(limit: limit);
  }

  /// حساب إحصائيات المبيعات لفترة محددة (دالة ثابتة للتوافق)
  static Future<Map<String, int>> getSalesStatsStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final DashboardService service = DashboardService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.getSalesStats(startDate, endDate);
  }

  /// حساب إحصائيات المخزون (دالة ثابتة للتوافق)
  static Future<Map<String, dynamic>> getInventoryStatsStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    final DashboardService service = DashboardService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.getInventoryStats();
  }

  /// الحصول على إحصائيات المبيعات الأسبوعية (دالة ثابتة للتوافق)
  static Future<List<Map<String, dynamic>>> getWeeklySalesStatsStatic({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    final DashboardService service = DashboardService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    return await service.getWeeklySalesStats();
  }
}
