import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة منتج محسنة لـ POS مع تصميم HTML وعرض عمودي قابل للتوسيع
class WindowsPOSCard extends StatefulWidget {
  const WindowsPOSCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onDiscountChanged,
    this.isExpanded = false,
    this.onExpansionChanged,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final ValueChanged<double>? onDiscountChanged;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<WindowsPOSCard> createState() => _WindowsPOSCardState();
}

class _WindowsPOSCardState extends State<WindowsPOSCard>
    with TickerProviderStateMixin {
  bool _isDeleting = false;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  final TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _discountController.text = widget.item.discount.toString();
  }

  @override
  void didUpdateWidget(WindowsPOSCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // تحديث controller الخصم عند تغيير القيمة
    if (oldWidget.item.discount != widget.item.discount) {
      _discountController.text = widget.item.discount.toString();
    }

    // إعادة بناء البطاقة عند تغيير أي خاصية في item
    if (oldWidget.item.quantity != widget.item.quantity ||
        oldWidget.item.retailPrice != widget.item.retailPrice ||
        oldWidget.item.discount != widget.item.discount ||
        oldWidget.item.name != widget.item.name) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    // إذا كان العنصر في حالة حذف، اعرض مؤشر التحميل
    if (_isDeleting) {
      return _buildDeletingCard(item, isDark);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      constraints: widget.isExpanded
          ? const BoxConstraints(maxHeight: 800)
          : const BoxConstraints.tightFor(height: 76),
      margin: EdgeInsets.symmetric(
        vertical: widget.isExpanded
            ? context.responsiveSpacing * 0.3
            : context.responsiveSpacing * 0.05,
        horizontal: context.responsiveSpacing * 0.1,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF334155),
                  const Color(0xFF1E293B),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(item, isDark),
          width: widget.isExpanded ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _toggleExpanded,
          child: Padding(
            padding: EdgeInsets.all(widget.isExpanded
                ? context.responsiveSpacing * 1.0
                : context.responsiveSpacing * 0.3),
            child: widget.isExpanded
                ? _ExpandedContent(
                    item: item,
                    isDark: isDark,
                    onQuantityChanged: widget.onQuantityChanged,
                    onRemove: widget.onRemove,
                    onDiscountChanged: widget.onDiscountChanged,
                    onToggleExpanded: _toggleExpanded,
                    discountController: _discountController,
                  )
                : _CollapsedRow(
                    item: item,
                    isDark: isDark,
                    onQuantityChanged: widget.onQuantityChanged,
                    onRemove: widget.onRemove,
                    onToggleExpanded: _toggleExpanded,
                  ),
          ),
        ),
      ),
    );
  }

  /// بطاقة الحذف
  Widget _buildDeletingCard(CartItem item, bool isDark) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        vertical: context.responsiveSpacing * 0.5,
        horizontal: context.responsiveSpacing * 0.25,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.responsiveSpacing * 1.5),
        child: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'جاري حذف ${item.name}...',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// الحصول على لون الحدود حسب حالة المنتج
  Color _getBorderColor(CartItem item, bool isDark) {
    if (item.discount > 0) {
      return isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B);
    } else if (item.quantity <= 1) {
      return isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
    } else {
      return isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0);
    }
  }

  /// تبديل حالة التوسيع
  void _toggleExpanded() {
    if (widget.onExpansionChanged != null) {
      widget.onExpansionChanged!(!widget.isExpanded);
    }

    if (mounted) {
      try {
        if (!widget.isExpanded) {
          _rotationController.forward();
        } else {
          _rotationController.reverse();
        }
      } catch (e) {
        // تجاهل الأخطاء إذا تم التخلص من المتحكمات
      }
    }
  }
}

/// صف مختصر للعرض المضغوط
class _CollapsedRow extends StatelessWidget {
  const _CollapsedRow({
    required this.item,
    required this.isDark,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onToggleExpanded,
  });

