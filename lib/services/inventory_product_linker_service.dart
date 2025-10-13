import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';

/// خدمة ربط بيانات المخزون بالمنتجات
class InventoryProductLinkerService {
  factory InventoryProductLinkerService() => _instance;
  InventoryProductLinkerService._internal();
  static final InventoryProductLinkerService _instance =
      InventoryProductLinkerService._internal();

  /// ربط بيانات المخزون بالمنتج
  static ProductLinkData? linkInventoryToProduct({
    required Product product,
    required List<InventoryItem> inventoryItems,
  }) {
    try {
      // البحث عن عنصر المخزون المطابق للمنتج
      final InventoryItem? matchingItem = _findMatchingInventoryItem(
        product: product,
        inventoryItems: inventoryItems,
      );

      if (matchingItem == null) {
        debugPrint(
            '⚠️ لم يتم العثور على عنصر مخزون مطابق للمنتج: ${product.name}');
        return null;
      }

      return ProductLinkData(
        product: product,
        inventoryItem: matchingItem,
        linkedWholesalePrice: matchingItem.wholesalePrice,
        linkedQuantity: matchingItem.quantity,
        linkedOriginalQuantity: matchingItem.originalQuantity,
        isLinked: true,
      );
    } catch (e) {
      debugPrint('❌ خطأ في ربط بيانات المخزون بالمنتج: $e');
      return null;
    }
  }

  /// البحث عن عنصر المخزون المطابق للمنتج
  static InventoryItem? _findMatchingInventoryItem({
    required Product product,
    required List<InventoryItem> inventoryItems,
  }) {
    try {
      // البحث بالاسم أولاً (الأكثر دقة)
      final InventoryItem? matchByName = inventoryItems
          .where((InventoryItem item) =>
              item.name.toLowerCase().trim() ==
              product.name.toLowerCase().trim())
          .firstOrNull;

      if (matchByName != null) {
        debugPrint('✅ تم العثور على مطابق بالاسم: ${matchByName.name}');
        return matchByName;
      }

      // البحث بالباركود إذا كان متوفراً
      if (product.barcode != null && product.barcode!.isNotEmpty) {
        final InventoryItem? matchByBarcode = inventoryItems
            .where((InventoryItem item) => item.barcode == product.barcode)
            .firstOrNull;

        if (matchByBarcode != null) {
          debugPrint('✅ تم العثور على مطابق بالباركود: ${matchByBarcode.name}');
          return matchByBarcode;
        }
      }

      // البحث الجزئي بالاسم (أقل دقة)
      final InventoryItem? matchByPartialName = inventoryItems
          .where((InventoryItem item) => _isPartialMatch(item.name, product.name))
          .firstOrNull;

      if (matchByPartialName != null) {
        debugPrint(
            '✅ تم العثور على مطابق جزئي بالاسم: ${matchByPartialName.name}');
        return matchByPartialName;
      }

      return null;
    } catch (e) {
      debugPrint('❌ خطأ في البحث عن عنصر المخزون المطابق: $e');
      return null;
    }
  }

  /// التحقق من التطابق الجزئي للأسماء
  static bool _isPartialMatch(String inventoryName, String productName) {
    final String cleanInventory = inventoryName.toLowerCase().trim();
    final String cleanProduct = productName.toLowerCase().trim();

    // التحقق من أن أحد الأسماء يحتوي على الآخر
    return cleanInventory.contains(cleanProduct) ||
        cleanProduct.contains(cleanInventory);
  }

  /// ربط جميع المنتجات ببيانات المخزون
  static List<ProductLinkData> linkAllProductsWithInventory({
    required List<Product> products,
    required List<InventoryItem> inventoryItems,
  }) {
    try {
      final List<ProductLinkData> linkedData = <ProductLinkData>[];

      for (final Product product in products) {
        final ProductLinkData? linkData = linkInventoryToProduct(
          product: product,
          inventoryItems: inventoryItems,
        );

        if (linkData != null) {
          linkedData.add(linkData);
        } else {
          // إضافة المنتج بدون ربط
          linkedData.add(ProductLinkData(
            product: product,
            linkedWholesalePrice: product.wholesalePrice,
            linkedQuantity: 0,
            linkedOriginalQuantity: 0,
            isLinked: false,
          ));
        }
      }

      debugPrint(
          '✅ تم ربط ${linkedData.where((ProductLinkData data) => data.isLinked).length} منتج من أصل ${products.length}');
      return linkedData;
    } catch (e) {
      debugPrint('❌ خطأ في ربط جميع المنتجات: $e');
      return <ProductLinkData>[];
    }
  }

