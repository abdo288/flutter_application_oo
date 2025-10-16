import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/inventory_item.dart';
import '../providers/stream_product_provider.dart';
import '../providers/stream_inventory_provider.dart';

/// Stream App Provider للـ Riverpod
class StreamAppNotifier extends StateNotifier<StreamAppState> {
  final StreamProductProvider _productProvider = StreamProductProvider();
  final StreamInventoryProvider _inventoryProvider = StreamInventoryProvider();

  StreamSubscription<Map<String, dynamic>>? _syncStatusSubscription;

  StreamAppNotifier() : super(const StreamAppState());

  /// تهيئة التطبيق
  Future<void> initialize() async {
    if (state.isInitialized) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      debugPrint('🚀 بدء تهيئة StreamAppNotifier...');

      // تهيئة providers بالتوازي
      await Future.wait([
        _productProvider.initialize(),
        _inventoryProvider.initialize(),
      ]);

      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );

      debugPrint('✅ تم تهيئة StreamAppNotifier بنجاح');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تهيئة التطبيق: $e',
      );
      debugPrint('❌ خطأ في تهيئة StreamAppNotifier: $e');
    }
  }

  /// تحديث جميع البيانات
  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await Future.wait<void>([
        _productProvider.refresh(),
        _inventoryProvider.refresh(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطأ في تحديث البيانات: $e',
      );
    }
  }

  /// إغلاق الموارد
  @override
  void dispose() {
    _syncStatusSubscription?.cancel();
    _productProvider.dispose();
    _inventoryProvider.dispose();
    super.dispose();
  }
}

/// حالة التطبيق
class StreamAppState {
  final bool isInitialized;
  final bool isLoading;
  final String? errorMessage;

  const StreamAppState({
    this.isInitialized = false,
    this.isLoading = false,
    this.errorMessage,
  });

  StreamAppState copyWith({
    bool? isInitialized,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StreamAppState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ========== Riverpod Providers ==========

/// Provider للتطبيق الرئيسي
final streamAppProvider =
    StateNotifierProvider<StreamAppNotifier, StreamAppState>((ref) {
  return StreamAppNotifier();
});

/// Provider للمنتجات
final streamProductProvider = Provider<StreamProductProvider>((ref) {
  return StreamProductProvider();
});

/// Provider للمخزون
final streamInventoryProvider = Provider<StreamInventoryProvider>((ref) {
  return StreamInventoryProvider();
});

/// Provider لتهيئة التطبيق
final streamAppInitializationProvider = FutureProvider<void>((ref) async {
  final streamAppNotifier = ref.read(streamAppProvider.notifier);
  await streamAppNotifier.initialize();
});

/// Provider للمنتجات كـ Stream
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  final productProvider = ref.watch(streamProductProvider);
  return Stream.value(productProvider.products);
});

/// Provider للمخزون كـ Stream
final inventoryStreamProvider = StreamProvider<List<InventoryItem>>((ref) {
  final inventoryProvider = ref.watch(streamInventoryProvider);
  return Stream.value(inventoryProvider.inventoryItems);
});

/// Provider للبحث عن منتج بالاسم
final findProductByNameProvider =
    FutureProvider.family<Product?, String>((ref, name) async {
  final productProvider = ref.read(streamProductProvider);

  // البحث في المنتجات أولاً
  final products = productProvider.products;
  final product = products.firstWhere(
    (Product p) => p.name.toLowerCase() == name.toLowerCase(),
    orElse: () => throw StateError('Product not found'),
  );

  return product;
});

/// Provider للبحث عن منتج بالباركود
final findProductByBarcodeProvider =
    FutureProvider.family<Product?, String>((ref, barcode) async {
  final productProvider = ref.read(streamProductProvider);

  // البحث في المنتجات أولاً
  final products = productProvider.products;
  final product = products.firstWhere(
    (Product p) => p.barcode == barcode,
    orElse: () => throw StateError('Product not found'),
  );

  return product;
});

/// Provider للحصول على الكمية المتاحة
final getAvailableQuantityProvider =
    FutureProvider.family<int, String>((ref, barcode) async {
  final inventoryProvider = ref.read(streamInventoryProvider);
  final inventory = inventoryProvider.inventoryItems;
  final item = inventory.firstWhere(
    (InventoryItem item) => item.barcode == barcode,
    orElse: () => throw StateError('Item not found'),
  );
  return item.quantity;
});

/// Provider للحصول على الكمية المتاحة بالاسم
final getAvailableQuantityByNameProvider =
    FutureProvider.family<int, String>((ref, name) async {
  final inventoryProvider = ref.read(streamInventoryProvider);
  final inventory = inventoryProvider.inventoryItems;
  final item = inventory.firstWhere(
    (InventoryItem item) => item.name.toLowerCase() == name.toLowerCase(),
    orElse: () => throw StateError('Item not found'),
  );
  return item.quantity;
});

/// Provider لتقليل كمية المخزون
final decreaseInventoryQuantityProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final inventoryProvider = ref.read(streamInventoryProvider);
  final String barcode = params['barcode'] as String;
  final int quantity = params['quantity'] as int;

  final inventory = inventoryProvider.inventoryItems;
  final item = inventory.firstWhere(
    (InventoryItem item) => item.barcode == barcode,
    orElse: () => throw StateError('Item not found'),
  );

  final updatedItem = item.copyWith(quantity: item.quantity - quantity);
  await inventoryProvider.updateInventoryItem(updatedItem);
});

/// Provider لتقليل كمية المخزون بالاسم
final decreaseInventoryQuantityByNameProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final inventoryProvider = ref.read(streamInventoryProvider);
  final String name = params['name'] as String;
  final int quantity = params['quantity'] as int;

  final inventory = inventoryProvider.inventoryItems;
  final item = inventory.firstWhere(
    (InventoryItem item) => item.name.toLowerCase() == name.toLowerCase(),
    orElse: () => throw StateError('Item not found'),
  );

  final updatedItem = item.copyWith(quantity: item.quantity - quantity);
  await inventoryProvider.updateInventoryItem(updatedItem);
});

/// Provider لزيادة كمية المخزون
final increaseInventoryQuantityProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final inventoryProvider = ref.read(streamInventoryProvider);
  final String barcode = params['barcode'] as String;
  final int quantity = params['quantity'] as int;

  final inventory = inventoryProvider.inventoryItems;
  final item = inventory.firstWhere(
    (InventoryItem item) => item.barcode == barcode,
    orElse: () => throw StateError('Item not found'),
  );

  final updatedItem = item.copyWith(quantity: item.quantity + quantity);
  await inventoryProvider.updateInventoryItem(updatedItem);
});

/// Provider لزيادة كمية المخزون بالاسم
final increaseInventoryQuantityByNameProvider =
    FutureProvider.family<void, Map<String, dynamic>>((ref, params) async {
  final inventoryProvider = ref.read(streamInventoryProvider);
  final String name = params['name'] as String;
  final int quantity = params['quantity'] as int;

  final inventory = inventoryProvider.inventoryItems;
  final item = inventory.firstWhere(
    (InventoryItem item) => item.name.toLowerCase() == name.toLowerCase(),
    orElse: () => throw StateError('Item not found'),
  );

  final updatedItem = item.copyWith(quantity: item.quantity + quantity);
  await inventoryProvider.updateInventoryItem(updatedItem);
});
