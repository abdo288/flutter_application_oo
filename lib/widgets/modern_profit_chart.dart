import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../utils/responsive_breakpoints.dart';

/// مخطط الأرباح محسن بتصميم HTML
class ModernProfitChart extends StatefulWidget {
  const ModernProfitChart({
    super.key,
    required this.title,
    required this.profitHistory,
    this.height,
    this.onTap,
  });

  final String title;
  final List<Map<String, dynamic>> profitHistory;
  final double? height;
  final VoidCallback? onTap;

  @override
  State<ModernProfitChart> createState() => _ModernProfitChartState();
}

class _ModernProfitChartState extends State<ModernProfitChart>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // بدء التحريكات
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          _fadeController.forward();
          _slideController.forward();
        } catch (e) {
          // تجاهل الأخطاء إذا تم التخلص من المتحكمات
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(
            vertical: context.responsiveSpacing * 0.5,
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
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: EdgeInsets.all(context.responsiveSpacing * 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // العنوان
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF2563EB),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: context.responsiveFontSize(18),
                              color: isDark
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        // أيقونة التفاعل
                        Icon(
                          Icons.touch_app,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),

                    SizedBox(height: context.responsiveSpacing * 1.0),

                    // المخطط
                    Container(
                      height:
                          widget.height ?? (context.isSmallScreen ? 250 : 300),
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: widget.profitHistory.isEmpty
                            ? _buildEmptyState(isDark)
                            : LineChart(_createChartData(isDark)),
                      ),
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

  /// حالة فارغة
  Widget _buildEmptyState(bool isDark) => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات للعرض',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );

  /// إنشاء بيانات المخطط
  LineChartData _createChartData(bool isDark) {
    final List<FlSpot> spots = widget.profitHistory
        .asMap()
        .entries
        .map((MapEntry<int, Map<String, dynamic>> e) =>
            FlSpot(e.key.toDouble(), (e.value['profit'] as num).toDouble()))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        getDrawingHorizontalLine: (double value) => FlLine(
          color: isDark
              ? const Color(0xFF475569).withOpacity(0.3)
              : const Color(0xFFE2E8F0).withOpacity(0.5),
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (double value) => FlLine(
          color: isDark
              ? const Color(0xFF475569).withOpacity(0.3)
              : const Color(0xFFE2E8F0).withOpacity(0.5),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (double value, TitleMeta meta) => Text(
              _formatValue(value),
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (widget.profitHistory.length / 5).ceil().toDouble(),
            getTitlesWidget: (double value, TitleMeta meta) {
              final int index = value.toInt();
              if (index < widget.profitHistory.length) {
                return Text(
                  widget.profitHistory[index]['date'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        rightTitles: const AxisTitles(),
        topTitles: const AxisTitles(),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569).withOpacity(0.3)
              : const Color(0xFFE2E8F0).withOpacity(0.5),
        ),
      ),
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          spots: spots,
          isCurved: true,
          gradient: const LinearGradient(
            colors: <Color>[
              Color(0xFF2563EB),
              Color(0xFF3B82F6),
              Color(0xFF8B5CF6),
            ],
          ),
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            getDotPainter: (FlSpot spot, double percent,
                LineChartBarData barData, int index) => FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF2563EB),
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: <Color>[
                const Color(0xFF2563EB).withOpacity(0.3),
                const Color(0xFF3B82F6).withOpacity(0.1),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  /// تنسيق القيم
  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}
