import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/realtime_update_service.dart';

/// Widget لعرض رسوم بيانية لإحصائيات التحديثات الفورية
class RealtimeStatsChart extends StatefulWidget {
  const RealtimeStatsChart({super.key});

  @override
  State<RealtimeStatsChart> createState() => _RealtimeStatsChartState();
}

class _RealtimeStatsChartState extends State<RealtimeStatsChart>
    with TickerProviderStateMixin {
  final RealtimeUpdateService _realtimeService = RealtimeUpdateService.instance;

  late TabController _tabController;
  Map<String, dynamic> _performanceStats = <String, dynamic>{};
  Map<String, dynamic> _typeStats = <String, dynamic>{};
  Map<String, dynamic> _actionStats = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadStats() {
    setState(() {
      _performanceStats = _realtimeService.getPerformanceStats();
      _typeStats = _realtimeService.getUpdateStatsByType();
      _actionStats = _realtimeService.getUpdateStatsByAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    // معالجة خاصة لـ Windows
    if (Platform.isWindows) {
      return _buildWindowsOptimizedChart(context);
    }

    return _buildDefaultChart(context);
  }

  /// بناء رسم بياني محسن لـ Windows
  Widget _buildWindowsOptimizedChart(BuildContext context) => Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            // Windows-specific header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.laptop_windows,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إحصائيات التحديثات - Windows',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث الإحصائيات',
                  ),
                ],
              ),
            ),

            // Windows-optimized Tab Bar
            TabBar(
              controller: _tabController,
              isScrollable: true, // إضافة scrollable لـ Windows
              tabAlignment: TabAlignment.start, // محاذاة خاصة لـ Windows
              tabs: const <Widget>[
                Tab(text: 'الأداء', icon: Icon(Icons.speed)),
                Tab(text: 'النوع', icon: Icon(Icons.category)),
                Tab(text: 'الإجراء', icon: Icon(Icons.touch_app)),
              ],
            ),

            // Windows-optimized Tab Views
            SizedBox(
              height: 350, // زيادة الارتفاع لـ Windows
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildWindowsPerformanceChart(),
                  _buildWindowsTypeChart(),
                  _buildWindowsActionChart(),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء رسم بياني افتراضي
  Widget _buildDefaultChart(BuildContext context) => Card(
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'إحصائيات التحديثات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadStats,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث الإحصائيات',
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              tabs: const <Widget>[
                Tab(text: 'الأداء', icon: Icon(Icons.speed)),
                Tab(text: 'النوع', icon: Icon(Icons.category)),
                Tab(text: 'الإجراء', icon: Icon(Icons.touch_app)),
              ],
            ),

            // Tab Views
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildPerformanceChart(),
                  _buildTypeChart(),
                  _buildActionChart(),
                ],
              ),
            ),
          ],
        ),
      );

  /// رسم بياني للأداء
  Widget _buildPerformanceChart() {
    final double successRate =
        (_performanceStats['successRate'] as double?) ?? 0.0;
    final int totalUpdates = (_performanceStats['totalUpdates'] as int?) ?? 0;
    final int successCount = (_performanceStats['successCount'] as int?) ?? 0;
    final int failureCount = (_performanceStats['failureCount'] as int?) ?? 0;
    final int avgResponseTime =
        (_performanceStats['avgResponseTime'] as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Success Rate Pie Chart
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sections: <PieChartSectionData>[
                        PieChartSectionData(
                          value: successCount.toDouble(),
                          title: 'نجح',
                          color: Colors.green,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: failureCount.toDouble(),
                          title: 'فشل',
                          color: Colors.red,
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildStatItem('إجمالي التحديثات',
                          totalUpdates.toString(), Colors.blue),
                      _buildStatItem('معدل النجاح',
                          '${successRate.toStringAsFixed(1)}%', Colors.green),
                      _buildStatItem('متوسط وقت الاستجابة',
                          '${avgResponseTime}ms', Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// رسم بياني حسب النوع
  Widget _buildTypeChart() {
    final Map<String, int> totalStats = Map<String, int>.from(
        (_typeStats['total'] as Map<String, dynamic>?) ?? <String, int>{});

    if (totalStats.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات متاحة'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: totalStats.values
                        .reduce((int a, int b) => a > b ? a : b)
                        .toDouble() +
                    5,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (BarChartGroupData group, int groupIndex,
                        BarChartRodData rod, int rodIndex) {
                      final String type = _getTypeName(group.x.toInt());
                      return BarTooltipItem(
                        '$type\n${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) =>
                          Text(_getTypeName(value.toInt())),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) =>
                          Text(value.toInt().toString()),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    totalStats.entries.map((MapEntry<String, int> entry) {
                  final int index = totalStats.keys.toList().indexOf(entry.key);
                  return BarChartGroupData(
                    x: index,
                    barRods: <BarChartRodData>[
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            children: <Widget>[
              _buildLegendItem('إجمالي', Colors.blue),
              _buildLegendItem('نجح', Colors.green),
              _buildLegendItem('فشل', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  /// رسم بياني حسب الإجراء
  Widget _buildActionChart() {
    final Map<String, int> totalStats = Map<String, int>.from(
        (_actionStats['total'] as Map<String, dynamic>?) ?? <String, int>{});

    if (totalStats.isEmpty) {
      return const Center(
        child: Text('لا توجد بيانات متاحة'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) =>
                          Text(_getActionName(value.toInt())),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) =>
                          Text(value.toInt().toString()),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    spots:
                        totalStats.entries.map((MapEntry<String, int> entry) {
                      final int index =
                          totalStats.keys.toList().indexOf(entry.key);
                      return FlSpot(index.toDouble(), entry.value.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(),
                    belowBarData: BarAreaData(
                        show: true, color: Colors.blue.withOpacity(0.3)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildStatItem(
                  'إجمالي',
                  totalStats.values.fold(0, (int a, int b) => a + b).toString(),
                  Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء عنصر إحصائية
  Widget _buildStatItem(String label, String value, Color color) => Column(
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );

  /// بناء عنصر الأسطورة
  Widget _buildLegendItem(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      );

  /// الحصول على اسم النوع
  String _getTypeName(int index) {
    final List<String> types = <String>['product', 'inventory', 'sale'];
    if (index >= 0 && index < types.length) {
      switch (types[index]) {
        case 'product':
          return 'منتجات';
        case 'inventory':
          return 'مخزون';
        case 'sale':
          return 'مبيعات';
        default:
          return types[index];
      }
    }
    return 'غير معروف';
  }

  /// الحصول على اسم الإجراء
  String _getActionName(int index) {
    final List<String> actions = <String>['create', 'update', 'delete', 'sync'];
    if (index >= 0 && index < actions.length) {
      switch (actions[index]) {
        case 'create':
          return 'إنشاء';
        case 'update':
          return 'تحديث';
        case 'delete':
          return 'حذف';
        case 'sync':
          return 'مزامنة';
        default:
          return actions[index];
      }
    }
    return 'غير معروف';
  }

  // ========== دوال محسنة لـ Windows ==========

  /// رسم بياني للأداء محسن لـ Windows
  Widget _buildWindowsPerformanceChart() {
    final double successRate =
        (_performanceStats['successRate'] as double?) ?? 0.0;
    final int totalUpdates = (_performanceStats['totalUpdates'] as int?) ?? 0;
    final double avgResponseTime =
        ((_performanceStats['avgResponseTime'] as num?) ?? 0).toDouble();

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Windows-specific info header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.speed, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'إحصائيات الأداء - Windows',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Performance metrics
          Row(
            children: <Widget>[
              Expanded(
                child: _buildWindowsStatCard(
                  'معدل النجاح',
                  '${(successRate * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWindowsStatCard(
                  'إجمالي التحديثات',
                  totalUpdates.toString(),
                  Icons.update,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildWindowsStatCard(
                  'متوسط وقت الاستجابة',
                  '${avgResponseTime.toStringAsFixed(0)}ms',
                  Icons.timer,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildWindowsStatCard(
                  'نوع المزامنة',
                  'دورية',
                  Icons.sync,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// رسم بياني للنوع محسن لـ Windows
  Widget _buildWindowsTypeChart() {
    final Map<String, int> typeStats = Map<String, int>.from(
        (_typeStats['total'] as Map<String, dynamic>?) ?? <String, int>{});

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Windows-specific info header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.category, color: Colors.purple.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'إحصائيات النوع - Windows',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Type statistics
          if (typeStats.isNotEmpty) ...<Widget>[
            ...typeStats.entries
                .map((MapEntry<String, int> entry) =>
                    _buildWindowsTypeItem(entry.key, entry.value))
                .toList(),
          ] else ...<Widget>[
            const Center(
              child: Text('لا توجد بيانات متاحة'),
            ),
          ],
        ],
      ),
    );
  }

  /// رسم بياني للإجراء محسن لـ Windows
  Widget _buildWindowsActionChart() {
    final Map<String, int> actionStats = Map<String, int>.from(
        (_actionStats['total'] as Map<String, dynamic>?) ?? <String, int>{});

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: <Widget>[
          // Windows-specific info header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.touch_app, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'إحصائيات الإجراء - Windows',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action statistics
          if (actionStats.isNotEmpty) ...<Widget>[
            ...actionStats.entries
                .map((MapEntry<String, int> entry) =>
                    _buildWindowsActionItem(entry.key, entry.value))
                .toList(),
          ] else ...<Widget>[
            const Center(
              child: Text('لا توجد بيانات متاحة'),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية لـ Windows
  Widget _buildWindowsStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// بناء عنصر نوع لـ Windows
  Widget _buildWindowsTypeItem(String type, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            _getTypeDisplayName(type),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء عنصر إجراء لـ Windows
  Widget _buildWindowsActionItem(String action, int count) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            _getActionDisplayName(action),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على اسم العرض للنوع
  String _getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return 'منتج';
      case 'inventory':
        return 'مخزون';
      case 'sale':
        return 'بيع';
      case 'sync':
        return 'مزامنة';
      default:
        return type;
    }
  }

  /// الحصول على اسم العرض للإجراء
  String _getActionDisplayName(String action) {
    switch (action.toLowerCase()) {
      case 'add':
        return 'إضافة';
      case 'update':
        return 'تحديث';
      case 'delete':
        return 'حذف';
      case 'sync':
        return 'مزامنة';
      default:
        return action;
    }
  }
}
