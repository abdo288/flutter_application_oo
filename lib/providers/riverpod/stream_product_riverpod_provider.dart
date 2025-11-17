import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:profit_calculator/database/drift_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../models/product.dart';
import '../../providers/auth_riverpod_providers.dart';
import '../../repositories/unified_repository.dart';
import '../../services/app_event_bus.dart';
import '../../utils/compute_helpers.dart';
import 'shared_types.dart';

part 'stream_product_riverpod_provider.g.dart';

/// State class للمنتجات
class ProductsState {
  const ProductsState({
    required this.products,
    required this.filteredProducts,
    this.isLoading = false,
    this.isDeleting = false,
    this.errorMessage,
    this.sortOption = SortOption.dateDesc,
    this.filterOption = FilterOption.all,
    this.searchQuery = '',
    this.isInitialized = false,
    this.minProfit = 0,
    this.maxProfit = 1000000,
    this.searchCache = const <String, List<Product>>{},
    this.cacheHits = 0,
    this.cacheMisses = 0,
  });

  factory ProductsState.initial() => const ProductsState(
        products: <Product>[],
        filteredProducts: <Product>[],
      );
  final List<Product> products;
  final List<Product> filteredProducts;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;
  final SortOption sortOption;
  final FilterOption filterOption;
  final String searchQuery;
  final bool isInitialized;
  final double minProfit;
  final double maxProfit;
  final Map<String, List<Product>> searchCache;
  final int cacheHits;
  final int cacheMisses;

  ProductsState copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    SortOption? sortOption,
    FilterOption? filterOption,
    String? searchQuery,
    bool? isInitialized,
    double? minProfit,
    double? maxProfit,
    Map<String, List<Product>>? searchCache,
    int? cacheHits,
    int? cacheMisses,
  }) =>
      ProductsState(
        products: products ?? this.products,
        filteredProducts: filteredProducts ?? this.filteredProducts,
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        errorMessage: errorMessage,
        sortOption: sortOption ?? this.sortOption,
        filterOption: filterOption ?? this.filterOption,
        searchQuery: searchQuery ?? this.searchQuery,
        isInitialized: isInitialized ?? this.isInitialized,
        minProfit: minProfit ?? this.minProfit,
        maxProfit: maxProfit ?? this.maxProfit,
        searchCache: searchCache ?? this.searchCache,
        cacheHits: cacheHits ?? this.cacheHits,
        cacheMisses: cacheMisses ?? this.cacheMisses,
      );

  int get productCount => products.length;

  double getTotalValue() => products.fold<double>(
      0, (double total, Product product) => total + product.retailPrice);

  double getTotalProfit() => products.fold<double>(
      0, (double total, Product product) => total + product.calculateProfit());
}

/// UnifiedRepository Provider
@riverpod
UnifiedRepository unifiedRepository(UnifiedRepositoryRef ref) =>
    UnifiedRepository();

/// Products Stream Provider
@riverpod
Stream<List<Product>> productsStream(ProductsStreamRef ref) {
  final UnifiedRepository repository = ref.watch(unifiedRepositoryProvider);
  return repository.productsStream;
}

/// Products Controller الرئيسي
@riverpod
class ProductsController extends _$ProductsController {
  StreamSubscription<List<Product>>? _productsSubscription;
  Timer? _updateDebounceTimer;
  Timer? _searchDebounceTimer;
  Timer? _filterDebounceTimer;
  bool _isBatchingUpdates = false;
  int _updateCount = 0;
  DateTime? _lastUpdateTime;

  static const int _maxCacheSize = 100;

  @override
  ProductsState build() {
    // ✅ التحقق من مفتاح الأمان
    final bool streamsEnabled = ref.watch(userStreamsEnabledProvider);

    // ✅ الاستماع لتغييرات المصادقة
    ref.listen<AuthState>(authStateProvider, (AuthState? previous, AuthState next) {
      if (!next.isAuthenticated && previous?.isAuthenticated == true) {
        // تسجيل الخروج تم - إلغاء جميع الاشتراكات
        debugPrint('🚪 تسجيل الخروج تم - إلغاء اشتراكات المنتجات');
        _productsSubscription?.cancel();
        _productsSubscription = null;
      }
    });

    // ✅ إذا كان المفتاح متوقفاً، لا تقم بإعداد الـ listeners
    if (streamsEnabled) {
      _setupListeners();
    } else {
      debugPrint('🔒 Streams معطلة - تخطي إعداد listeners للمنتجات');
    }

    ref.onDispose(() {
      _productsSubscription?.cancel();
      _updateDebounceTimer?.cancel();
      _searchDebounceTimer?.cancel();
      _filterDebounceTimer?.cancel();
      debugPrint(
          '🗑️ تم تنظيف ProductsController (Firestore subscription مغلق)');
    });

    return ProductsState.initial();
  }

