import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';

/// نموذج إحصائيات لوحة التحكم
class DashboardStats {
  DashboardStats({
    required this.totalProducts,
    required this.totalProductsValue,
    required this.uniqueProductNames,
    required this.todaySales,
    required this.monthlySales,
    required this.totalProfit,
    required this.profitHistory,
  });

  /// إنشاء إحصائيات فارغة
  factory DashboardStats.empty() => DashboardStats(
        totalProducts: 0,
        totalProductsValue: 0.0,
        uniqueProductNames: 0,
        todaySales: 0,
        monthlySales: 0,
        totalProfit: 0.0,
        profitHistory: <ProfitData>[],
      );
  final int totalProducts;
  final double totalProductsValue;
  final int uniqueProductNames;
  final int todaySales;
  final int monthlySales;
  final double totalProfit;
  final List<ProfitData> profitHistory;

  /// تنسيق القيمة المالية للمنتجات
  String formattedProductsValue(BuildContext context) =>
      CurrencyFormatter.formatCurrency(totalProductsValue, context);

  /// تنسيق إجمالي الأرباح
  String formattedTotalProfit(BuildContext context) =>
      CurrencyFormatter.formatCurrency(totalProfit, context);

  /// حساب متوسط الأرباح اليومية
  double get averageDailyProfit {
    if (profitHistory.isEmpty) return 0.0;
    return profitHistory
            .map((ProfitData e) => e.profit)
            .reduce((double a, double b) => a + b) /
        profitHistory.length;
  }

  /// تنسيق متوسط الأرباح اليومية
  String formattedAverageDailyProfit(BuildContext context) =>
      CurrencyFormatter.formatCurrency(averageDailyProfit, context);

  /// حساب متوسط سعر المنتج
  double get averageProductPrice {
    if (totalProducts == 0) return 0.0;
    return totalProductsValue / totalProducts;
  }

  /// تنسيق متوسط سعر المنتج
  String formattedAverageProductPrice(BuildContext context) =>
      CurrencyFormatter.formatCurrency(averageProductPrice, context);

  /// حساب نسبة الربح الإجمالية
  double get totalProfitPercentage {
    if (totalProductsValue == 0) return 0.0;
    return (totalProfit / totalProductsValue) * 100;
  }

  /// تنسيق نسبة الربح الإجمالية
  String get formattedTotalProfitPercentage =>
      '${totalProfitPercentage.toStringAsFixed(1)}%';

  /// حساب متوسط المبيعات الشهرية
  double get averageMonthlySales {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;

    // حساب عدد الأيام في الشهر الحالي
    final int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    if (daysInMonth == 0) return 0.0;
    return monthlySales / daysInMonth;
  }

  /// تنسيق متوسط المبيعات الشهرية
  String get formattedAverageMonthlySales =>
      averageMonthlySales.toStringAsFixed(1);

  /// حساب متوسط المبيعات اليومية
  double get averageDailySales {
    final DateTime now = DateTime.now();
    final int currentMonth = now.month;
    final int currentYear = now.year;

    // حساب عدد الأيام في الشهر الحالي
    final int daysInMonth = DateTime(currentYear, currentMonth + 1, 0).day;

    if (daysInMonth == 0) return 0.0;
    return monthlySales / daysInMonth;
  }

  /// تنسيق متوسط المبيعات اليومية
  String get formattedAverageDailySales => averageDailySales.toStringAsFixed(1);

  @override
  String toString() =>
      'DashboardStats{totalProducts: $totalProducts, totalProductsValue: $totalProductsValue, uniqueProductNames: $uniqueProductNames, todaySales: $todaySales, monthlySales: $monthlySales, totalProfit: $totalProfit}';
}

/// نموذج بيانات الأرباح للرسم البياني
class ProfitData {
  ProfitData({
    required this.date,
    required this.profit,
  }) : formattedDate = DateFormat('MM/dd').format(date);

  /// إنشاء بيانات أرباح من Map
  factory ProfitData.fromMap(Map<String, dynamic> map) => ProfitData(
        date: DateTime.parse(map['date'] as String),
        profit: (map['profit'] as num).toDouble(),
      );
  final DateTime date;
  final double profit;
  final String formattedDate;

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => <String, dynamic>{
        'date': date.toIso8601String(),
        'profit': profit,
      };

  @override
  String toString() => 'ProfitData{date: $date, profit: $profit}';
}

/// نموذج بيانات المبيعات
class SalesData {
  SalesData({
    required this.date,
    required this.quantity,
    required this.profit,
  });

  /// إنشاء بيانات مبيعات من Map
  factory SalesData.fromMap(Map<String, dynamic> map) => SalesData(
        date: DateTime.parse(map['date'] as String),
        quantity: map['quantity'] as int,
        profit: (map['profit'] as num).toDouble(),
      );
  final DateTime date;
  final int quantity;
  final double profit;

  /// تحويل إلى Map
  Map<String, dynamic> toMap() => <String, dynamic>{
        'date': date.toIso8601String(),
        'quantity': quantity,
        'profit': profit,
      };

  @override
  String toString() =>
      'SalesData{date: $date, quantity: $quantity, profit: $profit}';
}
