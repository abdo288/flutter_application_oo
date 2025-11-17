import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/eod_report.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/app_event_bus.dart';
import '../services/connectivity_service.dart';
import '../services/cross_tab_sync_service.dart';
import '../services/pos_service.dart';

/// خدمة إدارة تقارير نهاية اليوم
class EODService {
  static const String _eodReportsKey = 'eod_reports';
  static const String _eodCounterKey = 'eod_counter';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _eodReportsCollection =
      _firestore.collection('eod_reports');

  /// إنشاء تقرير نهاية اليوم
  static Future<EODReport> generateEODReport({
    required String employeeId,
    required String employeeName,
    DateTime? targetDate,
    List<CartItem>? currentCartItems, // إضافة معامل للسلة الحالية
  }) async {
    try {
      final DateTime reportDate = targetDate ?? DateTime.now();
      final DateTime startOfDay = DateTime(
        reportDate.year,
        reportDate.month,
        reportDate.day,
      );
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      debugPrint(
          '📊 بدء إنشاء تقرير نهاية اليوم لـ ${startOfDay.toIso8601String()}');

      // 1. حفظ السلة الحالية كبيع إذا تم تمريرها
      if (currentCartItems != null && currentCartItems.isNotEmpty) {
        await saveCurrentCartAsSaleFromState(
            currentCartItems, employeeId, employeeName);
      } else {
        // جلب السلة من SharedPreferences كبديل
        await _saveCurrentCartAsSale(employeeId, employeeName);
      }

      // 2. جمع بيانات المبيعات المحفوظة فقط
      final List<Sale> todaySales = await _getTodaySales(startOfDay, endOfDay);
      debugPrint('📈 تم جمع ${todaySales.length} مبيعات محفوظة');

      // 3. حساب الإحصائيات الأساسية
      final double totalSales = todaySales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalAmount);
      final double totalProfit = todaySales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalProfit);
      final int totalItemsSold =
          todaySales.fold(0, (int sum, Sale sale) => sum + sale.totalQuantity);
      final Set<String> uniqueProducts = todaySales
          .expand(
              (Sale sale) => sale.items.map((CartItem item) => item.productId))
          .toSet();

      // 4. حساب أفضل المنتجات مبيعاً
      final List<TopProduct> topProducts =
          await _calculateTopProducts(todaySales);
      debugPrint('🏆 تم حساب ${topProducts.length} منتج من الأفضل');

      // 5. فحص المخزون المنخفض
      final List<LowStockProduct> lowStockProducts =
          await _getLowStockProducts();
      debugPrint(
          '⚠️ تم العثور على ${lowStockProducts.length} منتج بمخزون منخفض');

      // 6. حساب إجمالي المنتجات في المخزون
      final int totalProductsInStock = await _getTotalProductsInStock();

      // 7. إنشاء رقم التقرير
      final String reportNumber = await _generateReportNumber(reportDate);

      // 8. تحديث لوحة التحكم
      await _updateDashboardAfterEOD(todaySales);

      // 9. إنشاء التقرير
      final EODReport report = EODReport(
        id: 'eod_${reportDate.millisecondsSinceEpoch}',
        reportNumber: reportNumber,
        date: reportDate,
        generatedAt: DateTime.now(),
        totalSales: totalSales,
        totalProfit: totalProfit,
        totalItemsSold: totalItemsSold,
        uniqueProducts: uniqueProducts.length,
        topProducts: topProducts,
        lowStockProducts: lowStockProducts,
        totalProductsInStock: totalProductsInStock,
        employeeId: employeeId,
        employeeName: employeeName,
      );

      debugPrint('✅ تم إنشاء تقرير نهاية اليوم: $reportNumber');

      // إطلاق أحداث تحديث التقارير
      await _triggerReportsUpdateEvents(report);

