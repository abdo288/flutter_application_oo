import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';

/// مكون تحليلات المنتجات المبسط
class ProductAnalyticsSimple extends StatelessWidget {
  const ProductAnalyticsSimple({
    super.key,
    required this.products,
    this.onCategorySelected,
    this.onSupplierSelected,
  });

  final List<Product> products;
  final ValueChanged<String>? onCategorySelected;
  final ValueChanged<String>? onSupplierSelected;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'إحصائيات المنتجات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildAnalyticsGrid(context),
        ],
      ),
    );
  }

  Widget _buildAnalyticsGrid(BuildContext context) {
    final ProductAnalytics analytics = _calculateAnalytics();

    return Column(
      children: <Widget>[
        // الصف الأول - الإحصائيات الأساسية
        Row(
          children: <Widget>[
            Expanded(
              child: _buildAnalyticsCard(
                'إجمالي المنتجات',
                '${products.length}',
                Icons.inventory,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnalyticsCard(
                'متوسط السعر',
                CurrencyFormatter.formatCurrencyNoDecimals(
                    analytics.averagePrice, context),
                Icons.attach_money,
                Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // الصف الثاني - إحصائيات الربح
        Row(
          children: <Widget>[
            Expanded(
              child: _buildAnalyticsCard(
                'متوسط الربح',
                CurrencyFormatter.formatCurrencyNoDecimals(
                    analytics.averageProfit, context),
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnalyticsCard(
                'أعلى ربح',
                CurrencyFormatter.formatCurrencyNoDecimals(
                    analytics.highestProfit, context),
                Icons.star,
                Colors.orange,
              ),
            ),
          ],
        ),

        // عرض الفئات إذا كانت متوفرة
        if (analytics.categories.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          _buildCategoriesSection(analytics.categories),
        ],
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildCategoriesSection(Map<String, int> categories) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الفئات',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: categories.entries.map((entry) {
              return _buildCategoryChip(entry.key, entry.value);
            }).toList(),
          ),
        ],
      );

  Widget _buildCategoryChip(String category, int count) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onCategorySelected?.call(category),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              '$category ($count)',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );

  ProductAnalytics _calculateAnalytics() {
    if (products.isEmpty) {
      return ProductAnalytics.empty();
    }

    // حساب المتوسطات
    final int totalPrice = products.fold<int>(
      0,
      (int sum, Product product) => sum + product.retailPrice,
    );
    final double averagePrice = totalPrice / products.length;

    final int totalProfit = products.fold<int>(
      0,
      (int sum, Product product) => sum + product.calculateProfit(),
    );
    final double averageProfit = totalProfit / products.length;

    // أعلى ربح
    final int highestProfit = products.fold<int>(
      0,
      (int max, Product product) =>
          product.calculateProfit() > max ? product.calculateProfit() : max,
    );

    // حساب الفئات
    final Map<String, int> categories = <String, int>{};
    for (final Product product in products) {
      if (product.category != null) {
        categories[product.category!] =
            (categories[product.category!] ?? 0) + 1;
      }
    }

    return ProductAnalytics(
      totalProducts: products.length,
      averagePrice: averagePrice / 100, // تحويل من قروش إلى ريال
      averageProfit: averageProfit / 100,
      highestProfit: highestProfit / 100,
      categories: categories,
    );
  }
}

/// نموذج بيانات التحليلات
class ProductAnalytics {
  const ProductAnalytics({
    required this.totalProducts,
    required this.averagePrice,
    required this.averageProfit,
    required this.highestProfit,
    required this.categories,
  });

  factory ProductAnalytics.empty() {
    return const ProductAnalytics(
      totalProducts: 0,
      averagePrice: 0,
      averageProfit: 0,
      highestProfit: 0,
      categories: {},
    );
  }
  final int totalProducts;
  final double averagePrice;
  final double averageProfit;
  final double highestProfit;
  final Map<String, int> categories;
}
