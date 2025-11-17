import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/sale.dart';

/// خدمة التحليلات المحسنة للأداء - تستخدم background threads وcaching
class PerformanceOptimizedAnalyticsService {

  PerformanceOptimizedAnalyticsService();
  static const int _cacheExpirationMinutes = 5;
  static const int _maxCacheSize = 100;

  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  /// حساب التحليلات مع تحسين الأداء
  Future<Map<String, dynamic>> calculateOptimizedAnalytics({
    required List<Sale> sales,
    bool useCache = true,
  }) async {
    if (sales.isEmpty) {
      return _getEmptyAnalytics();
    }

    // التحقق من الـ cache
    final String cacheKey = _generateCacheKey(sales);
    if (useCache && _cache.containsKey(cacheKey)) {
      final _CacheEntry entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        debugPrint('📊 استخدام البيانات المحفوظة مؤقتاً للتحليلات');
        return entry.data;
      }
    }

    // حساب التحليلات في background thread
    final Map<String, dynamic> analytics =
        await compute(_calculateAnalyticsInIsolate, sales);

    // حفظ في الـ cache
    if (useCache) {
      _updateCache(cacheKey, analytics);
    }

    return analytics;
  }

  /// حساب تحليل الاتجاهات مع تحسين الأداء
  Future<Map<String, dynamic>> calculateOptimizedTrendAnalysis({
    required List<Sale> sales,
    bool useCache = true,
  }) async {
    if (sales.length < 2) {
      return _getEmptyTrendAnalysis();
    }

    final String cacheKey = 'trend_${_generateCacheKey(sales)}';
    if (useCache && _cache.containsKey(cacheKey)) {
      final _CacheEntry entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        debugPrint('📊 استخدام البيانات المحفوظة مؤقتاً لتحليل الاتجاهات');
        return entry.data;
      }
    }

    // حساب تحليل الاتجاهات في background thread
    final Map<String, dynamic> trendAnalysis =
        await compute(_calculateTrendInIsolate, sales);

    // حفظ في الـ cache
    if (useCache) {
      _updateCache(cacheKey, trendAnalysis);
    }

    return trendAnalysis;
  }

  /// حساب التحليلات بالساعة مع تحسين الأداء
  Future<Map<int, double>> calculateOptimizedHourlySales({
    required List<Sale> sales,
    bool useCache = true,
  }) async {
    if (sales.isEmpty) {
      return <int, double>{};
    }

    final String cacheKey = 'hourly_${_generateCacheKey(sales)}';
    if (useCache && _cache.containsKey(cacheKey)) {
      final _CacheEntry entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return Map<int, double>.from(entry.data['hourlySales'] as Map);
      }
    }

    // حساب المبيعات بالساعة في background thread
    final Map<int, double> hourlySales =
        await compute(_calculateHourlySalesInIsolate, sales);

    // حفظ في الـ cache
    if (useCache) {
      _updateCache(cacheKey, <String, dynamic>{'hourlySales': hourlySales});
    }

    return hourlySales;
  }

  /// حساب التحليلات اليومية مع تحسين الأداء
  Future<Map<DateTime, double>> calculateOptimizedDailySales({
    required List<Sale> sales,
    bool useCache = true,
  }) async {
    if (sales.isEmpty) {
      return <DateTime, double>{};
    }

    final String cacheKey = 'daily_${_generateCacheKey(sales)}';
    if (useCache && _cache.containsKey(cacheKey)) {
      final _CacheEntry entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        final Map<String, dynamic> dailySalesData =
            entry.data['dailySales'] as Map<String, dynamic>;
        return dailySalesData.map((String key, value) =>
            MapEntry(DateTime.parse(key), value as double));
      }
    }

    // حساب المبيعات اليومية في background thread
    final Map<DateTime, double> dailySales =
        await compute(_calculateDailySalesInIsolate, sales);

    // حفظ في الـ cache
    if (useCache) {
      final Map<String, double> serializedDailySales = dailySales.map(
          (DateTime key, double value) =>
              MapEntry(key.toIso8601String(), value));
      _updateCache(cacheKey, <String, dynamic>{'dailySales': serializedDailySales});
    }

    return dailySales;
  }

  /// حساب التحليلات المتقدمة (تحليل المنتجات الأكثر ربحية، إلخ)
  Future<Map<String, dynamic>> calculateAdvancedAnalytics({
    required List<Sale> sales,
    bool useCache = true,
  }) async {
    if (sales.isEmpty) {
      return _getEmptyAdvancedAnalytics();
    }

    final String cacheKey = 'advanced_${_generateCacheKey(sales)}';
    if (useCache && _cache.containsKey(cacheKey)) {
      final _CacheEntry entry = _cache[cacheKey]!;
      if (!entry.isExpired) {
        return entry.data;
      }
    }

    // حساب التحليلات المتقدمة في background thread
    final Map<String, dynamic> advancedAnalytics =
        await compute(_calculateAdvancedAnalyticsInIsolate, sales);

    // حفظ في الـ cache
    if (useCache) {
      _updateCache(cacheKey, advancedAnalytics);
    }

    return advancedAnalytics;
  }

  /// مسح الـ cache
  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ تم مسح cache التحليلات');
  }

  /// مسح الـ cache المنتهي الصلاحية
  void cleanExpiredCache() {
    final List<String> expiredKeys = _cache.entries
        .where((MapEntry<String, _CacheEntry> entry) => entry.value.isExpired)
        .map((MapEntry<String, _CacheEntry> entry) => entry.key)
        .toList();

    for (final String key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint(
          '🗑️ تم مسح ${expiredKeys.length} إدخال منتهي الصلاحية من cache');
    }
  }

  /// تحديث الـ cache
  void _updateCache(String key, Map<String, dynamic> data) {
    // مسح الـ cache المنتهي الصلاحية أولاً
    cleanExpiredCache();

    // التحقق من حجم الـ cache
    if (_cache.length >= _maxCacheSize) {
      // إزالة أقدم إدخال
      final String oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }

    _cache[key] = _CacheEntry(data, DateTime.now());
  }

  /// توليد مفتاح cache
  String _generateCacheKey(List<Sale> sales) {
    if (sales.isEmpty) return 'empty';

    final int totalAmount =
        sales.fold<int>(0, (int sum, Sale sale) => sum + sale.totalAmount);
    final int totalProfit =
        sales.fold<int>(0, (int sum, Sale sale) => sum + sale.totalProfit);
    final String lastSaleId = sales.first.id ?? 'unknown';

    return '${sales.length}_${totalAmount}_${totalProfit}_$lastSaleId';
  }

  /// الحصول على تحليلات فارغة
  Map<String, dynamic> _getEmptyAnalytics() => <String, dynamic>{
      'totalRevenue': 0.0,
      'totalProfit': 0.0,
      'totalTransactions': 0,
      'averageTransactionValue': 0.0,
      'averageProfit': 0.0,
      'hourlySales': <int, double>{},
      'dailySales': <DateTime, double>{},
    };

  /// الحصول على تحليل اتجاهات فارغ
  Map<String, dynamic> _getEmptyTrendAnalysis() => <String, dynamic>{
      'revenueGrowth': 0.0,
      'profitGrowth': 0.0,
      'transactionGrowth': 0.0,
      'trend': 'stable',
    };

  /// الحصول على تحليلات متقدمة فارغة
  Map<String, dynamic> _getEmptyAdvancedAnalytics() => <String, dynamic>{
      'topProducts': <Map<String, dynamic>>[],
      'topCustomers': <Map<String, dynamic>>[],
      'paymentMethodBreakdown': <String, double>{},
      'peakHours': <int>[],
      'revenueDistribution': <String, double>{},
    };
}

