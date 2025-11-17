import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/app_event_bus.dart';
import '../widgets/product_filters.dart';
import 'riverpod/shared_types.dart';
import 'riverpod/stream_product_riverpod_provider.dart';

// Constant for undefined values in copyWith
const Object _undefined = Object();

/// Riverpod provider for product list state
final StateNotifierProvider<ProductListNotifier, ProductListState>
    productListStateProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>(
  ProductListNotifier.new,
  dependencies: <ProviderOrFamily>[productsControllerProvider],
);

/// Riverpod provider for filtered products
final Provider<List<Product>> filteredProductsProvider =
    Provider<List<Product>>(
  (ProviderRef<List<Product>> ref) {
    final ProductListState productListState =
        ref.watch(productListStateProvider);
    return productListState.filteredProducts;
  },
  dependencies: <ProviderOrFamily>[productListStateProvider],
);

/// Riverpod provider for product loading state
final Provider<bool> productLoadingProvider = Provider<bool>(
  (ProviderRef<bool> ref) {
    final ProductListState productListState =
        ref.watch(productListStateProvider);
    return productListState.isLoading;
  },
  dependencies: <ProviderOrFamily>[productListStateProvider],
);

/// Riverpod provider for product deletion state
final Provider<bool> productDeletingProvider = Provider<bool>(
  (ProviderRef<bool> ref) {
    final ProductListState productListState =
        ref.watch(productListStateProvider);
    return productListState.isDeleting;
  },
  dependencies: <ProviderOrFamily>[productListStateProvider],
);

/// Riverpod provider for search query
final StateProvider<String> searchQueryProvider =
    StateProvider<String>((StateProviderRef<String> ref) => '');

/// Riverpod provider for advanced filters visibility
final StateProvider<bool> showAdvancedFiltersProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Riverpod provider for expanded product ID
final StateProvider<String?> expandedProductIdProvider =
    StateProvider<String?>((StateProviderRef<String?> ref) => null);

/// Riverpod provider for current filters
final StateProvider<ProductFilters> currentFiltersProvider =
    StateProvider<ProductFilters>(
        (StateProviderRef<ProductFilters> ref) => const ProductFilters());

