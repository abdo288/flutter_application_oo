import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_pos_reports_providers.dart';
// ✅ استخدام النظام المحسن
import '../../providers/realtime_analytics_riverpod_providers.dart';
import '../models/chart_data.dart';
import '../widgets/simple_chart_widget.dart';
import '../widgets/stat_card_widget.dart';

/// شاشة التحليلات المتقدمة المحسنة
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedChartType = 'daily';

  @override
  Widget build(BuildContext context) {
    // ✅ استخدام النظام المحسن
    final AsyncValue<Map<String, dynamic>> analytics = ref.watch(realtimeAnalyticsStreamProvider);
    final AsyncValue<Map<String, dynamic>> trendAnalysis = ref.watch(realtimeTrendAnalysisStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات المتقدمة المحسنة'),
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
            // ✅ فلاتر التحليل المحسنة
            _buildEnhancedFilters(),

            const SizedBox(height: 24),

            // ✅ بطاقات الإحصائيات المحسنة
            _buildEnhancedAnalyticsCards(analytics, trendAnalysis),

            const SizedBox(height: 24),

            // ✅ الرسوم البيانية المحسنة
            _buildEnhancedCharts(analytics),
          ],
        ),
      ),
    );
  }

  /// بناء فلاتر التحليل المحسنة
  Widget _buildEnhancedFilters() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'فلاتر التحليل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('من تاريخ'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Text(
                                  '${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('إلى تاريخ'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() => _endDate = date);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                              Text(
                                  '${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedChartType,
                    decoration: const InputDecoration(
                      labelText: 'نوع التحليل',
                      border: OutlineInputBorder(),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'daily', child: Text('يومي')),
                      DropdownMenuItem(value: 'hourly', child: Text('ساعي')),
                      DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                      DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _selectedChartType = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

  /// بناء بطاقات التحليلات المحسنة
  Widget _buildEnhancedAnalyticsCards(
    AsyncValue<Map<String, dynamic>> analytics,
    AsyncValue<Map<String, dynamic>> trendAnalysis,
  ) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'التحليلات الرئيسية',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: analytics.when(
                data: (Map<String, dynamic> data) => StatCardWidget(
                  title: 'متوسط المعاملة',
                  value:
                      '${(data['averageTransactionValue'] as double? ?? 0).toStringAsFixed(0)} دج',
                  icon: Icons.trending_up,
                  color: Colors.green,
                ),
                loading: () => const StatCardWidget(
                  title: 'متوسط المعاملة',
                  value: 'جاري التحميل...',
                  icon: Icons.trending_up,
                  color: Colors.grey,
                ),
                error: (_, __) => const StatCardWidget(
                  title: 'متوسط المعاملة',
                  value: 'خطأ في التحميل',
                  icon: Icons.trending_up,
                  color: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: trendAnalysis.when(
                data: (Map<String, dynamic> data) => StatCardWidget(
                  title: 'اتجاه النمو',
                  value:
                      '${(data['revenueGrowth'] as double? ?? 0).toStringAsFixed(1)}%',
                  icon: _getTrendIcon(data['trend'] as String? ?? 'stable'),
                  color: _getTrendColor(data['trend'] as String? ?? 'stable'),
                ),
                loading: () => const StatCardWidget(
                  title: 'اتجاه النمو',
                  value: 'جاري التحميل...',
                  icon: Icons.trending_flat,
                  color: Colors.grey,
                ),
                error: (_, __) => const StatCardWidget(
                  title: 'اتجاه النمو',
                  value: 'خطأ في التحميل',
                  icon: Icons.trending_flat,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );

  /// بناء الرسوم البيانية المحسنة
  Widget _buildEnhancedCharts(AsyncValue<Map<String, dynamic>> analytics) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'الرسوم البيانية',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        analytics.when(
          data: (Map<String, dynamic> data) {
            final Map<int, double> hourlySales =
                data['hourlySales'] as Map<int, double>? ?? <int, double>{};
            final Map<DateTime, double> dailySales = data['dailySales'] as Map<DateTime, double>? ??
                <DateTime, double>{};

            return Column(
              children: <Widget>[
                if (_selectedChartType == 'hourly' && hourlySales.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: SimpleChartWidget(
                      chartData: _buildHourlyChartData(hourlySales),
                    ),
                  )
                else if (_selectedChartType == 'daily' && dailySales.isNotEmpty)
                  SizedBox(
                    height: 200,
                    child: SimpleChartWidget(
                      chartData: _buildDailyChartData(dailySales),
                    ),
                  )
                else
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'لا توجد بيانات للعرض',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const SizedBox(
            height: 200,
            child: Center(
              child: Text(
                'خطأ في تحميل البيانات',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ),
        ),
      ],
    );

  /// بناء بيانات الرسم البياني الساعي
  ChartData _buildHourlyChartData(Map<int, double> hourlySales) => ChartData(
      title: 'المبيعات الساعية',
      chartType: ChartType.line,
      xAxisLabel: 'الساعة',
      yAxisLabel: 'المبلغ (دج)',
      colors: const <ChartColor>[ChartColor(red: 33, green: 150, blue: 243)],
      dataPoints: hourlySales.entries
          .map((MapEntry<int, double> entry) => DataPoint(
                label: '${entry.key}:00',
                value: entry.value,
              ))
          .toList(),
    );

  /// بناء بيانات الرسم البياني اليومي
  ChartData _buildDailyChartData(Map<DateTime, double> dailySales) => ChartData(
      title: 'المبيعات اليومية',
      chartType: ChartType.line,
      xAxisLabel: 'التاريخ',
      yAxisLabel: 'المبلغ (دج)',
      colors: const <ChartColor>[ChartColor(red: 76, green: 175, blue: 80)],
      dataPoints: dailySales.entries
          .map((MapEntry<DateTime, double> entry) => DataPoint(
                label: '${entry.key.day}/${entry.key.month}',
                value: entry.value,
              ))
          .toList(),
    );

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
