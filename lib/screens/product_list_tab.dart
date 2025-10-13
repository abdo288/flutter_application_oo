import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../dialogs/delete_confirmation_dialog.dart';
import '../dialogs/modern_edit_product_dialog.dart';
import '../l10n/app_localizations.dart';
import '../models/product.dart';
import '../providers/stream_app_provider.dart';
import '../providers/stream_product_provider.dart';
// ✅ إضافة الخدمات الجديدة
import '../services/app_event_bus.dart';
import '../utils/constants.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/error_boundary.dart';
import '../widgets/product_analytics_simple.dart';
import '../widgets/product_card.dart';
import '../widgets/windows_product_card.dart';
import '../widgets/product_filters.dart';
import '../widgets/product_search_bar.dart';
import '../widgets/shimmer_loading.dart';

/// تبويب قائمة المنتجات المحسن
class ProductListTab extends StatefulWidget {
  const ProductListTab({super.key});

  @override
  State<ProductListTab> createState() => _ProductListTabState();
}

class _ProductListTabState extends State<ProductListTab>
    with TickerProviderStateMixin {
  bool _showAdvancedFilters = false;
  ProductFilters _currentFilters = const ProductFilters();

  // متغيرات التحسينات الجديدة
  Timer? _searchDebounceTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _isDeleting = false;

  // إدارة حالة التوسيع للبطاقات
  String? _expandedProductId;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ✅ إدارة الأحداث
  StreamSubscription<AppEvent>? _eventSubscription;

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

    // إعداد ScrollController للـ infinite scroll
    _scrollController.addListener(_onScroll);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _initializeData();
      _fadeController.forward();
      _slideController.forward();

      // ✅ بدء الاستماع للأحداث
      _startEventListening();
    });
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();

    // ✅ إيقاف الاستماع للأحداث
    _eventSubscription?.cancel();

    super.dispose();
  }

  /// تهيئة البيانات عند فتح التبويب
  /// ✅ بدء الاستماع للأحداث
  void _startEventListening() {
    _eventSubscription = AppEventBus.stream.listen((event) {
      if (!mounted) return;

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
        default:
          debugPrint(
              '📨 حدث غير معالج في ProductListTab: ${event.runtimeType}');
      }
    });
  }

  /// ✅ معالجة إضافة منتج جديد
  void _handleProductAdded(ProductAddedEvent event) {
    debugPrint('📦 معالجة إضافة منتج في ProductListTab: ${event.product.name}');

    // تحديث القائمة
    _refreshProductList();

    // إظهار إشعار
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ تمت إضافة "${event.product.name}"'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ معالجة تحديث منتج
  void _handleProductUpdated(ProductUpdatedEvent event) {
    debugPrint('✏️ معالجة تحديث منتج في ProductListTab: ${event.product.name}');

    // تحديث القائمة
    _refreshProductList();

    // إظهار إشعار
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✏️ تم تحديث "${event.product.name}"'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ معالجة حذف منتج
  void _handleProductDeleted(ProductDeletedEvent event) {
    debugPrint('🗑️ معالجة حذف منتج في ProductListTab: ${event.productName}');

    // تحديث القائمة
    _refreshProductList();

    // إظهار إشعار
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ تم حذف "${event.productName}"'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ معالجة تحديث المخزون
  void _handleInventoryUpdated(InventoryUpdatedEvent event) {
    debugPrint('📦 معالجة تحديث المخزون في ProductListTab: ${event.itemName}');

    // تحديث القائمة للتأكد من تحديث الكميات
    _refreshProductList();
  }

  /// ✅ معالجة إتمام بيع
  void _handleSaleCompleted(SaleCompletedEvent event) {
    debugPrint(
        '💰 معالجة إتمام بيع في ProductListTab: ${event.sale.totalAmount}');

    // تحديث القائمة للتأكد من تحديث الكميات
    _refreshProductList();
  }

  /// ✅ معالجة تنبيه مخزون منخفض
  void _handleLowStockAlert(LowStockAlertEvent event) {
    debugPrint(
        '⚠️ معالجة تنبيه مخزون منخفض في ProductListTab: ${event.itemName}');

    // إظهار تنبيه
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ مخزون منخفض: ${event.itemName}'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'عرض',
          textColor: Colors.white,
          onPressed: () {
            // تطبيق فلتر المخزون المنخفض
            _applyLowStockFilter();
          },
        ),
      ),
    );
  }

  /// ✅ معالجة تحديث الإحصائيات
  void _handleStatsUpdated(StatsUpdatedEvent event) {
    debugPrint('📊 معالجة تحديث الإحصائيات في ProductListTab');

    // تحديث القائمة
    _refreshProductList();
  }

  /// ✅ تحديث قائمة المنتجات
  void _refreshProductList() {
    if (!mounted) return;

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamProductProvider productProvider = appProvider.productProvider;

      // إعادة تحميل البيانات
      productProvider.refresh();

      debugPrint('🔄 تم تحديث قائمة المنتجات');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث قائمة المنتجات: $e');
    }
  }

  /// ✅ تطبيق فلتر المخزون المنخفض
  void _applyLowStockFilter() {
    setState(() {
      // تطبيق فلتر المخزون المنخفض باستخدام فلتر الربح
      _currentFilters = _currentFilters.copyWith(
        profitRange:
            'low_stock', // استخدام profitRange للدلالة على المخزون المنخفض
      );
    });

    // تطبيق الفلتر
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    final StreamProductProvider productProvider = appProvider.productProvider;

    // استخدام الطريقة الصحيحة لتطبيق الفلاتر
    productProvider.filterProducts('low_stock');
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();

      // تحسين خاص بـ Windows - إعادة تحميل البيانات
      if (Platform.isWindows) {
        debugPrint('🪟 Windows: إعادة تحميل البيانات...');
        await appProvider.refreshAll();
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      if (appProvider.isInitialized) {
        debugPrint('🔄 تم جلب بيانات المنتجات في ProductListTab');
      }
    } catch (e) {
      debugPrint('❌ خطأ في جلب بيانات المنتجات: $e');
    }
  }

  /// معالج الـ infinite scroll
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  /// إدارة حالة التوسيع للبطاقات (أكورديون)
  void _handleCardExpansion(String productId, bool isExpanded) {
    setState(() {
      if (isExpanded) {
        // إذا تم فتح بطاقة، أغلق الباقي
        _expandedProductId = productId;
      } else {
        // إذا تم إغلاق بطاقة، لا توجد بطاقة مفتوحة
        _expandedProductId = null;
      }
    });
  }

  /// تحميل المزيد من المنتجات
  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;

    // استخدام SchedulerBinding لتجنب استدعاء setState أثناء البناء
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }
    });

    try {
      // محاكاة تحميل المزيد من البيانات
      await Future<void>.delayed(const Duration(milliseconds: 500));

      // هنا يمكن إضافة منطق تحميل المزيد من المنتجات
      debugPrint('🔄 تحميل المزيد من المنتجات...');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المزيد من المنتجات: $e');
    } finally {
      if (mounted) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  /// Pull-to-refresh مع animation
  Future<void> _onRefresh() async {
    try {
      // إعادة تشغيل الـ animations
      _fadeController.reset();
      _slideController.reset();

      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      await appProvider.refreshAll();

      // إعادة تشغيل الـ animations
      _fadeController.forward();
      _slideController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث البيانات بنجاح'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('خطأ في التحديث: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => ErrorBoundary(
        onError: (error, stackTrace) {
          debugPrint('❌ خطأ في ProductListTab: $error');
        },
        child: Consumer<StreamAppProvider>(
          builder: (context, appProvider, child) {
            if (!appProvider.isInitialized) {
              return _buildShimmerLoading();
            }

            final productProvider = appProvider.productProvider;

            // التحقق من حالة الحذف
            if (_isDeleting || productProvider.isDeleting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري حذف المنتج...'),
                  ],
                ),
              );
            }
            final products = productProvider.filteredProducts;

            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppConstants.primaryColor,
              backgroundColor: Colors.white,
              strokeWidth: 2.5,
              displacement: 40,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildMainContent(products, productProvider),
                ),
              ),
            );
          },
        ),
      );

  /// بناء المحتوى الرئيسي
  Widget _buildMainContent(
          List<Product> products, StreamProductProvider provider) =>
      CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // شريط البحث والفلترة
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
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
          if (_showAdvancedFilters)
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
          _buildProductListSliver(products),

          // مؤشر التحميل للـ infinite scroll
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: Column(
                    children: [
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

  /// ✅ بناء قائمة المنتجات محسنة مع Selector
  Widget _buildProductListSliver(List<Product> products) {
    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    // استخدام MediaQuery بدلاً من LayoutBuilder لتجنب مشكلة RenderSliver
    final double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 600) {
      return _buildProductGridSliver(products, screenWidth >= 800 ? 3 : 2);
    } else {
      return _buildCompactGridSliver(products);
    }
  }

  /// بناء شبكة المنتجات كـ Sliver
  Widget _buildProductGridSliver(List<Product> products, int crossAxisCount) {
    if (Platform.isWindows) {
      // لـ Windows: استخدام SliverList مع Padding للتحكم في الارتفاع
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index >= products.length) {
                return const SizedBox.shrink();
              }

              final product = products[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Selector<StreamProductProvider, Product>(
                  selector: (_, provider) => provider.products.firstWhere(
                    (p) => p.id == product.id,
                    orElse: () => product,
                  ),
                  builder: (_, selectedProduct, __) => WindowsProductCard(
                    key: ValueKey('product_${selectedProduct.id}_$index'),
                    product: selectedProduct,
                    onEdit: () => _handleProductEdit(selectedProduct),
                    onDelete: () => _handleProductDelete(selectedProduct),
                    onTap: () => _handleProductTap(selectedProduct),
                    showActions: true,
                    compactMode: false,
                    isExpanded: _expandedProductId == selectedProduct.id,
                    onExpansionChanged: (isExpanded) => _handleCardExpansion(
                        selectedProduct.id ?? '', isExpanded),
                  ),
                ),
              );
            },
            childCount: products.length,
          ),
        ),
      );
    } else {
      // للمنصات الأخرى: استخدام SliverGrid العادي
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
            (context, index) {
              if (index >= products.length) {
                return const SizedBox.shrink();
              }

              final product = products[index];
              return Selector<StreamProductProvider, Product>(
                selector: (_, provider) => provider.products.firstWhere(
                  (p) => p.id == product.id,
                  orElse: () => product,
                ),
                builder: (_, selectedProduct, __) => _MemoizedProductCard(
                  key: ValueKey('product_${selectedProduct.id}_$index'),
                  product: selectedProduct,
                  onTap: () => _handleProductTap(selectedProduct),
                  onEdit: () => _handleProductEdit(selectedProduct),
                  onDelete: () => _handleProductDelete(selectedProduct),
                  showActions: true,
                  compactMode: false,
                ),
              );
            },
            childCount: products.length,
          ),
        ),
      );
    }
  }

  /// بناء قائمة المنتجات المضغوطة كـ Sliver
  Widget _buildCompactGridSliver(List<Product> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= products.length) {
              return const SizedBox.shrink();
            }

            final product = products[index];

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 400 + (index * 50)),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Selector<StreamProductProvider, Product>(
                  selector: (_, provider) => provider.products.firstWhere(
                    (p) => p.id == product.id,
                    orElse: () => product,
                  ),
                  builder: (_, selectedProduct, __) => Platform.isWindows
                      ? WindowsProductCard(
                          product: selectedProduct,
                          onEdit: () => _handleProductEdit(selectedProduct),
                          onDelete: () => _handleProductDelete(selectedProduct),
                          onTap: () => _handleProductTap(selectedProduct),
                          isExpanded: _expandedProductId == selectedProduct.id,
                          onExpansionChanged: (isExpanded) =>
                              _handleCardExpansion(
                                  selectedProduct.id ?? '', isExpanded),
                        )
                      : ProductCard(
                          product: selectedProduct,
                          onEdit: () => _handleProductEdit(selectedProduct),
                          onDelete: () => _handleProductDelete(selectedProduct),
                        ),
                ),
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

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
    // إلغاء البحث السابق
    _searchDebounceTimer?.cancel();

    // ✅ تحسين Debouncing - تقليل المدة لتحسين الاستجابة
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        final StreamAppProvider appProvider = context.read<StreamAppProvider>();
        final StreamProductProvider provider = appProvider.productProvider;

        // ✅ تطبيق البحث مع Optimistic UI
        provider.filterProducts(query);

        // ✅ إضافة animation للبحث مع تحسين
        _fadeController.reset();
        _fadeController.forward();

        // ✅ إظهار مؤشر البحث إذا كان النص طويلاً
        if (query.length > 2) {
          _showSearchIndicator();
        }
      }
    });
  }

  /// إظهار مؤشر البحث
  void _showSearchIndicator() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              const Text('جاري البحث...'),
            ],
          ),
          duration: const Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppConstants.primaryColor,
        ),
      );
    }
  }

  void _handleFiltersChanged(ProductFilters filters) {
    setState(() {
      _currentFilters = filters;
    });
    // تطبيق الفلاتر على المنتجات
    _applyFilters();
  }

  void _handleCategorySelected(String category) {
    // تطبيق فلتر الفئة
    debugPrint('تم اختيار الفئة: $category');
  }

  void _handleSupplierSelected(String supplier) {
    // تطبيق فلتر المورد
    debugPrint('تم اختيار المورد: $supplier');
  }

  void _handleProductTap(Product product) {
    // عرض تفاصيل المنتج
    debugPrint('تم النقر على المنتج: ${product.name}');
  }

  void _handleProductEdit(Product product) {
    _showEditProductDialog(product);
  }

  void _handleProductDelete(Product product) {
    _confirmDeleteProduct(product);
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
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });
  }

  /// ✅ Reset شامل للفلاتر والبحث والترتيب
  void _resetFilters() {
    setState(() {
      _currentFilters = const ProductFilters();
      _showAdvancedFilters = false;
    });

    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    final StreamProductProvider provider = appProvider.productProvider;

    // ✅ Reset شامل
    provider.resetFilter();

    // ✅ إظهار تأكيد Reset
    _showResetConfirmation();

    // ✅ إعادة تشغيل الـ animations
    _fadeController.reset();
    _slideController.reset();
    _fadeController.forward();
    _slideController.forward();
  }

  /// إظهار تأكيد Reset
  void _showResetConfirmation() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.white),
              const SizedBox(width: 8),
              const Text('تم إعادة تعيين جميع الفلاتر والبحث'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFilters() {
    // تطبيق الفلاتر الحالية
    debugPrint('تطبيق الفلاتر: $_currentFilters');
  }

  void _applySorting(SortOption option) {
    final StreamAppProvider appProvider = context.read<StreamAppProvider>();
    final StreamProductProvider provider = appProvider.productProvider;
    provider.applySorting(option);
  }

  void _showEditProductDialog(Product product) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => ModernEditProductDialog(
        product: product,
        onProductUpdated: () {
          debugPrint('تم تحديث المنتج: ${product.name}');
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
        onConfirm: () {}, // dummy callback - لن يُستخدم
      ),
    );

    if (confirmed == true) {
      _deleteProduct(product);
    }
  }

  Future<void> _deleteProduct(Product product) async {
    if (_isDeleting || product.id == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final StreamAppProvider appProvider = context.read<StreamAppProvider>();
      final StreamProductProvider provider = appProvider.productProvider;

      final bool success = await provider.deleteProduct(product.id!);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('تم حذف "${product.name}" بنجاح'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('فشل في حذف "${product.name}"'),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتج: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('خطأ في حذف المنتج: $e'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
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
  Widget _buildShimmerLoading() {
    return CustomScrollView(
      slivers: [
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
              (context, index) {
                return const ShimmerCard(
                  height: 200,
                );
              },
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }
}

/// بطاقة منتج محسنة مع memorization
class _MemoizedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;
  final bool compactMode;

  const _MemoizedProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.showActions = true,
    this.compactMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        // يمكن إضافة animations إضافية هنا
      ]),
      builder: (context, child) {
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: Opacity(
                opacity: value,
                child: Platform.isWindows
                    ? WindowsProductCard(
                        product: product,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      )
                    : ProductCard(
                        product: product,
                        onEdit: onEdit,
                        onDelete: onDelete,
                      ),
              ),
            );
          },
        );
      },
    );
  }

  // إزالة operator == و hashCode لأنها غير مسموحة في Widget
}