  final CartItem item;
  final bool isDark;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: context.responsiveFontSize(14),
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // اسم المنتج
        Expanded(
          child: Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: context.responsiveFontSize(16),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // الكمية
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.3),
            ),
          ),
          child: Text(
            '${item.quantity}',
            style: textStyle.copyWith(
              color: const Color(0xFF22C55E),
              fontSize: context.responsiveFontSize(14),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(width: 12),

        // المجموع النهائي
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item.discount > 0
                  ? [
                      const Color(0xFFF59E0B).withOpacity(0.2),
                      const Color(0xFFF59E0B).withOpacity(0.1),
                    ]
                  : [
                      const Color(0xFF2563EB).withOpacity(0.2),
                      const Color(0xFF2563EB).withOpacity(0.1),
                    ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item.discount > 0
                  ? const Color(0xFFF59E0B).withOpacity(0.4)
                  : const Color(0xFF2563EB).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.discount > 0) ...[
                    Icon(
                      Icons.discount,
                      size: 16,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    CurrencyFormatter.formatCurrency(
                      item.discount > 0
                          ? ((item.retailPrice * item.quantity) - item.discount)
                              .toDouble()
                          : (item.retailPrice * item.quantity).toDouble(),
                      context,
                    ),
                    style: textStyle.copyWith(
                      color: item.discount > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF2563EB),
                      fontSize: context.responsiveFontSize(14),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (item.discount > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'خصم: ${CurrencyFormatter.formatCurrency(item.discount.toDouble(), context)}',
                  style: textStyle.copyWith(
                    fontSize: context.responsiveFontSize(10),
                    color: const Color(0xFFF59E0B).withOpacity(0.8),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 8),

        // زر التوسيع/الانغلاق
        AnimatedRotation(
          turns: 0.0, // دائماً في حالة الإغلاق
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            onPressed: onToggleExpanded,
            icon: Icon(
              Icons.expand_more,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              size: 16,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
        ),
      ],
    );
  }
}

/// محتوى موسع مع تمرير سلس
class _ExpandedContent extends StatefulWidget {
  const _ExpandedContent({
    required this.item,
    required this.isDark,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onDiscountChanged,
    required this.onToggleExpanded,
    required this.discountController,
  });

  final CartItem item;
  final bool isDark;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final ValueChanged<double>? onDiscountChanged;
  final VoidCallback onToggleExpanded;
  final TextEditingController discountController;

  @override
  State<_ExpandedContent> createState() => _ExpandedContentState();
}

class _ExpandedContentState extends State<_ExpandedContent> {
  bool _showProductDetails = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    final onQuantityChanged = widget.onQuantityChanged;
    final onRemove = widget.onRemove;
    final onDiscountChanged = widget.onDiscountChanged;
    final onToggleExpanded = widget.onToggleExpanded;
    final discountController = widget.discountController;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // الصف الأول في العرض الموسع
              Row(
                children: [
                  // العنوان
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(18),
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 8),

                  // زر التوسيع/الانغلاق
                  AnimatedRotation(
                    turns: 0.5, // دائماً في حالة التوسيع
                    duration: const Duration(milliseconds: 300),
                    child: IconButton(
                      onPressed: onToggleExpanded,
                      icon: Icon(
                        Icons.expand_more,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // زر تفاصيل المنتج - قابل للنقر
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showProductDetails = !_showProductDetails;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                const Color(0xFF1E293B),
                                const Color(0xFF334155),
                              ]
                            : [
                                const Color(0xFFF8FAFC),
                                const Color(0xFFE2E8F0),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عنوان القسم مع أيقونة التوسيع
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: const Color(0xFF2563EB),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'تفاصيل المنتج',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Icon(
                              _showProductDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: const Color(0xFF2563EB),
                              size: 24,
                            ),
                          ],
                        ),

                        // نص توضيحي
                        const SizedBox(height: 8),
                        Text(
                          _showProductDetails
                              ? 'انقر لإخفاء التفاصيل'
                              : 'انقر لعرض تفاصيل المنتج',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF2563EB).withOpacity(0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        // التفاصيل (تظهر عند التوسيع)
                        if (_showProductDetails) ...[
                          const SizedBox(height: 16),

                          // الباركود
                          _buildDetailInfoRow(
                            'الباركود',
                            item.barcode,
                            Icons.qr_code,
                            const Color(0xFF2563EB),
                            isDark,
                            onCopy: () => _copyBarcode(item.barcode, context),
                          ),

                          const SizedBox(height: 12),

                          // معرف المنتج
                          _buildDetailInfoRow(
                            'معرف المنتج',
                            item.productId,
                            Icons.fingerprint,
                            const Color(0xFF8B5CF6),
                            isDark,
                          ),

                          const SizedBox(height: 12),

                          // سعر الجملة
                          _buildDetailInfoRow(
                            'سعر الجملة',
                            CurrencyFormatter.formatCurrency(
                                item.wholesalePrice.toDouble(), context),
                            Icons.store,
                            const Color(0xFFF59E0B),
                            isDark,
                          ),

                          const SizedBox(height: 12),

                          // هامش الربح
                          _buildDetailInfoRow(
                            'هامش الربح',
                            CurrencyFormatter.formatCurrency(
                                (item.retailPrice - item.wholesalePrice)
                                    .toDouble(),
                                context),
                            Icons.trending_up,
                            const Color(0xFF22C55E),
                            isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // المعلومات المالية المحسنة
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان القسم
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: const Color(0xFF22C55E),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'المعلومات المالية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // صفوف المعلومات المالية
                    _buildFinancialRow(
                      'السعر الفردي',
                      CurrencyFormatter.formatCurrency(
                          item.retailPrice.toDouble(), context),
                      Icons.price_check,
                      const Color(0xFF2563EB),
                      isDark,
                    ),

                    const SizedBox(height: 8),

                    _buildFinancialRow(
                      'الكمية',
                      '${item.quantity} ${item.quantity > 1 ? 'منتجات' : 'منتج'}',
                      Icons.shopping_bag,
                      const Color(0xFF8B5CF6),
                      isDark,
                    ),

                    const SizedBox(height: 8),

                    _buildFinancialRow(
                      'السعر الإجمالي',
                      CurrencyFormatter.formatCurrency(
                          (item.retailPrice * item.quantity).toDouble(),
                          context),
                      Icons.calculate,
                      const Color(0xFF3B82F6),
                      isDark,
                      subtitle:
                          '${CurrencyFormatter.formatCurrency(item.retailPrice.toDouble(), context)} × $item.quantity',
                    ),

                    if (item.discount > 0) ...[
                      const SizedBox(height: 8),
                      _buildFinancialRow(
                        'الخصم',
                        CurrencyFormatter.formatCurrency(
                            item.discount.toDouble(), context),
                        Icons.discount,
                        const Color(0xFFF59E0B),
                        isDark,
                        subtitle: 'خصم من المجموع الإجمالي',
                      ),
                      const SizedBox(height: 8),
                      _buildFinancialRow(
                        'المجموع النهائي',
                        CurrencyFormatter.formatCurrency(
                            ((item.retailPrice * item.quantity) - item.discount)
                                .toDouble(),
                            context),
                        Icons.check_circle,
                        const Color(0xFF22C55E),
                        isDark,
                        subtitle:
                            '${CurrencyFormatter.formatCurrency((item.retailPrice * item.quantity).toDouble(), context)} - ${CurrencyFormatter.formatCurrency(item.discount.toDouble(), context)}',
                        isHighlighted: true,
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      _buildFinancialRow(
                        'المجموع النهائي',
                        CurrencyFormatter.formatCurrency(
                            (item.retailPrice * item.quantity).toDouble(),
                            context),
                        Icons.check_circle,
                        const Color(0xFF22C55E),
                        isDark,
                        isHighlighted: true,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // هامش الربح
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF22C55E).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: const Color(0xFF22C55E),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'هامش الربح الإجمالي',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.formatCurrency(
                                    ((item.retailPrice * item.quantity) -
                                            item.discount -
                                            (item.wholesalePrice *
                                                item.quantity))
                                        .toDouble(),
                                    context,
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF22C55E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // تفاصيل الخصم (عند وجود أكثر من منتج واحد)
              if (item.quantity > 1 && item.discount > 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withOpacity(0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF475569)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calculate,
                            color: const Color(0xFFF59E0B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'تفاصيل الحساب',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'السعر الإجمالي',
                        '${CurrencyFormatter.formatCurrency(item.retailPrice.toDouble(), context)} × $item.quantity = ${CurrencyFormatter.formatCurrency((item.retailPrice * item.quantity).toDouble(), context)}',
                        Icons.price_check,
                        const Color(0xFF2563EB),
                        isDark,
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        'الخصم من المجموع',
                        CurrencyFormatter.formatCurrency(
                            item.discount.toDouble(), context),
                        Icons.discount,
                        const Color(0xFFF59E0B),
                        isDark,
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(
                        'المجموع النهائي',
                        '${CurrencyFormatter.formatCurrency((item.retailPrice * item.quantity).toDouble(), context)} - ${CurrencyFormatter.formatCurrency(item.discount.toDouble(), context)} = ${CurrencyFormatter.formatCurrency(((item.retailPrice * item.quantity) - item.discount).toDouble(), context)}',
                        Icons.check_circle,
                        const Color(0xFF22C55E),
                        isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // أزرار التحكم
              Row(
                children: [
                  // تقليل الكمية
                  Expanded(
                    child: _buildActionButton(
                      'تقليل',
                      Icons.remove,
                      const Color(0xFFEF4444),
                      () => onQuantityChanged(math.max(0, item.quantity - 1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // زيادة الكمية
                  Expanded(
                    child: _buildActionButton(
                      'زيادة',
                      Icons.add,
                      const Color(0xFF22C55E),
                      () => onQuantityChanged(item.quantity + 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // حذف
                  Expanded(
                    child: _buildActionButton(
                      'حذف',
                      Icons.delete,
                      const Color(0xFFEF4444),
                      onRemove,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // إدخال الخصم - في الأسفل
              if (onDiscountChanged != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B),
                              const Color(0xFF334155),
                            ]
                          : [
                              const Color(0xFFF8FAFC),
                              const Color(0xFFE2E8F0),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // عنوان القسم مع أيقونة
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.discount,
                              color: const Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'تعديل الخصم',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // حقل إدخال الخصم محسن
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'مبلغ الخصم (دينار)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: discountController,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFFF1F5F9)
                                    : const Color(0xFF1E293B),
                              ),
                              decoration: InputDecoration(
                                hintText: 'أدخل مبلغ الخصم',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFF59E0B)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFF59E0B)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF59E0B),
                                    width: 2,
                                  ),
                                ),
                                prefixIcon: Icon(
                                  Icons.discount,
                                  color: const Color(0xFFF59E0B),
                                ),
                                suffixIcon: Icon(
                                  Icons.edit,
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.7),
                                  size: 20,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: (value) {
                                final discount = double.tryParse(value) ?? 0.0;
                                onDiscountChanged(discount);
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // معلومات إضافية
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFFF59E0B),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الخصم سيُطبق على المجموع الإجمالي للمنتجات',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFF59E0B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// بناء صف التفاصيل
  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// بناء صف معلومات تفصيلي مع إمكانية النسخ
  Widget _buildDetailInfoRow(
      String label, String value, IconData icon, Color color, bool isDark,
      {VoidCallback? onCopy}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCopy,
              icon: Icon(
                Icons.copy,
                color: color,
                size: 18,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء صف معلومات مالي
  Widget _buildFinancialRow(
      String label, String value, IconData icon, Color color, bool isDark,
      {String? subtitle, bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isHighlighted ? color.withOpacity(0.15) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isHighlighted ? color.withOpacity(0.4) : color.withOpacity(0.2),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isHighlighted ? 16 : 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// بناء زر الإجراء
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// نسخ الباركود
  Future<void> _copyBarcode(String barcode, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: barcode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ الباركود: $barcode'),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }
}
