import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/inventory_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة مخزون محسنة بتصميم HTML مع دعم Dark Mode
class ModernInventoryCard extends StatefulWidget {
  const ModernInventoryCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onPrint,
    required this.onDelete,
    this.showActions = true,
    this.compactMode = false,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onPrint;
  final VoidCallback onDelete;
  final bool showActions;
  final bool compactMode;

  @override
  State<ModernInventoryCard> createState() => _ModernInventoryCardState();
}

class _ModernInventoryCardState extends State<ModernInventoryCard>
    with TickerProviderStateMixin {
  bool _expanded = false;
  bool _isDeleting = false;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final item = widget.item;

    // إذا كان العنصر في حالة حذف، اعرض مؤشر التحميل
    if (_isDeleting) {
      return _buildDeletingCard(item, isDark);
    }

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: context.responsiveSpacing * 0.5,
        horizontal: context.responsiveSpacing * 0.25,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF334155), // surface-dark
                  const Color(0xFF1E293B), // background-dark
                ]
              : [
                  Colors.white, // surface-light
                  const Color(0xFFF8FAFC), // background-light
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _getBorderColor(item, isDark),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleExpanded(),
          child: Padding(
            padding: EdgeInsets.all(context.responsiveSpacing * 1.0),
            child: Column(
              children: [
                _buildCompactView(item, isDark),
                _buildExpandedDetails(item, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// العرض المضغوط المحسّن بتصميم HTML
  Widget _buildCompactView(InventoryItem item, bool isDark) {
    return Column(
      children: [
        // الصف الأول: الاسم والحالة
        Row(
          children: [
            // أيقونة المنتج
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(item).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                color: _getStatusColor(item),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // اسم المنتج
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الكود: ${item.barcode ?? 'غير محدد'}',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(12),
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // شارة التحذير (إن وجدت)
            if (item.quantity <= 10) _buildWarningBadge(isDark),

            const SizedBox(width: 8),

            // أيقونة التوسيع
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 3.14159, // 180 degrees
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: const Color(0xFF2563EB),
                    size: 24,
                  ),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // الصف الثاني: المعلومات الأساسية
        Row(
          children: [
            _buildInfoChip(
              icon: Icons.inventory_2_outlined,
              label: 'الكمية',
              value: '${item.quantity} قطعة',
              color: const Color(0xFF2563EB),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              icon: Icons.sell_outlined,
              label: 'سعر البيع',
              value: CurrencyFormatter.formatCurrency(
                  item.retailPrice.toDouble(), context),
              color: const Color(0xFF22C55E),
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              icon: Icons.trending_up,
              label: 'الربح',
              value: CurrencyFormatter.formatCurrency(
                (item.retailPrice - item.wholesalePrice).toDouble(),
                context,
              ),
              color: const Color(0xFF8B5CF6),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  /// شارة التحذير بتصميم HTML
  Widget _buildWarningBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF7C2D12) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFFDC2626) : const Color(0xFFF59E0B),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber,
            size: 16,
            color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            'كمية منخفضة',
            style: TextStyle(
              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF92400E),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget مساعد للمعلومات
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// التفاصيل الموسعة
  Widget _buildExpandedDetails(InventoryItem item, bool isDark) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: _expanded
          ? Column(
              children: [
                const SizedBox(height: 16),
                Divider(
                  height: 24,
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFE2E8F0),
                ),

                // معلومات مالية مفصلة (بتصميم HTML)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B),
                              const Color(0xFF0F172A),
                            ]
                          : [
                              const Color(0xFFF8FAFC),
                              const Color(0xFFF1F5F9),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'سعر الشراء:',
                        CurrencyFormatter.formatCurrency(
                            item.wholesalePrice.toDouble(), context),
                        Icons.shopping_cart_outlined,
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'سعر البيع:',
                        CurrencyFormatter.formatCurrency(
                            item.retailPrice.toDouble(), context),
                        Icons.sell_outlined,
                        const Color(0xFF22C55E),
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'الربح للقطعة:',
                        CurrencyFormatter.formatCurrency(
                          (item.retailPrice - item.wholesalePrice).toDouble(),
                          context,
                        ),
                        Icons.trending_up,
                        const Color(0xFF8B5CF6),
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'آخر تحديث:',
                        _getTimeAgo(item.addedDate),
                        Icons.access_time,
                        const Color(0xFF64748B),
                        isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // الباركود (إن وجد)
                if (item.barcode != null && item.barcode!.isNotEmpty)
                  _buildBarcodeSection(item.barcode!, isDark),

                const SizedBox(height: 16),

                // أزرار الإجراءات بتصميم محسّن
                if (widget.showActions) _buildActionsRow(isDark),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  /// قسم الباركود
  Widget _buildBarcodeSection(String barcode, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2563EB).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.qr_code,
              size: 20,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الباركود:',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  barcode,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFF1E293B),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'نسخ الباركود',
            icon: const Icon(
              Icons.copy,
              size: 20,
              color: Color(0xFF2563EB),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: barcode));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ الباركود'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  /// أزرار الإجراءات بتصميم HTML
  Widget _buildActionsRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'تحرير',
            icon: Icons.edit_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
            ),
            onPressed: widget.onEdit,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            label: 'طباعة',
            icon: Icons.print_outlined,
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
            ),
            onPressed: widget.onPrint,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildActionButton(
            label: 'حذف',
            icon: Icons.delete_outline,
            gradient: const LinearGradient(
              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            ),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بطاقة الحذف
  Widget _buildDeletingCard(InventoryItem item, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: context.responsiveSpacing * 0.5,
        horizontal: context.responsiveSpacing * 0.25,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.responsiveSpacing * 1.0),
        child: Row(
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'جاري حذف ${item.name}...',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
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

  /// تبديل حالة التوسيع
  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });

    if (mounted) {
      try {
        if (_expanded) {
          _rotationController.forward();
        } else {
          _rotationController.reverse();
        }
      } catch (e) {
        // تجاهل الأخطاء إذا تم التخلص من المتحكمات
      }
    }
  }

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

  /// الحصول على لون الحالة
  Color _getStatusColor(InventoryItem item) {
    if (item.isOutOfStock()) {
      return const Color(0xFFEF4444);
    } else if (item.quantity <= 10) {
      return const Color(0xFFF59E0B);
    } else {
      return const Color(0xFF22C55E);
    }
  }

  /// حساب الوقت النسبي
  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
