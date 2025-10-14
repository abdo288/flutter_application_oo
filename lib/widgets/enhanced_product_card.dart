import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/inventory_product_linker_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';

/// أوضاع عرض البطاقة
enum DisplayMode {
  compact,
  medium,
  full,
}

/// ثيم مخصص لبطاقة المنتج
class ProductCardTheme {
  const ProductCardTheme({
    this.cardColor,
    this.borderColor,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.textColor,
    this.backgroundColor,
  });

  final Color? cardColor;
  final Color? borderColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final Color? textColor;
  final Color? backgroundColor;
}

/// بطاقة منتج محسنة مع عرض معلومات شاملة
class EnhancedProductCard extends StatefulWidget {
  const EnhancedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.showActions = true,
    this.compactMode = false,
    this.inventoryItems = const <dynamic>[],
    this.showInventoryData = true,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableAnimations = true,
    this.enableGradient = false,
    this.customTheme,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool showActions;
  final bool compactMode;
  final List<dynamic> inventoryItems; // يمكن أن يكون List<InventoryItem>
  final bool showInventoryData;
  final Duration animationDuration;
  final bool enableAnimations;
  final bool enableGradient;
  final ProductCardTheme? customTheme;

  @override
  State<EnhancedProductCard> createState() => _EnhancedProductCardState();
}

