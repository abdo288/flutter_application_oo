import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import 'inventory_riverpod_providers.dart';
import 'riverpod/stream_inventory_riverpod_provider.dart' as stream;

// ========== State Model ==========

/// حالة تبويب المخزون (عرض قائمة المخزون)
class InventoryDisplayState {
  const InventoryDisplayState({
    this.isLoading = false,
    this.isDeleting = false,
    this.searchQuery = '',
    this.sortBy = 'name',
    this.sortAscending = true,
    this.expandedItemId,
    this.errorMessage,
    this.isInitialized = false,
  });

  final bool isLoading;
  final bool isDeleting;
  final String searchQuery;
  final String sortBy;
  final bool sortAscending;
  final String? expandedItemId;
  final String? errorMessage;
  final bool isInitialized;

  InventoryDisplayState copyWith({
    bool? isLoading,
    bool? isDeleting,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,
    String? expandedItemId,
    String? errorMessage,
    bool? isInitialized,
  }) =>
      InventoryDisplayState(
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
        expandedItemId: expandedItemId, // Allow explicit null to collapse card
        errorMessage: errorMessage ?? this.errorMessage,
        isInitialized: isInitialized ?? this.isInitialized,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryDisplayState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          isDeleting == other.isDeleting &&
          searchQuery == other.searchQuery &&
          sortBy == other.sortBy &&
          sortAscending == other.sortAscending &&
          expandedItemId == other.expandedItemId &&
          errorMessage == other.errorMessage &&
          isInitialized == other.isInitialized;

  @override
  int get hashCode => Object.hash(
        isLoading,
        isDeleting,
        searchQuery,
        sortBy,
        sortAscending,
        expandedItemId,
        errorMessage,
        isInitialized,
      );
}

// ========== Notifier ==========

/// Notifier لإدارة حالة تبويب المخزون (عرض قائمة المخزون)
class InventoryDisplayNotifier extends StateNotifier<InventoryDisplayState> {
  InventoryDisplayNotifier() : super(const InventoryDisplayState());

  /// تهيئة الحالة
  void initialize() {
    state = state.copyWith(isInitialized: true);
  }

  /// تحديث استعلام البحث
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// تعيين نوع الترتيب
  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  /// تعيين اتجاه الترتيب
  void setSortAscending(bool ascending) {
    state = state.copyWith(sortAscending: ascending);
  }

  /// إعادة تعيين الفلتر
  void resetFilter() {
    state = state.copyWith(searchQuery: '');
  }

  /// إدارة حالة التوسيع للبطاقات
  void handleCardExpansion(String? itemId) {
    state = state.copyWith(expandedItemId: itemId);
  }

  /// تعيين حالة التحميل
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// تعيين حالة الحذف
  void setDeleting(bool deleting) {
    state = state.copyWith(isDeleting: deleting);
  }

  /// تعيين رسالة الخطأ
  void setError(String? error) {
    state = state.copyWith(errorMessage: error);
  }