  /// تحديث سعر الجملة في المنتج من بيانات المخزون
  static Product updateProductWholesalePrice({
    required Product product,
    required int newWholesalePrice,
  }) => product.copyWith(wholesalePrice: newWholesalePrice);

  /// الحصول على إحصائيات الربط
  static LinkStatistics getLinkStatistics({
    required List<Product> products,
    required List<InventoryItem> inventoryItems,
  }) {
    try {
      final List<ProductLinkData> linkedData = linkAllProductsWithInventory(
        products: products,
        inventoryItems: inventoryItems,
      );

      final int linkedCount = linkedData.where((ProductLinkData data) => data.isLinked).length;
      final int unlinkedCount =
          linkedData.where((ProductLinkData data) => !data.isLinked).length;
      final int totalInventoryValue = linkedData
          .where((ProductLinkData data) => data.isLinked)
          .fold<int>(
              0,
              (int total, ProductLinkData data) =>
                  total + (data.linkedWholesalePrice * data.linkedQuantity));

      return LinkStatistics(
        totalProducts: products.length,
        totalInventoryItems: inventoryItems.length,
        linkedProducts: linkedCount,
        unlinkedProducts: unlinkedCount,
        linkPercentage:
            products.isNotEmpty ? (linkedCount / products.length) * 100 : 0.0,
        totalInventoryValue: totalInventoryValue,
      );
    } catch (e) {
      debugPrint('❌ خطأ في حساب إحصائيات الربط: $e');
      return const LinkStatistics(
        totalProducts: 0,
        totalInventoryItems: 0,
        linkedProducts: 0,
        unlinkedProducts: 0,
        linkPercentage: 0.0,
        totalInventoryValue: 0,
      );
    }
  }
}

/// بيانات ربط المنتج بالمخزون
class ProductLinkData {

  const ProductLinkData({
    required this.product,
    this.inventoryItem,
    required this.linkedWholesalePrice,
    required this.linkedQuantity,
    required this.linkedOriginalQuantity,
    required this.isLinked,
  });
  final Product product;
  final InventoryItem? inventoryItem;
  final int linkedWholesalePrice;
  final int linkedQuantity;
  final int linkedOriginalQuantity;
  final bool isLinked;

  /// الحصول على الكمية المتبقية
  int get remainingQuantity => linkedQuantity;

  /// التحقق من نفاد الكمية
  bool get isOutOfStock => linkedQuantity <= 0;

  /// حساب القيمة الإجمالية للمخزون
  int get totalValue => linkedWholesalePrice * linkedQuantity;

  /// حساب نسبة الربح المحدثة
  double get updatedProfitPercentage {
    if (linkedWholesalePrice <= 0) return 0.0;
    return ((product.retailPrice - linkedWholesalePrice) /
            linkedWholesalePrice) *
        100;
  }
}

/// إحصائيات الربط
class LinkStatistics {

  const LinkStatistics({
    required this.totalProducts,
    required this.totalInventoryItems,
    required this.linkedProducts,
    required this.unlinkedProducts,
    required this.linkPercentage,
    required this.totalInventoryValue,
  });
  final int totalProducts;
  final int totalInventoryItems;
  final int linkedProducts;
  final int unlinkedProducts;
  final double linkPercentage;
  final int totalInventoryValue;

  /// التحقق من وجود منتجات غير مربوطة
  bool get hasUnlinkedProducts => unlinkedProducts > 0;

  /// الحصول على نسبة الربط كنص
  String get linkPercentageText => '${linkPercentage.toStringAsFixed(1)}%';
}
