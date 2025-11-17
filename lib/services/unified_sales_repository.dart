import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../models/cart_item.dart';
import '../models/sale.dart';
import '../utils/platform_thread_safety.dart';

/// مستودع المبيعات الموحد - يجمع البيانات من المصادر المحلية والبعيدة
class UnifiedSalesRepository {
  static const String _salesCollection = 'sales';
  final AppDatabase _localDb = AppDatabase.instance;

  /// الحصول على جميع المبيعات (محلية + بعيدة) مع إزالة التكرار
  Future<List<Sale>> getAllSales({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) async {
    try {
      // جلب البيانات المحلية
      final List<Sale> localSales = await _getLocalSales(startDate, endDate);

      // جلب البيانات من Firestore
      final List<Sale> firestoreSales =
          await _getFirestoreSales(startDate, endDate, limit);

      // دمج وإزالة التكرار
      final List<Sale> combinedSales =
          _mergeAndDeduplicateSales(localSales, firestoreSales);

      // ترتيب حسب التاريخ وتطبيق الحد الأقصى
      combinedSales.sort((Sale a, Sale b) => b.saleDate.compareTo(a.saleDate));
      return combinedSales.take(limit).toList();
    } catch (e) {
      debugPrint('❌ خطأ في UnifiedSalesRepository.getAllSales: $e');
      return <Sale>[];
    }
  }

  /// مراقبة المبيعات في الوقت الفعلي
  Stream<List<Sale>> watchSales({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) {
    // ✅ التحقق من حالة المصادقة
    return FirebaseAuth.instance.authStateChanges().asyncExpand((User? user) {
      if (user == null) {
        debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع قائمة فارغة');
        return Stream.value(<Sale>[]);
      }

      debugPrint('✅ المستخدم مصادق عليه - بدء الاستماع للمبيعات');

      return FirebaseFirestore.instance
          .collection(_salesCollection)
          .where('saleDate',
              isGreaterThanOrEqualTo: startDate ??
                  DateTime.now().subtract(const Duration(days: 30)))
          .where('saleDate', isLessThanOrEqualTo: endDate ?? DateTime.now())
          .orderBy('saleDate', descending: true)
          .limit(limit)
          .snapshots()
          .asyncMap((QuerySnapshot<Map<String, dynamic>> snapshot) async {
        // ✅ استخدام PlatformThreadSafety لضمان التنفيذ على platform thread
        return await PlatformThreadSafety.executeStreamHandler(
          () async {
            // تحويل بيانات Firestore
            final List<Sale> firestoreSales =
                snapshot.docs.map(Sale.fromFirestore).toList();

            // دمج مع البيانات المحلية
            final List<Sale> localSales =
                await _getLocalSales(startDate, endDate);
            return _mergeAndDeduplicateSales(localSales, firestoreSales);
          },
          operationName: 'salesStream_asyncMap',
        );
      }).handleError((Object error) {
        // تجاهل أخطاء الصلاحيات بعد تسجيل الخروج
        if (error.toString().contains('permission-denied') ||
            error.toString().contains('Missing or insufficient permissions')) {
          debugPrint('⚠️ تم تجاهل خطأ صلاحيات في watchSales: $error');
          return <Sale>[];
        }
        debugPrint('❌ خطأ في watchSales: $error');
        return <Sale>[];
      });
    });
  }

  /// جلب البيانات المحلية
  Future<List<Sale>> _getLocalSales(
      DateTime? startDate, DateTime? endDate) async {
    try {
      final List<SalesTableData> salesData = await _localDb.getAllSales();
      final List<Sale> localSales = salesData
          .map((SalesTableData data) {
            try {
              return Sale(
                id: data.id,
                items: <CartItem>[], // سيتم تحميلها لاحقاً إذا لزم الأمر
                totalAmount: data.totalAmount,
                totalProfit: data.totalProfit,
                saleDate: DateTime.parse(data.saleDate),
                customerName: data.customerName,
                notes: data.notes,
                paymentMethod: data.paymentMethod,
                discount: data.discount,
                isSynced: data.isSynced,
              );
            } catch (e) {
              debugPrint('❌ خطأ في تحويل البيانات المحلية: $e');
              return null;
            }
          })
          .where((Sale? sale) => sale != null)
          .cast<Sale>()
          .toList();

      // فلترة حسب التاريخ إذا تم تحديده
      if (startDate != null || endDate != null) {
        return localSales.where((Sale sale) {
          if (startDate != null && sale.saleDate.isBefore(startDate)) {
            return false;
          }
          if (endDate != null && sale.saleDate.isAfter(endDate)) return false;
          return true;
        }).toList();
      }

      return localSales;
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات المحلية: $e');
      return <Sale>[];
    }
  }

  /// جلب البيانات من Firestore
  Future<List<Sale>> _getFirestoreSales(
      DateTime? startDate, DateTime? endDate, int limit) async {
    try {
      // ✅ التحقق من حالة المصادقة
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع قائمة فارغة');
        return <Sale>[];
      }

      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection(_salesCollection)
          .orderBy('saleDate', descending: true)
          .limit(limit);

      if (startDate != null && endDate != null) {
        query = query
            .where('saleDate', isGreaterThanOrEqualTo: startDate)
            .where('saleDate', isLessThanOrEqualTo: endDate);
      }

      // ✅ استخدام PlatformThreadSafety لضمان التنفيذ على platform thread
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await PlatformThreadSafety.executeFirestoreOperation(
        () => query.get(),
        operationName: 'getSalesFromFirestore',
      );
      return snapshot.docs.map(Sale.fromFirestore).toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب البيانات من Firestore: $e');
      return <Sale>[];
    }
  }

  /// دمج وإزالة التكرار من المبيعات
  List<Sale> _mergeAndDeduplicateSales(
      List<Sale> localSales, List<Sale> firestoreSales) {
    final Map<String, Sale> salesMap = <String, Sale>{};

    // إضافة بيانات Firestore أولاً (لها أولوية)
    for (final Sale sale in firestoreSales) {
      if (sale.id != null) {
        salesMap[sale.id!] = sale;
      }
    }

    // إضافة البيانات المحلية إذا لم تكن موجودة في Firestore
    for (final Sale sale in localSales) {
      if (sale.id != null && !salesMap.containsKey(sale.id!)) {
        salesMap[sale.id!] = sale;
      }
    }

    return salesMap.values.toList();
  }

  /// حساب إحصائيات المبيعات في background thread
  Future<Map<String, dynamic>> calculateSalesAnalytics({
    required List<Sale> sales,
  }) async {
    // استخدام isolate للحسابات الثقيلة
    return await compute(_calculateAnalyticsInIsolate, sales);
  }

  /// حساب الإحصائيات في isolate منفصل
  static Map<String, dynamic> _calculateAnalyticsInIsolate(List<Sale> sales) {
    if (sales.isEmpty) {
      return <String, dynamic>{
        'totalRevenue': 0.0,
        'totalProfit': 0.0,
        'totalTransactions': 0,
        'averageTransactionValue': 0.0,
        'averageProfit': 0.0,
        'hourlySales': <int, double>{},
        'dailySales': <DateTime, double>{},
      };
    }

    // حساب الإجماليات
    final double totalRevenue = sales.fold<double>(
        0, (double sum, Sale sale) => sum + sale.totalAmount);
    final double totalProfit = sales.fold<double>(
        0, (double sum, Sale sale) => sum + sale.totalProfit);
    final int totalTransactions = sales.length;
    final double averageTransactionValue = totalRevenue / totalTransactions;
    final double averageProfit = totalProfit / totalTransactions;

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

  /// تحليل الاتجاهات في background thread
  Future<Map<String, dynamic>> calculateTrendAnalysis({
    required List<Sale> sales,
  }) async =>
      await compute(_calculateTrendInIsolate, sales);

  /// حساب الاتجاهات في isolate منفصل
  static Map<String, dynamic> _calculateTrendInIsolate(List<Sale> sales) {
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
    final double firstHalfRevenue = firstHalf.fold<double>(
            0, (double sum, Sale sale) => sum + sale.totalAmount) /
        firstHalf.length;
    final double secondHalfRevenue = secondHalf.fold<double>(
            0, (double sum, Sale sale) => sum + sale.totalAmount) /
        secondHalf.length;

    final double firstHalfProfit = firstHalf.fold<double>(
            0, (double sum, Sale sale) => sum + sale.totalProfit) /
        firstHalf.length;
    final double secondHalfProfit = secondHalf.fold<double>(
            0, (double sum, Sale sale) => sum + sale.totalProfit) /
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
}

// Provider للمستودع الموحد - تم نقله إلى realtime_analytics_riverpod_providers.dart