      return report;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء تقرير نهاية اليوم: $e');
      rethrow;
    }
  }

  /// حفظ تقرير نهاية اليوم محلياً
  static Future<void> saveEODReportLocally(EODReport report) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> existingReports =
          prefs.getStringList(_eodReportsKey) ?? <String>[];

      // إضافة التقرير الجديد
      existingReports.add(jsonEncode(report.toMap()));

      await prefs.setStringList(_eodReportsKey, existingReports);
      debugPrint('💾 تم حفظ تقرير نهاية اليوم محلياً: ${report.reportNumber}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ تقرير نهاية اليوم محلياً: $e');
      rethrow;
    }
  }

  /// مزامنة تقرير نهاية اليوم مع Firebase
  static Future<void> syncEODReport(EODReport report) async {
    try {
      if (!ConnectivityService.isOnline) {
        debugPrint('📡 غير متصل - سيتم المزامنة لاحقاً');
        return;
      }

      await _eodReportsCollection.doc(report.id).set(report.toMap());

      // تحديث حالة المزامنة محلياً
      final EODReport syncedReport = report.copyWith(
        isSynced: true,
        syncedAt: DateTime.now(),
      );

      await _updateLocalReport(syncedReport);
      debugPrint('☁️ تم مزامنة تقرير نهاية اليوم: ${report.reportNumber}');
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة تقرير نهاية اليوم: $e');
      rethrow;
    }
  }

  /// جلب تقارير نهاية اليوم المحفوظة محلياً
  static Future<List<EODReport>> getLocalEODReports() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> reportsJson =
          prefs.getStringList(_eodReportsKey) ?? <String>[];

      final List<EODReport> reports = reportsJson.map((String json) {
        final Map<String, dynamic> data =
            jsonDecode(json) as Map<String, dynamic>;
        return EODReport.fromMap(data);
      }).toList();

      debugPrint('📊 عدد التقارير المحلية الحقيقية: ${reports.length}');

      // إرجاع التقارير الحقيقية فقط (بدون تقارير تجريبية)
      return reports;
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقارير نهاية اليوم المحلية: $e');
      return <EODReport>[]; // إرجاع قائمة فارغة بدلاً من التقارير التجريبية
    }
  }

  /// جلب تقارير نهاية اليوم من Firebase
  static Future<List<EODReport>> getFirebaseEODReports({
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // ✅ التحقق من حالة المصادقة
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint('⚠️ المستخدم غير مصادق عليه - إرجاع قائمة فارغة');
        return <EODReport>[];
      }

      if (!ConnectivityService.isOnline) {
        return <EODReport>[];
      }

      Query query = _eodReportsCollection.orderBy('date', descending: true);

      if (startDate != null) {
        query = query.where('date',
            isGreaterThanOrEqualTo: startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.where('date', isLessThan: endDate.toIso8601String());
      }

      final QuerySnapshot snapshot = await query.limit(limit).get();

      final List<EODReport> reports =
          snapshot.docs.map((QueryDocumentSnapshot<Object?> doc) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return EODReport.fromMap(data);
      }).toList();

      debugPrint('📊 تم جلب ${reports.length} تقرير حقيقي من Firebase');
      return reports;
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقارير نهاية اليوم من Firebase: $e');
      return <EODReport>[];
    }
  }

  /// حفظ البيع مباشرة في قاعدة البيانات المحلية
  static Future<void> _saveSaleDirectly(Sale sale) async {
    try {
      // حفظ في SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> salesList =
          prefs.getStringList('sales_list') ?? <String>[];

      // إضافة البيع الجديد
      salesList.add(jsonEncode(sale.toMap()));

      // حفظ القائمة المحدثة
      await prefs.setStringList('sales_list', salesList);

      debugPrint('💾 تم حفظ البيع مباشرة: ${sale.id}');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ البيع مباشرة: $e');
      rethrow;
    }
  }

  /// حفظ السلة الحالية كبيع
  static Future<void> _saveCurrentCartAsSale(
      String employeeId, String employeeName) async {
    try {
      // جلب السلة الحالية من SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cartString = prefs.getString('cart_items');

      if (cartString == null || cartString.isEmpty) {
        debugPrint('🛒 السلة الحالية فارغة - لا يوجد شيء لحفظه');
        return;
      }

      final List<dynamic> cartJson = jsonDecode(cartString) as List<dynamic>;
      final List<CartItem> cartItems = cartJson
          .map((itemData) => CartItem.fromMap(itemData as Map<String, dynamic>))
          .toList();

      if (cartItems.isEmpty) {
        debugPrint('🛒 السلة الحالية فارغة - لا يوجد شيء لحفظه');
        return;
      }

      // إنشاء بيع من السلة
      final Sale cartSale = Sale(
        id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
        items: cartItems,
        totalAmount: cartItems.fold(
            0, (int sum, CartItem item) => sum + item.totalPrice),
        totalProfit: cartItems.fold(
            0, (int sum, CartItem item) => sum + item.totalProfit),
        saleDate: DateTime.now(),
        notes: 'بيع من إنهاء اليوم',
        isSynced: false,
      );

      // حفظ البيع مباشرة في قاعدة البيانات المحلية
      await _saveSaleDirectly(cartSale);
      debugPrint('💾 تم حفظ السلة الحالية كبيع: ${cartItems.length} عنصر');

      // مسح السلة بعد حفظها
      await prefs.remove('cart_items');
      await prefs.remove('cart_timestamp');
      debugPrint('🗑️ تم مسح السلة بعد حفظها كبيع');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة الحالية كبيع: $e');
      // لا نرمي الخطأ هنا لأن التقرير يجب أن يستمر
    }
  }

  /// حفظ السلة الحالية كبيع من Riverpod state
  static Future<void> saveCurrentCartAsSaleFromState(
      List<CartItem> cartItems, String employeeId, String employeeName) async {
    try {
      if (cartItems.isEmpty) {
        debugPrint('🛒 السلة الحالية فارغة - لا يوجد شيء لحفظه');
        return;
      }

      // إنشاء بيع من السلة
      final Sale cartSale = Sale(
        id: 'sale_${DateTime.now().millisecondsSinceEpoch}',
        items: cartItems,
        totalAmount: cartItems.fold(
            0, (int sum, CartItem item) => sum + item.totalPrice),
        totalProfit: cartItems.fold(
            0, (int sum, CartItem item) => sum + item.totalProfit),
        saleDate: DateTime.now(),
        notes: 'بيع من إنهاء اليوم',
        isSynced: false,
      );

      // حفظ البيع مباشرة في قاعدة البيانات المحلية
      await _saveSaleDirectly(cartSale);
      debugPrint(
          '💾 تم حفظ السلة الحالية كبيع من Riverpod state: ${cartItems.length} عنصر');
    } catch (e) {
      debugPrint('❌ خطأ في حفظ السلة الحالية كبيع من Riverpod state: $e');
      rethrow;
    }
  }

  /// تحديث لوحة التحكم بعد إنهاء اليوم
  static Future<void> _updateDashboardAfterEOD(List<Sale> allTodaySales) async {
    try {
      // حساب الإحصائيات الجديدة
      final double totalSales = allTodaySales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalAmount);
      final int totalItemsSold = allTodaySales.fold(
          0, (int sum, Sale sale) => sum + sale.totalQuantity);
      final Set<String> uniqueProducts = allTodaySales
          .expand(
              (Sale sale) => sale.items.map((CartItem item) => item.productId))
          .toSet();

      // حفظ الإحصائيات في SharedPreferences لتحديث لوحة التحكم
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('today_sales', totalSales);
      await prefs.setInt('today_items_sold', totalItemsSold);
      await prefs.setInt('today_unique_products', uniqueProducts.length);
      await prefs.setString(
          'last_eod_update', DateTime.now().toIso8601String());

      debugPrint(
          '📊 تم تحديث لوحة التحكم: $totalSales دج، $totalItemsSold عنصر، ${uniqueProducts.length} منتج فريد');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث لوحة التحكم: $e');
      // لا نرمي الخطأ هنا لأن التقرير يجب أن يستمر
    }
  }

  /// إطلاق أحداث تحديث التقارير
  static Future<void> _triggerReportsUpdateEvents(EODReport report) async {
    try {
      // إطلاق حدث تحديث التقارير عبر AppEventBus
      AppEventBus.fire(ReportsUpdateEvent(
        'eod',
        sourceTab: 'EODService',
        data: <String, dynamic>{
          'reportId': report.id,
          'reportNumber': report.reportNumber,
          'totalSales': report.totalSales,
          'totalProfit': report.totalProfit,
          'date': report.date.toIso8601String(),
        },
      ));

      // إشعار CrossTabSyncService
      CrossTabSyncService.notifyReportsUpdate(
        'eod',
        sourceTab: 'EODService',
        data: <String, dynamic>{
          'reportId': report.id,
          'reportNumber': report.reportNumber,
          'totalSales': report.totalSales,
        },
      );

      debugPrint(
          '📊 تم إطلاق أحداث تحديث التقارير لـ EOD: ${report.reportNumber}');
    } catch (e) {
      debugPrint('❌ خطأ في إطلاق أحداث تحديث التقارير: $e');
      // لا نرمي الخطأ هنا لأن التقرير يجب أن يستمر
    }
  }

  /// جلب بيانات المبيعات لليوم
  static Future<List<Sale>> _getTodaySales(
      DateTime startOfDay, DateTime endOfDay) async {
    try {
      debugPrint(
          '🔍 جلب بيانات المبيعات من ${startOfDay.toIso8601String()} إلى ${endOfDay.toIso8601String()}');

      // جلب البيانات المحلية من SharedPreferences مباشرة
      final List<Sale> localSales =
          await _getLocalSalesFromStorage(startOfDay, endOfDay);
      debugPrint('📊 عدد المبيعات المحلية: ${localSales.length}');

      // جلب البيانات من Firebase إذا كان متصل
      List<Sale> firebaseSales = <Sale>[];
      if (ConnectivityService.isOnline) {
        try {
          final PageResult<Sale> firebasePage = await POSService.getSalesPage(
            startDate: startOfDay,
            endDate: endOfDay,
            limit: 1000, // حد كبير لضمان جلب كل البيانات
          );
          firebaseSales = firebasePage.items;
          debugPrint('📊 عدد المبيعات من Firebase: ${firebaseSales.length}');
        } catch (e) {
          debugPrint('⚠️ خطأ في جلب بيانات Firebase: $e');
        }
      } else {
        debugPrint('📡 غير متصل - لا يمكن جلب بيانات Firebase');
      }

      // دمج البيانات وإزالة التكرار
      final Map<String, Sale> salesMap = <String, Sale>{};

      // إضافة البيانات المحلية أولاً
      for (final Sale sale in localSales) {
        if (sale.id != null) {
          salesMap[sale.id!] = sale;
        }
      }

      // إضافة بيانات Firebase (لها أولوية في حالة التكرار)
      for (final Sale sale in firebaseSales) {
        if (sale.id != null) {
          salesMap[sale.id!] = sale;
        }
      }

      final List<Sale> finalSales = salesMap.values.toList()
        ..sort((Sale a, Sale b) => b.saleDate.compareTo(a.saleDate));

      debugPrint('✅ إجمالي المبيعات النهائية: ${finalSales.length}');
      for (final Sale sale in finalSales) {
        debugPrint(
            '   - ${sale.id}: ${sale.totalAmount} دج (${sale.items.length} عنصر)');
      }

      return finalSales;
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المبيعات: $e');
      return <Sale>[];
    }
  }

  /// جلب المبيعات المحلية من SharedPreferences مباشرة
  static Future<List<Sale>> _getLocalSalesFromStorage(
      DateTime startOfDay, DateTime endOfDay) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> salesList =
          prefs.getStringList('sales_list') ?? <String>[];

      final List<Sale> sales = <Sale>[];
      for (final String saleJson in salesList) {
        try {
          final Map<String, dynamic> saleData =
              jsonDecode(saleJson) as Map<String, dynamic>;
          final Sale sale = Sale.fromMap(saleData);

          // فلترة المبيعات حسب التاريخ
          if (sale.saleDate.isAfter(startOfDay) &&
              sale.saleDate.isBefore(endOfDay)) {
            sales.add(sale);
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في تحليل بيع محلي: $e');
        }
      }

      debugPrint('📊 تم جلب ${sales.length} مبيع محلي من SharedPreferences');
      return sales;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات المحلية: $e');
      return <Sale>[];
    }
  }

  /// حساب أفضل المنتجات مبيعاً
  static Future<List<TopProduct>> _calculateTopProducts(
      List<Sale> sales) async {
    try {
      final Map<String, Map<String, dynamic>> productStats =
          <String, Map<String, dynamic>>{};

      for (final Sale sale in sales) {
        for (final CartItem item in sale.items) {
          if (productStats.containsKey(item.productId)) {
            final Map<String, dynamic> stats = productStats[item.productId]!;
            stats['quantity'] = (stats['quantity'] as int) + item.quantity;
            stats['totalValue'] =
                (stats['totalValue'] as double) + item.totalPrice;
            stats['profit'] = (stats['profit'] as double) + item.totalProfit;
          } else {
            productStats[item.productId] = <String, dynamic>{
              'name': item.name,
              'quantity': item.quantity,
              'totalValue': item.totalPrice.toDouble(),
              'profit': item.totalProfit.toDouble(),
            };
          }
        }
      }

      final List<TopProduct> topProducts = productStats.entries
          .map((MapEntry<String, Map<String, dynamic>> entry) {
        final Map<String, dynamic> stats = entry.value;
        return TopProduct(
          productId: entry.key,
          name: stats['name'] as String,
          quantity: stats['quantity'] as int,
          totalValue: stats['totalValue'] as double,
          profit: stats['profit'] as double,
        );
      }).toList();

      // ترتيب حسب الكمية المباعة
      topProducts.sort(
          (TopProduct a, TopProduct b) => b.quantity.compareTo(a.quantity));

      return topProducts.take(20).toList(); // أفضل 20 منتج
    } catch (e) {
      debugPrint('❌ خطأ في حساب أفضل المنتجات: $e');
      return <TopProduct>[];
    }
  }

  /// جلب المنتجات ذات المخزون المنخفض
  static Future<List<LowStockProduct>> _getLowStockProducts() async {
    try {
      // TODO: إضافة دالة getAllProducts في POSService
      final List<Product> products = <Product>[];
      final List<LowStockProduct> lowStockProducts = <LowStockProduct>[];

      for (final Product product in products) {
        if ((product.minimumStock ?? 0) <= 10) {
          lowStockProducts.add(LowStockProduct(
            productId: product.id ?? '',
            name: product.name,
            currentStock: 0, // Product doesn't have quantity field
            minStock: product.minimumStock ?? 10,
          ));
        }
      }

      return lowStockProducts;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المنتجات ذات المخزون المنخفض: $e');
      return <LowStockProduct>[];
    }
  }

  /// حساب إجمالي المنتجات في المخزون
  static Future<int> _getTotalProductsInStock() async {
    try {
      // TODO: إضافة دالة getAllProducts في POSService
      final List<Product> products = <Product>[];
      return products.where((Product product) => product.isActive).length;
    } catch (e) {
      debugPrint('❌ خطأ في حساب إجمالي المنتجات: $e');
      return 0;
    }
  }

  /// إنشاء رقم التقرير
  static Future<String> _generateReportNumber(DateTime date) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int counter = (prefs.getInt(_eodCounterKey) ?? 0) + 1;
      await prefs.setInt(_eodCounterKey, counter);

      final String dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return 'EOD-$dateStr-${counter.toString().padLeft(3, '0')}';
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء رقم التقرير: $e');
      return 'EOD-${date.millisecondsSinceEpoch}';
    }
  }

  /// تحديث تقرير محلي
  static Future<void> _updateLocalReport(EODReport updatedReport) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> reportsJson =
          prefs.getStringList(_eodReportsKey) ?? <String>[];

      // البحث عن التقرير وتحديثه
      for (int i = 0; i < reportsJson.length; i++) {
        final Map<String, dynamic> data =
            jsonDecode(reportsJson[i]) as Map<String, dynamic>;
        if (data['id'] == updatedReport.id) {
          reportsJson[i] = jsonEncode(updatedReport.toMap());
          break;
        }
      }

      await prefs.setStringList(_eodReportsKey, reportsJson);
    } catch (e) {
      debugPrint('❌ خطأ في تحديث التقرير المحلي: $e');
    }
  }

  /// حذف تقرير نهاية اليوم
  static Future<void> deleteEODReport(String reportId) async {
    try {
      // حذف من Firebase
      if (ConnectivityService.isOnline) {
        await _eodReportsCollection.doc(reportId).delete();
      }

      // حذف من التخزين المحلي
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> reportsJson =
          prefs.getStringList(_eodReportsKey) ?? <String>[];

      reportsJson.removeWhere((String json) {
        final Map<String, dynamic> data =
            jsonDecode(json) as Map<String, dynamic>;
        return data['id'] == reportId;
      });

      await prefs.setStringList(_eodReportsKey, reportsJson);
      debugPrint('🗑️ تم حذف تقرير نهاية اليوم: $reportId');
    } catch (e) {
      debugPrint('❌ خطأ في حذف تقرير نهاية اليوم: $e');
      rethrow;
    }
  }

  /// إنشاء نسخة احتياطية من تقرير نهاية اليوم
  static Future<String> createBackup(EODReport report) async {
    try {
      final String backupData = jsonEncode(<String, Object>{
        'report': report.toMap(),
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0',
      });

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String backupKey = 'eod_backup_${report.id}';
      await prefs.setString(backupKey, backupData);

      debugPrint('💾 تم إنشاء نسخة احتياطية: $backupKey');
      return backupKey;
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء النسخة الاحتياطية: $e');
      rethrow;
    }
  }

  /// مسح بيانات المبيعات القديمة من قاعدة البيانات المحلية
  static Future<void> clearOldSalesData() async {
    try {
      debugPrint('🗑️ بدء مسح بيانات المبيعات القديمة...');

      // مسح بيانات المبيعات من SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('sales_data');
      await prefs.remove('sales_timestamp');
      await prefs.remove('last_sync_time');
      await prefs.remove('local_sales');
      await prefs.remove('sales_cache');

      debugPrint('✅ تم مسح بيانات المبيعات من SharedPreferences');
    } catch (e) {
      debugPrint('❌ خطأ في مسح بيانات المبيعات: $e');
    }
  }

  /// مسح بيانات المبيعات اليومية فقط (بدون مسح جميع البيانات)
  static Future<void> clearTodaySalesData() async {
    try {
      debugPrint('🗑️ بدء مسح بيانات المبيعات اليومية...');

      final DateTime today = DateTime.now();
      final DateTime startOfDay = DateTime(today.year, today.month, today.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      // جلب جميع المبيعات المحلية
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> salesList =
          prefs.getStringList('sales_list') ?? <String>[];

      // فلترة المبيعات (إزالة مبيعات اليوم)
      final List<String> filteredSales = <String>[];
      for (final String saleJson in salesList) {
        try {
          final Map<String, dynamic> saleData =
              jsonDecode(saleJson) as Map<String, dynamic>;
          final Sale sale = Sale.fromMap(saleData);

          // الاحتفاظ بالمبيعات التي ليست من اليوم
          if (!(sale.saleDate.isAfter(startOfDay) &&
              sale.saleDate.isBefore(endOfDay))) {
            filteredSales.add(saleJson);
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في تحليل بيع: $e');
          // الاحتفاظ بالبيانات في حالة الخطأ
          filteredSales.add(saleJson);
        }
      }

      // حفظ المبيعات المفلترة
      await prefs.setStringList('sales_list', filteredSales);

      debugPrint(
          '✅ تم مسح ${salesList.length - filteredSales.length} مبيع من اليوم');
      debugPrint(
          '✅ تم الاحتفاظ بـ ${filteredSales.length} مبيع من الأيام السابقة');
    } catch (e) {
      debugPrint('❌ خطأ في مسح بيانات المبيعات اليومية: $e');
    }
  }

  /// جلب جميع تقارير نهاية اليوم الحقيقية
  static Future<List<EODReport>> getAllRealEODReports() async {
    try {
      debugPrint('🔍 جلب جميع التقارير الحقيقية...');

      // جلب التقارير المحلية الحقيقية
      final List<EODReport> localReports = await getLocalEODReports();
      debugPrint('📊 عدد التقارير المحلية الحقيقية: ${localReports.length}');

      // جلب التقارير من Firebase إذا كان متصل
      List<EODReport> firebaseReports = <EODReport>[];
      if (ConnectivityService.isOnline) {
        firebaseReports = await getFirebaseEODReports(limit: 100);
        debugPrint('📊 عدد التقارير من Firebase: ${firebaseReports.length}');
      }

      // دمج التقارير وإزالة التكرار
      final Map<String, EODReport> reportsMap = <String, EODReport>{};

      // إضافة التقارير المحلية
      for (final EODReport report in localReports) {
        reportsMap[report.id] = report;
      }

      // إضافة التقارير من Firebase (لها أولوية)
      for (final EODReport report in firebaseReports) {
        reportsMap[report.id] = report;
      }

      final List<EODReport> allReports = reportsMap.values.toList();
      allReports.sort((EODReport a, EODReport b) => b.date.compareTo(a.date));

      debugPrint('✅ إجمالي التقارير الحقيقية: ${allReports.length}');
      return allReports;
    } catch (e) {
      debugPrint('❌ خطأ في جلب التقارير الحقيقية: $e');
      return <EODReport>[];
    }
  }

  /// البحث في تقارير نهاية اليوم
  static Future<List<EODReport>> searchEODReports({
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    double? minSales,
    double? maxSales,
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 البحث في تقارير EOD مع المعايير:');
      debugPrint('   - الاستعلام: $query');
      debugPrint('   - من: $startDate');
      debugPrint('   - إلى: $endDate');
      debugPrint('   - الموظف: $employeeId');

      List<EODReport> reports = await getLocalEODReports();
      debugPrint('📊 عدد التقارير المحلية: ${reports.length}');

      // إضافة التقارير من Firebase إذا كان متصل
      if (ConnectivityService.isOnline) {
        debugPrint('🌐 جلب التقارير من Firebase...');
        final List<EODReport> firebaseReports = await getFirebaseEODReports(
          limit: limit,
          startDate: startDate,
          endDate: endDate,
        );
        debugPrint('📊 عدد التقارير من Firebase: ${firebaseReports.length}');

        // دمج التقارير وإزالة التكرار
        final Map<String, EODReport> reportsMap = <String, EODReport>{};
        for (final EODReport report in reports) {
          reportsMap[report.id] = report;
        }
        for (final EODReport report in firebaseReports) {
          reportsMap[report.id] = report;
        }
        reports = reportsMap.values.toList();
        debugPrint('📊 إجمالي التقارير بعد الدمج: ${reports.length}');
      } else {
        debugPrint('📱 غير متصل - استخدام التقارير المحلية فقط');
      }

      // تطبيق الفلاتر
      if (query != null && query.isNotEmpty) {
        final String searchQuery = query.toLowerCase();
        reports = reports
            .where((EODReport report) =>
                report.reportNumber.toLowerCase().contains(searchQuery) ||
                report.employeeName.toLowerCase().contains(searchQuery))
            .toList();
      }

      if (startDate != null) {
        reports = reports
            .where((EODReport report) =>
                report.date.isAfter(startDate) ||
                report.date.isAtSameMomentAs(startDate))
            .toList();
      }

      if (endDate != null) {
        reports = reports
            .where((EODReport report) =>
                report.date.isBefore(endDate) ||
                report.date.isAtSameMomentAs(endDate))
            .toList();
      }

      if (employeeId != null && employeeId.isNotEmpty) {
        reports = reports
            .where((EODReport report) => report.employeeId == employeeId)
            .toList();
      }

      if (minSales != null) {
        reports = reports
            .where((EODReport report) => report.totalSales >= minSales)
            .toList();
      }

      if (maxSales != null) {
        reports = reports
            .where((EODReport report) => report.totalSales <= maxSales)
            .toList();
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      reports.sort((EODReport a, EODReport b) => b.date.compareTo(a.date));

      final List<EODReport> finalReports = reports.take(limit).toList();
      debugPrint('✅ تم إرجاع ${finalReports.length} تقرير EOD');

      return finalReports;
    } catch (e) {
      debugPrint('❌ خطأ في البحث في تقارير نهاية اليوم: $e');
      return <EODReport>[];
    }
  }

  /// جلب تقرير نهاية اليوم بواسطة ID
  static Future<EODReport?> getEODReportById(String reportId) async {
    try {
      // البحث في التقارير المحلية أولاً
      final List<EODReport> localReports = await getLocalEODReports();
      final EODReport? localReport = localReports
          .where((EODReport report) => report.id == reportId)
          .firstOrNull;

      if (localReport != null) {
        return localReport;
      }

      // البحث في Firebase إذا كان متصل
      if (ConnectivityService.isOnline) {
        try {
          final DocumentSnapshot doc =
              await _eodReportsCollection.doc(reportId).get();
          if (doc.exists) {
            final Map<String, dynamic> data =
                doc.data() as Map<String, dynamic>;
            return EODReport.fromMap(data);
          }
        } catch (e) {
          debugPrint('⚠️ خطأ في جلب التقرير من Firebase: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ خطأ في جلب تقرير نهاية اليوم: $e');
      return null;
    }
  }

  /// جلب إحصائيات تقارير نهاية اليوم
  static Future<Map<String, dynamic>> getEODReportsStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final List<EODReport> reports = await searchEODReports(
        startDate: startDate,
        endDate: endDate,
        limit: 1000, // حد كبير للحصول على إحصائيات دقيقة
      );

      if (reports.isEmpty) {
        return <String, dynamic>{
          'totalReports': 0,
          'totalSales': 0.0,
          'totalProfit': 0.0,
          'averageSales': 0.0,
          'averageProfit': 0.0,
          'bestDay': null,
          'worstDay': null,
        };
      }

      final double totalSales = reports.fold(
          0.0, (double sum, EODReport report) => sum + report.totalSales);
      final double totalProfit = reports.fold(
          0.0, (double sum, EODReport report) => sum + report.totalProfit);
      final double averageSales = totalSales / reports.length;
      final double averageProfit = totalProfit / reports.length;

      // أفضل يوم (أعلى مبيعات)
      final EODReport bestDay = reports.reduce(
          (EODReport a, EODReport b) => a.totalSales > b.totalSales ? a : b);

      // أسوأ يوم (أقل مبيعات)
      final EODReport worstDay = reports.reduce(
          (EODReport a, EODReport b) => a.totalSales < b.totalSales ? a : b);

      return <String, dynamic>{
        'totalReports': reports.length,
        'totalSales': totalSales,
        'totalProfit': totalProfit,
        'averageSales': averageSales,
        'averageProfit': averageProfit,
        'bestDay': <String, Object>{
          'date': bestDay.date,
          'sales': bestDay.totalSales,
          'reportNumber': bestDay.reportNumber,
        },
        'worstDay': <String, Object>{
          'date': worstDay.date,
          'sales': worstDay.totalSales,
          'reportNumber': worstDay.reportNumber,
        },
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات تقارير نهاية اليوم: $e');
      return <String, dynamic>{
        'totalReports': 0,
        'totalSales': 0.0,
        'totalProfit': 0.0,
        'averageSales': 0.0,
        'averageProfit': 0.0,
        'bestDay': null,
        'worstDay': null,
      };
    }
  }

  /// تصدير تقارير نهاية اليوم
  static Future<String> exportEODReports({
    required List<EODReport> reports,
    required String format, // 'pdf', 'excel', 'csv'
    String? fileName,
  }) async {
    try {
      final String exportFileName =
          fileName ?? 'eod_reports_${DateTime.now().millisecondsSinceEpoch}';

      switch (format.toLowerCase()) {
        case 'pdf':
          return await _exportToPDF(reports, exportFileName);
        case 'excel':
          return await _exportToExcel(reports, exportFileName);
        case 'csv':
          return await _exportToCSV(reports, exportFileName);
        default:
          throw Exception('تنسيق التصدير غير مدعوم: $format');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تصدير تقارير نهاية اليوم: $e');
      rethrow;
    }
  }

  /// تصدير إلى PDF
  static Future<String> _exportToPDF(
      List<EODReport> reports, String fileName) async {
    // TODO: تنفيذ تصدير PDF
    throw UnimplementedError('تصدير PDF غير مطبق بعد');
  }

  /// تصدير إلى Excel
  static Future<String> _exportToExcel(
      List<EODReport> reports, String fileName) async {
    // TODO: تنفيذ تصدير Excel
    throw UnimplementedError('تصدير Excel غير مطبق بعد');
  }

  /// تصدير إلى CSV
  static Future<String> _exportToCSV(
      List<EODReport> reports, String fileName) async {
    try {
      final StringBuffer csv = StringBuffer();

      // رؤوس الأعمدة
      csv.writeln(
          'رقم التقرير,التاريخ,الموظف,إجمالي المبيعات,إجمالي الربح,الكمية المباعة,المنتجات الفريدة');

      // البيانات
      for (final EODReport report in reports) {
        csv.writeln(
            '${report.reportNumber},${report.date.toIso8601String()},${report.employeeName},${report.totalSales},${report.totalProfit},${report.totalItemsSold},${report.uniqueProducts}');
      }

      // حفظ الملف
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/$fileName.csv';
      final File file = File(filePath);
      await file.writeAsString(csv.toString());

      debugPrint('📄 تم تصدير التقارير إلى CSV: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ خطأ في تصدير CSV: $e');
      rethrow;
    }
  }

  /// مزامنة جميع التقارير غير المزامنة
  static Future<void> syncAllPendingReports() async {
    try {
      if (!ConnectivityService.isOnline) {
        debugPrint('📡 غير متصل - لا يمكن المزامنة');
        return;
      }

      final List<EODReport> localReports = await getLocalEODReports();
      final List<EODReport> unsyncedReports =
          localReports.where((EODReport report) => !report.isSynced).toList();

      debugPrint('🔄 بدء مزامنة ${unsyncedReports.length} تقرير');

      for (final EODReport report in unsyncedReports) {
        try {
          await syncEODReport(report);
          await Future<void>.delayed(const Duration(
              milliseconds: 500)); // تأخير بسيط لتجنب الضغط على الخادم
        } catch (e) {
          debugPrint('⚠️ فشل في مزامنة التقرير ${report.reportNumber}: $e');
        }
      }

      debugPrint('✅ تمت مزامنة التقارير');
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة التقارير: $e');
    }
  }
}
