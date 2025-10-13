import 'package:flutter/material.dart';

import '../utils/currency_formatter.dart';
import '../utils/responsive_breakpoints.dart';

/// بطاقة المنتج الأكثر ربحية محسنة بتصميم HTML
class ModernProductProfitCard extends StatefulWidget {
  const ModernProductProfitCard({
    super.key,
    required this.rank,
    required this.productName,
    required this.profit,
    required this.profitPercentage,
    this.onTap,
  });

  final int rank;
  final String productName;
  final double profit;
  final double profitPercentage;
  final VoidCallback? onTap;

  @override
  State<ModernProductProfitCard> createState() =>
      _ModernProductProfitCardState();
}

class _ModernProductProfitCardState extends State<ModernProductProfitCard>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.rank * 100)),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // بدء التحريكات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _slideController.forward();
          _scaleController.forward();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rankColor = _getRankColor(widget.rank - 1);

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing * 0.5),
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
              color: rankColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.all(context.responsiveSpacing * 1.0),
                child: Row(
                  children: [
                    // ترتيب المنتج
                    Container(
                      width: context.responsiveSpacing * 3.0,
                      height: context.responsiveSpacing * 3.0,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            rankColor,
                            rankColor.withOpacity(0.8),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: rankColor.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.rank}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: context.responsiveFontSize(16),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // معلومات المنتج
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // اسم المنتج
                          Text(
                            widget.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.responsiveFontSize(16),
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 8),

                          // صف الربح والنسبة
                          Row(
                            children: [
                              // قيمة الربح
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22C55E)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF22C55E)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.trending_up,
                                        size: 16,
                                        color: const Color(0xFF22C55E),
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          CurrencyFormatter.formatCurrency(
                                            widget.profit,
                                            context,
                                          ),
                                          style: TextStyle(
                                            color: const Color(0xFF22C55E),
                                            fontSize:
                                                context.responsiveFontSize(14),
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // نسبة الربح
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: rankColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: rankColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${widget.profitPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: rankColor,
                                    fontSize: context.responsiveFontSize(14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // أيقونة السهم
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// الحصول على لون الترتيب
  Color _getRankColor(int index) => switch (index) {
        0 => const Color(0xFFFFD700), // ذهبي للمركز الأول
        1 => const Color(0xFFC0C0C0), // فضي للمركز الثاني
        2 => const Color(0xFFCD7F32), // برونزي للمركز الثالث
        _ => const Color(0xFF2563EB), // أزرق للباقي
      };
}