class _EnhancedProductCardState extends State<EnhancedProductCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ يحتفظ بالحالة

  // ✅ Cache للبيانات المحسوبة
  late final int _cachedProfit;
  late final double _cachedProfitPercentage;
  late final int _cachedWholesalePrice;
  late final bool _cachedIsValidProduct;
  late final bool _cachedIsOutOfStock;

  @override
  void initState() {
    super.initState();
    _calculateCachedValues();
  }

  @override
  void didUpdateWidget(EnhancedProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ إعادة حساب فقط إذا تغير المنتج
    if (oldWidget.product != widget.product) {
      _calculateCachedValues();
    }
  }

  /// حساب القيم المحسوبة مرة واحدة
  void _calculateCachedValues() {
    _cachedWholesalePrice = _calculateWholesalePrice();
    _cachedProfit = _calculateProfitValue();
    _cachedProfitPercentage = _calculateProfitPercentage();
    _cachedIsValidProduct = _validateProduct();
    _cachedIsOutOfStock = _checkOutOfStock();
  }

  // ثوابت التصميم
  static const EdgeInsets _defaultPadding =
      EdgeInsets.all(20); // زيادة من 16 إلى 20
  static const EdgeInsets _compactPadding =
      EdgeInsets.all(16); // زيادة من 12 إلى 16
  static const EdgeInsets _smallPadding =
      EdgeInsets.all(12); // زيادة من 8 إلى 12
  static const BorderRadius _defaultBorderRadius =
      BorderRadius.all(Radius.circular(16));
  static const BorderRadius _compactBorderRadius =
      BorderRadius.all(Radius.circular(12));
  static const Curve _defaultAnimationCurve = Curves.easeInOut;

  /// الحصول على بيانات المخزون المربوطة
  ProductLinkData? get _linkedInventoryData {
    if (!widget.showInventoryData || widget.inventoryItems.isEmpty) return null;

    try {
      // تحويل inventoryItems إلى List<InventoryItem>
      final List<dynamic> validItems =
          widget.inventoryItems.where((item) => item != null).toList();
      if (validItems.isEmpty) return null;

      return InventoryProductLinkerService.linkInventoryToProduct(
        product: widget.product,
        inventoryItems: validItems.cast(),
      );
    } catch (e) {
      debugPrint('❌ خطأ في ربط بيانات المخزون: $e');
      return null;
    }
  }

  /// البيانات المحسوبة مرة واحدة لتحسين الأداء
  int get _wholesalePrice => _cachedWholesalePrice;
  double get _profitPercentage => _cachedProfitPercentage;
  int get _profitValue => _cachedProfit;
  bool get _isValidProduct => _cachedIsValidProduct;
  bool get _isOutOfStock => _cachedIsOutOfStock;

  /// حساب سعر الجملة
  int _calculateWholesalePrice() {
    if (_linkedInventoryData != null && _linkedInventoryData!.isLinked) {
      return _linkedInventoryData!.linkedWholesalePrice;
    }
    return widget.product.wholesalePrice;
  }

  /// حساب نسبة الربح
  double _calculateProfitPercentage() {
    if (_cachedWholesalePrice <= 0) return 0.0;
    return ((widget.product.retailPrice - _cachedWholesalePrice) /
            _cachedWholesalePrice) *
        100;
  }

  /// حساب قيمة الربح
  int _calculateProfitValue() => widget.product.retailPrice - _cachedWholesalePrice;

  /// التحقق من صحة بيانات المنتج
  bool _validateProduct() => widget.product.name.isNotEmpty &&
        widget.product.retailPrice >= 0 &&
        widget.product.wholesalePrice >= 0;

  /// التحقق من نفاد المخزون
  bool _checkOutOfStock() => _linkedInventoryData != null &&
        _linkedInventoryData!.isLinked &&
        _linkedInventoryData!.isOutOfStock;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    // التحقق من صحة البيانات
    if (!_isValidProduct) {
      return _buildErrorCard(context);
    }

    return RepaintBoundary(
      // ✅ يمنع إعادة الرسم غير الضرورية
      child: ClipRRect(
        borderRadius: BorderRadius.circular(context.isSmallScreen ? 8 : 12),
        child: _buildResponsiveCard(context),
      ),
    );
  }

  /// بناء البطاقة المتجاوبة
  Widget _buildResponsiveCard(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        // التحقق من صحة القيود
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        final screenWidth = constraints.maxWidth;
        final isCompact = screenWidth < 300 || context.isSmallScreen;
        final isMedium =
            screenWidth >= 300 && screenWidth < 600 && !context.isSmallScreen;
        final isFull = screenWidth >= 600 && !context.isSmallScreen;

        return _buildAnimatedCard(
          context,
          isCompact: isCompact,
          isMedium: isMedium,
          isFull: isFull,
        );
      },
    );

  /// بناء البطاقة المتحركة
  Widget _buildAnimatedCard(
    BuildContext context, {
    required bool isCompact,
    required bool isMedium,
    required bool isFull,
  }) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // تحديد وضع العرض
    final DisplayMode displayMode = isCompact
        ? DisplayMode.compact
        : isMedium
            ? DisplayMode.medium
            : DisplayMode.full;

    final Widget cardContent = _buildCardContent(context, displayMode);

    if (widget.enableAnimations) {
      return AnimatedContainer(
        duration: widget.animationDuration,
        curve: _defaultAnimationCurve,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: _buildCardDecoration(context, isDark, displayMode),
        child: cardContent,
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: _buildCardDecoration(context, isDark, displayMode),
        child: cardContent,
      );
    }
  }

  /// بناء تزيين البطاقة
  BoxDecoration _buildCardDecoration(
    BuildContext context,
    bool isDark,
    DisplayMode displayMode,
  ) {
    final Color cardColor = widget.customTheme?.cardColor ??
        (isDark ? Theme.of(context).cardColor : Colors.white);
    final Color borderColor = widget.customTheme?.borderColor ??
        widget.product.getStatusColor().withValues(alpha: 0.2);

    return BoxDecoration(
      color: cardColor,
      borderRadius: widget.customTheme?.borderRadius ??
          (displayMode == DisplayMode.compact
              ? _compactBorderRadius
              : _defaultBorderRadius),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.05),
          blurRadius: displayMode == DisplayMode.compact ? 4 : 8,
          offset: const Offset(0, 2),
        ),
        if (widget.enableGradient)
          BoxShadow(
            color: widget.product.getStatusColor().withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
      ],
      border: Border.all(
        color: borderColor,
        width: 1.5,
      ),
      gradient: widget.enableGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                cardColor,
                widget.product.getStatusColor().withValues(alpha: 0.05),
              ],
            )
          : null,
    );
  }

  /// بناء محتوى البطاقة
  Widget _buildCardContent(BuildContext context, DisplayMode displayMode) => Semantics(
      label: 'بطاقة منتج ${widget.product.name}',
      hint: 'اضغط للعرض التفصيلي',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          borderRadius: displayMode == DisplayMode.compact
              ? _compactBorderRadius
              : _defaultBorderRadius,
          splashColor: widget.product.getStatusColor().withValues(alpha: 0.1),
          highlightColor:
              widget.product.getStatusColor().withValues(alpha: 0.05),
          child: Flexible(
            child: Padding(
              padding: _getPaddingForMode(displayMode),
              child: _buildContentForMode(context, displayMode),
            ),
          ),
        ),
      ),
    );

  /// الحصول على padding حسب الوضع
  EdgeInsets _getPaddingForMode(DisplayMode displayMode) {
    if (widget.customTheme?.padding != null) {
      return widget.customTheme!.padding!;
    }

    switch (displayMode) {
      case DisplayMode.compact:
        return _compactPadding;
      case DisplayMode.medium:
        return _defaultPadding;
      case DisplayMode.full:
        return _defaultPadding;
    }
  }

  /// بناء المحتوى حسب الوضع
  Widget _buildContentForMode(BuildContext context, DisplayMode displayMode) {
    switch (displayMode) {
      case DisplayMode.compact:
        return _buildCompactContent(context);
      case DisplayMode.medium:
        return _buildMediumContent(context);
      case DisplayMode.full:
        return _buildFullContent(context);
    }
  }

  /// بناء بطاقة الخطأ
  Widget _buildErrorCard(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      padding: _defaultPadding,
      decoration: BoxDecoration(
        color: isDark ? Colors.red[900] : Colors.red[50],
        borderRadius: _defaultBorderRadius,
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'بيانات المنتج غير صحيحة',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء المحتوى المضغوط
  Widget _buildCompactContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // أيقونة الحالة
          _buildStatusIndicator(),
          SizedBox(width: context.responsiveSpacing * 1.0), // زيادة المسافة

          // معلومات أساسية
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildProductName(context, isDark, maxLines: 1),
                if (widget.product.category != null) ...<Widget>[
                  SizedBox(
                      height: context.responsiveSpacing * 0.5), // زيادة المسافة
                  _buildCategoryChip(context, isDark),
                ],
              ],
            ),
          ),

          SizedBox(
              width: context.responsiveSpacing *
                  0.8), // استخدام responsive spacing

          // الأسعار
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _buildRetailPriceChip(context, isDark),
                SizedBox(
                    height: context.responsiveSpacing * 0.4), // زيادة المسافة
                _buildWholesalePriceText(context, isDark),
                _buildProfitText(context, isDark),
              ],
            ),
          ),

          // أزرار الإجراءات
          if (widget.showActions &&
              (widget.onEdit != null || widget.onDelete != null)) ...<Widget>[
            SizedBox(
                width: context.responsiveSpacing *
                    0.8), // استخدام responsive spacing
            _buildActionButtons(context, isDark),
          ],
        ],
      ),
    );
  }

  /// بناء المحتوى المتوسط
  Widget _buildMediumContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // العنوان والحالة
        Row(
          children: <Widget>[
            Expanded(child: _buildProductName(context, isDark)),
            _buildStatusBadge(context, isDark),
          ],
        ),
        const SizedBox(height: 12),

        // معلومات المنتج
        _buildProductInfo(context, isDark, isCompact: true),
        const SizedBox(height: 12),

        // أزرار الإجراءات
        if (widget.showActions) _buildActionButtonsRow(context, isDark),
      ],
    );
  }

  /// بناء المحتوى الكامل
  Widget _buildFullContent(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // العنوان والحالة
        Row(
          children: <Widget>[
            Expanded(child: _buildProductName(context, isDark)),
            _buildStatusBadge(context, isDark),
          ],
        ),
        const SizedBox(height: 12),

        // معلومات المنتج
        _buildProductInfo(context, isDark, isCompact: false),
        const SizedBox(height: 12),

        // أزرار الإجراءات
        if (widget.showActions) _buildActionButtonsRow(context, isDark),
      ],
    );
  }

  /// بناء مؤشر الحالة
  Widget _buildStatusIndicator() => Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: widget.product.getStatusColor(),
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.product.getStatusColor().withValues(alpha: 0.3),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

  /// بناء اسم المنتج
  Widget _buildProductName(BuildContext context, bool isDark,
      {int maxLines = 2}) {
    final ThemeData theme = Theme.of(context);
    final Color textColor = widget.customTheme?.textColor ??
        (isDark ? theme.colorScheme.onSurface : Colors.black87);

    return Text(
      widget.product.name,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: context.responsiveFontSize(18), // زيادة من 14 إلى 18
        color: textColor,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// بناء شريحة الفئة
  Widget _buildCategoryChip(BuildContext context, bool isDark) {
    final Color? chipColor = isDark ? Colors.blue[800] : Colors.blue[50];
    final Color? borderColor = isDark ? Colors.blue[600] : Colors.blue[200];
    final Color? textColor = isDark ? Colors.blue[200] : Colors.blue[700];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing * 0.3,
        vertical: context.responsiveSpacing * 0.1,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 6 : 8,
        ),
        border: Border.all(color: borderColor!),
      ),
      child: Text(
        widget.product.category!,
        style: TextStyle(
          color: textColor,
          fontSize: context.responsiveFontSize(12), // زيادة من 8 إلى 12
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// بناء شريحة سعر التجزئة
  Widget _buildRetailPriceChip(BuildContext context, bool isDark) {
    final Color? chipColor = isDark ? Colors.green[800] : Colors.green[50];
    final Color? borderColor = isDark ? Colors.green[600] : Colors.green[200];
    final Color? textColor = isDark ? Colors.green[200] : Colors.green;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing * 0.3,
        vertical: context.responsiveSpacing * 0.2,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(
          context.isSmallScreen ? 4 : 6,
        ),
        border: Border.all(color: borderColor!),
      ),
      child: Text(
        CurrencyFormatter.formatCurrencyNoDecimals(
            widget.product.retailPrice / 100, context),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: context.responsiveFontSize(14), // زيادة من 10 إلى 14
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// بناء نص سعر الجملة
  Widget _buildWholesalePriceText(BuildContext context, bool isDark) {
    final Color? textColor = isDark
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
        : Colors.grey[600];

    return Text(
      'جملة: ${CurrencyFormatter.formatCurrencyNoDecimals(_wholesalePrice / 100, context)}',
      style: TextStyle(
        color: textColor,
        fontSize: context.responsiveFontSize(12), // زيادة من 8 إلى 12
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// بناء نص الربح
  Widget _buildProfitText(BuildContext context, bool isDark) {
    final Color? textColor = isDark ? Colors.orange[300] : Colors.orange[700];

    return Text(
      'ربح: ${_profitPercentage.toStringAsFixed(1)}%',
      style: TextStyle(
        color: textColor,
        fontSize: context.responsiveFontSize(12), // زيادة من 8 إلى 12
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// بناء شارة الحالة
  Widget _buildStatusBadge(BuildContext context, bool isDark) {
    final Color backgroundColor =
        widget.product.getStatusColor().withValues(alpha: 0.1);
    final Color borderColor = widget.product.getStatusColor();
    final Color textColor = widget.product.getStatusColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        widget.product.getStatusText(),
        style: TextStyle(
          color: textColor,
          fontSize:
              context.responsiveFontSize(12), // استخدام responsive font size
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// بناء معلومات المنتج
  Widget _buildProductInfo(BuildContext context, bool isDark,
      {required bool isCompact}) {
    final ThemeData theme = Theme.of(context);
    final Color? backgroundColor =
        isDark ? theme.colorScheme.surface : Colors.grey[50];
    final Color? borderColor = isDark ? theme.colorScheme.outline : Colors.grey[200];

    return Container(
      padding: isCompact ? _smallPadding : _defaultPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor!),
      ),
      child: Column(
        children: <Widget>[
          // صف الأسعار
          Row(
            children: <Widget>[
              Flexible(
                child: _buildInfoCard(
                  'سعر الجملة',
                  CurrencyFormatter.formatCurrencyNoDecimals(
                      _wholesalePrice / 100, context),
                  Colors.blue,
                  Icons.store,
                  context,
                  isDark,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: _buildInfoCard(
                  'سعر التجزئة',
                  CurrencyFormatter.formatCurrencyNoDecimals(
                      widget.product.retailPrice / 100, context),
                  Colors.green,
                  Icons.shopping_cart,
                  context,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // صف الربح
          Row(
            children: <Widget>[
              Flexible(
                child: _buildInfoCard(
                  'الربح',
                  CurrencyFormatter.formatCurrencyNoDecimals(
                      _profitValue / 100, context),
                  Colors.orange,
                  Icons.trending_up,
                  context,
                  isDark,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: _buildInfoCard(
                  'نسبة الربح',
                  '${_profitPercentage.toStringAsFixed(1)}%',
                  Colors.purple,
                  Icons.percent,
                  context,
                  isDark,
                ),
              ),
            ],
          ),

          // عرض بيانات المخزون إذا كانت متوفرة
          if (_linkedInventoryData != null &&
              _linkedInventoryData!.isLinked) ...<Widget>[
            const SizedBox(height: 8),
            _buildInventoryInfo(context, isDark),
          ],
        ],
      ),
    );
  }

  /// بناء بطاقة معلومات
  Widget _buildInfoCard(
    String label,
    String value,
    Color color,
    IconData icon,
    BuildContext context,
    bool isDark,
  ) {
    final Color backgroundColor = color.withValues(alpha: 0.1);
    final Color borderColor = color.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon,
                  size: context.responsiveFontSize(14),
                  color: color), // زيادة من 12 إلى 14
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize:
                        context.responsiveFontSize(11), // زيادة من 9 إلى 11
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: context.responsiveFontSize(13), // زيادة من 10 إلى 13
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// بناء معلومات المخزون
  Widget _buildInventoryInfo(BuildContext context, bool isDark) {
    final Color? backgroundColor = isDark ? Colors.blue[800] : Colors.blue[50];
    final Color? borderColor = isDark ? Colors.blue[600] : Colors.blue[200];
    final Color? textColor = isDark ? Colors.blue[200] : Colors.blue[700];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor!),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.inventory,
              size: context.responsiveFontSize(18),
              color: textColor), // زيادة من 16 إلى 18
          const SizedBox(width: 8),
          Text(
            'الكمية: ${_linkedInventoryData!.linkedQuantity}',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: context.responsiveFontSize(14), // زيادة من 12 إلى 14
            ),
          ),
          const Spacer(),
          if (_isOutOfStock)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.red[800] : Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'نفدت',
                style: TextStyle(
                  color: isDark ? Colors.red[200] : Colors.red[700],
                  fontSize:
                      context.responsiveFontSize(12), // زيادة من 10 إلى 12
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons(BuildContext context, bool isDark) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: context.responsiveSpacing * 8, // استخدام responsive spacing
        minHeight:
            context.responsiveSpacing * 2.5, // استخدام responsive spacing
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.onEdit != null)
            Flexible(
              child: _buildActionButton(
                icon: Icons.edit,
                label: 'تعديل',
                color: Colors.blue,
                onTap: widget.onEdit!,
                context: context,
                isDark: isDark,
              ),
            ),
          if (widget.onEdit != null && widget.onDelete != null)
            SizedBox(width: context.responsiveSpacing * 0.3),
          if (widget.onDelete != null)
            Flexible(
              child: _buildActionButton(
                icon: Icons.delete,
                label: 'حذف',
                color: Colors.red,
                onTap: widget.onDelete!,
                context: context,
                isDark: isDark,
              ),
            ),
        ],
      ),
    );

  /// بناء صف أزرار الإجراءات
  Widget _buildActionButtonsRow(BuildContext context, bool isDark) {
    final ThemeData theme = Theme.of(context);
    final Color? backgroundColor =
        isDark ? theme.colorScheme.surface : Colors.grey[50];
    final Color? borderColor = isDark ? theme.colorScheme.outline : Colors.grey[200];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (widget.onEdit != null)
            _buildActionButton(
              icon: Icons.edit,
              label: 'تعديل',
              color: Colors.blue,
              onTap: widget.onEdit!,
              context: context,
              isDark: isDark,
            ),
          if (widget.onEdit != null && widget.onDelete != null)
            SizedBox(width: context.responsiveSpacing * 0.8),
          if (widget.onDelete != null)
            _buildActionButton(
              icon: Icons.delete,
              label: 'حذف',
              color: Colors.red,
              onTap: widget.onDelete!,
              context: context,
              isDark: isDark,
            ),
        ],
      ),
    );
  }

  /// بناء زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required BuildContext context,
    required bool isDark,
  }) => Semantics(
      label: label,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth:
                  context.responsiveSpacing * 3, // استخدام responsive spacing
              minHeight:
                  context.responsiveSpacing * 2.2, // استخدام responsive spacing
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing * 0.8,
                vertical: context.responsiveSpacing * 0.4,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: context.responsiveFontSize(16),
                      color: color), // زيادة من 14 إلى 16
                  SizedBox(width: context.responsiveSpacing * 0.3),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: context
                            .responsiveFontSize(12), // زيادة من 10 إلى 12
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
}
