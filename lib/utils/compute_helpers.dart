import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../providers/riverpod/shared_types.dart';

/// مساعدات العمليات الثقيلة في Isolate منفصل
class ComputeHelpers {
  /// فلترة المنتجات في Isolate منفصل
  static Future<List<Product>> filterProducts({
    required List<Product> products,
    required String searchText,
    required FilterOption filter,
    required double minProfit,
    required double maxProfit,
  }) async =>
      compute(_filterProductsImpl, <String, Object>{
        'products': products,
        'searchText': searchText,
        'filter': filter,
        'minProfit': minProfit,
        'maxProfit': maxProfit,
      });

  static List<Product> _filterProductsImpl(Map<String, dynamic> params) {
    final List<Product> products = params['products'] as List<Product>;
    final String searchText = params['searchText'] as String;
    final FilterOption filter = params['filter'] as FilterOption;
    final double minProfit = params['minProfit'] as double;
    final double maxProfit = params['maxProfit'] as double;

    List<Product> filtered = List.from(products);

    // تطبيق البحث المحسن
    if (searchText.trim().isNotEmpty) {
      filtered = filtered
          .where((Product product) => _matchesSearch(product, searchText))
          .toList();
    }

    // تطبيق الفلتر المتقدم
    filtered = _applyAdvancedFilters(filtered, filter, minProfit, maxProfit);

    return filtered;
  }

  /// ترتيب المنتجات في Isolate منفصل
  static Future<List<Product>> sortProducts({
    required List<Product> products,
    required SortOption sortOption,
  }) async =>
      compute(_sortProductsImpl, <String, Object>{
        'products': products,
        'sortOption': sortOption,
      });