  /// إعداد المستمعين
  /// ✅ تحديث: إضافة الاستماع للأحداث للتحديثات الفورية
  void _setupListeners() {
    final UnifiedRepository repository = ref.read(unifiedRepositoryProvider);

    // ✅ الاستماع لـ stream الموحد مع platform thread safety
    _productsSubscription = repository.productsStream.listen(
      (List<Product> products) {
        if (!_isBatchingUpdates) {
          _isBatchingUpdates = true;
          // ✅ استخدام Future.microtask لضمان التنفيذ على platform thread
          Future.microtask(() {
            _updateProducts(products);
            _isBatchingUpdates = false;
          });
        }
      },
      onError: (Object error) {
        debugPrint('❌ خطأ في stream المنتجات: $error');
        state = state.copyWith(
          errorMessage: error.toString(),
          isLoading: false,
        );
        _isBatchingUpdates = false;
      },
      cancelOnError: false,
    );

    // ✅ إضافة الاستماع للأحداث للتحديثات الفورية
    _setupEventListeners();

    debugPrint('✅ تم إعداد listener للمنتجات (Firestore → Local DB → UI)');
  }

  /// إعداد الاستماع للأحداث
  void _setupEventListeners() {
    // الاستماع لأحداث المنتجات
    AppEventBus.stream.listen((AppEvent event) {
      switch (event.runtimeType) {
        case ProductAddedEvent:
        case ProductUpdatedEvent:
        case ProductDeletedEvent:
          debugPrint('🔄 ProductsController: استلام حدث ${event.runtimeType}');
          // إعادة تحميل البيانات من Firestore
          _refreshFromFirestore();
          break;
        case InventoryUpdatedEvent:
          // تحديث المنتجات عند تغيير المخزون
          debugPrint('🔄 ProductsController: حدث تحديث المخزون');
          _refreshFromFirestore();
          break;
      }
    });
  }

  /// إعادة تحميل البيانات من Firestore
  Future<void> _refreshFromFirestore() async {
    try {
      debugPrint('🔄 ProductsController: إعادة تحميل البيانات من Firestore...');
      await ref.read(unifiedRepositoryProvider).syncFromFirestore();
      debugPrint('✅ ProductsController: تم إعادة تحميل البيانات بنجاح');
    } catch (e) {
      debugPrint('❌ ProductsController: خطأ في إعادة تحميل البيانات: $e');
    }
  }

  /// معالجة تحديث المنتجات
  void _updateProducts(List<Product> products) {
    _updateCount++;
    _lastUpdateTime = DateTime.now();

    debugPrint(
        '🔄 تحديث المنتجات: ${products.length} منتج (تحديث #$_updateCount)');

    state = state.copyWith(
      products: products,
      isInitialized: true,
      isLoading: false,
    );

    _applyFiltersAndSort();
  }

  // ❌ تم إزالة: _handleCrossTabEvent - لم نعد نحتاجه، Firestore يتولى كل شيء

