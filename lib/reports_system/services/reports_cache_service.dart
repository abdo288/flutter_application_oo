import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/eod_report.dart';
import '../models/dashboard_summary.dart';
import '../models/inventory_report.dart';
import '../models/payment_report.dart';
import '../models/sales_analytics.dart';

/// خدمة التخزين المؤقت للتقارير
class ReportsCacheService {
  factory ReportsCacheService() => _instance;
  ReportsCacheService._internal();
  static final ReportsCacheService _instance = ReportsCacheService._internal();

  static const String _dashboardCacheKey = 'dashboard_cache';
  static const String _salesAnalyticsCacheKey = 'sales_analytics_cache';
  static const String _paymentReportCacheKey = 'payment_report_cache';
  static const String _inventoryReportCacheKey = 'inventory_report_cache';
  static const String _eodReportsCacheKey = 'eod_reports_cache';
  static const String _cacheTimestampKey = 'cache_timestamp';
  static const String _cacheSizeKey = 'cache_size';

  // مدة صلاحية التخزين المؤقت (بالدقائق)
  static const int _cacheExpiryMinutes = 30;
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50 MB

  /// حفظ لوحة التحكم في التخزين المؤقت
  Future<void> cacheDashboardSummary(DashboardSummary summary) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(summary.toMap());

      await prefs.setString(_dashboardCacheKey, jsonString);
      await prefs.setString(
          '${_dashboardCacheKey}_timestamp', DateTime.now().toIso8601String());

