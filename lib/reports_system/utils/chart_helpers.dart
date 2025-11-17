import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';
import 'reports_constants.dart';

/// مساعدات الرسوم البيانية
class ChartHelpers {
  /// إنشاء ألوان للرسم البياني
  static List<Color> getChartColors(int count) {
    final List<Color> colors = <Color>[];
    for (int i = 0; i < count; i++) {
      final int colorIndex = i % ReportsConstants.chartColors.length;
      colors.add(Color(ReportsConstants.chartColors[colorIndex]));
    }
    return colors;
  }

  /// إنشاء رسم بياني خطي
  static LineChartData createLineChart({
    required List<DataPoint> dataPoints,
    required String title,
    Color? primaryColor,
    Color? secondaryColor,
    bool showGrid = true,
    bool showDots = true,
    bool showArea = false,
  }) {
    final List<Color> colors = getChartColors(2);
    final Color primary = primaryColor ?? colors[0];
    final Color secondary = secondaryColor ?? colors[1];

    return LineChartData(
      gridData: showGrid ? _createGridData() : const FlGridData(show: false),
      titlesData: _createTitlesData(),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      minX: 0,
      maxX: (dataPoints.length - 1).toDouble(),
      minY: 0,
      maxY: _getMaxValue(dataPoints) * 1.1,
      lineBarsData: <LineChartBarData>[
        LineChartBarData(
          spots: dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) => FlSpot(entry.key.toDouble(), entry.value.value)).toList(),
          isCurved: true,
          color: primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: showDots),
          belowBarData: BarAreaData(
            show: showArea,
            color: secondary.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  /// إنشاء رسم بياني عمودي
  static BarChartData createBarChart({
    required List<DataPoint> dataPoints,
    required String title,
    Color? primaryColor,
    bool showTooltips = true,
  }) {
    final List<Color> colors = getChartColors(1);
    final Color primary = primaryColor ?? colors[0];

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: _getMaxValue(dataPoints) * 1.1,
      barTouchData: BarTouchData(
        enabled: showTooltips,
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) => BarTooltipItem(
              '${dataPoints[group.x].label}\n${rod.toY.toInt()}',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
        ),
      ),
      titlesData: _createTitlesData(),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      barGroups: dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) => BarChartGroupData(
          x: entry.key,
          barRods: <BarChartRodData>[
            BarChartRodData(
              toY: entry.value.value,
              color: primary,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        )).toList(),
    );
  }

  /// إنشاء رسم بياني دائري
  static PieChartData createPieChart({
    required List<DataPoint> dataPoints,
    required String title,
    bool showTooltips = true,
    double centerSpaceRadius = 40,
  }) {
    final List<Color> colors = getChartColors(dataPoints.length);

    return PieChartData(
      pieTouchData: PieTouchData(
        enabled: showTooltips,
        touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
          // Handle touch events
        },
      ),
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: centerSpaceRadius,
      sections: dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) {
        final int index = entry.key;
        final DataPoint dataPoint = entry.value;
        final Color color = colors[index % colors.length];

        return PieChartSectionData(
          color: color,
          value: dataPoint.value,
          title: '${dataPoint.value.toInt()}',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList(),
    );
  }

  /// إنشاء رسم بياني مساحي
  static LineChartData createAreaChart({
    required List<DataPoint> dataPoints,
    required String title,
    Color? primaryColor,
    Color? secondaryColor,
  }) => createLineChart(
      dataPoints: dataPoints,
      title: title,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      showArea: true,
    );

