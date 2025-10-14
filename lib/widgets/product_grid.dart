import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/product.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'enhanced_product_card.dart';

/// مكون شبكة المنتجات المحسنة
class ProductGrid extends StatefulWidget {
  const ProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onProductEdit,
    this.showActions = true,
  });

  final List<Product> products;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onProductEdit;
  final bool showActions;

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  @override
  void didUpdateWidget(ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة بناء الواجهة عند تغيير المنتجات
    if (oldWidget.products != widget.products) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // تحديد عدد الأعمدة حسب عرض الشاشة
        final int crossAxisCount = context.gridColumns;

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

  /// بناء شبكة المنتجات كـ Sliver للاستخدام مع CustomScrollView
  Widget buildSliver(BuildContext context, int crossAxisCount) {
    if (crossAxisCount == 1) {
      return _buildSliverListView();
    } else {
      return _buildSliverGridView(crossAxisCount);
    }
  }

  Widget _buildGridView(int crossAxisCount) => AnimationLimiter(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: context.responsiveSpacing * 1.0,
            mainAxisSpacing: context.responsiveSpacing * 1.0,
            childAspectRatio: context.responsiveAspectRatio,
          ),
          itemCount: widget.products.length,
          cacheExtent: 100, // ✅ Cache للعناصر القريبة
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index >= widget.products.length) {
              return const SizedBox.shrink();
            }

            final Product product = widget.products[index];
            return AnimationConfiguration.staggeredGrid(
              position: index,
              columnCount: crossAxisCount,
              duration: const Duration(milliseconds: 300),
              child: SlideAnimation(
                verticalOffset: 20,
                child: FadeInAnimation(
                  child: RepaintBoundary(
                    // ✅ يمنع إعادة الرسم غير الضرورية
                    key: ValueKey(product.id), // ✅ مفتاح مستقر
                    child: _buildProductCard(product),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildListView() => AnimationLimiter(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: widget.products.length,
          cacheExtent: 100, // ✅ Cache للعناصر القريبة
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          itemBuilder: (BuildContext context, int index) {
            if (index >= widget.products.length) {
              return const SizedBox.shrink();
            }

            final Product product = widget.products[index];
            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 250),
              child: SlideAnimation(
                horizontalOffset: 30,
                child: FadeInAnimation(
                  child: RepaintBoundary(
                    // ✅ يمنع إعادة الرسم غير الضرورية
                    key: ValueKey(product.id), // ✅ مفتاح مستقر
                    child: _buildProductCard(product),
                  ),
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
        enableAnimations: false, // ✅ تعطيل للأداء
      );

  Widget _buildSliverGridView(int crossAxisCount) => SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: context.responsiveSpacing * 1.2,
          mainAxisSpacing: context.responsiveSpacing * 1.2,
          childAspectRatio: context.responsiveAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (index >= widget.products.length) {
              return const SizedBox.shrink();
            }

            final Product product = widget.products[index];
            return _buildProductCard(product);
          },
          childCount: widget.products.length,
        ),
      );

  Widget _buildSliverListView() => SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            if (index >= widget.products.length) {
              return const SizedBox.shrink();
            }

            final Product product = widget.products[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: _buildProductCard(product),
            );
          },
          childCount: widget.products.length,
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

/// مكون شبكة المنتجات المضغوطة للشاشات الصغيرة
class CompactProductGrid extends StatefulWidget {
  const CompactProductGrid({
    super.key,
    required this.products,
    this.onProductTap,
    this.onProductEdit,
    this.showActions = true,
  });

  final List<Product> products;
  final ValueChanged<Product>? onProductTap;
  final ValueChanged<Product>? onProductEdit;
  final bool showActions;

  @override
  State<CompactProductGrid> createState() => _CompactProductGridState();
}

class _CompactProductGridState extends State<CompactProductGrid> {
  @override
  void didUpdateWidget(CompactProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة بناء الواجهة عند تغيير المنتجات
    if (oldWidget.products != widget.products) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: widget.products.length,
        itemBuilder: (BuildContext context, int index) {
          if (index >= widget.products.length) {
            return const SizedBox.shrink();
          }

          final Product product = widget.products[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 200),
            child: SlideAnimation(
              horizontalOffset: 20,
              child: FadeInAnimation(
                child: _buildCompactProductCard(product),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactProductCard(Product product) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: Card(
        margin: EdgeInsets.only(bottom: context.responsiveSpacing * 0.3),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            context.isSmallScreen ? 8 : 12,
          ),
          side: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: context.isSmallScreen ? 60 : 70,
          ),
          padding: context.responsivePadding,
          child: Row(
            children: <Widget>[
              // معلومات المنتج
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.responsiveFontSize(12),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.1),
                    Text(
                      'سعر التجزئة: ${CurrencyFormatter.formatCurrencyNoDecimals(product.retailPrice / 100, context)}',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(9),
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'الربح: ${CurrencyFormatter.formatCurrencyNoDecimals(product.calculateProfit() / 100, context)} (${product.calculateProfitPercentage().toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(10),
                        fontWeight: FontWeight.bold,
                        color: AppConstants.successColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // أزرار الإجراءات
              if (widget.showActions) ...<Widget>[
                SizedBox(width: context.responsiveSpacing * 0.3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (widget.onProductEdit != null)
                      IconButton(
                        onPressed: () => widget.onProductEdit!(product),
                        icon: Icon(
                          Icons.edit,
                          size: context.isSmallScreen ? 14 : 16,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              isDark ? Colors.blue[800] : Colors.blue[50],
                          foregroundColor: Colors.blue,
                          padding: EdgeInsets.all(
                            context.responsiveSpacing * 0.2,
                          ),
                          minimumSize: Size(
                            context.isSmallScreen ? 28 : 32,
                            context.isSmallScreen ? 28 : 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// بناء قائمة المنتجات المضغوطة كـ Sliver للاستخدام مع CustomScrollView
  Widget buildSliver(BuildContext context) => SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= widget.products.length) {
            return const SizedBox.shrink();
          }

          final Product product = widget.products[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: _buildCompactProductCard(product),
          );
        },
        childCount: widget.products.length,
      ),
    );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.inventory_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد منتجات',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
}
