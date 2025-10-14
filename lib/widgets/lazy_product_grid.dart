import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/product.dart';
import '../utils/responsive_breakpoints.dart';
import 'enhanced_product_card.dart';

/// مكون شبكة المنتجات مع تحسين الأداء والتحميل التدريجي
class LazyProductGrid extends StatefulWidget {
  const LazyProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onProductEdit,
    this.showActions = true,
    this.batchSize = 20,
    this.initialLoadSize = 10,
  });

  final List<Product> products;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onProductEdit;
  final bool showActions;
  final int batchSize;
  final int initialLoadSize;

  @override
  State<LazyProductGrid> createState() => _LazyProductGridState();
}

class _LazyProductGridState extends State<LazyProductGrid> {
  late List<Product> _displayedProducts;
  bool _isLoadingMore = false;
  bool _hasMoreProducts = true;

  @override
  void initState() {
    super.initState();
    _initializeProducts();
  }

  @override
  void didUpdateWidget(LazyProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _initializeProducts();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تهيئة المنتجات عند تغيير التبعيات
    _initializeProducts();
  }

  void _initializeProducts() {
    _displayedProducts = widget.products.take(widget.initialLoadSize).toList();
    _hasMoreProducts = widget.products.length > widget.initialLoadSize;
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    setState(() {
      _isLoadingMore = true;
    });

    // محاكاة تحميل تدريجي
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final int currentLength = _displayedProducts.length;
    final List<Product> nextBatch =
        widget.products.skip(currentLength).take(widget.batchSize).toList();

    setState(() {
      _displayedProducts.addAll(nextBatch);
      _isLoadingMore = false;
      _hasMoreProducts = _displayedProducts.length < widget.products.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedProducts.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount;

        if (width >= 800) {
          crossAxisCount = 3;
        } else if (width >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return _buildResponsiveGrid(crossAxisCount);
      },
    );
  }

  Widget _buildResponsiveGrid(int crossAxisCount) {
    if (crossAxisCount == 1) {
      return _buildListView();
    } else {
      return _buildGridView(crossAxisCount);
    }
  }

  Widget _buildGridView(int crossAxisCount) => AnimationLimiter(
        child: GridView.builder(
          padding: context.responsivePadding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: context.responsiveSpacing * 1.0,
            mainAxisSpacing: context.responsiveSpacing * 1.0,
            childAspectRatio: context.responsiveAspectRatio,
          ),
          itemCount: _displayedProducts.length + (_hasMoreProducts ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= _displayedProducts.length) {
              return _buildLoadMoreButton();
            }

            final Product product = _displayedProducts[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: crossAxisCount,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 20,
                child: FadeInAnimation(
                  child: _buildProductCard(product),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildListView() => AnimationLimiter(
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
              horizontal: context.responsiveSpacing * 0.8,
              vertical: context.responsiveSpacing * 0.5),
          itemCount: _displayedProducts.length + (_hasMoreProducts ? 1 : 0),
          itemBuilder: (BuildContext context, int index) {
            if (index >= _displayedProducts.length) {
              return _buildLoadMoreButton();
            }

            final Product product = _displayedProducts[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 250),
              child: SlideAnimation(
                horizontalOffset: 30,
                child: FadeInAnimation(
                  child: _buildProductCard(product),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildProductCard(Product product) => EnhancedProductCard(
        product: product,
        onTap: widget.onProductTap != null
            ? () => widget.onProductTap!(product)
            : null,
        onEdit: widget.onProductEdit != null
            ? () => widget.onProductEdit!(product)
            : null,
        showActions: widget.showActions,
      );

  Widget _buildLoadMoreButton() => Container(
        padding: context.responsivePadding,
        child: Center(
          child: _isLoadingMore
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('جاري تحميل المزيد...'),
                  ],
                )
              : ElevatedButton.icon(
                  onPressed: _loadMoreProducts,
                  icon: Icon(Icons.expand_more,
                      size: context.isSmallScreen ? 18 : 20),
                  label: Text(
                    'تحميل المزيد',
                    style: TextStyle(fontSize: context.responsiveFontSize(14)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
        ),
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد منتجات للعرض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
}

/// مكون تحسين الأداء مع التخزين المؤقت
class OptimizedProductGrid extends StatefulWidget {
  const OptimizedProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onProductEdit,
    this.showActions = true,
    this.cacheSize = 100,
  });

  final List<Product> products;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onProductEdit;
  final bool showActions;
  final int cacheSize;

  @override
  State<OptimizedProductGrid> createState() => _OptimizedProductGridState();
}

class _OptimizedProductGridState extends State<OptimizedProductGrid> {
  final Map<String, Widget> _productCardCache = <String, Widget>{};
  final Set<String> _visibleProducts = <String>{};

  @override
  void didUpdateWidget(OptimizedProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      _clearCache();
    }
  }

  void _clearCache() {
    _productCardCache.clear();
    _visibleProducts.clear();
  }

  Widget _buildCachedProductCard(Product product) {
    final String productId = product.id ?? product.name;

    if (_productCardCache.containsKey(productId)) {
      return _productCardCache[productId]!;
    }

    final EnhancedProductCard card = EnhancedProductCard(
      product: product,
      onTap: widget.onProductTap != null
          ? () => widget.onProductTap!(product)
          : null,
      onEdit: widget.onProductEdit != null
          ? () => widget.onProductEdit!(product)
          : null,
      showActions: widget.showActions,
    );

    // تخزين البطاقة في الذاكرة المؤقتة
    if (_productCardCache.length < widget.cacheSize) {
      _productCardCache[productId] = card;
    }

    return card;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount;

        if (width >= 800) {
          crossAxisCount = 3;
        } else if (width >= 600) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        return _buildOptimizedGrid(crossAxisCount);
      },
    );
  }

  Widget _buildOptimizedGrid(int crossAxisCount) {
    if (crossAxisCount == 1) {
      return _buildOptimizedListView();
    } else {
      return _buildOptimizedGridView(crossAxisCount);
    }
  }

  Widget _buildOptimizedGridView(int crossAxisCount) => GridView.builder(
        padding: EdgeInsets.all(
            context.responsiveSpacing * 1.0), // استخدام responsive spacing
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: context.responsiveSpacing * 1.2,
          mainAxisSpacing: context.responsiveSpacing * 1.2,
          childAspectRatio: context.responsiveAspectRatio,
        ),
        itemCount: widget.products.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= widget.products.length) {
            return const SizedBox.shrink();
          }

          final Product product = widget.products[index];
          return _buildCachedProductCard(product);
        },
      );

  Widget _buildOptimizedListView() => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: widget.products.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= widget.products.length) {
            return const SizedBox.shrink();
          }

          final Product product = widget.products[index];
          return _buildCachedProductCard(product);
        },
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد منتجات للعرض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
}