/// إدخال cache
class _CacheEntry {
  _CacheEntry(this.data, this.timestamp);

  final Map<String, dynamic> data;
  final DateTime timestamp;

  bool get isExpired =>
      DateTime.now().difference(timestamp).inMinutes >
      PerformanceOptimizedAnalyticsService._cacheExpirationMinutes;
}

/// حساب التحليلات في isolate منفصل
Map<String, dynamic> _calculateAnalyticsInIsolate(List<Sale> sales) {
  final double totalRevenue =
      sales.fold<double>(0, (double sum, Sale sale) => sum + sale.totalAmount);
  final double totalProfit =
      sales.fold<double>(0, (double sum, Sale sale) => sum + sale.totalProfit);
  final int totalTransactions = sales.length;
  final double averageTransactionValue =
      totalTransactions > 0 ? totalRevenue / totalTransactions : 0.0;
  final double averageProfit =
      totalTransactions > 0 ? totalProfit / totalTransactions : 0.0;

  // حساب المبيعات بالساعة
  final Map<int, double> hourlySales = <int, double>{};
  for (final Sale sale in sales) {
    final int hour = sale.saleDate.hour;
    hourlySales[hour] = (hourlySales[hour] ?? 0) + sale.totalAmount;
  }

  // حساب المبيعات اليومية
  final Map<DateTime, double> dailySales = <DateTime, double>{};
  for (final Sale sale in sales) {
    final DateTime day =
        DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
    dailySales[day] = (dailySales[day] ?? 0) + sale.totalAmount;
  }

  return <String, dynamic>{
    'totalRevenue': totalRevenue,
    'totalProfit': totalProfit,
    'totalTransactions': totalTransactions,
    'averageTransactionValue': averageTransactionValue,
    'averageProfit': averageProfit,
    'hourlySales': hourlySales,
    'dailySales': dailySales,
  };
}