  /// مسح رسالة الخطأ
  void clearError() {
    state = state.copyWith();
  }
}

// ========== Providers ==========

/// Provider لحالة تبويب المخزون (عرض قائمة المخزون)
final StateNotifierProvider<InventoryDisplayNotifier, InventoryDisplayState>
    inventoryDisplayStateProvider =
    StateNotifierProvider<InventoryDisplayNotifier, InventoryDisplayState>(
        (StateNotifierProviderRef<InventoryDisplayNotifier, InventoryDisplayState>
                ref) =>
            InventoryDisplayNotifier());

/// Provider للمخزون المفلتر والمرتب
/// ✅ إصلاح: ضمان التناسق التام مع ProductFormTab
final Provider<List<InventoryItem>> filteredInventoryProvider =
    Provider<List<InventoryItem>>((ProviderRef<List<InventoryItem>> ref) {
  // استخدام نفس مصدر البيانات مع ProductFormTab لضمان التناسق
  final InventoryDisplayState inventoryDisplayState =
      ref.watch(inventoryDisplayStateProvider);

  // التحقق من أن inventoryControllerProvider مهيأ
  try {
    final stream.InventoryState inventoryState =
        ref.watch(stream.inventoryControllerProvider);

    // التحقق من أن البيانات مهيأة أولاً
    if (!inventoryState.isInitialized) {
      debugPrint('⚠️ filteredInventoryProvider: البيانات غير مهيأة بعد');
      return <InventoryItem>[];
    }

    // استخدام البيانات من inventoryControllerProvider
    final List<InventoryItem> inventoryItems = inventoryState.inventoryItems;
    debugPrint(
        '🔍 filteredInventoryProvider: ${inventoryItems.length} عنصر من inventoryControllerProvider');

    if (inventoryItems.isEmpty) {
      debugPrint(
          '⚠️ filteredInventoryProvider: لا توجد عناصر في inventoryItems');
      return <InventoryItem>[];
    }

    List<InventoryItem> filteredItems =
        List<InventoryItem>.from(inventoryItems);

    // تطبيق البحث مع تحسينات للبحث المتقدم
    if (inventoryDisplayState.searchQuery.isNotEmpty) {
      final String query = inventoryDisplayState.searchQuery.toLowerCase().trim();
      filteredItems = filteredItems.where((InventoryItem item) {
        // البحث في الاسم
        if (item.name.toLowerCase().contains(query)) {
          return true;
        }

        // البحث في الباركود
        if (item.barcode != null &&
            item.barcode!.isNotEmpty &&
            item.barcode!.toLowerCase().contains(query)) {
          return true;
        }

        // البحث في السعر (تحويل السعر إلى نص للبحث)
        if (item.retailPrice.toString().contains(query)) {
          return true;
        }

        return false;
      }).toList();
    }

    // تطبيق الترتيب مع تحسينات
    filteredItems.sort((InventoryItem a, InventoryItem b) {
      int comparison = 0;
      switch (inventoryDisplayState.sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'price':
          comparison = a.retailPrice.compareTo(b.retailPrice);
          break;
        case 'date':
          comparison = a.addedDate.compareTo(b.addedDate);
          break;
        case 'profit':
          // إضافة ترتيب حسب الربح
          final int profitA = a.retailPrice - a.wholesalePrice;
          final int profitB = b.retailPrice - b.wholesalePrice;
          comparison = profitA.compareTo(profitB);
          break;
        default:
          comparison = a.name.compareTo(b.name);
      }

      return inventoryDisplayState.sortAscending ? comparison : -comparison;
    });

    debugPrint(
        '✅ filteredInventoryProvider: تم تطبيق الفلترة والترتيب - ${filteredItems.length} عنصر');
    return filteredItems;
  } catch (e) {
    debugPrint('❌ خطأ في filteredInventoryProvider: $e');
    return <InventoryItem>[];
  }
}, dependencies: <ProviderOrFamily>[
  stream.inventoryControllerProvider,
  inventoryDisplayStateProvider
]);

/// Provider لإحصائيات المخزون
final Provider<Map<String, dynamic>> inventoryStatsProvider =
    Provider<Map<String, dynamic>>((ProviderRef<Map<String, dynamic>> ref) {
  final List<InventoryItem> filteredItems =
      ref.watch(filteredInventoryProvider);

  final int totalItems = filteredItems.length;
  final int outOfStockCount =
      filteredItems.where((InventoryItem item) => item.isOutOfStock()).length;
  final double totalValue = filteredItems.fold<double>(
      0, (double sum, InventoryItem item) => sum + item.getTotalValue());

  return <String, dynamic>{
    'totalItems': totalItems,
    'outOfStockCount': outOfStockCount,
    'totalValue': totalValue,
  };
}, dependencies: <ProviderOrFamily>[filteredInventoryProvider]);

/// Provider للتحقق من وجود عناصر
final Provider<bool> hasInventoryItemsProvider =
    Provider<bool>((ProviderRef<bool> ref) {
  try {
    final stream.InventoryState inventoryState =
        ref.watch(stream.inventoryControllerProvider);

    // التحقق من أن البيانات مهيأة أولاً
    if (!inventoryState.isInitialized) {
      debugPrint('⚠️ hasInventoryItemsProvider: البيانات غير مهيأة بعد');
      return false;
    }

    final bool hasItems = inventoryState.inventoryItems.isNotEmpty;
    debugPrint(
        '🔍 hasInventoryItemsProvider: ${inventoryState.inventoryItems.length} عنصر، hasItems: $hasItems');
    return hasItems;
  } catch (e) {
    debugPrint('❌ خطأ في hasInventoryItemsProvider: $e');
    return false;
  }
}, dependencies: <ProviderOrFamily>[stream.inventoryControllerProvider]);

/// Provider للتحقق من وجود نتائج بعد الفلترة
final Provider<bool> hasFilteredResultsProvider =
    Provider<bool>((ProviderRef<bool> ref) {
  final List<InventoryItem> filteredItems =
      ref.watch(filteredInventoryProvider);
  return filteredItems.isNotEmpty;
}, dependencies: <ProviderOrFamily>[filteredInventoryProvider]);

/// Provider لإحصائيات المخزون المفلتر
final Provider<Map<String, dynamic>> filteredInventoryStatsProvider =
    Provider<Map<String, dynamic>>((ProviderRef<Map<String, dynamic>> ref) {
  final List<InventoryItem> filteredItems =
      ref.watch(filteredInventoryProvider);

  final int totalItems = filteredItems.length;
  final int outOfStockCount =
      filteredItems.where((InventoryItem item) => item.isOutOfStock()).length;
  final double totalValue = filteredItems.fold<double>(
      0, (double sum, InventoryItem item) => sum + item.getTotalValue());

  return <String, dynamic>{
    'totalItems': totalItems,
    'outOfStockCount': outOfStockCount,
    'totalValue': totalValue,
  };
}, dependencies: <ProviderOrFamily>[filteredInventoryProvider]);

/// Provider لتنظيف البيانات
final FutureProvider<void> cleanupInventoryDataProvider =
    FutureProvider<void>((FutureProviderRef<void> ref) async {
  try {
    // تنظيف البيانات الخاطئة
    debugPrint('🔄 تحديث المخزون - الـ provider يتولى التحديث تلقائياً');
    // يمكن إضافة منطق تنظيف إضافي هنا
  } catch (e) {
    debugPrint('❌ خطأ في تنظيف البيانات: $e');
    rethrow;
  }
});

/// Provider لاختبار تحميل البيانات
final FutureProvider<Map<String, dynamic>> testDataLoadingProvider =
    FutureProvider<Map<String, dynamic>>(
        (FutureProviderRef<Map<String, dynamic>> ref) async {
  try {
    debugPrint('🧪 بدء اختبار تحميل البيانات...');

    // إعادة تحميل البيانات
    ref.invalidate(inventoryItemsProvider);

    final List<InventoryItem> inventoryItems = ref.read(inventoryItemsProvider);
    final int totalCount = inventoryItems.length;
    final int filteredCount = ref.read(filteredInventoryProvider).length;

    debugPrint('📊 نتائج الاختبار:');
    debugPrint('   - إجمالي العناصر: $totalCount');
    debugPrint('   - العناصر المفلترة: $filteredCount');

    return <String, dynamic>{
      'totalCount': totalCount,
      'filteredCount': filteredCount,
      'success': true,
    };
  } catch (e) {
    debugPrint('❌ خطأ في اختبار تحميل البيانات: $e');
    return <String, dynamic>{
      'error': e.toString(),
      'success': false,
    };
  }
});

// ملاحظة: تم حذف deleteInventoryItemProvider و updateInventoryItemProvider
// لأنه يسبب مشكلة Riverpod (Providers are not allowed to modify other providers during their initialization)
// بدلاً من ذلك، نستخدم inventoryControllerProvider.notifier مباشرة

/// Provider لإعادة تحميل المخزون
final FutureProvider<void> refreshInventoryProvider =
    FutureProvider<void>((FutureProviderRef<void> ref) async {
  try {
    ref.invalidate(inventoryItemsProvider);
    debugPrint('🔄 تم إعادة تحميل المخزون بنجاح');
  } catch (e) {
    debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
    rethrow;
  }
});
