import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة قابلة للتوسع مع animations سلسة
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    super.key,
    required this.header,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.headerColor,
    this.expandedColor,
    this.elevation = 2,
    this.borderRadius,
    this.padding,
    this.margin,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onExpansionChanged,
  });

  final Widget header;
  final Widget expandedContent;
  final bool initiallyExpanded;
  final Color? headerColor;
  final Color? expandedColor;
  final double elevation;
  final double? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Duration animationDuration;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _isExpanded = widget.initiallyExpanded;
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (mounted) {
        try {
          if (_isExpanded) {
            _controller.forward();
          } else {
            _controller.reverse();
          }
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    });

    widget.onExpansionChanged?.call(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: widget.margin ??
          EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing * 0.5,
            vertical: context.responsiveSpacing * 0.3,
          ),
      constraints: context.expandedCardConstraints,
      child: Card(
        elevation: widget.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? (context.isSmallScreen ? 8 : 12),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.borderRadius ?? (context.isSmallScreen ? 8 : 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Header قابل للنقر
              Material(
                color: widget.headerColor ??
                    (isDark ? Colors.grey[800] : Colors.white),
                child: InkWell(
                  onTap: _toggleExpansion,
                  child: Container(
                    padding: widget.padding ?? context.responsivePadding,
                    child: Row(
                      children: <Widget>[
                        Expanded(child: widget.header),
                        SizedBox(width: context.responsiveSpacing * 0.5),
                        AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (BuildContext context, Widget? child) => Transform.rotate(
                              angle: _rotationAnimation.value * 3.14159,
                              child: Icon(
                                Icons.expand_more,
                                color: AppConstants.primaryColor,
                                size: context.responsiveFontSize(24),
                              ),
                            ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // المحتوى القابل للتوسع
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (BuildContext context, Widget? child) => ClipRect(
                    child: Align(
                      heightFactor: _expandAnimation.value,
                      child: Container(
                        color: widget.expandedColor ??
                            (isDark ? Colors.grey[700] : Colors.grey[50]),
                        child: child,
                      ),
                    ),
                  ),
                child: Container(
                  padding: widget.padding ?? context.responsivePadding,
                  child: widget.expandedContent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة قابلة للتوسع مبسطة للمنتجات
class ExpandableProductCard extends StatelessWidget {
  const ExpandableProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.initiallyExpanded = false,
  });

  final dynamic product; // Product أو InventoryItem
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return ExpandableCard(
      initiallyExpanded: initiallyExpanded,
      header: _buildHeader(context, isDark),
      expandedContent: _buildExpandedContent(context, isDark),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) => Row(
      children: <Widget>[
        // أيقونة المنتج
        Container(
          padding: EdgeInsets.all(context.responsiveSpacing * 0.4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
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
        SizedBox(width: context.responsiveSpacing * 0.5),

        // معلومات أساسية
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                product.name.toString(),
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppConstants.textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.responsiveSpacing * 0.2),
              Text(
                _getSubtitle(),
                style: TextStyle(
                  fontSize: context.responsiveFontSize(12),
                  color: isDark ? Colors.grey[300] : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

  Widget _buildExpandedContent(BuildContext context, bool isDark) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // تفاصيل المنتج
        _buildDetailsSection(context, isDark),

        if (showActions) ...<Widget>[
          SizedBox(height: context.responsiveSpacing * 0.5),
          _buildActionsSection(context, isDark),
        ],
      ],
    );

  Widget _buildDetailsSection(BuildContext context, bool isDark) {
    final bool isInventoryItem =
        product.runtimeType.toString().contains('InventoryItem');

    return Container(
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 6 : 8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildDetailRow(context, 'سعر الجملة', _getWholesalePrice(),
              Icons.store_outlined, AppConstants.infoColor),
          SizedBox(height: context.responsiveSpacing * 0.3),
          _buildDetailRow(context, 'سعر التجزئة', _getRetailPrice(),
              Icons.shopping_cart_outlined, AppConstants.successColor),
          if (isInventoryItem) ...<Widget>[
            SizedBox(height: context.responsiveSpacing * 0.3),
            _buildDetailRow(context, 'الكمية', '${product.quantity}',
                Icons.inventory, AppConstants.infoColor),
          ],
          SizedBox(height: context.responsiveSpacing * 0.3),
          _buildDetailRow(context, 'الربح', _getProfit(), Icons.trending_up,
              AppConstants.warningColor),
          SizedBox(height: context.responsiveSpacing * 0.3),
          _buildDetailRow(context, 'نسبة الربح', _getProfitPercentage(),
              Icons.percent, AppConstants.secondaryColor),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      IconData icon, Color color) => Row(
      children: <Widget>[
        Icon(icon, size: context.responsiveFontSize(16), color: color),
        SizedBox(width: context.responsiveSpacing * 0.3),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: context.responsiveFontSize(12),
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsiveFontSize(14),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );

  Widget _buildActionsSection(BuildContext context, bool isDark) => Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        if (onEdit != null)
          _buildActionButton(
            context,
            icon: Icons.edit_outlined,
            label: 'تعديل',
            color: AppConstants.infoColor,
            onPressed: onEdit!,
          ),
        if (onEdit != null && onDelete != null)
          SizedBox(width: context.responsiveSpacing * 0.3),
        if (onDelete != null)
          _buildActionButton(
            context,
            icon: Icons.delete_outline,
            label: 'حذف',
            color: AppConstants.errorColor,
            onPressed: onDelete!,
          ),
      ],
    );

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 4 : 6,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing * 0.6,
            vertical: context.responsiveSpacing * 0.3,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(
              context.isSmallScreen ? 4 : 6,
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: context.responsiveFontSize(16), color: color),
              SizedBox(width: context.responsiveSpacing * 0.2),
              Text(
                label,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(12),
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  String _getSubtitle() {
    // التحقق من نوع المنتج
    if (product.runtimeType.toString().contains('InventoryItem') &&
        product.quantity != null) {
      return 'الكمية: ${product.quantity}';
    }
    return 'سعر التجزئة: ${_getRetailPrice()}';
  }

  String _getWholesalePrice() {
    if (product.wholesalePrice != null) {
      return '${(product.wholesalePrice / 100).toStringAsFixed(0)} DZ';
    }
    return 'غير محدد';
  }

  String _getRetailPrice() {
    if (product.retailPrice != null) {
      return '${(product.retailPrice / 100).toStringAsFixed(0)} DZ';
    }
    return 'غير محدد';
  }

  String _getProfit() {
    try {
      if (product.calculateProfit != null) {
        return '${(product.calculateProfit() / 100).toStringAsFixed(0)} DZ';
      }
    } catch (e) {
      // تجاهل الخطأ إذا لم تكن الدالة متاحة
    }
    return 'غير محدد';
  }

  String _getProfitPercentage() {
    try {
      if (product.calculateProfitPercentage != null) {
        return '${product.calculateProfitPercentage().toStringAsFixed(1)}%';
      }
    } catch (e) {
      // تجاهل الخطأ إذا لم تكن الدالة متاحة
    }
    return 'غير محدد';
  }
}