  static List<Product> _sortProductsImpl(Map<String, dynamic> params) {
    final List<Product> products = params['products'] as List<Product>;
    final SortOption sortOption = params['sortOption'] as SortOption;

    final List<Product> sorted = List<Product>.from(products);
    switch (sortOption) {
      case SortOption.nameAsc:
        sorted.sort((Product a, Product b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        sorted.sort((Product a, Product b) => b.name.compareTo(a.name));
        break;
      case SortOption.priceAsc:
        sorted.sort(
            (Product a, Product b) => a.retailPrice.compareTo(b.retailPrice));
        break;
      case SortOption.priceDesc:
        sorted.sort(
            (Product a, Product b) => b.retailPrice.compareTo(a.retailPrice));
        break;
      case SortOption.profitAsc:
        sorted.sort((Product a, Product b) =>
            a.calculateProfit().compareTo(b.calculateProfit()));
        break;
      case SortOption.profitDesc:
        sorted.sort((Product a, Product b) =>
            b.calculateProfit().compareTo(a.calculateProfit()));
        break;
      case SortOption.dateAsc:
        sorted.sort((Product a, Product b) => a.savedAt.compareTo(b.savedAt));
        break;
      case SortOption.dateDesc:
        sorted.sort((Product a, Product b) => b.savedAt.compareTo(a.savedAt));
        break;
    }
    return sorted;
  }

  /// فلترة وترتيب المنتجات معاً في Isolate منفصل
  static Future<List<Product>> filterAndSortProducts({
    required List<Product> products,
    required String searchText,
    required FilterOption filter,
    required SortOption sortOption,
    required double minProfit,
    required double maxProfit,
  }) async =>
      compute(_filterAndSortProductsImpl, <String, Object>{
        'products': products,
        'searchText': searchText,
        'filter': filter.index,
        'sortOption': sortOption.index,
        'minProfit': minProfit,
        'maxProfit': maxProfit,
      });

  static List<Product> _filterAndSortProductsImpl(Map<String, dynamic> params) {
    final List<Product> products = params['products'] as List<Product>;
    final String searchText = params['searchText'] as String;
    final FilterOption filter = FilterOption.values[params['filter'] as int];
    final SortOption sortOption =
        SortOption.values[params['sortOption'] as int];
    final double minProfit = params['minProfit'] as double;
    final double maxProfit = params['maxProfit'] as double;

    List<Product> filtered = List.from(products);

    // تطبيق البحث المحسن
    if (searchText.trim().isNotEmpty) {
      filtered = filtered
          .where((Product product) => _matchesSearch(product, searchText))
          .toList();
    }

    // تطبيق الفلتر المتقدم
    filtered = _applyAdvancedFilters(filtered, filter, minProfit, maxProfit);

    // تطبيق الترتيب
    final List<Product> sorted = List<Product>.from(filtered);
    switch (sortOption) {
      case SortOption.nameAsc:
        sorted.sort((Product a, Product b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameDesc:
        sorted.sort((Product a, Product b) => b.name.compareTo(a.name));
        break;
      case SortOption.priceAsc:
        sorted.sort(
            (Product a, Product b) => a.retailPrice.compareTo(b.retailPrice));
        break;
      case SortOption.priceDesc:
        sorted.sort(
            (Product a, Product b) => b.retailPrice.compareTo(a.retailPrice));
        break;
      case SortOption.profitAsc:
        sorted.sort((Product a, Product b) =>
            a.calculateProfit().compareTo(b.calculateProfit()));
        break;
      case SortOption.profitDesc:
        sorted.sort((Product a, Product b) =>
            b.calculateProfit().compareTo(a.calculateProfit()));
        break;
      case SortOption.dateAsc:
        sorted.sort((Product a, Product b) => a.savedAt.compareTo(b.savedAt));
        break;
      case SortOption.dateDesc:
        sorted.sort((Product a, Product b) => b.savedAt.compareTo(a.savedAt));
        break;
    }

    return sorted;
  }

  /// دالة البحث المتقدم المحسنة مع تحسينات الأداء
  static bool _matchesSearch(Product product, String searchText) {
    try {
      final String searchLower = searchText.toLowerCase().trim();
      if (searchLower.isEmpty) return true;

      // ✅ تحسين البحث - استخدام بحث أسرع لجميع المنصات
      return _optimizedSearch(product, searchLower);
    } catch (e) {
      return false;
    }
  }

  /// بحث محسن لجميع المنصات مع تحسينات الأداء
  static bool _optimizedSearch(Product product, String searchLower) {
    // البحث في الاسم أولاً (الأسرع)
    if (product.name.toLowerCase().contains(searchLower)) {
      return true;
    }

    // البحث في الباركود (سريع أيضاً) - فقط للنصوص القصيرة
    if (searchLower.length <= 15 &&
        product.barcode != null &&
        product.barcode!.isNotEmpty &&
        product.barcode!.toLowerCase().contains(searchLower)) {
      return true;
    }

    // البحث في الحقول الثانوية للنصوص القصيرة فقط
    if (searchLower.length <= 10) {
      // البحث في الفئة
      if (product.category != null &&
          product.category!.isNotEmpty &&
          product.category!.toLowerCase().contains(searchLower)) {
        return true;
      }

      // البحث في المورد
      if (product.supplier != null &&
          product.supplier!.isNotEmpty &&
          product.supplier!.toLowerCase().contains(searchLower)) {
        return true;
      }
    }

    // البحث في الوصف للنصوص الطويلة فقط
    if (searchLower.length > 10 &&
        product.description != null &&
        product.description!.isNotEmpty &&
        product.description!.toLowerCase().contains(searchLower)) {
      return true;
    }

    return false;
  }

  /// تطبيق الفلاتر المتقدمة
  static List<Product> _applyAdvancedFilters(
    List<Product> products,
    FilterOption filter,
    double minProfit,
    double maxProfit,
  ) {
    if (filter == FilterOption.all) {
      return products.where((Product product) {
        final double profit = product.calculateProfit().toDouble();
        return profit >= minProfit && profit <= maxProfit;
      }).toList();
    }

    return products.where((Product product) {
      final double profit = product.calculateProfit().toDouble();
      final DateTime now = DateTime.now();
      final int daysSinceAdded = now.difference(product.savedAt).inDays;

      switch (filter) {
        case FilterOption.highProfit:
          return profit >= 1000 && profit >= minProfit && profit <= maxProfit;
        case FilterOption.lowProfit:
          return profit < 1000 && profit >= minProfit && profit <= maxProfit;
        case FilterOption.recent:
          return daysSinceAdded <= 7 &&
              profit >= minProfit &&
              profit <= maxProfit;
        case FilterOption.old:
          return daysSinceAdded > 30 &&
              profit >= minProfit &&
              profit <= maxProfit;
        default:
          return profit >= minProfit && profit <= maxProfit;
      }
    }).toList();
  }

  /// حساب إحصائيات المنتجات في Isolate منفصل
  static Future<Map<String, dynamic>> calculateProductStats({
    required List<Product> products,
  }) async =>
      compute(_calculateProductStatsImpl, products);

  static Map<String, dynamic> _calculateProductStatsImpl(
      List<Product> products) {
    if (products.isEmpty) {
      return <String, dynamic>{
        'totalValue': 0.0,
        'totalProfit': 0.0,
        'averageProfit': 0.0,
        'highProfitCount': 0,
        'lowProfitCount': 0,
        'recentCount': 0,
        'oldCount': 0,
      };
    }

    final double totalValue = products.fold<double>(
        0, (double total, Product product) => total + product.retailPrice);

    final double totalProfit = products.fold<double>(0,
        (double total, Product product) => total + product.calculateProfit());

    final double averageProfit = totalProfit / products.length;

    final DateTime now = DateTime.now();
    final int highProfitCount = products
        .where((Product product) => product.calculateProfit() >= 1000)
        .length;

    final int lowProfitCount = products
        .where((Product product) => product.calculateProfit() < 1000)
        .length;

    final int recentCount = products.where((Product product) {
      final int daysSinceAdded = now.difference(product.savedAt).inDays;
      return daysSinceAdded <= 7;
    }).length;

    final int oldCount = products.where((Product product) {
      final int daysSinceAdded = now.difference(product.savedAt).inDays;
      return daysSinceAdded > 30;
    }).length;

    return <String, dynamic>{
      'totalValue': totalValue,
      'totalProfit': totalProfit,
      'averageProfit': averageProfit,
      'highProfitCount': highProfitCount,
      'lowProfitCount': lowProfitCount,
      'recentCount': recentCount,
      'oldCount': oldCount,
    };
  }
}
