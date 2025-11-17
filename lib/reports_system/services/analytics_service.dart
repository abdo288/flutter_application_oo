import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:profit_calculator/models/cart_item.dart';

import '../../models/sale.dart';
import '../models/chart_data.dart';
import '../models/sales_analytics.dart';
import 'advanced_sales_service.dart';

/// خدمة التحليلات
class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();

  final AdvancedSalesService _salesService = AdvancedSalesService();

  /// جلب تحليل الاتجاهات
  Future<TrendAnalysis> getTrendAnalysis(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startDate, endDate);

      return _calculateTrendAnalysis(sales);
    } catch (e) {
      debugPrint('❌ خطأ في جلب تحليل الاتجاهات: $e');
      rethrow;
    }
  }

  /// جلب المبيعات الساعية
  Future<List<HourlySale>> getHourlySales(DateTime date) async {
    try {
      final DateTime startOfDay = DateTime(date.year, date.month, date.day);
      final DateTime endOfDay = startOfDay.add(const Duration(days: 1));

      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startOfDay, endOfDay);
      return _calculateHourlySales(sales);
    } catch (e) {
      debugPrint('❌ خطأ في جلب المبيعات الساعية: $e');
      return <HourlySale>[];
    }
  }

  /// جلب بيانات الرسم البياني اليومي
  Future<ChartData> getDailySalesChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startDate, endDate);
      final List<DailySale> dailySales =
          _calculateDailySales(sales, startDate, endDate);

      final List<DataPoint> dataPoints = dailySales.map((DailySale dailySale) => DataPoint(
          label: '${dailySale.date.day}/${dailySale.date.month}',
          value: dailySale.totalAmount,
          tooltip: 'المبيعات: ${dailySale.totalAmount.toStringAsFixed(2)} دج\n'
              'المعاملات: ${dailySale.transactionCount}',
        )).toList();

      return ChartData(
        title: 'المبيعات اليومية',
        dataPoints: dataPoints,
        chartType: ChartType.line,
        xAxisLabel: 'التاريخ',
        yAxisLabel: 'المبلغ (DZ)',
        colors: ChartColors.salesPalette,
        showGrid: true,
        showLegend: true,
        showTooltips: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات الرسم البياني اليومي: $e');
      return _getEmptyChartData('المبيعات اليومية');
    }
  }

  /// جلب توزيع طرق الدفع
  Future<ChartData> getPaymentDistributionChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startDate, endDate);
      final PaymentDistribution distribution =
          _calculatePaymentDistribution(sales);

      final List<DataPoint> dataPoints = <DataPoint>[
        DataPoint(
          label: 'نقدي',
          value: distribution.cashAmount,
          tooltip:
              'النقد: ${distribution.cashAmount.toStringAsFixed(2)} DZ (${distribution.cashPercentage.toStringAsFixed(1)}%)',
          color: ChartColors.paymentPalette[0],
        ),
        DataPoint(
          label: 'بطاقة',
          value: distribution.cardAmount,
          tooltip:
              'البطاقة: ${distribution.cardAmount.toStringAsFixed(2)} DZ (${distribution.cardPercentage.toStringAsFixed(1)}%)',
          color: ChartColors.paymentPalette[1],
        ),
        DataPoint(
          label: 'أخرى',
          value: distribution.otherAmount,
          tooltip:
              'أخرى: ${distribution.otherAmount.toStringAsFixed(2)} DZ (${distribution.otherPercentage.toStringAsFixed(1)}%)',
          color: ChartColors.paymentPalette[2],
        ),
      ];

      return ChartData(
        title: 'توزيع طرق الدفع',
        dataPoints: dataPoints,
        chartType: ChartType.pie,
        xAxisLabel: 'طريقة الدفع',
        yAxisLabel: 'المبلغ (DZ)',
        colors: ChartColors.paymentPalette,
        showGrid: false,
        showLegend: true,
        showTooltips: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب توزيع طرق الدفع: $e');
      return _getEmptyChartData('توزيع طرق الدفع');
    }
  }

  /// جلب بيانات أفضل المنتجات
  Future<ChartData> getTopProductsChart(DateTime startDate, DateTime endDate,
      {int limit = 10}) async {
    try {
      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startDate, endDate);
      final List<ProductAnalytics> topProducts = _calculateTopProducts(sales);

      final List<DataPoint> dataPoints = topProducts.take(limit).map((ProductAnalytics product) => DataPoint(
          label: product.productName.length > 15
              ? '${product.productName.substring(0, 15)}...'
              : product.productName,
          value: product.totalValue,
          tooltip: '${product.productName}\n'
              'المبيعات: ${product.totalValue.toStringAsFixed(2)} DZ\n'
              'الكمية: ${product.quantitySold}',
        )).toList();

      return ChartData(
        title: 'أفضل المنتجات مبيعاً',
        dataPoints: dataPoints,
        chartType: ChartType.bar,
        xAxisLabel: 'المنتجات',
        yAxisLabel: 'المبلغ (DZ)',
        colors: ChartColors.defaultPalette,
        showGrid: true,
        showLegend: false,
        showTooltips: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات أفضل المنتجات: $e');
      return _getEmptyChartData('أفضل المنتجات مبيعاً');
    }
  }

  /// جلب الرسم البياني الساعي
  Future<ChartData> getHourlySalesChart(DateTime date) async {
    try {
      final List<HourlySale> hourlySales = await getHourlySales(date);

      final List<DataPoint> dataPoints = hourlySales.map((HourlySale hourlySale) => DataPoint(
          label: '${hourlySale.hour}:00',
          value: hourlySale.totalAmount,
          tooltip: 'الساعة ${hourlySale.hour}:00\n'
              'المبيعات: ${hourlySale.totalAmount.toStringAsFixed(2)} DZ\n'
              'المعاملات: ${hourlySale.transactionCount}',
        )).toList();

      return ChartData(
        title: 'المبيعات حسب الساعة',
        dataPoints: dataPoints,
        chartType: ChartType.bar,
        xAxisLabel: 'الساعة',
        yAxisLabel: 'المبلغ (DZ)',
        colors: ChartColors.salesPalette,
        showGrid: true,
        showLegend: false,
        showTooltips: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب الرسم البياني الساعي: $e');
      return _getEmptyChartData('المبيعات حسب الساعة');
    }
  }

  /// جلب الرسم البياني الأسبوعي
  Future<ChartData> getWeeklySalesChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startDate, endDate);
      final List<WeeklySale> weeklySales =
          _calculateWeeklySales(sales, startDate, endDate);

      final List<DataPoint> dataPoints = weeklySales.map((WeeklySale weeklySale) => DataPoint(
          label:
              'الأسبوع ${weeklySale.weekStart.day}/${weeklySale.weekStart.month}',
          value: weeklySale.totalAmount,
          tooltip:
              'الأسبوع من ${weeklySale.weekStart.day}/${weeklySale.weekStart.month} إلى ${weeklySale.weekEnd.day}/${weeklySale.weekEnd.month}\n'
              'المبيعات: ${weeklySale.totalAmount.toStringAsFixed(2)} DZ\n'
              'المعاملات: ${weeklySale.transactionCount}',
        )).toList();

      return ChartData(
        title: 'المبيعات الأسبوعية',
        dataPoints: dataPoints,
        chartType: ChartType.line,
        xAxisLabel: 'الأسبوع',
        yAxisLabel: 'المبلغ (DZ)',
        colors: ChartColors.salesPalette,
        showGrid: true,
        showLegend: true,
        showTooltips: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب الرسم البياني الأسبوعي: $e');
      return _getEmptyChartData('المبيعات الأسبوعية');
    }
  }

  /// جلب الرسم البياني الشهري
  Future<ChartData> getMonthlySalesChart(
      DateTime startDate, DateTime endDate) async {
    try {
      final List<Sale> sales =
          await _salesService.getSalesByTimeRange(startDate, endDate);
      final List<MonthlySale> monthlySales =
          _calculateMonthlySales(sales, startDate, endDate);

      final List<DataPoint> dataPoints = monthlySales.map((MonthlySale monthlySale) => DataPoint(
          label: '${monthlySale.month}/${monthlySale.year}',
          value: monthlySale.totalAmount,
          tooltip: '${monthlySale.month}/${monthlySale.year}\n'
              'المبيعات: ${monthlySale.totalAmount.toStringAsFixed(2)} DZ\n'
              'المعاملات: ${monthlySale.transactionCount}',
        )).toList();

      return ChartData(
        title: 'المبيعات الشهرية',
        dataPoints: dataPoints,
        chartType: ChartType.area,
        xAxisLabel: 'الشهر',
        yAxisLabel: 'المبلغ (DZ)',
        colors: ChartColors.salesPalette,
        showGrid: true,
        showLegend: true,
        showTooltips: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في جلب الرسم البياني الشهري: $e');
      return _getEmptyChartData('المبيعات الشهرية');
    }
  }

  /// جلب تحليلات شاملة
  Future<SalesAnalytics> getComprehensiveAnalytics(
      DateTime startDate, DateTime endDate) async {
    try {
      return await _salesService.getSalesAnalytics(startDate, endDate);
    } catch (e) {
      debugPrint('❌ خطأ في جلب التحليلات الشاملة: $e');
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

    final List<Sale> sortedSales = List<Sale>.from(sales)
      ..sort((Sale a, Sale b) => a.saleDate.compareTo(b.saleDate));

    // حساب النمو
    final int midPoint = sortedSales.length ~/ 2;
    final double firstHalf = sortedSales
        .take(midPoint)
        .fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);
    final double secondHalf = sortedSales
        .skip(midPoint)
        .fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount);

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
    final double mean = amounts.reduce((double a, double b) => a + b) / amounts.length;
    final double variance =
        amounts.map((double x) => (x - mean) * (x - mean)).reduce((double a, double b) => a + b) /
            amounts.length;
    final double volatility = math.sqrt(variance);

    // القيم القصوى والدنيا
    final Sale peakSale = sortedSales.reduce(
        (Sale a, Sale b) => a.totalAmount.toDouble() > b.totalAmount.toDouble() ? a : b);
    final Sale lowSale = sortedSales.reduce(
        (Sale a, Sale b) => a.totalAmount.toDouble() < b.totalAmount.toDouble() ? a : b);

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
      final double totalAmount =
          hourSales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());
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
      final double totalAmount =
          daySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalAmount.toDouble());
      final int transactionCount = daySales.length;
      final int customerCount =
          daySales.map((Sale s) => s.customerName ?? '').toSet().length;
      final double averageValue =
          transactionCount > 0 ? totalAmount / transactionCount : 0.0;
      final double profit =
          daySales.fold(0.0, (double sum, Sale sale) => sum + sale.totalProfit.toDouble());

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
    final Map<String, Map<String, dynamic>> productStats = <String, Map<String, dynamic>>{};

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
          ..sort((MapEntry<String, Map<String, dynamic>> a, MapEntry<String, Map<String, dynamic>> b) => (b.value['totalValue'] as double)
              .compareTo(a.value['totalValue'] as double));

    return sortedProducts.asMap().entries.map((MapEntry<int, MapEntry<String, Map<String, dynamic>>> entry) {
      final int index = entry.key;
      final Map<String, dynamic> productData = entry.value.value;
      return ProductAnalytics(
        productId: productData['productId'] as String,
        productName: productData['productName'] as String,
        quantitySold: productData['quantity'] as int,
        totalValue: productData['totalValue'] as double,
        profit: productData['profit'] as double,
        rank: index + 1,
        growthRate: 0.0,
      );
    }).toList();
  }

  /// إنشاء بيانات فارغة للرسم البياني
  ChartData _getEmptyChartData(String title) => ChartData(
      title: title,
      dataPoints: const <DataPoint>[],
      chartType: ChartType.line,
      xAxisLabel: '',
      yAxisLabel: '',
      colors: ChartColors.defaultPalette,
      showGrid: true,
      showLegend: true,
      showTooltips: true,
    );
}
