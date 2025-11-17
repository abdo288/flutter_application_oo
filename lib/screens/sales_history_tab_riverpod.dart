import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/modern_edit_product_dialog.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../providers/product_list_riverpod_providers.dart';
import '../providers/realtime_update_manager.dart';
import '../providers/riverpod/shared_types.dart';
import '../utils/constants.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_boundary.dart';
import '../widgets/product_analytics_simple.dart';
import '../widgets/product_card.dart';
import '../widgets/product_filters.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/windows_product_card.dart';

/// تبويب سجل المبيعات المحسن مع Riverpod
class SalesHistoryTabRiverpod extends ConsumerStatefulWidget {
  const SalesHistoryTabRiverpod({super.key});

  @override
  ConsumerState<SalesHistoryTabRiverpod> createState() =>
      _SalesHistoryTabRiverpodState();
}

class _SalesHistoryTabRiverpodState
    extends ConsumerState<SalesHistoryTabRiverpod>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // تهيئة Animation Controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      debugPrint('🔄 ProductListTabRiverpod: بدء تهيئة البيانات...');

      // تأكد من أن العملية تتم بعد انتهاء البناء الحالي
      await Future<void>.delayed(const Duration(milliseconds: 100));

      if (mounted) {
        try {
          debugPrint('🪟 Windows: إعادة تحميل البيانات...');
          // استخدام SchedulerBinding لتجنب استدعاء ref.read في build
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // استخدام Future.microtask لتجنب build scheduling errors
              Future.microtask(() {
                if (mounted) {
                  ref.read(productListStateProvider.notifier).refreshProducts();
                  debugPrint(
                      '✅ تم جلب بيانات المنتجات في ProductListTabRiverpod');
                }
              });
            }
          });
        } catch (e) {
          debugPrint('❌ خطأ في إعادة تحميل البيانات: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المنتجات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProductListState productListState =
        ref.watch(productListStateProvider);
    final bool isLoading = ref.watch(productLoadingProvider);
    final bool isDeleting = ref.watch(productDeletingProvider);
    final List<Product> products = ref.watch(filteredProductsProvider);
    final bool showAdvancedFilters = ref.watch(showAdvancedFiltersProvider);
    final String? expandedProductId = ref.watch(productListStateProvider
        .select((ProductListState state) => state.expandedProductId));
    final ProductFilters currentFilters = ref.watch(currentFiltersProvider);
    final ScrollController scrollController =
        ref.watch(scrollControllerProvider);

    // إزالة debug prints من build method لتجنب مشاكل الأداء

    return Stack(
      children: <Widget>[
        ErrorBoundary(
          onError: (Object error, StackTrace stackTrace) {
            debugPrint('❌ خطأ في ProductListTab: $error');
          },
          child: _buildContent(
            productListState,
            isLoading,
            isDeleting,
            products,
            showAdvancedFilters,
            expandedProductId,
            currentFilters,
            scrollController,
          ),
        ),
        // مؤشر التحديثات الفورية
        Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final bool isConnected = ref.watch(isConnectedProvider);
            final String? error = ref.watch(updateErrorProvider);

            if (!isConnected && error == null) return const SizedBox.shrink();

            return Positioned(
              top: 60,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: error != null
                      ? Colors.red.withOpacity(0.9)
                      : isConnected
                          ? Colors.green.withOpacity(0.9)
                          : Colors.orange.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      error != null
                          ? Icons.error_outline
                          : isConnected
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      error != null
                          ? 'خطأ'
                          : isConnected
                              ? 'محدث'
                              : 'غير متصل',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildContent(
    ProductListState productListState,
    bool isLoading,
    bool isDeleting,
    List<Product> products,
    bool showAdvancedFilters,
    String? expandedProductId,
    ProductFilters currentFilters,
    ScrollController scrollController,
  ) {
    if (!productListState.isInitialized) {
      return _buildShimmerLoading();
    }

    // التحقق من حالة الحذف
    if (isDeleting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري حذف المنتج...'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppConstants.primaryColor,
      backgroundColor: Colors.white,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildMainContent(
            products,
            showAdvancedFilters,
            expandedProductId,
            currentFilters,
            scrollController,
          ),
        ),
      ),
    );
  }

  /// بناء المحتوى الرئيسي
  Widget _buildMainContent(
    List<Product> products,
    bool showAdvancedFilters,
    String? expandedProductId,
    ProductFilters currentFilters,
    ScrollController scrollController,
  ) =>
      CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: <Widget>[
          // شريط البحث والفلترة
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    AppConstants.primaryColor.withValues(alpha: 0.03),
                    AppConstants.secondaryColor.withValues(alpha: 0.02),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: ProductSearchBar(
                onSearchChanged: _handleSearchChanged,
                onSortPressed: _showSortOptions,
                onFilterPressed: _toggleAdvancedFilters,
                onResetPressed: _resetFilters,
              ),
            ),
          ),

          // الفلاتر المتقدمة (قابلة للطي)
          if (showAdvancedFilters)
            SliverToBoxAdapter(
              child: ProductFiltersWidget(
                onFiltersChanged: _handleFiltersChanged,
              ),
            ),

          // تحليلات المنتجات (قابلة للطي)
          if (products.isNotEmpty)
            SliverToBoxAdapter(
              child: ProductAnalyticsSimple(
                products: products,
                onCategorySelected: _handleCategorySelected,
                onSupplierSelected: _handleSupplierSelected,
              ),
            ),

          // قائمة المنتجات
          _buildProductListSliver(products, expandedProductId),

          // مؤشر التحميل للـ infinite scroll
          if (ref.watch(isLoadingMoreProvider))
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Column(
                    children: <Widget>[
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppConstants.primaryColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'جاري تحميل المزيد...',
                        style: TextStyle(
                          color: AppConstants.lightTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );

  /// بناء قائمة المنتجات محسنة مع Riverpod
  Widget _buildProductListSliver(
      List<Product> products, String? expandedProductId) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return _buildProductGridSliver(
          products, screenWidth >= 800 ? 3 : 2, expandedProductId);
    } else {
      return _buildCompactGridSliver(products, expandedProductId);
    }
  }

  /// بناء شبكة المنتجات كـ Sliver
  Widget _buildProductGridSliver(
      List<Product> products, int crossAxisCount, String? expandedProductId) {
    if (Platform.isWindows) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (index >= products.length) {
                return const SizedBox.shrink();
              }

              final Product product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: WindowsProductCard(
                  key: ValueKey('product_${product.id}_$index'),
                  product: product,
                  onEdit: () => _handleProductEdit(product),
                  onDelete: () => _handleProductDelete(product),
                  onTap: () => _handleProductTap(product),
                  isExpanded: expandedProductId == product.id,
                  onExpansionChanged: (bool isExpanded) =>
                      _handleCardExpansion(product.id ?? '', isExpanded),
                ),
              );
            },
            childCount: products.length,
          ),
        ),
      );
    } else {
      return SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 3 ? 0.7 : 0.8,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (index >= products.length) {
                return const SizedBox.shrink();
              }

              final Product product = products[index];
              return _MemoizedProductCard(
                key: ValueKey('product_${product.id}_$index'),
                product: product,
                onTap: () => _handleProductTap(product),
                onEdit: () => _handleProductEdit(product),
                onDelete: () => _handleProductDelete(product),
              );
            },
            childCount: products.length,
          ),
        ),
      );
    }
  }

  /// بناء قائمة المنتجات المضغوطة كـ Sliver
  Widget _buildCompactGridSliver(
          List<Product> products, String? expandedProductId) =>
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              if (index >= products.length) {
                return const SizedBox.shrink();
              }

              final Product product = products[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Platform.isWindows
                    ? WindowsProductCard(
                        product: product,
                        onEdit: () => _handleProductEdit(product),
                        onDelete: () => _handleProductDelete(product),
                        onTap: () => _handleProductTap(product),
                        isExpanded: expandedProductId == product.id,
                        onExpansionChanged: (bool isExpanded) =>
                            _handleCardExpansion(product.id ?? '', isExpanded),
                      )
                    : ProductCard(
                        product: product,
                        onEdit: () => _handleProductEdit(product),
                        onDelete: () => _handleProductDelete(product),
                      ),
              );
            },
            childCount: products.length,
          ),
        ),
      );

  /// بناء حالة فارغة
  Widget _buildEmptyState() => EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: AppLocalizations.of(context).noProducts,
        message: 'ابدأ بإضافة منتجات جديدة لإدارة مخزونك',
        subtitle: 'يمكنك إضافة منتج جديد من خلال النقر على الزر أدناه',
      );

  // ========== معالجات الأحداث ==========

  /// البحث مع debouncing محسن لتحسين الأداء
  void _handleSearchChanged(String query) {
    if (!mounted) return;

    // إلغاء البحث السابق
    final Timer? currentTimer = ref.read(searchDebounceProvider);
    currentTimer?.cancel();

    // ✅ تحسين Debouncing - تقليل المدة لتحسين الاستجابة
    final Timer newTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(productListStateProvider.notifier).updateSearchQuery(query);

        // ✅ إضافة animation للبحث مع تحسين
        _fadeController.reset();
        _fadeController.forward();

        // ✅ إظهار مؤشر البحث إذا كان النص طويلاً
        if (query.length > 2) {
          _showSearchIndicator();
        }
      }
    });

    if (mounted) {
      ref.read(searchDebounceProvider.notifier).state = newTimer;
    }
  }

  /// إظهار مؤشر البحث
  void _showSearchIndicator() {
    if (mounted) {
      SnackbarUtils.showInfo(context, 'جاري البحث...');
    }
  }

  void _handleFiltersChanged(ProductFilters filters) {
    if (!mounted) return;
    ref.read(productListStateProvider.notifier).updateFilters(filters);
  }

  void _handleCategorySelected(String category) {
    debugPrint('تم اختيار الفئة: $category');
  }

  void _handleSupplierSelected(String supplier) {
    debugPrint('تم اختيار المورد: $supplier');
  }

  void _handleProductTap(Product product) {
    if (!mounted) return;

    debugPrint('تم النقر على المنتج: ${product.name}');

    // فقط عرض تفاصيل المنتج، لا نفتح نافذة التعديل
    // يمكن إضافة عرض تفاصيل المنتج هنا لاحقاً
  }

  void _handleProductEdit(Product product) {
    _showEditProductDialog(product);
  }

  void _handleProductDelete(Product product) {
    _confirmDeleteProduct(product);
  }

  void _handleCardExpansion(String productId, bool isExpanded) {
    if (!mounted) return;
    debugPrint('🔄 _handleCardExpansion: $productId, isExpanded: $isExpanded');

    // استخدام toggleProductExpansion الذي يحتوي على المنطق الصحيح
    ref
        .read(productListStateProvider.notifier)
        .toggleProductExpansion(productId);
  }

  // ========== طرق مساعدة ==========

  void _showSortOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'خيارات الترتيب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            ...SortOption.values.map((SortOption option) => ListTile(
                  leading: Icon(_getSortIcon(option)),
                  title: Text(_getSortLabel(option)),
                  onTap: () {
                    Navigator.pop(context);
                    _applySorting(option);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _toggleAdvancedFilters() {
    if (!mounted) return;
    ref.read(showAdvancedFiltersProvider.notifier).state =
        !ref.read(showAdvancedFiltersProvider);
  }

  void _resetFilters() {
    if (!mounted) return;
    ref.read(productListStateProvider.notifier).resetFilters();

    // ✅ إعادة تشغيل الـ animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  void _applySorting(SortOption option) {
    if (!mounted) return;
    ref.read(productListStateProvider.notifier).applySorting(option);
  }

  void _showEditProductDialog(Product product) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModernEditProductDialog(
        product: product,
        onProductUpdated: () {
          debugPrint('تم تحديث المنتج: ${product.name}');
          // إعادة تحميل البيانات
          ref.read(productListStateProvider.notifier).refreshProducts();
        },
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeleteConfirmationDialog(
        title: 'حذف المنتج',
        message:
            'هل تريد حذف "${product.name}"؟\nهذا الإجراء لا يمكن التراجع عنه.',
        onConfirm: () {},
      ),
    );

    if (confirmed == true) {
      await _deleteProduct(product);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (product.id == null) return;

    try {
      await ref
          .read(productListStateProvider.notifier)
          .deleteProduct(product.id!);

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم حذف "${product.name}" بنجاح');
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتج: $e');
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في حذف المنتج: $e');
      }
    }
  }

  /// Pull-to-refresh مع animation
  Future<void> _onRefresh() async {
    if (!mounted) return;

    try {
      // إعادة تشغيل الـ animations
      _fadeController.reset();
      _slideController.reset();

      await ref.read(productListStateProvider.notifier).refreshProducts();

      if (mounted) {
        // إعادة تشغيل الـ animations
        _fadeController.forward();
        _slideController.forward();
      }

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم تحديث البيانات بنجاح');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في التحديث: $e');
      }
    }
  }

  // ========== طرق مساعدة للترتيب ==========

  IconData _getSortIcon(SortOption option) {
    switch (option) {
      case SortOption.nameAsc:
      case SortOption.nameDesc:
        return Icons.sort_by_alpha;
      case SortOption.priceAsc:
      case SortOption.priceDesc:
        return Icons.attach_money;
      case SortOption.profitAsc:
      case SortOption.profitDesc:
        return Icons.trending_up;
      case SortOption.dateAsc:
      case SortOption.dateDesc:
        return Icons.calendar_today;
    }
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.nameAsc:
        return 'الاسم (أ-ي)';
      case SortOption.nameDesc:
        return 'الاسم (ي-أ)';
      case SortOption.priceAsc:
        return 'السعر (منخفض-عالي)';
      case SortOption.priceDesc:
        return 'السعر (عالي-منخفض)';
      case SortOption.profitAsc:
        return 'الربح (منخفض-عالي)';
      case SortOption.profitDesc:
        return 'الربح (عالي-منخفض)';
      case SortOption.dateAsc:
        return 'التاريخ (قديم-جديد)';
      case SortOption.dateDesc:
        return 'التاريخ (جديد-قديم)';
    }
  }

  /// بناء Shimmer Loading للحالة الأولية
  Widget _buildShimmerLoading() => CustomScrollView(
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppConstants.spacing12,
                crossAxisSpacing: AppConstants.spacing12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => const ShimmerCard(
                  height: 200,
                ),
                childCount: 6,
              ),
            ),
          ),
        ],
      );
}

/// بطاقة منتج محسنة مع memorization
class _MemoizedProductCard extends StatelessWidget {
  const _MemoizedProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Platform.isWindows
      ? WindowsProductCard(
          product: product,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        )
      : ProductCard(
          product: product,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
        );
}
