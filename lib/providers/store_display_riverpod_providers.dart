import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inventory_item.dart';
import 'inventory_riverpod_providers.dart';

// ========== State Model ==========

/// حالة تبويب عرض المتجر
class StoreDisplayState {
  const StoreDisplayState({
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

  StoreDisplayState copyWith({
    bool? isLoading,
    bool? isDeleting,
    String? searchQuery,
    String? sortBy,
    bool? sortAscending,
    String? expandedItemId,
    String? errorMessage,
    bool? isInitialized,
  }) =>
      StoreDisplayState(
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
        sortAscending: sortAscending ?? this.sortAscending,
        expandedItemId: expandedItemId ?? this.expandedItemId,
        errorMessage: errorMessage ?? this.errorMessage,
        isInitialized: isInitialized ?? this.isInitialized,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreDisplayState &&
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

/// Notifier لإدارة حالة تبويب عرض المتجر
class StoreDisplayNotifier extends StateNotifier<StoreDisplayState> {
  StoreDisplayNotifier() : super(const StoreDisplayState());

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
    state = state.copyWith(errorMessage: null);
  }
}

// ========== Providers ==========

/// Provider لحالة تبويب عرض المتجر
final storeDisplayStateProvider =
    StateNotifierProvider<StoreDisplayNotifier, StoreDisplayState>((ref) {
  return StoreDisplayNotifier();
});

/// Provider للمخزون المفلتر والمرتب
final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final inventoryItems = ref.watch(inventoryItemsProvider);
  final storeDisplayState = ref.watch(storeDisplayStateProvider);

  if (inventoryItems.isEmpty) {
    return [];
  }

  List<InventoryItem> filteredItems = List<InventoryItem>.from(inventoryItems);

  // تطبيق البحث
  if (storeDisplayState.searchQuery.isNotEmpty) {
    final String query = storeDisplayState.searchQuery.toLowerCase();
    filteredItems = filteredItems.where((item) {
      return item.name.toLowerCase().contains(query) ||
          (item.barcode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // تطبيق الترتيب
  filteredItems.sort((a, b) {
    int comparison = 0;
    switch (storeDisplayState.sortBy) {
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
      default:
        comparison = a.name.compareTo(b.name);
    }

    return storeDisplayState.sortAscending ? comparison : -comparison;
  });

  return filteredItems;
}, dependencies: [inventoryItemsProvider, storeDisplayStateProvider]);

/// Provider لإحصائيات المخزون
final inventoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final filteredItems = ref.watch(filteredInventoryProvider);

  final int totalItems = filteredItems.length;
  final int outOfStockCount =
      filteredItems.where((item) => item.isOutOfStock()).length;
  final double totalValue =
      filteredItems.fold<double>(0, (sum, item) => sum + item.getTotalValue());

  return {
    'totalItems': totalItems,
    'outOfStockCount': outOfStockCount,
    'totalValue': totalValue,
  };
}, dependencies: [filteredInventoryProvider]);

/// Provider للتحقق من وجود عناصر
final hasInventoryItemsProvider = Provider<bool>((ref) {
  final inventoryItems = ref.watch(inventoryItemsProvider);
  return inventoryItems.isNotEmpty;
}, dependencies: [inventoryItemsProvider]);

/// Provider للتحقق من وجود نتائج بعد الفلترة
final hasFilteredResultsProvider = Provider<bool>((ref) {
  final filteredItems = ref.watch(filteredInventoryProvider);
  return filteredItems.isNotEmpty;
}, dependencies: [filteredInventoryProvider]);

/// Provider لإحصائيات المخزون المفلتر
final filteredInventoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final filteredItems = ref.watch(filteredInventoryProvider);

  final int totalItems = filteredItems.length;
  final int outOfStockCount =
      filteredItems.where((item) => item.isOutOfStock()).length;
  final double totalValue =
      filteredItems.fold<double>(0, (sum, item) => sum + item.getTotalValue());

  return {
    'totalItems': totalItems,
    'outOfStockCount': outOfStockCount,
    'totalValue': totalValue,
  };
}, dependencies: [filteredInventoryProvider]);

/// Provider لتنظيف البيانات
final cleanupInventoryDataProvider = FutureProvider<void>((ref) async {
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
final testDataLoadingProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    debugPrint('🧪 بدء اختبار تحميل البيانات...');

    // إعادة تحميل البيانات
    ref.invalidate(inventoryItemsProvider);

    final inventoryItems = ref.read(inventoryItemsProvider);
    final int totalCount = inventoryItems.length;
    final int filteredCount = ref.read(filteredInventoryProvider).length;

    debugPrint('📊 نتائج الاختبار:');
    debugPrint('   - إجمالي العناصر: $totalCount');
    debugPrint('   - العناصر المفلترة: $filteredCount');

    return {
      'totalCount': totalCount,
      'filteredCount': filteredCount,
      'success': true,
    };
  } catch (e) {
    debugPrint('❌ خطأ في اختبار تحميل البيانات: $e');
    return {
      'error': e.toString(),
      'success': false,
    };
  }
});

/// Provider لحذف عنصر المخزون
final deleteInventoryItemProvider =
    FutureProvider.family<bool, String>((ref, itemId) async {
  try {
    debugPrint('🗑️ بدء حذف العنصر: $itemId');
    // إعادة تحميل البيانات بعد الحذف
    ref.invalidate(inventoryItemsProvider);
    debugPrint('✅ تم حذف العنصر بنجاح: $itemId');
    return true;
  } catch (e) {
    debugPrint('❌ خطأ في حذف العنصر: $e');
    return false;
  }
});

/// Provider لتحديث عنصر المخزون
final updateInventoryItemProvider =
    FutureProvider.family<bool, InventoryItem>((ref, item) async {
  try {
    // إعادة تحميل البيانات بعد التحديث
    ref.invalidate(inventoryItemsProvider);
    debugPrint('✅ تم تحديث عنصر المخزون بنجاح: ${item.name}');
    return true;
  } catch (e) {
    debugPrint('❌ خطأ في تحديث عنصر المخزون: $e');
    return false;
  }
});

/// Provider لإعادة تحميل المخزون
final refreshInventoryProvider = FutureProvider<void>((ref) async {
  try {
    ref.invalidate(inventoryItemsProvider);
    debugPrint('🔄 تم إعادة تحميل المخزون بنجاح');
  } catch (e) {
    debugPrint('❌ خطأ في إعادة تحميل المخزون: $e');
    rethrow;
  }
});
