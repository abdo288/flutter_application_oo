import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/currency_formatter.dart';

/// widget إحصائيات وتحليلات المنتجات
class ProductAnalyticsWidget extends StatelessWidget {
  const ProductAnalyticsWidget({
    super.key,
    required this.products,
    this.onCategorySelected,
    this.onSupplierSelected,
  });

  final List<Product> products;
  final void Function(String)? onCategorySelected;
  final void Function(String)? onSupplierSelected;

  @override
  Widget build(BuildContext context) {
    final ProductAnalytics analytics = _calculateAnalytics();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // العنوان المختصر
          Row(
            children: <Widget>[
              const Icon(Icons.analytics, color: Colors.blue, size: 16),
              const SizedBox(width: 6),
              Text(
                'إحصائيات (${products.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الإحصائيات المختصرة
          _buildCompactStats(context, analytics),
        ],
      ),
    );
  }

  Widget _buildCompactStats(BuildContext context, ProductAnalytics analytics) => Row(
      children: <Widget>[
        Expanded(
          child: _buildCompactStatCard(
            title: 'إجمالي الربح',
            value: CurrencyFormatter.formatCurrencyNoDecimals(
                analytics.totalProfit / 100, context),
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            title: 'متوسط الربح',
            value: CurrencyFormatter.formatCurrencyNoDecimals(
                analytics.averageProfit / 100, context),
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            title: 'ربح عالي',
            value: '${analytics.highProfitProducts}',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactStatCard(
            title: 'ربح منخفض',
            value: '${analytics.lowProfitProducts}',
            color: Colors.red,
          ),
        ),
      ],
    );

  Widget _buildCompactStatCard({
    required String title,
    required String value,
    required Color color,
  }) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

  ProductAnalytics _calculateAnalytics() {
    if (products.isEmpty) {
      return ProductAnalytics.empty();
    }

    // حساب القيمة الإجمالية
    final int totalValue = products.fold<int>(
      0,
      (int sum, Product product) => sum + product.retailPrice,
    );

    // حساب متوسط الربح
    final double totalProfitPercentage = products.fold<double>(
      0,
      (double sum, Product product) => sum + product.calculateProfitPercentage(),
    );
    final double averageProfitPercentage = totalProfitPercentage / products.length;

    // أعلى نسبة ربح
    final double highestProfitPercentage = products.fold<double>(
      0,
      (double max, Product product) => product.calculateProfitPercentage() > max
          ? product.calculateProfitPercentage()
          : max,
    );

    // إحصائيات الفئات
    final Map<String, int> categoryStats = <String, int>{};
    for (final Product product in products) {
      if (product.category != null) {
        categoryStats[product.category!] =
            (categoryStats[product.category!] ?? 0) + 1;
      }
    }

    // إحصائيات الموردين
    final Map<String, int> supplierStats = <String, int>{};
    for (final Product product in products) {
      if (product.supplier != null) {
        supplierStats[product.supplier!] =
            (supplierStats[product.supplier!] ?? 0) + 1;
      }
    }

    // تحليل الأرباح
    int highProfitCount = 0;
    int mediumProfitCount = 0;
    int lowProfitCount = 0;

    for (final Product product in products) {
      final double profitPercentage = product.calculateProfitPercentage();
      if (profitPercentage >= 50) {
        highProfitCount++;
      } else if (profitPercentage >= 25) {
        mediumProfitCount++;
      } else {
        lowProfitCount++;
      }
    }

    // حساب إجمالي الربح
    final int totalProfit = products.fold<int>(
      0,
      (int sum, Product product) => sum + product.calculateProfit(),
    );

    // حساب متوسط الربح
    final int averageProfit = totalProfit ~/ products.length;

    return ProductAnalytics(
      totalValue: totalValue,
      totalProfit: totalProfit,
      averageProfit: averageProfit,
      averageProfitPercentage: averageProfitPercentage,
      highestProfitPercentage: highestProfitPercentage,
      categoryStats: categoryStats,
      supplierStats: supplierStats,
      highProfitCount: highProfitCount,
      mediumProfitCount: mediumProfitCount,
      lowProfitCount: lowProfitCount,
      highProfitProducts: highProfitCount,
      lowProfitProducts: lowProfitCount,
    );
  }
}

/// فئة إحصائيات المنتجات
class ProductAnalytics {

  ProductAnalytics({
    required this.totalValue,
    required this.totalProfit,
    required this.averageProfit,
    required this.averageProfitPercentage,
    required this.highestProfitPercentage,
    required this.categoryStats,
    required this.supplierStats,
    required this.highProfitCount,
    required this.mediumProfitCount,
    required this.lowProfitCount,
    required this.highProfitProducts,
    required this.lowProfitProducts,
  });

  factory ProductAnalytics.empty() => ProductAnalytics(
      totalValue: 0,
      totalProfit: 0,
      averageProfit: 0,
      averageProfitPercentage: 0,
      highestProfitPercentage: 0,
      categoryStats: <String, int>{},
      supplierStats: <String, int>{},
      highProfitCount: 0,
      mediumProfitCount: 0,
      lowProfitCount: 0,
      highProfitProducts: 0,
      lowProfitProducts: 0,
    );
  final int totalValue;
  final int totalProfit;
  final int averageProfit;
  final double averageProfitPercentage;
  final double highestProfitPercentage;
  final Map<String, int> categoryStats;
  final Map<String, int> supplierStats;
  final int highProfitCount;
  final int mediumProfitCount;
  final int lowProfitCount;
  final int highProfitProducts;
  final int lowProfitProducts;
}
