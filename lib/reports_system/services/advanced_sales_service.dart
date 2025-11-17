import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:profit_calculator/models/cart_item.dart';

import '../../models/page_result.dart';
import '../../models/sale.dart';
import '../../services/pos_service.dart';
import '../models/common/price_range.dart';
import '../models/enums/payment_enums.dart';
import '../models/report_filter.dart';
import '../models/sales_analytics.dart';
import '../validators/model_validators.dart';

/// خدمة تقارير المبيعات المتقدمة
class AdvancedSalesService {
  factory AdvancedSalesService() => _instance;
  AdvancedSalesService._internal();
  static final AdvancedSalesService _instance =
      AdvancedSalesService._internal();

  // final POSService _posService = POSService();

  /// جلب المبيعات مع الفلاتر المتقدمة
  Future<PageResult<Sale>> getSalesWithFilters(ReportFilter filter) async {
    try {
      // التحقق من صحة الفلتر
      final ValidationResult validation = ReportFilterValidator.validate(filter);
      if (!validation.isValid) {
        debugPrint('❌ خطأ في فلتر التقارير: ${validation.errorMessage}');
        return PageResult<Sale>(
          items: <Sale>[],
          lastDocument: null,
          hasMore: false,
        );
      }

      DateTime? startDate = filter.dateRange?.startDate;
      DateTime? endDate = filter.dateRange?.endDate;

      // إذا لم يتم تحديد التاريخ، استخدم آخر 30 يوم
      if (startDate == null || endDate == null) {
        endDate = DateTime.now();
        startDate = endDate.subtract(const Duration(days: 30));
      }

      // جلب البيانات من الخدمة الأساسية
      final PageResult<Sale> pageResult = await POSService.getCombinedSalesPage(
        startDate: startDate,
        endDate: endDate,
      );

      // تطبيق الفلاتر الإضافية
      List<Sale> filteredSales = pageResult.items;

      // فلتر طريقة الدفع
      if (filter.paymentMethods != null && filter.paymentMethods!.isNotEmpty) {
        filteredSales = filteredSales
            .where((Sale sale) =>
                filter.paymentMethods!.contains(sale.paymentMethod))
            .toList();
      }

      // فلتر الموظف
      if (filter.employees != null && filter.employees!.isNotEmpty) {
        filteredSales = filteredSales
            .where((Sale sale) =>
                filter.employees!.contains(sale.customerName ?? ''))
            .toList();
      }

      // فلتر نطاق السعر
      if (filter.priceRange != null) {
        filteredSales = filteredSales
            .where((Sale sale) =>
                filter.priceRange!.contains(sale.totalAmount.toDouble()))
            .toList();
      }

      // فلتر البحث
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final String query = filter.searchQuery!.toLowerCase();
        filteredSales = filteredSales
            .where((Sale sale) =>
                (sale.id?.toLowerCase().contains(query) ?? false) ||
                (sale.customerName?.toLowerCase().contains(query) ?? false) ||
                (sale.customerName?.toLowerCase().contains(query) ?? false))
            .toList();
      }

      // ترتيب النتائج
      if (filter.sortBy != null) {
        filteredSales.sort((Sale a, Sale b) {
          int comparison = 0;
          switch (filter.sortBy!) {
            case SortField.date:
              comparison = a.saleDate.compareTo(b.saleDate);
              break;
            case SortField.amount:
              comparison = a.totalAmount.compareTo(b.totalAmount);
              break;
            case SortField.customer:
              comparison =
                  (a.customerName ?? '').compareTo(b.customerName ?? '');
              break;
            case SortField.employee:
              comparison =
                  (a.customerName ?? '').compareTo(b.customerName ?? '');
              break;
            case SortField.status:
              comparison = a.paymentMethod.compareTo(b.paymentMethod);
              break;
            default:
              comparison = a.saleDate.compareTo(b.saleDate);
          }

          return filter.sortOrder == SortOrder.ascending
              ? comparison
              : -comparison;
        });
      }

      // تطبيق الحد الأقصى للنتائج
      if (filter.limit != null) {
        filteredSales = filteredSales.take(filter.limit!).toList();
      }

      return PageResult<Sale>(
        items: filteredSales,
        hasMore: false,
        lastDocument: null,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات مع الفلاتر: $e');
      rethrow;
    }
  }

