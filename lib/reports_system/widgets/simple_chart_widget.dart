import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/chart_data.dart';

/// Widget مبسط للرسوم البيانية
class SimpleChartWidget extends StatelessWidget {
  const SimpleChartWidget({
    super.key,
    required this.chartData,
    this.height = 300,
    this.showLegend = true,
    this.showGrid = true,
  });

  final ChartData chartData;
  final double height;
  final bool showLegend;
  final bool showGrid;

  @override
  Widget build(BuildContext context) => Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // عنوان الرسم البياني
          Text(
            chartData.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // الرسم البياني
          Expanded(
            child: _buildChart(),
          ),
        ],
      ),
    );

  Widget _buildChart() {
    if (chartData.dataPoints.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد بيانات للعرض',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    switch (chartData.chartType) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
      case ChartType.area:
        return _buildAreaChart();
      default:
        return const Center(child: Text('نوع الرسم البياني غير مدعوم'));
    }
  }

  Widget _buildLineChart() => LineChart(
      LineChartData(
        gridData: showGrid
            ? FlGridData(
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
              )
            : const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            
          ),
          topTitles: const AxisTitles(
            
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < chartData.dataPoints.length) {
                  return Text(
                    chartData.dataPoints[value.toInt()].label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
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
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (chartData.dataPoints.length - 1).toDouble(),
        minY: 0,
        maxY: chartData.maxValue * 1.1,
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: chartData.dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) => FlSpot(entry.key.toDouble(), entry.value.value)).toList(),
            isCurved: true,
            color: _getPrimaryColor(),
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: _getPrimaryColor().withOpacity(0.3),
            ),
          ),
        ],
      ),
    );

  Widget _buildBarChart() => BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartData.maxValue * 1.1,
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) => BarTooltipItem(
                '${chartData.dataPoints[group.x].label}\n${rod.toY.toInt()}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            
          ),
          topTitles: const AxisTitles(
            
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < chartData.dataPoints.length) {
                  return Text(
                    chartData.dataPoints[value.toInt()].label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
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
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        barGroups: chartData.dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) => BarChartGroupData(
            x: entry.key,
            barRods: <BarChartRodData>[
              BarChartRodData(
                toY: entry.value.value,
                color: _getPrimaryColor(),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          )).toList(),
      ),
    );

  Widget _buildPieChart() => PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
            // Handle touch events
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: chartData.dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) {
          final int index = entry.key;
          final DataPoint dataPoint = entry.value;
          final List<Color> colors = <Color>[
            _getPrimaryColor(),
            Colors.orange,
            Colors.green,
            Colors.purple,
            Colors.red,
            Colors.blue,
            Colors.teal,
          ];

          return PieChartSectionData(
            color: colors[index % colors.length],
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
      ),
    );

  Widget _buildAreaChart() => LineChart(
      LineChartData(
        gridData: showGrid
            ? FlGridData(
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
              )
            : const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            
          ),
          topTitles: const AxisTitles(
            
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() < chartData.dataPoints.length) {
                  return Text(
                    chartData.dataPoints[value.toInt()].label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
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
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        minX: 0,
        maxX: (chartData.dataPoints.length - 1).toDouble(),
        minY: 0,
        maxY: chartData.maxValue * 1.1,
        lineBarsData: <LineChartBarData>[
          LineChartBarData(
            spots: chartData.dataPoints.asMap().entries.map((MapEntry<int, DataPoint> entry) => FlSpot(entry.key.toDouble(), entry.value.value)).toList(),
            isCurved: true,
            color: _getPrimaryColor(),
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: _getPrimaryColor().withOpacity(0.5),
            ),
          ),
        ],
      ),
    );

  Color _getPrimaryColor() {
    if (chartData.colors.isNotEmpty) {
      final ChartColor color = chartData.colors.first;
      return Color.fromRGBO(
        color.red,
        color.green,
        color.blue,
        color.alpha,
      );
    }
    return Colors.blue;
  }
}
