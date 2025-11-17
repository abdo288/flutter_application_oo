import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/sale.dart';
import '../../providers/enhanced_pos_reports_providers.dart';
// ✅ استخدام النظام المحسن
import '../../providers/realtime_analytics_riverpod_providers.dart';
import '../models/chart_data.dart';
import '../widgets/simple_chart_widget.dart';
import '../widgets/stat_card_widget.dart';

/// شاشة لوحة التحكم الرئيسية المحسنة
class DashboardScreenFixed extends ConsumerWidget {
  const DashboardScreenFixed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ استخدام النظام المحسن
    final AsyncValue<Map<String, dynamic>> realtimeAnalytics =
        ref.watch(realtimeAnalyticsStreamProvider);
    final EnhancedPOSReportsState enhancedReports =
        ref.watch(enhancedPOSReportsProvider);
    final AsyncValue<Map<String, dynamic>> trendAnalysis =
        ref.watch(realtimeTrendAnalysisStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم المحسنة'),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              // ✅ تحديث البيانات باستخدام النظام المحسن
              ref.read(enhancedPOSReportsProvider.notifier).refreshData();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ✅ بطاقات الإحصائيات المحسنة في الوقت الفعلي
            _buildEnhancedStatsCards(realtimeAnalytics, trendAnalysis),

            const SizedBox(height: 24),

            // ✅ الرسم البياني المحسن للمبيعات
            _buildEnhancedSalesChart(enhancedReports),

            const SizedBox(height: 24),

            // ✅ أفضل المنتجات المحسنة
            _buildEnhancedTopProducts(enhancedReports),

            const SizedBox(height: 24),

            // ✅ تنبيهات المخزون المحسنة
            _buildEnhancedLowStockAlerts(enhancedReports),
          ],
        ),
      ),
    );
  }

  /// بناء أفضل المنتجات المحسنة
  Widget _buildEnhancedTopProducts(EnhancedPOSReportsState enhancedReports) {
    final List<dynamic> topProducts =
        enhancedReports.advancedAnalytics?['topProducts'] as List<dynamic>? ??
            <dynamic>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'أفضل المنتجات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topProducts.isNotEmpty)
              ...topProducts.take(5).map((product) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        (product['totalProfit'] as double? ?? 0)
                            .toStringAsFixed(0),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                    title: Text(product['name'] as String? ?? 'غير محدد'),
                    subtitle: Text(
                        'الربح: ${(product['totalProfit'] as double? ?? 0).toStringAsFixed(0)} دج'),
                    trailing: Text('${product['totalQuantity'] ?? 0} قطعة'),
                  ))
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'لا توجد بيانات للمنتجات',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// بناء تنبيهات المخزون المحسنة
  Widget _buildEnhancedLowStockAlerts(
          EnhancedPOSReportsState enhancedReports) =>
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'تنبيهات المخزون',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'لا توجد تنبيهات حالياً',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ✅ الدوال الجديدة للنظام المحسن

  /// بناء بطاقات الإحصائيات المحسنة
  Widget _buildEnhancedStatsCards(
    AsyncValue<Map<String, dynamic>> analytics,
    AsyncValue<Map<String, dynamic>> trendAnalysis,
  ) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'الإحصائيات الرئيسية',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: analytics.when(
                      data: (Map<String, dynamic> data) => StatCardWidget(
                        title: 'إجمالي الإيرادات',
                        value:
                            '${(data['totalRevenue'] as double? ?? 0).toStringAsFixed(0)} دج',
                        icon: Icons.attach_money,
                        color: Colors.green,
                      ),
                      loading: () => const StatCardWidget(
                        title: 'إجمالي الإيرادات',
                        value: 'جاري التحميل...',
                        icon: Icons.attach_money,
                        color: Colors.grey,
                      ),
                      error: (_, __) => const StatCardWidget(
                        title: 'إجمالي الإيرادات',
                        value: 'خطأ في التحميل',
                        icon: Icons.attach_money,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: analytics.when(
                      data: (Map<String, dynamic> data) => StatCardWidget(
                        title: 'إجمالي الأرباح',
                        value:
                            '${(data['totalProfit'] as double? ?? 0).toStringAsFixed(0)} دج',
                        icon: Icons.trending_up,
                      ),
                      loading: () => const StatCardWidget(
                        title: 'إجمالي الأرباح',
                        value: 'جاري التحميل...',
                        icon: Icons.trending_up,
                        color: Colors.grey,
                      ),
                      error: (_, __) => const StatCardWidget(
                        title: 'إجمالي الأرباح',
                        value: 'خطأ في التحميل',
                        icon: Icons.trending_up,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: analytics.when(
                      data: (Map<String, dynamic> data) => StatCardWidget(
                        title: 'عدد المعاملات',
                        value: '${data['totalTransactions'] ?? 0}',
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                      ),
                      loading: () => const StatCardWidget(
                        title: 'عدد المعاملات',
                        value: 'جاري التحميل...',
                        icon: Icons.shopping_cart,
                        color: Colors.grey,
                      ),
                      error: (_, __) => const StatCardWidget(
                        title: 'عدد المعاملات',
                        value: 'خطأ في التحميل',
                        icon: Icons.shopping_cart,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: trendAnalysis.when(
                      data: (Map<String, dynamic> data) => StatCardWidget(
                        title: 'نمو الإيرادات',
                        value:
                            '${(data['revenueGrowth'] as double? ?? 0).toStringAsFixed(1)}%',
                        icon:
                            _getTrendIcon(data['trend'] as String? ?? 'stable'),
                        color: _getTrendColor(
                            data['trend'] as String? ?? 'stable'),
                      ),
                      loading: () => const StatCardWidget(
                        title: 'نمو الإيرادات',
                        value: 'جاري التحميل...',
                        icon: Icons.trending_flat,
                        color: Colors.grey,
                      ),
                      error: (_, __) => const StatCardWidget(
                        title: 'نمو الإيرادات',
                        value: 'خطأ في التحميل',
                        icon: Icons.trending_flat,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// بناء الرسم البياني المحسن للمبيعات
  Widget _buildEnhancedSalesChart(EnhancedPOSReportsState enhancedReports) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'الرسم البياني للمبيعات',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (enhancedReports.sales.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: SimpleChartWidget(
                    chartData: _buildChartDataFromSales(enhancedReports.sales),
                  ),
                )
              else
                const SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'لا توجد بيانات للمبيعات',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );

  /// بناء بيانات الرسم البياني من المبيعات
  ChartData _buildChartDataFromSales(List<Sale> sales) {
    final Map<String, double> dailySales = <String, double>{};

    for (final Sale sale in sales) {
      final String dateKey = '${sale.saleDate.day}/${sale.saleDate.month}';
      dailySales[dateKey] = (dailySales[dateKey] ?? 0) + sale.totalAmount;
    }

    return ChartData(
      title: 'المبيعات اليومية',
      chartType: ChartType.line,
      xAxisLabel: 'التاريخ',
      yAxisLabel: 'المبلغ (دج)',
      colors: const <ChartColor>[
        ChartColor(red: 33, green: 150, blue: 243),
        ChartColor(red: 76, green: 175, blue: 80),
      ],
      dataPoints: dailySales.entries
          .map((MapEntry<String, double> entry) => DataPoint(
                label: entry.key,
                value: entry.value,
              ))
          .toList(),
    );
  }

  /// الحصول على أيقونة الاتجاه
  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'growing':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  /// الحصول على لون الاتجاه
  Color _getTrendColor(String trend) {
    switch (trend) {
      case 'growing':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