/// حساب تحليل الاتجاهات في isolate منفصل
Map<String, dynamic> _calculateTrendInIsolate(List<Sale> sales) {
  if (sales.length < 2) {
    return <String, dynamic>{
      'revenueGrowth': 0.0,
      'profitGrowth': 0.0,
      'transactionGrowth': 0.0,
      'trend': 'stable',
    };
  }

  // ترتيب المبيعات حسب التاريخ
  final List<Sale> sortedSales = List<Sale>.from(sales)
    ..sort((Sale a, Sale b) => a.saleDate.compareTo(b.saleDate));

  // تقسيم إلى فترتين للمقارنة
  final int midPoint = sortedSales.length ~/ 2;
  final List<Sale> firstHalf = sortedSales.take(midPoint).toList();
  final List<Sale> secondHalf = sortedSales.skip(midPoint).toList();

  // حساب المتوسطات
  final double firstHalfRevenue =
      firstHalf.fold<double>(0, (double sum, Sale sale) => sum + sale.totalAmount) /
          firstHalf.length;
  final double secondHalfRevenue =
      secondHalf.fold<double>(0, (double sum, Sale sale) => sum + sale.totalAmount) /
          secondHalf.length;

  final double firstHalfProfit =
      firstHalf.fold<double>(0, (double sum, Sale sale) => sum + sale.totalProfit) /
          firstHalf.length;
  final double secondHalfProfit =
      secondHalf.fold<double>(0, (double sum, Sale sale) => sum + sale.totalProfit) /
          secondHalf.length;

  // حساب النمو
  final double revenueGrowth = firstHalfRevenue > 0
      ? ((secondHalfRevenue - firstHalfRevenue) / firstHalfRevenue) * 100
      : 0;
  final double profitGrowth = firstHalfProfit > 0
      ? ((secondHalfProfit - firstHalfProfit) / firstHalfProfit) * 100
      : 0;
  final double transactionGrowth = firstHalf.isNotEmpty
      ? ((secondHalf.length - firstHalf.length) / firstHalf.length) * 100
      : 0;

  // تحديد الاتجاه
  String trend = 'stable';
  if (revenueGrowth > 5) {
    trend = 'growing';
  } else if (revenueGrowth < -5) {
    trend = 'declining';
  }

  return <String, dynamic>{
    'revenueGrowth': revenueGrowth,
    'profitGrowth': profitGrowth,
    'transactionGrowth': transactionGrowth,
    'trend': trend,
  };
}

/// حساب المبيعات بالساعة في isolate منفصل
Map<int, double> _calculateHourlySalesInIsolate(List<Sale> sales) {
  final Map<int, double> hourlySales = <int, double>{};

  for (final Sale sale in sales) {
    final int hour = sale.saleDate.hour;
    hourlySales[hour] = (hourlySales[hour] ?? 0) + sale.totalAmount;
  }

  return hourlySales;
}

/// حساب المبيعات اليومية في isolate منفصل
Map<DateTime, double> _calculateDailySalesInIsolate(List<Sale> sales) {
  final Map<DateTime, double> dailySales = <DateTime, double>{};

  for (final Sale sale in sales) {
    final DateTime day =
        DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
    dailySales[day] = (dailySales[day] ?? 0) + sale.totalAmount;
  }

  return dailySales;
}

