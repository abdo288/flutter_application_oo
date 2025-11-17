import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/inventory_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة مخزون محسنة لـ Windows مع تصميم HTML وعرض عمودي قابل للتوسيع
class WindowsInventoryCard extends StatefulWidget {
  const WindowsInventoryCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    this.showActions = true,
    this.compactMode = false,
    this.isExpanded = false,
    this.onExpansionChanged,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onDelete;
  final bool showActions;
  final bool compactMode;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<WindowsInventoryCard> createState() => _WindowsInventoryCardState();
}

class _WindowsInventoryCardState extends State<WindowsInventoryCard>
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
    final InventoryItem item = widget.item;

    // إذا كان العنصر في حالة حذف، اعرض مؤشر التحميل
    if (_isDeleting) {
      return _buildDeletingCard(item, isDark);
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
            : context.responsiveSpacing * 0.05, // تقليل المسافة العمودية
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
                : context.responsiveSpacing * 0.3), // تقليل المسافة الداخلية
            child: widget.isExpanded
                ? _ExpandedContent(
                    item: item,
                    isDark: isDark,
                    onEdit: widget.onEdit,
                    onPrint: widget.onPrint,
                    onDelete: widget.onDelete,
                    showActions: widget.showActions,
                    onToggleExpanded: _toggleExpanded,
                    onCopyBarcode: _copyBarcode,
                  )
                : _CollapsedRow(
                    item: item,
                    isDark: isDark,
                    onToggleExpanded: _toggleExpanded,
                  ),
          ),
        ),
      ),
    );
  }

  /// نسخ الباركود
  Future<void> _copyBarcode(String barcode) async {
    await Clipboard.setData(ClipboardData(text: barcode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم نسخ الباركود: $barcode'),
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    }
  }

  /// بطاقة الحذف
  Widget _buildDeletingCard(InventoryItem item, bool isDark) => Container(
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
          children: <Widget>[
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

  /// الحصول على لون الحدود حسب حالة المخزون
  Color _getBorderColor(InventoryItem item, bool isDark) {
    if (item.isOutOfStock()) {
      return isDark ? const Color(0xFFDC2626) : const Color(0xFFEF4444);
    } else if (item.quantity <= 10) {
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
    required this.item,
    required this.isDark,
    required this.onToggleExpanded,
  });

  final InventoryItem item;
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
            item.name,
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

        // الكود — شارة أنيقة
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
            item.barcode ?? item.id?.toString() ?? 'غير محدد',
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

        // الكمية — شارة مميزة
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
                Icons.inventory_2_rounded,
                size: 16,
                color: Color(0xFF22C55E),
              ),
              const SizedBox(width: 4),
              Text(
                '${item.quantity}',
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
    required this.item,
    required this.isDark,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    required this.showActions,
    required this.onToggleExpanded,
    required this.onCopyBarcode,
  });

  final InventoryItem item;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onDelete;
  final bool showActions;
  final VoidCallback onToggleExpanded;
  final Future<void> Function(String) onCopyBarcode;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // الصف الأول في العرض الموسع
          Row(
            children: <Widget>[
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

              // الكود
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'الكود: ${item.id ?? 'غير محدد'}',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(12),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
          if (item.barcode != null && item.barcode!.isNotEmpty) ...<Widget>[
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
                children: <Widget>[
                  const Icon(
                    Icons.qr_code,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.barcode!,
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
                    onPressed: () => onCopyBarcode(item.barcode!),
                    icon: const Icon(
                      Icons.copy,
                      color: Color(0xFF2563EB),
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
              children: <Widget>[
                // الربح
                Expanded(
                  child: _buildInfoCard(
                    'الربح',
                    CurrencyFormatter.formatCurrency(
                      (item.retailPrice - item.wholesalePrice).toDouble(),
                      context,
                    ),
                    const Color(0xFF8B5CF6),
                    Icons.trending_up,
                  ),
                ),

                const SizedBox(width: 8),

                // سعر البيع
                Expanded(
                  child: _buildInfoCard(
                    'البيع',
                    CurrencyFormatter.formatCurrency(
                      item.retailPrice.toDouble(),
                      context,
                    ),
                    const Color(0xFF22C55E),
                    Icons.sell,
                  ),
                ),

                const SizedBox(width: 8),

                // الكمية
                Expanded(
                  child: _buildInfoCard(
                    'كمية',
                    item.quantity.toString(),
                    const Color(0xFF2563EB),
                    Icons.inventory,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // تفاصيل إضافية
          _buildExpandedContent(item, isDark, context),

          const SizedBox(height: 16),

          // الأزرار
          if (showActions) ...<Widget>[
            Row(
              children: <Widget>[
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
                    'طباعة',
                    Icons.print,
                    const Color(0xFF2563EB),
                    onPrint,
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
        children: <Widget>[
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
      InventoryItem item, bool isDark, BuildContext context) => Container(
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
        children: <Widget>[
          // عنوان القسم
          Row(
            children: <Widget>[
              const Icon(
                Icons.info_outline,
                color: Color(0xFF2563EB),
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
              'سعر الجملة',
              CurrencyFormatter.formatCurrency(
                  item.wholesalePrice.toDouble(), context),
              Icons.store,
              const Color(0xFF8B5CF6),
              isDark),

          const SizedBox(height: 12),

          _buildDetailRow('الكمية الأصلية', item.originalQuantity.toString(),
              Icons.inventory_2, const Color(0xFF2563EB), isDark),

          const SizedBox(height: 12),

          _buildDetailRow(
              'تاريخ الإضافة',
              _formatDate(item.addedDate.toIso8601String()),
              Icons.calendar_today,
              const Color(0xFF22C55E),
              isDark),

          const SizedBox(height: 12),

          _buildDetailRow(
              'وقت الإضافة',
              _formatTime(item.addedTime.toIso8601String()),
              Icons.access_time,
              const Color(0xFFF59E0B),
              isDark),

          const SizedBox(height: 16),

          // حالة المخزون
          _buildStockStatus(item, isDark),
        ],
      ),
    );

  /// بناء صف التفاصيل
  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color, bool isDark) => Row(
      children: <Widget>[
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

  /// بناء حالة المخزون
  Widget _buildStockStatus(InventoryItem item, bool isDark) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (item.isOutOfStock()) {
      statusColor = const Color(0xFFEF4444);
      statusText = 'نفد المخزون';
      statusIcon = Icons.warning;
    } else if (item.quantity <= 10) {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'مخزون منخفض';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = const Color(0xFF22C55E);
      statusText = 'متوفر';
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Text(
            'حالة المخزون: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  /// تنسيق التاريخ
  String _formatDate(String dateString) {
    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  /// تنسيق الوقت
  String _formatTime(String timeString) {
    try {
      final DateTime time = DateTime.parse(timeString);
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeString;
    }
  }
}