  /// تحديث المنتجات يدوياً
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    try {
      debugPrint('🔄 إعادة تحميل بيانات المنتجات...');
      await ref.read(unifiedRepositoryProvider).syncFromFirestore();
      debugPrint('✅ تم إعادة تحميل بيانات المنتجات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المنتجات: $e');
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  /// إعادة تحميل البيانات من قاعدة البيانات المحلية
  Future<void> _loadProducts() async {
    try {
      final UnifiedRepository repository = ref.read(unifiedRepositoryProvider);
      final List<ProductsTableData> items =
          await repository.localDb.getAllProducts();
      final List<Product> products = items
          .map((ProductsTableData item) => Product(
                id: item.id,
                name: item.name,
                wholesalePrice: item.wholesalePrice,
                retailPrice: item.retailPrice,
                savedAt: DateTime.parse(item.savedAt),
              ))
          .toList();
      state = state.copyWith(products: products);
      _applyFiltersAndSort();
      debugPrint('✅ تم إعادة تحميل المنتجات: ${products.length} منتج');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تحميل المنتجات: $e');
    }
  }

  /// إضافة منتج جديد
  Future<String?> addProduct(Product product) async {
    try {
      final String productId =
          product.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final Product newProduct =
          product.copyWith(id: productId, isSynced: false);

      // Optimistic UI (اختياري - Firestore listener سيحدث UI تلقائياً)
      final List<Product> updatedProducts = <Product>[
        ...state.products,
        newProduct
      ];
      state = state.copyWith(products: updatedProducts);
      _applyFiltersAndSort();

      // ✅ حفظ في Firestore مباشرة (Repository يتولى المزامنة)
      await ref.read(unifiedRepositoryProvider).addProduct(newProduct);

      // ❌ إزالة: CrossTabSyncService.notifyDataChanged - Firestore يتولى الإشعارات

      debugPrint('✅ تم إضافة المنتج بنجاح: $productId');
      return productId;
    } catch (e) {
      debugPrint('❌ خطأ في إضافة المنتج: $e');
      state = state.copyWith(errorMessage: e.toString());
      await _loadProducts();
      return null;
    }
  }

  /// تحديث منتج موجود
  Future<bool> updateProduct(Product product) async {
    Product? originalProduct;
    try {
      final int index =
          state.products.indexWhere((Product p) => p.id == product.id);
      originalProduct = index != -1 ? state.products[index] : null;

      if (index != -1) {
        // Optimistic UI (اختياري - Firestore listener سيحدث UI تلقائياً)
        final List<Product> updatedProducts = <Product>[...state.products];
        updatedProducts[index] = product.copyWith(isSynced: false);
        state = state.copyWith(products: updatedProducts);
        _applyFiltersAndSort();
      }

      // ✅ حفظ في Firestore مباشرة (Repository يتولى المزامنة)
      await ref.read(unifiedRepositoryProvider).updateProduct(product);

      // ❌ إزالة: CrossTabSyncService.notifyDataChanged - Firestore يتولى الإشعارات

      debugPrint('✅ تم تحديث المنتج بنجاح: ${product.id}');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في تحديث المنتج: $e');
      state = state.copyWith(errorMessage: e.toString());

      // استعادة النسخة الأصلية
      if (originalProduct != null) {
        final int index =
            state.products.indexWhere((Product p) => p.id == product.id);
        if (index != -1) {
          final List<Product> updatedProducts = <Product>[...state.products];
          updatedProducts[index] = originalProduct;
          state = state.copyWith(products: updatedProducts);
          _applyFiltersAndSort();
        }
      }
      return false;
    }
  }

  /// حذف منتج
  Future<bool> deleteProduct(String productId) async {
    try {
      state = state.copyWith(isDeleting: true);

      // Optimistic UI (اختياري - Firestore listener سيحدث UI تلقائياً)
      final List<Product> updatedProducts =
          state.products.where((Product p) => p.id != productId).toList();
      state = state.copyWith(products: updatedProducts, isDeleting: false);
      _applyFiltersAndSort();

      // ✅ حذف من Firestore مباشرة (Repository يتولى المزامنة)
      await ref.read(unifiedRepositoryProvider).deleteProduct(productId);

      // ❌ إزالة: CrossTabSyncService.notifyDataChanged - Firestore يتولى الإشعارات

      debugPrint('✅ تم حذف المنتج بنجاح: $productId');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتج: $e');
      state = state.copyWith(errorMessage: e.toString(), isDeleting: false);
      await _loadProducts();
      return false;
    }
  }

  /// التحقق من وجود منتج بالاسم
  Future<bool> checkIfProductNameExists(String name) async =>
      state.products.any((Product product) =>
          product.name.toLowerCase() == name.toLowerCase());

  /// البحث عن منتج بالاسم
  Product? findProductByName(String name) {
    try {
      return state.products
          .firstWhere((Product product) => product.name == name);
    } catch (e) {
      return null;
    }
  }

  /// البحث عن منتج بالمعرف
  Product? findProductById(String id) {
    try {
      return state.products.firstWhere((Product product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// التحقق من وجود منتج بالمعرف
  bool productExists(String id) =>
      state.products.any((Product product) => product.id == id);

  /// تطبيق البحث مع debouncing
  void filterProducts(String criteria) {
    _searchDebounceTimer?.cancel();

    if (criteria.trim().isEmpty) {
      state = state.copyWith(searchQuery: '');
      _applyFiltersAndSort();
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(searchQuery: criteria.trim());
      _applyFiltersAndSort();
    });
  }

  /// فلترة المنتجات بالتاريخ
  void filterProductsByDate(DateTime date) {
    final List<Product> filtered = state.products
        .where((Product product) =>
            product.savedAt.year == date.year &&
            product.savedAt.month == date.month &&
            product.savedAt.day == date.day)
        .toList();
    state = state.copyWith(filteredProducts: filtered);
  }

  /// تطبيق فلتر متقدم
  void applyAdvancedFilter(FilterOption filter,
      {double? minProfit, double? maxProfit}) {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      state = state.copyWith(
        filterOption: filter,
        minProfit: minProfit ?? state.minProfit,
        maxProfit: maxProfit ?? state.maxProfit,
      );
      _applyFiltersAndSort();
    });
  }

  /// تطبيق ترتيب
  void applySorting(SortOption sort) {
    _filterDebounceTimer?.cancel();
    _filterDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      state = state.copyWith(sortOption: sort);
      _applyFiltersAndSort();
    });
  }