/// Riverpod provider for scroll controller
final Provider<ScrollController> scrollControllerProvider =
    Provider<ScrollController>((ProviderRef<ScrollController> ref) {
  final ScrollController controller = ScrollController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Riverpod provider for infinite scroll loading
final StateProvider<bool> isLoadingMoreProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Riverpod provider for search debounce timer
final StateProvider<Timer?> searchDebounceProvider =
    StateProvider<Timer?>((StateProviderRef<Timer?> ref) => null);

/// Product list state
class ProductListState {
  const ProductListState({
    this.isInitialized = false,
    this.isLoading = false,
    this.isDeleting = false,
    this.errorMessage,
    this.products = const <Product>[],
    this.filteredProducts = const <Product>[],
    this.searchQuery = '',
    this.showAdvancedFilters = false,
    this.expandedProductId,
    this.currentFilters = const ProductFilters(),
    this.isLoadingMore = false,
  });
  final bool isInitialized;
  final bool isLoading;
  final bool isDeleting;
  final String? errorMessage;
  final List<Product> products;
  final List<Product> filteredProducts;
  final String searchQuery;
  final bool showAdvancedFilters;
  final String? expandedProductId;
  final ProductFilters currentFilters;
  final bool isLoadingMore;

  ProductListState copyWith({
    bool? isInitialized,
    bool? isLoading,
    bool? isDeleting,
    String? errorMessage,
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    bool? showAdvancedFilters,
    Object? expandedProductId = _undefined, // استخدام Object مع قيمة افتراضية
    ProductFilters? currentFilters,
    bool? isLoadingMore,
  }) =>
      ProductListState(
        isInitialized: isInitialized ?? this.isInitialized,
        isLoading: isLoading ?? this.isLoading,
        isDeleting: isDeleting ?? this.isDeleting,
        errorMessage: errorMessage ?? this.errorMessage,
        products: products ?? this.products,
        filteredProducts: filteredProducts ?? this.filteredProducts,
        searchQuery: searchQuery ?? this.searchQuery,
        showAdvancedFilters: showAdvancedFilters ?? this.showAdvancedFilters,
        expandedProductId: expandedProductId == _undefined
            ? this.expandedProductId
            : expandedProductId as String?,
        currentFilters: currentFilters ?? this.currentFilters,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

/// Product list notifier
class ProductListNotifier extends StateNotifier<ProductListState> {
  ProductListNotifier(this._ref) : super(const ProductListState()) {
    _initialize();
  }
  final Ref _ref;
  StreamSubscription<AppEvent>? _eventSubscription;

  void _initialize() {
    _startEventListening();

    // Listen to ProductsController changes for automatic updates
    _ref.listen<ProductsState>(
      productsControllerProvider,
      (ProductsState? previous, ProductsState next) {
        if (mounted && previous != next) {
          debugPrint(
              '🔄 ProductListNotifier: ProductsController changed, updating state...');
          _updateFromController(next);
        }
      },
    );

    // Initialize data after the listener is set up
    Future.microtask(() {
      if (mounted) {
        _loadProducts();
      }
    });
  }

  void _startEventListening() {
    _eventSubscription = AppEventBus.stream.listen((AppEvent event) {
      switch (event.runtimeType) {
        case ProductAddedEvent:
          _handleProductAdded(event as ProductAddedEvent);
          break;
        case ProductUpdatedEvent:
          _handleProductUpdated(event as ProductUpdatedEvent);
          break;
        case ProductDeletedEvent:
          _handleProductDeleted(event as ProductDeletedEvent);
          break;
        case InventoryUpdatedEvent:
          _handleInventoryUpdated(event as InventoryUpdatedEvent);
          break;
        case SaleCompletedEvent:
          _handleSaleCompleted(event as SaleCompletedEvent);
          break;
        case LowStockAlertEvent:
          _handleLowStockAlert(event as LowStockAlertEvent);
          break;
        case StatsUpdatedEvent:
          _handleStatsUpdated(event as StatsUpdatedEvent);
          break;
      }
    });
  }

  void _handleProductAdded(ProductAddedEvent event) {
    if (mounted) _loadProducts();
  }

  void _handleProductUpdated(ProductUpdatedEvent event) {
    if (mounted) _loadProducts();
  }

  void _handleProductDeleted(ProductDeletedEvent event) {
    if (mounted) _loadProducts();
  }

  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    if (mounted) _loadProducts();
  }

  void _handleSaleCompleted(SaleCompletedEvent event) {
    if (mounted) _loadProducts();
  }

  void _handleLowStockAlert(LowStockAlertEvent event) {
    // Handle low stock alert
  }

  void _handleStatsUpdated(StatsUpdatedEvent event) {
    if (mounted) _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    try {
      state = state.copyWith(isLoading: true);

      final ProductsController productsController =
          _ref.read(productsControllerProvider.notifier);
      await productsController.refresh();

      if (!mounted) return;

      // الحصول على جميع المنتجات من ProductsController
      final ProductsState productsState = _ref.read(productsControllerProvider);
      final List<Product> allProducts = productsState.products;
      final List<Product> filteredProducts = productsState.filteredProducts;

      debugPrint('🔄 ProductListNotifier: تم تحميل ${allProducts.length} منتج');
      debugPrint(
          '🔄 ProductListNotifier: المنتجات المفلترة: ${filteredProducts.length}');

      state = state.copyWith(
        isLoading: false,
        products: allProducts,
        filteredProducts:
            filteredProducts.isNotEmpty ? filteredProducts : allProducts,
        isInitialized: true,
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ ProductListNotifier: خطأ في تحميل المنتجات: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Update state from ProductsController without triggering refresh
  void _updateFromController(ProductsState productsState) {
    if (!mounted) return;

    final List<Product> allProducts = productsState.products;
    final List<Product> filteredProducts = productsState.filteredProducts;

    debugPrint(
        '🔄 ProductListNotifier: تحديث من ProductsController - ${allProducts.length} منتج');

    state = state.copyWith(
      products: allProducts,
      filteredProducts:
          filteredProducts.isNotEmpty ? filteredProducts : allProducts,
      isInitialized: true,
      isLoading: productsState.isLoading,
      errorMessage: productsState.errorMessage,
    );
  }

  void updateSearchQuery(String query) {
    if (!mounted) return;
    state = state.copyWith(searchQuery: query);
    _applySearch(query);
  }

  void _applySearch(String query) {
    if (!mounted) return;

    final ProductsController productsController =
        _ref.read(productsControllerProvider.notifier);
    productsController.filterProducts(query);

    if (!mounted) return;

    // الحصول على المنتجات المفلترة من ProductsController
    final ProductsState productsState = _ref.read(productsControllerProvider);
    final List<Product> filteredProducts = productsState.filteredProducts;
    final List<Product> allProducts = productsState.products;

    state = state.copyWith(
      filteredProducts:
          filteredProducts.isNotEmpty ? filteredProducts : allProducts,
    );
  }

  void toggleAdvancedFilters() {
    if (!mounted) return;
    state = state.copyWith(
      showAdvancedFilters: !state.showAdvancedFilters,
    );
  }

  void updateFilters(ProductFilters filters) {
    if (!mounted) return;
    state = state.copyWith(currentFilters: filters);
    _applyFilters(filters);
  }

  void _applyFilters(ProductFilters filters) {
    if (!mounted) return;

    // Apply filters logic here
    final ProductsState productsState = _ref.read(productsControllerProvider);
    final List<Product> filteredProducts = productsState.filteredProducts;
    final List<Product> allProducts = productsState.products;

    if (!mounted) return;

    state = state.copyWith(
      filteredProducts:
          filteredProducts.isNotEmpty ? filteredProducts : allProducts,
    );
  }

  void resetFilters() {
    if (!mounted) return;
    state = state.copyWith(
      currentFilters: const ProductFilters(),
      showAdvancedFilters: false,
      searchQuery: '',
    );

    final ProductsController productsController =
        _ref.read(productsControllerProvider.notifier);
    productsController.resetFilter();

    if (!mounted) return;

    final ProductsState productsState = _ref.read(productsControllerProvider);
    final List<Product> allProducts = productsState.products;
    state = state.copyWith(filteredProducts: allProducts);
  }

  void toggleProductExpansion(String productId) {
    if (!mounted) {
      debugPrint('🔄 toggleProductExpansion: not mounted, skipping');
      return;
    }
    final bool isCurrentlyExpanded = state.expandedProductId == productId;
    debugPrint(
        '🔄 toggleProductExpansion: $productId, currently expanded: $isCurrentlyExpanded');

    // نفس منطق الملف الأصلي: إذا كانت مفتوحة، أغلقها. إذا كانت مغلقة، افتحها
    if (isCurrentlyExpanded) {
      // البطاقة مفتوحة حالياً، أغلقها
      state = state.copyWith(expandedProductId: null);
    } else {
      // البطاقة مغلقة، افتحها (وأغلق أي بطاقة أخرى مفتوحة)
      state = state.copyWith(expandedProductId: productId);
    }

    debugPrint(
        '🔄 toggleProductExpansion: new expandedProductId: ${state.expandedProductId}');
  }

  void applySorting(SortOption option) {
    if (!mounted) return;

    final ProductsController productsController =
        _ref.read(productsControllerProvider.notifier);
    productsController.applySorting(option);

    if (!mounted) return;

    final ProductsState productsState = _ref.read(productsControllerProvider);
    final List<Product> filteredProducts = productsState.filteredProducts;
    final List<Product> allProducts = productsState.products;

    state = state.copyWith(
      filteredProducts:
          filteredProducts.isNotEmpty ? filteredProducts : allProducts,
    );
  }

  Future<void> deleteProduct(String productId) async {
    if (!mounted) return;

    try {
      state = state.copyWith(isDeleting: true);

      final ProductsController productsController =
          _ref.read(productsControllerProvider.notifier);
      final bool success = await productsController.deleteProduct(productId);

      if (success && mounted) {
        await _loadProducts();
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isDeleting: false,
        errorMessage: e.toString(),
      );
    } finally {
      if (mounted) {
        state = state.copyWith(isDeleting: false);
      }
    }
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }

  Future<void> loadMoreProducts() async {
    if (!mounted || state.isLoadingMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      // Simulate loading more products
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // Add more products logic here
    } finally {
      if (mounted) {
        state = state.copyWith(isLoadingMore: false);
      }
    }
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
