import 'package:flutter/material.dart';

import '../utils/responsive_breakpoints.dart';

/// بطاقة إحصائيات محسنة بتصميم HTML للوحة التحكم
class ModernDashboardStatCard extends StatefulWidget {
  const ModernDashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendValue,
    this.delay = Duration.zero,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend; // 'up' or 'down'
  final double? trendValue;
  final Duration delay;
  final VoidCallback? onTap;

  @override
  State<ModernDashboardStatCard> createState() =>
      _ModernDashboardStatCardState();
}

class _ModernDashboardStatCardState extends State<ModernDashboardStatCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // بدء التحريكات مع التأخير
    Future.delayed(widget.delay, () {
      if (mounted) {
        try {
          _fadeController.forward();
          _scaleController.forward();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: context.responsiveSpacing * 0.3,
            horizontal: context.responsiveSpacing * 0.2,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? <Color>[
                      const Color(0xFF334155), // surface-dark
                      const Color(0xFF1E293B), // background-dark
                    ]
                  : <Color>[
                      Colors.white, // surface-light
                      const Color(0xFFF8FAFC), // background-light
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
              color: widget.color.withOpacity(0.2),
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
                padding: EdgeInsets.all(context.responsiveSpacing * 1.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // الصف الأول: الأيقونة والعنوان
                    Row(
                      children: <Widget>[
                        // أيقونة الإحصائية
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: <Color>[
                                widget.color,
                                widget.color.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: widget.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // العنوان
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(14),
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // مؤشر الاتجاه (إن وجد)
                        if (widget.trend != null) _buildTrendIndicator(isDark),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // القيمة الرئيسية
                    Flexible(
                      child: Text(
                        widget.value,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(24),
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // قيمة الاتجاه (إن وجدت)
                    if (widget.trendValue != null) ...<Widget>[
                      const SizedBox(height: 6),
                      _buildTrendValue(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// مؤشر الاتجاه
  Widget _buildTrendIndicator(bool isDark) {
    final bool isUp = widget.trend == 'up';
    final Color trendColor = isUp
        ? const Color(0xFF22C55E) // أخضر للصعود
        : const Color(0xFFEF4444); // أحمر للهبوط

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: trendColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: trendColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: trendColor,
          ),
          const SizedBox(width: 4),
          Text(
            isUp ? 'صاعد' : 'هابط',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  /// قيمة الاتجاه
  Widget _buildTrendValue(bool isDark) {
    final bool isUp = widget.trend == 'up';
    final Color trendColor =
        isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14,
          color: trendColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.trendValue!.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: context.responsiveFontSize(14),
            fontWeight: FontWeight.w600,
            color: trendColor,
          ),
        ),
      ],
    );
  }
}
