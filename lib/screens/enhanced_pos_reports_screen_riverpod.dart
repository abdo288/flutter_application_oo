import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/sale.dart';
import '../providers/pos_reports_riverpod_providers.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/snackbar_utils.dart';

// Simple currency formatter function
String formatCurrency(int amount) => '${amount.toString()} DZ';

// Helper function to convert int to double for CurrencyFormatter
String formatCurrencyDouble(int amount, BuildContext context) =>
    CurrencyFormatter.formatCurrency(amount.toDouble(), context);

/// شاشة تقارير نقطة البيع المحسنة مع Riverpod
class EnhancedPOSReportsScreenRiverpod extends ConsumerStatefulWidget {
  const EnhancedPOSReportsScreenRiverpod({super.key});

  @override
  ConsumerState<EnhancedPOSReportsScreenRiverpod> createState() =>
      _EnhancedPOSReportsScreenRiverpodState();
}

class _EnhancedPOSReportsScreenRiverpodState
    extends ConsumerState<EnhancedPOSReportsScreenRiverpod>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // تأجيل تحميل البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(posReportsProvider.notifier).loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final POSReportsState state = ref.watch(posReportsProvider);
    final int unsyncedCount = ref.watch(unsyncedSalesCountProvider);

    // الاستماع للأخطاء
    ref.listen<POSReportsState>(posReportsProvider, (previous, next) {
      if (next.errorMessage != null && mounted) {
        SnackbarUtils.showError(
            context, 'خطأ في تحميل البيانات: ${next.errorMessage}');
        ref.read(posReportsProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقارير نقطة البيع المحسنة (Riverpod)'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const <Widget>[
            Tab(text: 'المبيعات', icon: Icon(Icons.shopping_cart)),
            Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
            Tab(text: 'الرسوم البيانية', icon: Icon(Icons.bar_chart)),
          ],
        ),
        actions: <Widget>[
          // مؤشر حالة المزامنة
          _buildSyncStatusIndicator(unsyncedCount),
          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(posReportsProvider.notifier).refreshData(),
            tooltip: 'تحديث البيانات',
          ),
          IconButton(
            onPressed: _updateDateRange,
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد الفترة',
          ),
          IconButton(
            onPressed: _exportSalesReport,
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'تصدير PDF',
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildSalesTab(),
                _buildStatisticsTab(),
                _buildChartsTab(),
              ],
            ),
    );
  }

  /// بناء تبويب المبيعات
  Widget _buildSalesTab() {
    final POSReportsState state = ref.watch(posReportsProvider);

    return Column(
      children: <Widget>[
        _buildDateRangeBar(),
        _buildSalesStats(),
        Expanded(
          child: state.sales.isEmpty ? _buildEmptySales() : _buildSalesList(),
        ),
      ],
    );
  }

  /// بناء تبويب الإحصائيات
  Widget _buildStatisticsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildGeneralStats(),
            const SizedBox(height: AppConstants.mediumPadding),
            _buildSalesStatistics(),
            const SizedBox(height: AppConstants.mediumPadding),
            _buildInventoryStatistics(),
          ],
        ),
      );

  /// بناء تبويب الرسوم البيانية
  Widget _buildChartsTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSalesChart(),
            const SizedBox(height: AppConstants.largePadding),
            _buildProfitChart(),
            const SizedBox(height: AppConstants.largePadding),
            _buildPaymentMethodChart(),
            const SizedBox(height: AppConstants.largePadding),
            _buildDailySalesChart(),
          ],
        ),
      );

  /// بناء شريط الفترة الزمنية
  Widget _buildDateRangeBar() {
    final POSReportsState state = ref.watch(posReportsProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      margin: const EdgeInsets.all(AppConstants.mediumPadding),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.date_range, color: Colors.purple),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            'الفترة: ${DateFormat('yyyy-MM-dd').format(state.startDate ?? DateTime.now())} - ${DateFormat('yyyy-MM-dd').format(state.endDate ?? DateTime.now())}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _updateDateRange,
            icon: const Icon(Icons.edit),
            label: const Text('تغيير'),
          ),
        ],
      ),
    );
  }

  /// بناء إحصائيات المبيعات
  Widget _buildSalesStats() {
    final POSReportsState state = ref.watch(posReportsProvider);

    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppConstants.mediumPadding),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _buildStatCard(
              'إجمالي المبيعات',
              formatCurrency(state.sales.fold<int>(
                  0, (int sum, Sale sale) => sum + sale.totalAmount)),
              Icons.attach_money,
              Colors.green,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: _buildStatCard(
              'إجمالي الأرباح',
              formatCurrency(state.sales.fold<int>(
                  0, (int sum, Sale sale) => sum + sale.totalProfit)),
              Icons.trending_up,
              Colors.blue,
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: _buildStatCard(
              'عدد العمليات',
              state.sales.length.toString(),
              Icons.receipt,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء بطاقة إحصائية
  Widget _buildStatCard(
          String title, String value, IconData icon, Color color) =>
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.mediumPadding),
          child: Column(
            children: <Widget>[
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  /// بناء قائمة المبيعات
  Widget _buildSalesList() {
    final POSReportsState state = ref.watch(posReportsProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      itemCount: state.sales.length + (state.hasMoreSales ? 1 : 0),
      itemBuilder: (BuildContext context, int index) {
        if (index == state.sales.length) {
          return _buildLoadMoreButton(() {
            ref.read(posReportsProvider.notifier).loadMoreSales();
          });
        }

        final Sale sale = state.sales[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
          color: sale.isSynced ? null : Colors.orange.withOpacity(0.1),
          child: ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // مؤشر حالة المزامنة
                Icon(
                  sale.isSynced ? Icons.cloud_done : Icons.sync_disabled,
                  color: sale.isSynced ? Colors.green : Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            title: Text(formatCurrency(sale.totalAmount)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('الربح: ${formatCurrency(sale.totalProfit)}'),
                Text('طريقة الدفع: ${sale.paymentMethod}'),
                Text(
                    'التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate)}'),
                if (sale.customerName != null)
                  Text('العميل: ${sale.customerName}'),
                if (!sale.isSynced)
                  Text(
                    'غير مزامن',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            trailing: Text('${sale.items.length} عنصر'),
          ),
        );
      },
    );
  }

  /// بناء إحصائيات عامة
  Widget _buildGeneralStats() {
    final POSReportsState state = ref.watch(posReportsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'الإحصائيات العامة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatItem(
                      'إجمالي المبيعات',
                      formatCurrency(state.sales.fold<int>(
                          0, (int sum, Sale sale) => sum + sale.totalAmount))),
                ),
                Expanded(
                  child: _buildStatItem(
                      'إجمالي الأرباح',
                      formatCurrency(state.sales.fold<int>(
                          0, (int sum, Sale sale) => sum + sale.totalProfit))),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildStatItem(
                      'عدد العمليات', state.sales.length.toString()),
                ),
                Expanded(
                  child: _buildStatItem(
                      'متوسط البيع',
                      state.sales.isNotEmpty
                          ? formatCurrency(state.sales.fold<int>(
                                  0,
                                  (int sum, Sale sale) =>
                                      sum + sale.totalAmount) ~/
                              state.sales.length)
                          : '0 DZ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء عنصر إحصائي
  Widget _buildStatItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );

  /// بناء إحصائيات المبيعات
  Widget _buildSalesStatistics() {
    final POSReportsState state = ref.watch(posReportsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'إحصائيات المبيعات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            Text(
                'أعلى مبلغ بيع: ${state.sales.isNotEmpty ? formatCurrency(state.sales.map((Sale sale) => sale.totalAmount).reduce((int a, int b) => a > b ? a : b)) : '0 DZ'}'),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
                'أقل مبلغ بيع: ${state.sales.isNotEmpty ? formatCurrency(state.sales.map((Sale sale) => sale.totalAmount).reduce((int a, int b) => a < b ? a : b)) : '0 DZ'}'),
          ],
        ),
      ),
    );
  }

  /// بناء إحصائيات الجرد
  Widget _buildInventoryStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'إحصائيات الجرد',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
          ],
        ),
      ),
    );
  }

  /// بناء رسم المبيعات
  Widget _buildSalesChart() {
    final List<FlSpot> salesChartData = ref.watch(salesChartDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'رسم المبيعات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            SizedBox(
              height: 200,
              child: salesChartData.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: true),
                        lineBarsData: <LineChartBarData>[
                          LineChartBarData(
                            spots: salesChartData,
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء رسم الأرباح
  Widget _buildProfitChart() {
    final List<FlSpot> profitChartData = ref.watch(profitChartDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'رسم الأرباح',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            SizedBox(
              height: 200,
              child: profitChartData.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: true),
                        lineBarsData: <LineChartBarData>[
                          LineChartBarData(
                            spots: profitChartData,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء رسم طرق الدفع
  Widget _buildPaymentMethodChart() {
    final List<PieChartSectionData> paymentMethodData =
        ref.watch(paymentMethodDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'طرق الدفع',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            SizedBox(
              height: 200,
              child: paymentMethodData.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : PieChart(
                      PieChartData(
                        sections: paymentMethodData,
                        centerSpaceRadius: 40,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء رسم المبيعات اليومية
  Widget _buildDailySalesChart() {
    final List<BarChartGroupData> dailySalesData =
        ref.watch(dailySalesDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'المبيعات اليومية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            SizedBox(
              height: 200,
              child: dailySalesData.isEmpty
                  ? const Center(child: Text('لا توجد بيانات للعرض'))
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: dailySalesData.isNotEmpty
                            ? dailySalesData
                                    .map((BarChartGroupData data) =>
                                        data.barRods.first.toY)
                                    .reduce(
                                        (double a, double b) => a > b ? a : b) *
                                1.1
                            : 100,
                        barGroups: dailySalesData,
                        titlesData: const FlTitlesData(),
                        borderData: FlBorderData(show: true),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء رسالة فارغة للمبيعات
  Widget _buildEmptySales() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            Text(
              'لا توجد عمليات بيع في هذه الفترة',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );

  /// بناء زر تحميل المزيد
  Widget _buildLoadMoreButton(VoidCallback onPressed) => Container(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Center(
          child: ElevatedButton(
            onPressed: onPressed,
            child: const Text('تحميل المزيد'),
          ),
        ),
      );

  /// تحديث نطاق التاريخ
  Future<void> _updateDateRange() async {
    final POSReportsState state = ref.read(posReportsProvider);
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start:
            state.startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: state.endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      await ref
          .read(posReportsProvider.notifier)
          .updateDateRange(picked.start, picked.end);
    }
  }

  /// تصدير تقرير PDF
  Future<void> _exportSalesReport() async {
    final POSReportsState state = ref.read(posReportsProvider);

    if (state.sales.isEmpty) {
      SnackbarUtils.showError(context, 'لا توجد عمليات بيع للتصدير');
      return;
    }

    try {
      final pw.Document pdf = pw.Document();

      // إضافة الصفحة الأولى
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => <pw.Widget>[
            _buildPDFHeader(state),
            pw.SizedBox(height: 20),
            _buildPDFSummary(state),
            pw.SizedBox(height: 20),
            _buildPDFSalesTable(state),
            pw.SizedBox(height: 20),
            _buildPDFCharts(),
          ],
        ),
      );

      // حفظ الملف
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'sales_report_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // طباعة أو مشاركة الملف
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );

      SnackbarUtils.showSuccess(context, 'تم تصدير التقرير بنجاح');
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في تصدير التقرير: $e');
    }
  }

  /// بناء رأس PDF
  pw.Widget _buildPDFHeader(POSReportsState state) => pw.Container(
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColors.purple,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  'تقرير المبيعات (Riverpod)',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'فترة التقرير: ${DateFormat('yyyy-MM-dd').format(state.startDate ?? DateTime.now())} - ${DateFormat('yyyy-MM-dd').format(state.endDate ?? DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
            pw.Text(
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      );

  /// بناء ملخص PDF
  pw.Widget _buildPDFSummary(POSReportsState state) => pw.Container(
        padding: const pw.EdgeInsets.all(15),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: <pw.Widget>[
            _buildPDFSummaryItem(
                'إجمالي المبيعات',
                state.sales.fold<int>(
                    0, (int sum, Sale sale) => sum + sale.totalAmount)),
            _buildPDFSummaryItem(
                'إجمالي الأرباح',
                state.sales.fold<int>(
                    0, (int sum, Sale sale) => sum + sale.totalProfit)),
            _buildPDFSummaryItem('عدد العمليات', state.sales.length),
            _buildPDFSummaryItem(
                'متوسط البيع',
                state.sales.isNotEmpty
                    ? state.sales.fold<int>(0,
                            (int sum, Sale sale) => sum + sale.totalAmount) ~/
                        state.sales.length
                    : 0),
          ],
        ),
      );

  /// بناء عنصر ملخص PDF
  pw.Widget _buildPDFSummaryItem(String title, int value) => pw.Column(
        children: <pw.Widget>[
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            formatCurrency(value),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
        ],
      );

  /// بناء جدول المبيعات PDF
  pw.Widget _buildPDFSalesTable(POSReportsState state) => pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey300),
        columnWidths: <int, pw.TableColumnWidth>{
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(),
          2: const pw.FlexColumnWidth(),
          3: const pw.FlexColumnWidth(),
          4: const pw.FlexColumnWidth(),
        },
        children: <pw.TableRow>[
          // رأس الجدول
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColors.grey200),
            children: <pw.Widget>[
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('التاريخ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('المبلغ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('الربح',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('طريقة الدفع',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text('العميل',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
          // بيانات الجدول
          ...state.sales.take(50).map((Sale sale) => pw.TableRow(
                children: <pw.Widget>[
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatCurrency(sale.totalAmount)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(formatCurrency(sale.totalProfit)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(sale.paymentMethod),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(sale.customerName ?? '-'),
                  ),
                ],
              )),
        ],
      );

  /// بناء الرسوم البيانية PDF
  pw.Widget _buildPDFCharts() => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            'الرسوم البيانية',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'ملاحظة: الرسوم البيانية التفاعلية متوفرة في التطبيق',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ],
      );

  /// بناء مؤشر حالة المزامنة
  Widget _buildSyncStatusIndicator(int unsyncedCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: unsyncedCount > 0 ? Colors.orange : Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            unsyncedCount > 0 ? Icons.sync_disabled : Icons.cloud_done,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            unsyncedCount > 0 ? '$unsyncedCount غير مزامن' : 'مزامن',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
