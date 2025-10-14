import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة منتج محسنة لـ Windows مع تصميم HTML وعرض عمودي قابل للتوسيع
class WindowsProductCard extends StatefulWidget {
  const WindowsProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.showActions = true,
    this.compactMode = false,
    this.isExpanded = false,
    this.onExpansionChanged,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool showActions;
  final bool compactMode;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<WindowsProductCard> createState() => _WindowsProductCardState();
}

class _WindowsProductCardState extends State<WindowsProductCard>
    with TickerProviderStateMixin {
  final bool _isDeleting = false;
  late AnimationController _rotationController;
  late AnimationController _scaleController;

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
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Product product = widget.product;

    // إذا كان المنتج في حالة حذف، اعرض مؤشر التحميل
    if (_isDeleting) {
      return _buildDeletingCard(product, isDark);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      constraints: widget.isExpanded
          ? const BoxConstraints(maxHeight: 600)
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
              ? <Color>[
                  const Color(0xFF334155),
                  const Color(0xFF1E293B),
                ]
              : <Color>[
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(product, isDark),
          width: widget.isExpanded ? 2 : 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap ?? _toggleExpanded,
          child: Padding(
            padding: EdgeInsets.all(widget.isExpanded
                ? context.responsiveSpacing * 1.0
                : context.responsiveSpacing * 0.3),
            child: widget.isExpanded
                ? _ExpandedContent(
                    product: product,
                    isDark: isDark,
                    onEdit: widget.onEdit,
                    onDelete: widget.onDelete,
                    showActions: widget.showActions,
                    onToggleExpanded: _toggleExpanded,
                  )
                : _CollapsedRow(
                    product: product,
                    isDark: isDark,
                    onToggleExpanded: _toggleExpanded,
                  ),
          ),
        ),
      ),
    );
  }

  /// بطاقة الحذف
  Widget _buildDeletingCard(Product product, bool isDark) => Container(
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
                'جاري حذف ${product.name}...',
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

  /// الحصول على لون الحدود حسب حالة المنتج
  Color _getBorderColor(Product product, bool isDark) {
    if (product.retailPrice <= product.wholesalePrice) {
      return isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
    } else if (product.retailPrice - product.wholesalePrice < 100) {
      return isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B);
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
    required this.product,
    required this.isDark,
    required this.onToggleExpanded,
  });

  final Product product;
  final bool isDark;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final TextStyle textStyle = TextStyle(
      fontSize: context.responsiveFontSize(14),
      fontWeight: FontWeight.w600,
      color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
    );

    return Row(
      children: <Widget>[
        // الاسم — يأخذ المساحة المرنة
        Expanded(
          child: Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: context.responsiveFontSize(15),
            ),
          ),
        ),

        // فاصل صغير
        const SizedBox(width: 8),

        // السعر — شارة أنيقة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF2563EB).withOpacity(0.2),
            ),
          ),
          child: Text(
            CurrencyFormatter.formatCurrency(
                product.retailPrice.toDouble(), context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle.copyWith(
              color: const Color(0xFF2563EB),
              fontSize: context.responsiveFontSize(12),
            ),
          ),
        ),

        // فاصل صغير
        const SizedBox(width: 8),

        // الربح — شارة مميزة
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF22C55E).withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.trending_up,
                size: 16,
                color: Color(0xFF22C55E),
              ),
              const SizedBox(width: 4),
              Text(
                CurrencyFormatter.formatCurrency(
                  (product.retailPrice - product.wholesalePrice).toDouble(),
                  context,
                ),
                style: textStyle.copyWith(
                  color: const Color(0xFF22C55E),
                  fontSize: context.responsiveFontSize(12),
                ),
              ),
            ],
          ),
        ),

        // فاصل صغير
        const SizedBox(width: 6),

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
class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.product,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.showActions,
    required this.onToggleExpanded,
  });

  final Product product;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showActions;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                  product.name,
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

          // الباركود (إذا كان متوفراً)
          if (product.barcode != null && product.barcode!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code,
                    color: const Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      product.barcode!,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyBarcode(product.barcode!, context),
                    icon: Icon(
                      Icons.copy,
                      color: const Color(0xFF2563EB),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // المعلومات المالية
          IntrinsicHeight(
            child: Row(
              children: [
                // سعر البيع
                Expanded(
                  child: _buildInfoCard(
                    'سعر البيع',
                    CurrencyFormatter.formatCurrency(
                      product.retailPrice.toDouble(),
                      context,
                    ),
                    const Color(0xFF2563EB),
                    Icons.sell,
                  ),
                ),

                const SizedBox(width: 8),

                // سعر الجملة
                Expanded(
                  child: _buildInfoCard(
                    'سعر الجملة',
                    CurrencyFormatter.formatCurrency(
                      product.wholesalePrice.toDouble(),
                      context,
                    ),
                    const Color(0xFF8B5CF6),
                    Icons.store,
                  ),
                ),

                const SizedBox(width: 8),

                // الربح
                Expanded(
                  child: _buildInfoCard(
                    'الربح',
                    CurrencyFormatter.formatCurrency(
                      (product.retailPrice - product.wholesalePrice).toDouble(),
                      context,
                    ),
                    const Color(0xFF22C55E),
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // تفاصيل إضافية
          _buildExpandedContent(product, isDark, context),

          const SizedBox(height: 16),

          // الأزرار
          if (showActions) ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'تحرير',
                    Icons.edit,
                    const Color(0xFF22C55E),
                    onEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'حذف',
                    Icons.delete,
                    const Color(0xFFEF4444),
                    onDelete,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

  /// بناء بطاقة المعلومات
  Widget _buildInfoCard(
      String label, String value, Color color, IconData icon) => Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

  /// بناء زر الإجراء
  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) => ElevatedButton.icon(
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

  /// بناء المحتوى القابل للتوسيع
  Widget _buildExpandedContent(
      Product product, bool isDark, BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'تفاصيل إضافية',
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

          // معلومات إضافية
          _buildDetailRow(
              'تاريخ الإضافة',
              _formatDate(product.savedAt.toIso8601String()),
              Icons.calendar_today,
              const Color(0xFF22C55E),
              isDark),

          const SizedBox(height: 12),

          _buildDetailRow('حالة المزامنة', 'مزامن', Icons.sync,
              const Color(0xFF22C55E), isDark),

          const SizedBox(height: 12),

          _buildDetailRow(
              'آخر تعديل',
              _formatDate(product.lastModified?.toIso8601String() ??
                  product.savedAt.toIso8601String()),
              Icons.access_time,
              const Color(0xFF2563EB),
              isDark),
        ],
      ),
    );

  /// بناء صف التفاصيل
  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color, bool isDark) => Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );

  /// تنسيق التاريخ
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
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