  /// جلب المبيعات حسب الفترة الزمنية
  Future<List<Sale>> getSalesByTimeRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final PageResult<Sale> pageResult = await POSService.getCombinedSalesPage(
        startDate: startDate,
        endDate: endDate,
      );
      return pageResult.items;
    } catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات حسب الفترة: $e');
      return <Sale>[];
    }
  }

  /// جلب المبيعات حسب طريقة الدفع
  Future<List<Sale>> getSalesByPaymentMethod(PaymentMethod method) async {
    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 30));

      final PageResult<Sale> pageResult = await POSService.getCombinedSalesPage(
        startDate: startDate,
        endDate: endDate,
      );

      return pageResult.items
          .where((Sale sale) => sale.paymentMethod == method)
          .toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات حسب طريقة الدفع: $e');
      return <Sale>[];
    }
  }

  /// جلب المبيعات حسب الموظف
  Future<List<Sale>> getSalesByEmployee(String employeeId) async {
    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 30));

      final PageResult<Sale> pageResult = await POSService.getCombinedSalesPage(
        startDate: startDate,
        endDate: endDate,
      );

      return pageResult.items
          .where((Sale sale) => (sale.customerName ?? '') == employeeId)
          .toList();
    } catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات حسب الموظف: $e');
      return <Sale>[];
    }
  }

  /// حساب متوسط قيمة البيع
  Future<double> getAverageSaleValue(
      DateTime? startDate, DateTime? endDate) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final List<Sale> sales = await getSalesByTimeRange(startDate, endDate);

      if (sales.isEmpty) return 0.0;

      final double totalAmount =
          sales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);
      return totalAmount / sales.length;
    } catch (e) {
      debugPrint('❌ خطأ في حساب متوسط قيمة البيع: $e');
      return 0.0;
    }
  }

  /// جلب تحليلات المبيعات المتقدمة
  Future<SalesAnalytics> getSalesAnalytics(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales = await getSalesByTimeRange(startDate, endDate);

      // تحليل الاتجاهات
      final TrendAnalysis trendAnalysis = _calculateTrendAnalysis(sales);

      // المبيعات الساعية
      final List<HourlySale> hourlySales = _calculateHourlySales(sales);

      // المبيعات اليومية
      final List<DailySale> dailySales =
          _calculateDailySales(sales, startDate, endDate);

      // المبيعات الأسبوعية
      final List<WeeklySale> weeklySales =
          _calculateWeeklySales(sales, startDate, endDate);

      // المبيعات الشهرية
      final List<MonthlySale> monthlySales =
          _calculateMonthlySales(sales, startDate, endDate);

      // توزيع طرق الدفع
      final PaymentDistribution paymentDistribution =
          _calculatePaymentDistribution(sales);

      // أفضل المنتجات
      final List<ProductAnalytics> topProducts = _calculateTopProducts(sales);

      // تحليلات العملاء
      final CustomerAnalytics customerAnalytics =
          _calculateCustomerAnalytics(sales);

      // أداء الموظفين
      final List<EmployeePerformance> employeePerformance =
          _calculateEmployeePerformance(sales);

      // تحليل الموسمية
      final SeasonalityAnalysis seasonalityAnalysis =
          _calculateSeasonalityAnalysis(sales);

      return SalesAnalytics(
        trendAnalysis: trendAnalysis,
        hourlySales: hourlySales,
        dailySales: dailySales,
        weeklySales: weeklySales,
        monthlySales: monthlySales,
        paymentDistribution: paymentDistribution,
        topProducts: topProducts,
        customerAnalytics: customerAnalytics,
        employeePerformance: employeePerformance,
        seasonalityAnalysis: seasonalityAnalysis,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب تحليلات المبيعات: $e');
      rethrow;
    }
  }

  /// حساب تحليل الاتجاهات
  TrendAnalysis _calculateTrendAnalysis(List<Sale> sales) {
    if (sales.length < 2) {
      return TrendAnalysis(
        trend: TrendDirection.stable,
        growthRate: 0.0,
        volatility: 0.0,
        peakValue: 0.0,
        peakDate: DateTime(2024),
        lowValue: 0.0,
        lowDate: DateTime(2024),
      );
    }

    // ترتيب المبيعات حسب التاريخ
    final List<Sale> sortedSales = List<Sale>.from(sales)
      ..sort((Sale a, Sale b) => a.saleDate.compareTo(b.saleDate));

    // حساب النمو
    final double firstHalf = sortedSales.take(sortedSales.length ~/ 2).fold(
        0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());
    final double secondHalf = sortedSales.skip(sortedSales.length ~/ 2).fold(
        0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());

    final double growthRate =
        firstHalf > 0 ? ((secondHalf - firstHalf) / firstHalf) * 100 : 0.0;

    // تحديد الاتجاه
    TrendDirection trend;
    if (growthRate > 5) {
      trend = TrendDirection.increasing;
    } else if (growthRate < -5) {
      trend = TrendDirection.decreasing;
    } else if (growthRate.abs() < 2) {
      trend = TrendDirection.stable;
    } else {
      trend = TrendDirection.volatile;
    }

    // حساب التقلب
    final List<double> amounts =
        sortedSales.map((Sale s) => s.totalAmount.toDouble()).toList();
    final double mean =
        amounts.reduce((double a, double b) => a + b) / amounts.length;
    final double variance = amounts
            .map((double x) => (x - mean) * (x - mean))
            .reduce((double a, double b) => a + b) /
        amounts.length;
    final double volatility = math.sqrt(variance);

    // القيم القصوى والدنيا
    final Sale peakSale = sortedSales.reduce((Sale a, Sale b) =>
        a.totalAmount.toDouble() > b.totalAmount.toDouble() ? a : b);
    final Sale lowSale = sortedSales.reduce((Sale a, Sale b) =>
        a.totalAmount.toDouble() < b.totalAmount.toDouble() ? a : b);

    return TrendAnalysis(
      trend: trend,
      growthRate: growthRate,
      volatility: volatility,
      peakValue: peakSale.totalAmount.toDouble(),
      peakDate: peakSale.saleDate,
      lowValue: lowSale.totalAmount.toDouble(),
      lowDate: lowSale.saleDate,
    );
  }

  /// حساب المبيعات الساعية
  List<HourlySale> _calculateHourlySales(List<Sale> sales) {
    final Map<int, List<Sale>> hourlyMap = <int, List<Sale>>{};

    for (final Sale sale in sales) {
      final int hour = sale.saleDate.hour;
      hourlyMap[hour] ??= <Sale>[];
      hourlyMap[hour]!.add(sale);
    }

    return hourlyMap.entries.map((MapEntry<int, List<Sale>> entry) {
      final int hour = entry.key;
      final List<Sale> hourSales = entry.value;
      final double totalAmount = hourSales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());
      final int transactionCount = hourSales.length;
      final double averageValue =
          transactionCount > 0 ? totalAmount / transactionCount : 0.0;

      return HourlySale(
        hour: hour,
        totalAmount: totalAmount,
        transactionCount: transactionCount,
        averageValue: averageValue,
      );
    }).toList()
      ..sort((HourlySale a, HourlySale b) => a.hour.compareTo(b.hour));
  }

  /// حساب المبيعات اليومية
  List<DailySale> _calculateDailySales(
      List<Sale> sales, DateTime startDate, DateTime endDate) {
    final Map<String, List<Sale>> dailyMap = <String, List<Sale>>{};

    for (final Sale sale in sales) {
      final String dateKey =
          '${sale.saleDate.year}-${sale.saleDate.month.toString().padLeft(2, '0')}-${sale.saleDate.day.toString().padLeft(2, '0')}';
      dailyMap[dateKey] ??= <Sale>[];
      dailyMap[dateKey]!.add(sale);
    }

    return dailyMap.entries.map((MapEntry<String, List<Sale>> entry) {
      final List<Sale> daySales = entry.value;
      final DateTime date = DateTime.parse(entry.key);
      final double totalAmount = daySales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());
      final int transactionCount = daySales.length;
      final int customerCount =
          daySales.map((Sale s) => s.customerName ?? '').toSet().length;
      final double averageValue =
          transactionCount > 0 ? totalAmount / transactionCount : 0.0;
      final double profit = daySales.fold(
          0.0, (double sum, Sale sale) => sum + sale.totalProfit.toDouble());

      return DailySale(
        date: date,
        totalAmount: totalAmount,
        transactionCount: transactionCount,
        customerCount: customerCount,
        averageValue: averageValue,
        profit: profit,
      );
    }).toList()
      ..sort((DailySale a, DailySale b) => a.date.compareTo(b.date));
  }

  /// حساب المبيعات الأسبوعية
  List<WeeklySale> _calculateWeeklySales(
      List<Sale> sales, DateTime startDate, DateTime endDate) {
    // تنفيذ مبسط - يمكن تحسينه
    return <WeeklySale>[];
  }

  /// حساب المبيعات الشهرية
  List<MonthlySale> _calculateMonthlySales(
      List<Sale> sales, DateTime startDate, DateTime endDate) {
    // تنفيذ مبسط - يمكن تحسينه
    return <MonthlySale>[];
  }

  /// حساب توزيع طرق الدفع
  PaymentDistribution _calculatePaymentDistribution(List<Sale> sales) {
    double cashAmount = 0.0;
    double cardAmount = 0.0;
    double otherAmount = 0.0;

    for (final Sale sale in sales) {
      switch (sale.paymentMethod) {
        case 'cash':
          cashAmount += sale.totalAmount.toDouble();
          break;
        case 'card':
          cardAmount += sale.totalAmount.toDouble();
          break;
        default:
          otherAmount += sale.totalAmount.toDouble();
          break;
      }
    }

    final double totalAmount = cashAmount + cardAmount + otherAmount;
    final double cashPercentage =
        totalAmount > 0 ? (cashAmount / totalAmount) * 100 : 0.0;
    final double cardPercentage =
        totalAmount > 0 ? (cardAmount / totalAmount) * 100 : 0.0;
    final double otherPercentage =
        totalAmount > 0 ? (otherAmount / totalAmount) * 100 : 0.0;

    return PaymentDistribution(
      cashAmount: cashAmount,
      cardAmount: cardAmount,
      otherAmount: otherAmount,
      cashPercentage: cashPercentage,
      cardPercentage: cardPercentage,
      otherPercentage: otherPercentage,
    );
  }

  /// حساب أفضل المنتجات
  List<ProductAnalytics> _calculateTopProducts(List<Sale> sales) {
    final Map<String, Map<String, dynamic>> productStats =
        <String, Map<String, dynamic>>{};

    for (final Sale sale in sales) {
      for (final CartItem item in sale.items) {
        final String productId = item.productId;
        if (productStats.containsKey(productId)) {
          final Map<String, dynamic> stats = productStats[productId]!;
          stats['quantity'] = (stats['quantity'] as int) + item.quantity;
          stats['totalValue'] =
              (stats['totalValue'] as double) + item.totalPrice.toDouble();
          stats['profit'] =
              (stats['profit'] as double) + item.totalProfit.toDouble();
        } else {
          productStats[productId] = <String, dynamic>{
            'productId': productId,
            'productName': item.name,
            'quantity': item.quantity,
            'totalValue': item.totalPrice.toDouble(),
            'profit': item.totalProfit.toDouble(),
          };
        }
      }
    }

    final List<MapEntry<String, Map<String, dynamic>>> sortedProducts =
        productStats.entries.toList()
          ..sort((MapEntry<String, Map<String, dynamic>> a,
                  MapEntry<String, Map<String, dynamic>> b) =>
              (b.value['totalValue'] as double)
                  .compareTo(a.value['totalValue'] as double));

    return sortedProducts
        .asMap()
        .entries
        .map((MapEntry<int, MapEntry<String, Map<String, dynamic>>> entry) {
      final int index = entry.key;
      final Map<String, dynamic> productData = entry.value.value;
      return ProductAnalytics(
        productId: productData['productId'] as String,
        productName: productData['productName'] as String,
        quantitySold: productData['quantity'] as int,
        totalValue: productData['totalValue'] as double,
        profit: productData['profit'] as double,
        rank: index + 1,
        growthRate: 0.0, // يمكن حسابها لاحقاً
      );
    }).toList();
  }

  /// حساب تحليلات العملاء
  CustomerAnalytics _calculateCustomerAnalytics(List<Sale> sales) {
    final Set<String> uniqueCustomers =
        sales.map((Sale s) => s.customerName ?? '').toSet();
    final int totalCustomers = uniqueCustomers.length;
    const int newCustomers = 0; // يحتاج تنفيذ أكثر تعقيداً
    final int returningCustomers = totalCustomers - newCustomers;
    final double averageOrderValue = sales.isNotEmpty
        ? sales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount) /
            sales.length
        : 0.0;
    const double customerRetentionRate = 0.0; // يحتاج تنفيذ أكثر تعقيداً

    return CustomerAnalytics(
      totalCustomers: totalCustomers,
      newCustomers: newCustomers,
      returningCustomers: returningCustomers,
      averageOrderValue: averageOrderValue,
      customerRetentionRate: customerRetentionRate,
    );
  }

  /// حساب أداء الموظفين
  List<EmployeePerformance> _calculateEmployeePerformance(List<Sale> sales) {
    final Map<String, Map<String, dynamic>> employeeStats =
        <String, Map<String, dynamic>>{};

    for (final Sale sale in sales) {
      final String employeeId = sale.customerName ?? '';
      if (employeeStats.containsKey(employeeId)) {
        final Map<String, dynamic> stats = employeeStats[employeeId]!;
        stats['totalSales'] =
            (stats['totalSales'] as double) + sale.totalAmount.toDouble();
        stats['transactionCount'] = (stats['transactionCount'] as int) + 1;
      } else {
        employeeStats[employeeId] = <String, dynamic>{
          'employeeId': employeeId,
          'employeeName': sale.customerName ?? 'موظف غير معروف',
          'totalSales': sale.totalAmount.toDouble(),
          'transactionCount': 1,
        };
      }
    }

    final List<MapEntry<String, Map<String, dynamic>>> sortedEmployees =
        employeeStats.entries.toList()
          ..sort((MapEntry<String, Map<String, dynamic>> a,
                  MapEntry<String, Map<String, dynamic>> b) =>
              (b.value['totalSales'] as double)
                  .compareTo(a.value['totalSales'] as double));

    return sortedEmployees
        .asMap()
        .entries
        .map((MapEntry<int, MapEntry<String, Map<String, dynamic>>> entry) {
      final int index = entry.key;
      final Map<String, dynamic> employeeData = entry.value.value;
      final double totalSales = employeeData['totalSales'] as double;
      final int transactionCount = employeeData['transactionCount'] as int;
      final double averageSaleValue =
          transactionCount > 0 ? totalSales / transactionCount : 0.0;

      return EmployeePerformance(
        employeeId: employeeData['employeeId'] as String,
        employeeName: employeeData['employeeName'] as String,
        totalSales: totalSales,
        transactionCount: transactionCount,
        averageSaleValue: averageSaleValue,
        rank: index + 1,
      );
    }).toList();
  }

  /// حساب تحليل الموسمية
  SeasonalityAnalysis _calculateSeasonalityAnalysis(List<Sale> sales) {
    // تنفيذ مبسط - يمكن تحسينه
    return const SeasonalityAnalysis(
      seasonalPattern: <double>[],
      peakMonths: <int>[],
      lowMonths: <int>[],
      seasonalIndex: 0.0,
    );
  }
}