      await _updateCacheSize();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ لوحة التحكم في التخزين المؤقت: $e');
    }
  }

  /// جلب لوحة التحكم من التخزين المؤقت
  Future<DashboardSummary?> getCachedDashboardSummary() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_dashboardCacheKey);
      final String? timestampString =
          prefs.getString('${_dashboardCacheKey}_timestamp');

      if (jsonString == null || timestampString == null) return null;

      final DateTime cacheTime = DateTime.parse(timestampString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      // التحقق من انتهاء صلاحية التخزين المؤقت
      if (cacheAge.inMinutes > _cacheExpiryMinutes) {
        await _clearCache(_dashboardCacheKey);
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return DashboardSummary.fromMap(data);
    } catch (e) {
      debugPrint('❌ خطأ في جلب لوحة التحكم من التخزين المؤقت: $e');
      return null;
    }
  }

  /// حفظ تحليلات المبيعات في التخزين المؤقت
  Future<void> cacheSalesAnalytics(SalesAnalytics analytics, String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(analytics.toMap());

      await prefs.setString('${_salesAnalyticsCacheKey}_$key', jsonString);
      await prefs.setString('${_salesAnalyticsCacheKey}_${key}_timestamp',
          DateTime.now().toIso8601String());

      await _updateCacheSize();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تحليلات المبيعات في التخزين المؤقت: $e');
    }
  }

  /// جلب تحليلات المبيعات من التخزين المؤقت
  Future<SalesAnalytics?> getCachedSalesAnalytics(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString =
          prefs.getString('${_salesAnalyticsCacheKey}_$key');
      final String? timestampString =
          prefs.getString('${_salesAnalyticsCacheKey}_${key}_timestamp');

      if (jsonString == null || timestampString == null) return null;

      final DateTime cacheTime = DateTime.parse(timestampString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      if (cacheAge.inMinutes > _cacheExpiryMinutes) {
        await _clearCache('${_salesAnalyticsCacheKey}_$key');
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return SalesAnalytics.fromMap(data);
    } catch (e) {
      debugPrint('❌ خطأ في جلب تحليلات المبيعات من التخزين المؤقت: $e');
      return null;
    }
  }

  /// حفظ تقرير المدفوعات في التخزين المؤقت
  Future<void> cachePaymentReport(PaymentReport report, String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(report.toMap());

      await prefs.setString('${_paymentReportCacheKey}_$key', jsonString);
      await prefs.setString('${_paymentReportCacheKey}_${key}_timestamp',
          DateTime.now().toIso8601String());

      await _updateCacheSize();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تقرير المدفوعات في التخزين المؤقت: $e');
    }
  }

  /// جلب تقرير المدفوعات من التخزين المؤقت
  Future<PaymentReport?> getCachedPaymentReport(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString =
          prefs.getString('${_paymentReportCacheKey}_$key');
      final String? timestampString =
          prefs.getString('${_paymentReportCacheKey}_${key}_timestamp');

      if (jsonString == null || timestampString == null) return null;

      final DateTime cacheTime = DateTime.parse(timestampString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      if (cacheAge.inMinutes > _cacheExpiryMinutes) {
        await _clearCache('${_paymentReportCacheKey}_$key');
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return PaymentReport.fromMap(data);
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقرير المدفوعات من التخزين المؤقت: $e');
      return null;
    }
  }

  /// حفظ تقرير المخزون في التخزين المؤقت
  Future<void> cacheInventoryReport(InventoryReport report, String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(report.toMap());

      await prefs.setString('${_inventoryReportCacheKey}_$key', jsonString);
      await prefs.setString('${_inventoryReportCacheKey}_${key}_timestamp',
          DateTime.now().toIso8601String());

      await _updateCacheSize();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تقرير المخزون في التخزين المؤقت: $e');
    }
  }

  /// جلب تقرير المخزون من التخزين المؤقت
  Future<InventoryReport?> getCachedInventoryReport(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString =
          prefs.getString('${_inventoryReportCacheKey}_$key');
      final String? timestampString =
          prefs.getString('${_inventoryReportCacheKey}_${key}_timestamp');

      if (jsonString == null || timestampString == null) return null;

      final DateTime cacheTime = DateTime.parse(timestampString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      if (cacheAge.inMinutes > _cacheExpiryMinutes) {
        await _clearCache('${_inventoryReportCacheKey}_$key');
        return null;
      }

      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return InventoryReport.fromMap(data);
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقرير المخزون من التخزين المؤقت: $e');
      return null;
    }
  }

  /// حفظ تقارير EOD في التخزين المؤقت
  Future<void> cacheEODReports(List<EODReport> reports) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> reportsData =
          reports.map((EODReport report) => report.toMap()).toList();
      final String jsonString = jsonEncode(reportsData);

      await prefs.setString(_eodReportsCacheKey, jsonString);
      await prefs.setString(
          '${_eodReportsCacheKey}_timestamp', DateTime.now().toIso8601String());

      await _updateCacheSize();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تقارير EOD في التخزين المؤقت: $e');
    }
  }

  /// جلب تقارير EOD من التخزين المؤقت
  Future<List<EODReport>> getCachedEODReports() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_eodReportsCacheKey);
      final String? timestampString =
          prefs.getString('${_eodReportsCacheKey}_timestamp');

      if (jsonString == null || timestampString == null) return <EODReport>[];

      final DateTime cacheTime = DateTime.parse(timestampString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      if (cacheAge.inMinutes > _cacheExpiryMinutes) {
        await _clearCache(_eodReportsCacheKey);
        return <EODReport>[];
      }

      final List<dynamic> data = jsonDecode(jsonString) as List<dynamic>;
      return data
          .map((item) => EODReport.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقارير EOD من التخزين المؤقت: $e');
      return <EODReport>[];
    }
  }

  /// مسح عنصر محدد من التخزين المؤقت
  Future<void> _clearCache(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_timestamp');
    } catch (e) {
      debugPrint('❌ خطأ في مسح التخزين المؤقت: $e');
    }
  }

  /// مسح جميع التخزين المؤقت
  Future<void> clearAllCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // مسح جميع مفاتيح التخزين المؤقت
      final List<String> keys = <String>[
        _dashboardCacheKey,
        _salesAnalyticsCacheKey,
        _paymentReportCacheKey,
        _inventoryReportCacheKey,
        _eodReportsCacheKey,
        _cacheTimestampKey,
        _cacheSizeKey,
      ];

      for (final String key in keys) {
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }

      // مسح جميع المفاتيح التي تبدأ بـ cache
      final Set<String> allKeys = prefs.getKeys();
      for (final String key in allKeys) {
        if (key.startsWith('cache_') || key.contains('_cache')) {
          await prefs.remove(key);
        }
      }

      debugPrint('✅ تم مسح جميع التخزين المؤقت');
    } catch (e) {
      debugPrint('❌ خطأ في مسح جميع التخزين المؤقت: $e');
    }
  }

  /// تحديث حجم التخزين المؤقت
  Future<void> _updateCacheSize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();

      int totalSize = 0;
      for (final String key in keys) {
        if (key.contains('cache')) {
          final String? value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length * 2; // تقدير تقريبي للبايت
          }
        }
      }

      await prefs.setInt(_cacheSizeKey, totalSize);

      // إذا تجاوز الحد الأقصى، مسح أقدم العناصر
      if (totalSize > _maxCacheSize) {
        await _cleanOldCache();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث حجم التخزين المؤقت: $e');
    }
  }

  /// تنظيف التخزين المؤقت القديم
  Future<void> _cleanOldCache() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();

      final List<MapEntry<String, DateTime>> cacheEntries = <MapEntry<String, DateTime>>[];

      for (final String key in keys) {
        if (key.endsWith('_timestamp')) {
          final String? timestampString = prefs.getString(key);
          if (timestampString != null) {
            final DateTime timestamp = DateTime.parse(timestampString);
            final String dataKey = key.replaceAll('_timestamp', '');
            cacheEntries.add(MapEntry(dataKey, timestamp));
          }
        }
      }

      // ترتيب حسب التاريخ (الأقدم أولاً)
      cacheEntries.sort((MapEntry<String, DateTime> a, MapEntry<String, DateTime> b) => a.value.compareTo(b.value));

      // مسح النصف الأول (الأقدم)
      final int itemsToRemove = cacheEntries.length ~/ 2;
      for (int i = 0; i < itemsToRemove; i++) {
        final String key = cacheEntries[i].key;
        await prefs.remove(key);
        await prefs.remove('${key}_timestamp');
      }

      debugPrint('✅ تم تنظيف التخزين المؤقت القديم');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف التخزين المؤقت القديم: $e');
    }
  }

  /// الحصول على حجم التخزين المؤقت
  Future<int> getCacheSize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_cacheSizeKey) ?? 0;
    } catch (e) {
      debugPrint('❌ خطأ في جلب حجم التخزين المؤقت: $e');
      return 0;
    }
  }

  /// الحصول على إحصائيات التخزين المؤقت
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> keys = prefs.getKeys();

      int totalSize = 0;
      int itemCount = 0;
      final List<String> expiredItems = <String>[];

      for (final String key in keys) {
        if (key.contains('cache') && !key.endsWith('_timestamp')) {
          itemCount++;
          final String? value = prefs.getString(key);
          if (value != null) {
            totalSize += value.length * 2;
          }

          // التحقق من انتهاء الصلاحية
          final String? timestampString = prefs.getString('${key}_timestamp');
          if (timestampString != null) {
            final DateTime cacheTime = DateTime.parse(timestampString);
            final Duration cacheAge = DateTime.now().difference(cacheTime);
            if (cacheAge.inMinutes > _cacheExpiryMinutes) {
              expiredItems.add(key);
            }
          }
        }
      }

      return <String, dynamic>{
        'totalSize': totalSize,
        'itemCount': itemCount,
        'expiredItems': expiredItems.length,
        'maxSize': _maxCacheSize,
        'expiryMinutes': _cacheExpiryMinutes,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات التخزين المؤقت: $e');
      return <String, dynamic>{
        'totalSize': 0,
        'itemCount': 0,
        'expiredItems': 0,
        'maxSize': _maxCacheSize,
        'expiryMinutes': _cacheExpiryMinutes,
      };
    }
  }

  /// التحقق من وجود عنصر في التخزين المؤقت
  Future<bool> hasCachedData(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? timestampString = prefs.getString('${key}_timestamp');

      if (timestampString == null) return false;

      final DateTime cacheTime = DateTime.parse(timestampString);
      final Duration cacheAge = DateTime.now().difference(cacheTime);

      return cacheAge.inMinutes <= _cacheExpiryMinutes;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من وجود البيانات في التخزين المؤقت: $e');
      return false;
    }
  }
}