  /// تطبيق جميع الفلاتر والترتيب
  Future<void> _applyFiltersAndSort() async {
    try {
      // إنشاء مفتاح Cache
      final String cacheKey =
          '${state.searchQuery}_${state.filterOption}_${state.sortOption}_${state.minProfit}_${state.maxProfit}';

      // التحقق من Cache
      if (state.searchCache.containsKey(cacheKey)) {
        state = state.copyWith(
          filteredProducts: state.searchCache[cacheKey]!,
          cacheHits: state.cacheHits + 1,
        );
        debugPrint('📦 Cache Hit: ${state.filteredProducts.length} منتج');
        return;
      }

      // تطبيق الفلاتر
      final List<Product> filtered = await ComputeHelpers.filterAndSortProducts(
        products: state.products,
        searchText: state.searchQuery,
        filter: state.filterOption,
        sortOption: state.sortOption,
        minProfit: state.minProfit,
        maxProfit: state.maxProfit,
      );

      // حفظ في Cache
      final Map<String, List<Product>> updatedCache =
          Map<String, List<Product>>.from(state.searchCache);
      if (updatedCache.length >= _maxCacheSize) {
        updatedCache.remove(updatedCache.keys.first);
      }
      updatedCache[cacheKey] = filtered;

      state = state.copyWith(
        filteredProducts: filtered,
        searchCache: updatedCache,
        cacheMisses: state.cacheMisses + 1,
      );

      debugPrint(
          '✅ تم تطبيق الفلاتر: ${filtered.length} منتج من أصل ${state.products.length}');
    } catch (e) {
      debugPrint('❌ خطأ في تطبيق الفلاتر: $e');
      state = state.copyWith(filteredProducts: <Product>[...state.products]);
    }
  }

  /// إعادة تعيين الفلاتر
  void resetFilter() {
    try {
      debugPrint('🔄 إعادة تعيين الفلاتر...');

      _searchDebounceTimer?.cancel();
      _filterDebounceTimer?.cancel();
      _updateDebounceTimer?.cancel();

      state = state.copyWith(
        searchQuery: '',
        sortOption: SortOption.dateDesc,
        filterOption: FilterOption.all,
        minProfit: 0,
        maxProfit: 1000000,
        searchCache: <String, List<Product>>{},
        cacheHits: 0,
        cacheMisses: 0,
      );

      _applyFiltersAndSort();

      // معالجة خاصة لـ Windows
      if (Platform.isWindows &&
          state.filteredProducts.isEmpty &&
          state.products.isNotEmpty) {
        debugPrint('🪟 Windows: إعادة تحميل البيانات...');
        _loadProducts();
      }

      debugPrint('✅ تم إعادة تعيين الفلاتر بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين الفلاتر: $e');
      state = state.copyWith(filteredProducts: <Product>[...state.products]);
    }
  }

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      debugPrint('🔄 إعادة تعيين حالة المزامنة للمنتجات...');
      await ref.read(unifiedRepositoryProvider).resetSyncState();
      await _loadProducts();
      debugPrint('✅ تم إعادة تعيين حالة المزامنة للمنتجات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// مسح Cache يدوياً
  void clearCache() {
    state = state.copyWith(
      searchCache: <String, List<Product>>{},
      cacheHits: 0,
      cacheMisses: 0,
    );
    debugPrint('🧹 تم مسح Cache البحث');
  }

  /// الحصول على إحصائيات Cache
  Map<String, dynamic> getCacheStats() => <String, dynamic>{
        'cacheSize': state.searchCache.length,
        'maxCacheSize': _maxCacheSize,
        'cacheHits': state.cacheHits,
        'cacheMisses': state.cacheMisses,
        'cacheHitRate': state.cacheHits + state.cacheMisses > 0
            ? '${((state.cacheHits / (state.cacheHits + state.cacheMisses)) * 100).toStringAsFixed(1)}%'
            : '0%',
      };

  /// الحصول على إحصائيات Stream
  Map<String, dynamic> getStreamStats() => <String, dynamic>{
        'updateCount': _updateCount,
        'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
        'isBatchingUpdates': _isBatchingUpdates,
        'subscriptions': <String, bool>{
          'products': _productsSubscription != null,
          // ❌ تم إزالة: crossTab subscription
        },
      };
}

/// Helper Providers
@riverpod
List<Product> filteredProducts(FilteredProductsRef ref) =>
    ref.watch(productsControllerProvider).filteredProducts;

@riverpod
bool productLoadingProvider(ProductLoadingProviderRef ref) =>
    ref.watch(productsControllerProvider).isLoading;

@riverpod
bool productDeletingProvider(ProductDeletingProviderRef ref) =>
    ref.watch(productsControllerProvider).isDeleting;

@riverpod
int productCount(ProductCountRef ref) =>
    ref.watch(productsControllerProvider).productCount;