/// حساب التحليلات المتقدمة في isolate منفصل
Map<String, dynamic> _calculateAdvancedAnalyticsInIsolate(List<Sale> sales) {
  // تحليل المنتجات الأكثر ربحية
  final Map<String, Map<String, dynamic>> productStats =
      <String, Map<String, dynamic>>{};

  for (final Sale sale in sales) {
    for (final CartItem item in sale.items) {
      final String productKey = '${item.productId}_${item.name}';
      if (!productStats.containsKey(productKey)) {
        productStats[productKey] = <String, dynamic>{
          'name': item.name,
          'totalRevenue': 0.0,
          'totalProfit': 0.0,
          'totalQuantity': 0,
          'averagePrice': 0.0,
        };
      }

      final Map<String, dynamic> stats = productStats[productKey]!;
      stats['totalRevenue'] = (stats['totalRevenue'] as double) +
          (item.retailPrice * item.quantity);
      stats['totalProfit'] = (stats['totalProfit'] as double) +
          ((item.retailPrice - item.wholesalePrice) * item.quantity);
      stats['totalQuantity'] = (stats['totalQuantity'] as int) + item.quantity;
      stats['averagePrice'] =
          (stats['totalRevenue'] as double) / (stats['totalQuantity'] as int);
    }
  }

  // ترتيب المنتجات حسب الربحية
  final List<Map<String, dynamic>> topProducts = productStats.values.toList()
    ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        (b['totalProfit'] as double).compareTo(a['totalProfit'] as double));

  // تحليل طرق الدفع
  final Map<String, double> paymentMethodBreakdown = <String, double>{};
  for (final Sale sale in sales) {
    paymentMethodBreakdown[sale.paymentMethod] =
        (paymentMethodBreakdown[sale.paymentMethod] ?? 0) + sale.totalAmount;
  }

  // تحديد ساعات الذروة
  final Map<int, double> hourlyRevenue = <int, double>{};
  for (final Sale sale in sales) {
    final int hour = sale.saleDate.hour;
    hourlyRevenue[hour] = (hourlyRevenue[hour] ?? 0) + sale.totalAmount;
  }

  final List<MapEntry<int, double>> sortedHourlyRevenue = hourlyRevenue.entries
      .toList()
    ..sort((MapEntry<int, double> a, MapEntry<int, double> b) => b.value.compareTo(a.value));

  final List<int> peakHours = sortedHourlyRevenue
      .take(3)
      .map((MapEntry<int, double> entry) => entry.key)
      .toList();

  return <String, dynamic>{
    'topProducts': topProducts.take(10).toList(),
    'topCustomers': <Map<String, dynamic>>[], // يمكن إضافته لاحقاً
    'paymentMethodBreakdown': paymentMethodBreakdown,
    'peakHours': peakHours,
    'revenueDistribution': <String, double>{
      'morning': hourlyRevenue.entries
          .where(
              (MapEntry<int, double> entry) => entry.key >= 6 && entry.key < 12)
          .fold<double>(0, (double sum, MapEntry<int, double> entry) => sum + entry.value),
      'afternoon': hourlyRevenue.entries
          .where((MapEntry<int, double> entry) =>
              entry.key >= 12 && entry.key < 18)
          .fold<double>(0, (double sum, MapEntry<int, double> entry) => sum + entry.value),
      'evening': hourlyRevenue.entries
          .where((MapEntry<int, double> entry) =>
              entry.key >= 18 && entry.key < 24)
          .fold<double>(0, (double sum, MapEntry<int, double> entry) => sum + entry.value),
      'night': hourlyRevenue.entries
          .where(
              (MapEntry<int, double> entry) => entry.key >= 0 && entry.key < 6)
          .fold<double>(0, (double sum, MapEntry<int, double> entry) => sum + entry.value),
    },
  };
}

/// Provider للخدمة المحسنة
final Provider<PerformanceOptimizedAnalyticsService> performanceOptimizedAnalyticsServiceProvider =
    Provider<PerformanceOptimizedAnalyticsService>(
        (ProviderRef<PerformanceOptimizedAnalyticsService> ref) => PerformanceOptimizedAnalyticsService());
