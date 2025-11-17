import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:profit_calculator/models/cart_item.dart';
import 'package:profit_calculator/models/page_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/product.dart';
import '../../models/sale.dart';
import '../../services/connectivity_service.dart';
import '../../services/pos_service.dart';
import '../models/dashboard_summary.dart';

/// خدمة لوحة التحكم
class DashboardService {
  factory DashboardService() => _instance;
  DashboardService._internal();
  static final DashboardService _instance = DashboardService._internal();

  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final POSService _posService = POSService();
  // final ConnectivityService _connectivityService = ConnectivityService();

  /// جلب ملخص لوحة التحكم
  Future<DashboardSummary> getDashboardSummary() async {
    try {
      final DateTime now = DateTime.now();
      final DateTime startOfDay = DateTime(now.year, now.month, now.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));
      final DateTime yesterdayStart =
          startOfDay.subtract(const Duration(days: 1));
      final DateTime yesterdayEnd = startOfDay;

      // جلب مبيعات اليوم من قاعدة البيانات الحقيقية
      debugPrint('🔍 جلب مبيعات اليوم من $startOfDay إلى $endOfDay');

      List<Sale> todaySales = <Sale>[];
      try {
        final PageResult<Sale> pageResult = await POSService.getCombinedSalesPage(
          startDate: startOfDay,
          endDate: endOfDay,
        );
        todaySales = pageResult.items;
        debugPrint('📊 عدد مبيعات اليوم: ${todaySales.length}');
      } catch (e) {
        debugPrint('❌ خطأ في جلب مبيعات اليوم: $e');
        todaySales = <Sale>[];
      }

      // جلب مبيعات الأمس
      List<Sale> yesterdaySales = <Sale>[];
      try {
        final PageResult<Sale> pageResult = await POSService.getCombinedSalesPage(
          startDate: yesterdayStart,
          endDate: yesterdayEnd,
        );
        yesterdaySales = pageResult.items;
        debugPrint('📊 عدد مبيعات الأمس: ${yesterdaySales.length}');
      } catch (e) {
        debugPrint('❌ خطأ في جلب مبيعات الأمس: $e');
        yesterdaySales = <Sale>[];
      }

      // حساب إجمالي المبيعات اليوم
      final double totalSalesToday =
          todaySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);
      final double totalSalesYesterday =
          yesterdaySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);

      // حساب عدد العملاء
      final int totalCustomersToday = todaySales.length;
      final int totalCustomersYesterday = yesterdaySales.length;

      // حساب الأرباح
      final double totalProfitToday =
          todaySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalProfit);
      final double totalProfitYesterday =
          yesterdaySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalProfit);

      // جلب أفضل المنتجات
      final List<TopProductSummary> topProducts =
          await _getTopProducts(todaySales);

      // جلب تنبيهات المخزون
      final List<LowStockAlert> lowStockAlerts = await _getLowStockAlerts();

      // جلب حالة المزامنة
      final SyncStatus syncStatus = await _getSyncStatus();
      final DateTime? lastSyncTime = await _getLastSyncTime();

      // حساب عدد المعاملات
      final int totalTransactionsToday = totalCustomersToday;

      // حساب متوسط قيمة البيع
      final double averageSaleValue = totalTransactionsToday > 0
          ? totalSalesToday / totalTransactionsToday
          : 0.0;

      return DashboardSummary(
        totalSalesToday: totalSalesToday,
        totalSalesYesterday: totalSalesYesterday,
        totalCustomersToday: totalCustomersToday,
        totalCustomersYesterday: totalCustomersYesterday,
        topProducts: topProducts,
        lowStockAlerts: lowStockAlerts,
        syncStatus: syncStatus,
        lastSyncTime: lastSyncTime,
        totalTransactionsToday: totalTransactionsToday,
        averageSaleValue: averageSaleValue,
        totalProfitToday: totalProfitToday,
        totalProfitYesterday: totalProfitYesterday,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب ملخص لوحة التحكم: $e');

      // إرجاع بيانات فارغة في حالة الخطأ
      return const DashboardSummary(
        totalSalesToday: 0.0,
        totalSalesYesterday: 0.0,
        totalCustomersToday: 0,
        totalCustomersYesterday: 0,
        topProducts: <TopProductSummary>[],
        lowStockAlerts: <LowStockAlert>[],
        syncStatus: SyncStatus.synced,
        lastSyncTime: null,
        totalTransactionsToday: 0,
        averageSaleValue: 0.0,
        totalProfitToday: 0.0,
        totalProfitYesterday: 0.0,
      );
    }
  }

  /// جلب أفضل المنتجات
  Future<List<TopProductSummary>> _getTopProducts(List<Sale> sales,
      {int limit = 5}) async {
    try {
      final Map<String, Map<String, dynamic>> productStats = <String, Map<String, dynamic>>{};

      for (final Sale sale in sales) {
        for (final CartItem item in sale.items) {
          final String productId = item.productId;
          if (productStats.containsKey(productId)) {
            final Map<String, dynamic> stats = productStats[productId]!;
            stats['quantity'] = (stats['quantity'] as int) + item.quantity;
            stats['totalValue'] =
                (stats['totalValue'] as double) + (item.totalPrice as double);
          } else {
            productStats[productId] = <String, dynamic>{
              'productId': productId,
              'productName': item.name,
              'quantity': item.quantity,
              'totalValue': item.totalPrice as double,
            };
          }
        }
      }

      final List<MapEntry<String, Map<String, dynamic>>> sortedProducts =
          productStats.entries.toList()
            ..sort((MapEntry<String, Map<String, dynamic>> a, MapEntry<String, Map<String, dynamic>> b) => (b.value['totalValue'] as double)
                .compareTo(a.value['totalValue'] as double));

      return sortedProducts.take(limit).toList().asMap().entries.map((MapEntry<int, MapEntry<String, Map<String, dynamic>>> entry) {
        final int index = entry.key;
        final Map<String, dynamic> productData = entry.value.value;
        return TopProductSummary(
          productId: productData['productId'] as String,
          productName: productData['productName'] as String,
          quantitySold: productData['quantity'] as int,
          totalValue: productData['totalValue'] as double,
          rank: index + 1,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب أفضل المنتجات: $e');
      return <TopProductSummary>[];
    }
  }

  /// جلب تنبيهات المخزون
  Future<List<LowStockAlert>> _getLowStockAlerts() async {
    try {
      // تنفيذ مبسط - في التطبيق الحقيقي ستحتاج إلى جلب المنتجات
      final List<Product> products = <Product>[];
      final List<LowStockAlert> alerts = <LowStockAlert>[];

      for (final Product product in products) {
        if (!product.isActive) continue;

        const int currentStock = 0; // Product model doesn't have stock field
        final int minimumStock = product.minimumStock ?? 10;

        if (currentStock <= minimumStock) {
          AlertLevel alertLevel;
          if (currentStock == 0) {
            alertLevel = AlertLevel.outOfStock;
          } else if (currentStock <= (minimumStock * 0.5).round()) {
            alertLevel = AlertLevel.critical;
          } else {
            alertLevel = AlertLevel.low;
          }

          alerts.add(LowStockAlert(
            productId: product.id ?? '',
            productName: product.name,
            currentStock: currentStock,
            minimumStock: minimumStock,
            alertLevel: alertLevel,
          ));
        }
      }

      return alerts;
    } catch (e) {
      debugPrint('❌ خطأ في جلب تنبيهات المخزون: $e');
      return <LowStockAlert>[];
    }
  }

  /// جلب حالة المزامنة
  Future<SyncStatus> _getSyncStatus() async {
    try {
      final bool isConnected = ConnectivityService.isConnected;
      if (!isConnected) return SyncStatus.unknown;

      // التحقق من آخر مزامنة
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastSyncString = prefs.getString('last_sync_time');

      if (lastSyncString == null) return SyncStatus.unknown;

      final DateTime lastSync = DateTime.parse(lastSyncString);
      final Duration timeSinceSync = DateTime.now().difference(lastSync);

      if (timeSinceSync.inMinutes < 5) {
        return SyncStatus.synced;
      } else if (timeSinceSync.inMinutes < 30) {
        return SyncStatus.syncing;
      } else {
        return SyncStatus.failed;
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب حالة المزامنة: $e');
      return SyncStatus.unknown;
    }
  }

  /// جلب وقت آخر مزامنة
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? lastSyncString = prefs.getString('last_sync_time');

      if (lastSyncString == null) return null;

      return DateTime.parse(lastSyncString);
    } catch (e) {
      debugPrint('❌ خطأ في جلب وقت آخر مزامنة: $e');
      return null;
    }
  }

  /// تحديث حالة المزامنة
  Future<void> updateSyncStatus(SyncStatus status) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('sync_status', status.name);

      if (status == SyncStatus.synced) {
        await prefs.setString(
            'last_sync_time', DateTime.now().toIso8601String());
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حالة المزامنة: $e');
    }
  }

  /// جلب إحصائيات سريعة للفترة المحددة
  Future<Map<String, dynamic>> getQuickStats(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales = await POSService.getCombinedSalesPage(
        startDate: startDate,
        endDate: endDate,
      ).then((PageResult<Sale> page) => page.items);

      final double totalSales =
          sales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);
      final int totalTransactions = sales.length;
      final double totalProfit =
          sales.fold(0.0, (double sum, Sale sale) => sum + sale.totalProfit);
      final double averageSaleValue =
          totalTransactions > 0 ? totalSales / totalTransactions : 0.0;

      return <String, dynamic>{
        'totalSales': totalSales,
        'totalTransactions': totalTransactions,
        'totalProfit': totalProfit,
        'averageSaleValue': averageSaleValue,
        'period': <String, Object>{
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'days': endDate.difference(startDate).inDays + 1,
        },
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب الإحصائيات السريعة: $e');
      return <String, dynamic>{
        'totalSales': 0.0,
        'totalTransactions': 0,
        'totalProfit': 0.0,
        'averageSaleValue': 0.0,
        'period': <String, Object>{
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'days': endDate.difference(startDate).inDays + 1,
        },
      };
    }
  }

  /// جلب بيانات الرسم البياني للمبيعات اليومية (آخر 7 أيام)
  Future<List<Map<String, dynamic>>> getDailySalesChart() async {
    try {
      final List<Map<String, dynamic>> chartData = <Map<String, dynamic>>[];
      final DateTime now = DateTime.now();

      for (int i = 6; i >= 0; i--) {
        final DateTime date = now.subtract(Duration(days: i));
        final DateTime startOfDay = DateTime(date.year, date.month, date.day);
        final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

        final List<Sale> daySales = await POSService.getCombinedSalesPage(
          startDate: startOfDay,
          endDate: endOfDay,
        ).then((PageResult<Sale> page) => page.items);

        final double totalSales =
            daySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);

        chartData.add(<String, dynamic>{
          'date': startOfDay.toIso8601String(),
          'totalSales': totalSales,
          'transactionCount': daySales.length,
          'dayName': _getDayName(date.weekday),
        });
      }

      return chartData;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات الرسم البياني: $e');
      return <Map<String, dynamic>>[];
    }
  }

  /// جلب اسم اليوم
  String _getDayName(int weekday) {
    const List<String> dayNames = <String>[
      'الأحد',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت'
    ];
    return dayNames[weekday % 7];
  }

  /// مسح التخزين المؤقت
  Future<void> clearCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_sync_time');
      await prefs.remove('sync_status');
      await prefs.remove('dashboard_cache');
    } catch (e) {
      debugPrint('❌ خطأ في مسح التخزين المؤقت: $e');
    }
  }

  /// حفظ التخزين المؤقت
  Future<void> saveToCache(DashboardSummary summary) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_cache', summary.toMap().toString());
      await prefs.setString(
          'dashboard_cache_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ خطأ في حفظ التخزين المؤقت: $e');
    }
  }

  /// جلب من التخزين المؤقت
  Future<DashboardSummary?> getFromCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cacheString = prefs.getString('dashboard_cache');
      final String? cacheTimeString = prefs.getString('dashboard_cache_time');

      if (cacheString == null || cacheTimeString == null) return null;

      final DateTime cacheTime = DateTime.parse(cacheTimeString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      // إذا كان عمر التخزين المؤقت أكثر من 5 دقائق، تجاهله
      if (cacheAge.inMinutes > 5) return null;

      // تحليل البيانات المحفوظة
      // Note: This is a simplified implementation
      // In a real app, you'd want to properly deserialize the data
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في جلب من التخزين المؤقت: $e');
      return null;
    }
  }
}
