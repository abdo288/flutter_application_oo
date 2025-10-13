import 'package:flutter/material.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';
import '../utils/currency_formatter.dart';
import 'expandable_card.dart';

/// Modern Product Card with Enhanced UI
class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showShadow = true,
    this.enableHover = true,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showShadow;
  final bool enableHover;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppConstants.animationFast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(
      begin: AppConstants.elevation2,
      end: AppConstants.elevation8,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    if (!widget.enableHover) return;
    setState(() => _isHovered = isHovered);
    if (mounted) {
      try {
        if (isHovered) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      } catch (e) {
        // تجاهل الأخطاء إذا تم التخلص من المتحكمات
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // استخدام ExpandableProductCard للشاشات الكبيرة
    if (context.isDesktopScreen) {
      return ExpandableProductCard(
        product: widget.product,
        onTap: widget.onTap,
        onEdit: widget.onEdit,
        onDelete: widget.onDelete,
        showActions: widget.onEdit != null || widget.onDelete != null,
        initiallyExpanded: false,
      );
    }

    // البطاقة التقليدية للشاشات الصغيرة
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: Card(
                margin: EdgeInsets.symmetric(
                  horizontal: context.responsiveSpacing * 0.5,
                  vertical: context.responsiveSpacing * 0.3,
                ),
                elevation: widget.showShadow ? _elevationAnimation.value : 0,
                shadowColor: AppConstants.shadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    context.isSmallScreen ? 8 : 12,
                  ),
                  side: _isHovered
                      ? BorderSide(
                          color:
                              AppConstants.primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        )
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(
                    context.isSmallScreen ? 8 : 12,
                  ),
                  splashColor: AppConstants.primaryColor.withValues(alpha: 0.1),
                  highlightColor:
                      AppConstants.primaryColor.withValues(alpha: 0.05),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      context.isSmallScreen ? 8 : 12,
                    ),
                    child: Container(
                      constraints: context.windowsCardConstraints,
                      decoration: BoxDecoration(
                        gradient: _isHovered
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.02)
                                      : Colors.white,
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : AppConstants.primaryColor
                                          .withValues(alpha: 0.02),
                                ],
                              )
                            : null,
                      ),
                      child: Padding(
                        padding: context.responsivePadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // ✅ اسم المنتج مع أيقونة ومؤشر المزامنة
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    context.responsiveSpacing * 0.4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      context.isSmallScreen ? 6 : 8,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: AppConstants.primaryColor,
                                    size: context.responsiveFontSize(20),
                                  ),
                                ),
                                SizedBox(
                                    width: context.responsiveSpacing * 0.5),
                                Expanded(
                                  child: Text(
                                    widget.product.name,
                                    style: TextStyle(
                                      fontSize: context.responsiveFontSize(18),
                                      fontWeight: AppConstants.fontWeightBold,
                                      color: isDark
                                          ? Colors.white
                                          : AppConstants.textColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // ✅ مؤشر حالة المزامنة
                                if (widget.product.isSynced != null &&
                                    !widget.product.isSynced!)
                                  Container(
                                    padding: EdgeInsets.all(
                                      context.responsiveSpacing * 0.2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.orange
                                            .withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.sync,
                                      color: Colors.orange,
                                      size: context.responsiveFontSize(12),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: context.responsiveSpacing * 0.5),

                            // معلومات الأسعار والأرباح في بطاقات صغيرة
                            Flexible(
                              child: Container(
                                padding: context.responsivePadding,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(
                                    context.isSmallScreen ? 6 : 8,
                                  ),
                                ),
                                child: _buildProductInfo(context, isDark),
                              ),
                            ),

                            // أزرار الإجراءات المحسّنة
                            if (widget.onEdit != null ||
                                widget.onDelete != null) ...<Widget>[
                              SizedBox(height: context.responsiveSpacing * 0.5),
                              _buildActionsSection(context),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context, bool isDark) {
    final int profit = widget.product.calculateProfit();
    final double profitPercentage = widget.product.calculateProfitPercentage();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // صف الأسعار
        context.shouldUseVerticalLayout
            ? Column(
                children: [
                  _buildModernInfoItem(
                    context,
                    'سعر الجملة',
                    CurrencyFormatter.formatCurrencyNoDecimals(
                        widget.product.wholesalePrice / 100, context),
                    Icons.store_outlined,
                    AppConstants.infoColor,
                    isDark,
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  _buildModernInfoItem(
                    context,
                    'سعر التجزئة',
                    CurrencyFormatter.formatCurrencyNoDecimals(
                        widget.product.retailPrice / 100, context),
                    Icons.shopping_cart_outlined,
                    AppConstants.successColor,
                    isDark,
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(
                    child: _buildModernInfoItem(
                      context,
                      'سعر الجملة',
                      CurrencyFormatter.formatCurrencyNoDecimals(
                          widget.product.wholesalePrice / 100, context),
                      Icons.store_outlined,
                      AppConstants.infoColor,
                      isDark,
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.3),
                  Expanded(
                    child: _buildModernInfoItem(
                      context,
                      'سعر التجزئة',
                      CurrencyFormatter.formatCurrencyNoDecimals(
                          widget.product.retailPrice / 100, context),
                      Icons.shopping_cart_outlined,
                      AppConstants.successColor,
                      isDark,
                    ),
                  ),
                ],
              ),
        SizedBox(height: context.responsiveSpacing * 0.3),

        // صف الأرباح
        context.shouldUseVerticalLayout
            ? Column(
                children: [
                  _buildModernInfoItem(
                    context,
                    'الربح',
                    CurrencyFormatter.formatCurrencyNoDecimals(
                        profit / 100, context),
                    Icons.trending_up,
                    AppConstants.warningColor,
                    isDark,
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.3),
                  _buildModernInfoItem(
                    context,
                    'نسبة الربح',
                    '${profitPercentage.toStringAsFixed(1)}%',
                    Icons.percent,
                    AppConstants.secondaryColor,
                    isDark,
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(
                    child: _buildModernInfoItem(
                      context,
                      'الربح',
                      CurrencyFormatter.formatCurrencyNoDecimals(
                          profit / 100, context),
                      Icons.trending_up,
                      AppConstants.warningColor,
                      isDark,
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.3),
                  Expanded(
                    child: _buildModernInfoItem(
                      context,
                      'نسبة الربح',
                      '${profitPercentage.toStringAsFixed(1)}%',
                      Icons.percent,
                      AppConstants.secondaryColor,
                      isDark,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return context.shouldUseVerticalLayout
        ? Column(
            children: [
              if (widget.onEdit != null)
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    context,
                    icon: Icons.edit_outlined,
                    label: 'تعديل',
                    color: AppConstants.infoColor,
                    onPressed: widget.onEdit!,
                  ),
                ),
              if (widget.onEdit != null && widget.onDelete != null)
                SizedBox(height: context.responsiveSpacing * 0.3),
              if (widget.onDelete != null)
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    context,
                    icon: Icons.delete_outline,
                    label: 'حذف',
                    color: AppConstants.errorColor,
                    onPressed: widget.onDelete!,
                  ),
                ),
            ],
          )
        : Wrap(
            alignment: WrapAlignment.end,
            spacing: context.responsiveSpacing * 0.3,
            children: <Widget>[
              if (widget.onEdit != null)
                _buildActionButton(
                  context,
                  icon: Icons.edit_outlined,
                  label: 'تعديل',
                  color: AppConstants.infoColor,
                  onPressed: widget.onEdit!,
                ),
              if (widget.onDelete != null)
                _buildActionButton(
                  context,
                  icon: Icons.delete_outline,
                  label: 'حذف',
                  color: AppConstants.errorColor,
                  onPressed: widget.onDelete!,
                ),
            ],
          );
  }

  // Modern info item with icon
  Widget _buildModernInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: EdgeInsets.all(context.responsiveSpacing * 0.4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 4 : 6,
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: context.responsiveFontSize(16),
                color: color,
              ),
              SizedBox(width: context.responsiveSpacing * 0.2),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    color: isDark
                        ? color.withValues(alpha: 0.9)
                        : color.withValues(alpha: 0.8),
                    fontWeight: AppConstants.fontWeightMedium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: context.responsiveSpacing * 0.2),
          Text(
            value,
            style: TextStyle(
              fontSize: context.responsiveFontSize(15),
              fontWeight: AppConstants.fontWeightBold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Modern action button
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 4 : 6,
        ),
        child: Container(
          constraints: BoxConstraints(
            minHeight: context.responsiveSpacing * 2.5,
            minWidth: context.responsiveSpacing * 4,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing * 0.4,
            vertical: context.responsiveSpacing * 0.25,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 4 : 6,
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: context.responsiveFontSize(16),
                color: color,
              ),
              SizedBox(width: context.responsiveSpacing * 0.2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    fontWeight: AppConstants.fontWeightSemiBold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