  /// إنشاء بيانات الشبكة
  static FlGridData _createGridData() => FlGridData(
      horizontalInterval: 1,
      verticalInterval: 1,
      getDrawingHorizontalLine: (double value) => FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        ),
      getDrawingVerticalLine: (double value) => FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        ),
    );

  /// إنشاء بيانات العناوين
  static FlTitlesData _createTitlesData() => FlTitlesData(
      rightTitles: const AxisTitles(
        
      ),
      topTitles: const AxisTitles(
        
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (double value, TitleMeta meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          reservedSize: 40,
        ),
      ),
    );

  /// حساب القيمة القصوى
  static double _getMaxValue(List<DataPoint> dataPoints) {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints
        .map((DataPoint point) => point.value)
        .reduce((double a, double b) => a > b ? a : b);
  }

  /// إنشاء بيانات تجريبية للرسم البياني
  static List<DataPoint> createSampleData({
    required String type,
    int count = 7,
  }) {
    final List<DataPoint> dataPoints = <DataPoint>[];

    switch (type) {
      case 'daily':
        for (int i = 0; i < count; i++) {
          final DateTime date = DateTime.now().subtract(Duration(days: count - i - 1));
          dataPoints.add(DataPoint(
            label: '${date.day}/${date.month}',
            value: (i + 1) * 100.0 + (i * 50.0),
          ));
        }
        break;
      case 'hourly':
        for (int i = 0; i < count; i++) {
          dataPoints.add(DataPoint(
            label: '${i + 8}:00',
            value: (i + 1) * 50.0,
          ));
        }
        break;
      case 'weekly':
        final List<String> weeks = <String>[
          'الأحد',
          'الاثنين',
          'الثلاثاء',
          'الأربعاء',
          'الخميس',
          'الجمعة',
          'السبت'
        ];
        for (int i = 0; i < count && i < weeks.length; i++) {
          dataPoints.add(DataPoint(
            label: weeks[i],
            value: (i + 1) * 200.0,
          ));
        }
        break;
      case 'monthly':
        final List<String> months = <String>['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو'];
        for (int i = 0; i < count && i < months.length; i++) {
          dataPoints.add(DataPoint(
            label: months[i],
            value: (i + 1) * 1000.0,
          ));
        }
        break;
      default:
        for (int i = 0; i < count; i++) {
          dataPoints.add(DataPoint(
            label: 'عنصر ${i + 1}',
            value: (i + 1) * 100.0,
          ));
        }
    }

    return dataPoints;
  }

  /// إنشاء بيانات تجريبية لتوزيع طرق الدفع
  static List<DataPoint> createPaymentDistributionData() => <DataPoint>[
      const DataPoint(label: 'نقدي', value: 45.0),
      const DataPoint(label: 'بطاقة', value: 35.0),
      const DataPoint(label: 'تحويل بنكي', value: 15.0),
      const DataPoint(label: 'شيك', value: 5.0),
    ];

  /// إنشاء بيانات تجريبية لأفضل المنتجات
  static List<DataPoint> createTopProductsData() => <DataPoint>[
      const DataPoint(label: 'منتج 1', value: 150.0),
      const DataPoint(label: 'منتج 2', value: 120.0),
      const DataPoint(label: 'منتج 3', value: 100.0),
      const DataPoint(label: 'منتج 4', value: 80.0),
      const DataPoint(label: 'منتج 5', value: 60.0),
    ];

  /// تنسيق القيم للعرض
  static String formatValue(double value, {String unit = ''}) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M$unit';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K$unit';
    } else {
      return '${value.toStringAsFixed(0)}$unit';
    }
  }

  /// تنسيق العملة
  static String formatCurrency(double value) => '${value.toStringAsFixed(2)} ر.س';

  /// تنسيق النسبة المئوية
  static String formatPercentage(double value) => '${value.toStringAsFixed(1)}%';

  /// إنشاء تدرج لوني
  static LinearGradient createGradient(Color startColor, Color endColor) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[startColor, endColor],
    );

  /// إنشاء تدرج دائري
  static RadialGradient createRadialGradient(
      Color centerColor, Color edgeColor) => RadialGradient(
      radius: 0.8,
      colors: <Color>[centerColor, edgeColor],
    );

  /// إنشاء ظل للبطاقة
  static List<BoxShadow> createCardShadow() => <BoxShadow>[
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        spreadRadius: 1,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

  /// إنشاء ظل للزر
  static List<BoxShadow> createButtonShadow() => <BoxShadow>[
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 1,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];

  /// إنشاء ظل للرسم البياني
  static List<BoxShadow> createChartShadow() => <BoxShadow>[
      BoxShadow(
        color: Colors.grey.withOpacity(0.15),
        spreadRadius: 1,
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ];
}
