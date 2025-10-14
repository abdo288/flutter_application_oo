import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/page_result.dart';
import '../models/quick_inventory_item.dart';
import '../models/sale.dart';
import '../services/error_handler_service.dart';
import '../services/pos_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/snackbar_utils.dart';

// Simple currency formatter function
String formatCurrency(int amount) => '${amount.toString()} DZ';

// Helper function to convert int to double for CurrencyFormatter
String formatCurrencyDouble(int amount, BuildContext context) => CurrencyFormatter.formatCurrency(amount.toDouble(), context);

/// شاشة تقارير نقطة البيع المحسنة
class EnhancedPOSReportsScreen extends StatefulWidget {
  const EnhancedPOSReportsScreen({super.key});

  @override
  State<EnhancedPOSReportsScreen> createState() =>
      _EnhancedPOSReportsScreenState();
}

class _EnhancedPOSReportsScreenState extends State<EnhancedPOSReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Sale> _sales = <Sale>[];
  List<QuickInventoryItem> _quickInventoryItems = <QuickInventoryItem>[];
  bool _isLoading = false;
  bool _isLoadingMoreSales = false;
  bool _isLoadingMoreQuick = false;
  bool _hasMoreSales = true;
  bool _hasMoreQuick = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastQuickDoc;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  // Chart data
  List<FlSpot> _salesChartData = <FlSpot>[];
  List<FlSpot> _profitChartData = <FlSpot>[];
  List<PieChartSectionData> _paymentMethodData = <PieChartSectionData>[];
  List<BarChartGroupData> _dailySalesData = <BarChartGroupData>[];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // تأجيل تحميل البيانات إلى ما بعد اكتمال أول عملية بناء
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// تحميل البيانات
  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await Future.wait(<Future<void>>[
        _loadSales(),
        _loadQuickInventoryItems(),
      ]);
      _prepareChartData();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تحميل البيانات: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// تحميل عمليات البيع
  Future<void> _loadSales() async {
    try {
      final PageResult<Sale> page = await POSService.getCombinedSalesPage(
        startDate: _startDate,
        endDate: _endDate,
      );
      if (mounted) {
        setState(() {
          _sales = page.items;
          _hasMoreSales = page.hasMore;
        });
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل عمليات البيع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadSales',
        },
      );
      debugPrint('خطأ في تحميل عمليات البيع: $e');
    }
  }

  /// تحميل عناصر الجرد السريع
  Future<void> _loadQuickInventoryItems() async {
    try {
      _lastQuickDoc = null;
      final PageResult<QuickInventoryItem> page =
          await POSService.getQuickInventoryPage();
      if (mounted) {
        setState(() {
          _quickInventoryItems = page.items;
          _lastQuickDoc = page.lastDocument;
          _hasMoreQuick = page.hasMore;
        });
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل عناصر الجرد السريع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadQuickInventoryItems',
        },
      );
      debugPrint('خطأ في تحميل عناصر الجرد السريع: $e');
    }
  }

  /// إعداد بيانات الرسوم البيانية
  void _prepareChartData() {
    _prepareSalesChartData();
    _prepareProfitChartData();
    _preparePaymentMethodData();
    _prepareDailySalesData();
  }

  /// إعداد بيانات رسم المبيعات
  void _prepareSalesChartData() {
    final Map<String, double> dailySales = <String, double>{};

    for (final Sale sale in _sales) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
      dailySales[dateKey] =
          (dailySales[dateKey] ?? 0) + sale.totalAmount.toDouble();
    }

    _salesChartData = dailySales.entries.map((MapEntry<String, double> entry) {
      final DateTime date = DateTime.parse(entry.key);
      final double daysSinceStart =
          date.difference(_startDate).inDays.toDouble();
      return FlSpot(daysSinceStart, entry.value);
    }).toList()
      ..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
  }

  /// إعداد بيانات رسم الأرباح
  void _prepareProfitChartData() {
    final Map<String, double> dailyProfit = <String, double>{};

    for (final Sale sale in _sales) {
      final String dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
      dailyProfit[dateKey] =
          (dailyProfit[dateKey] ?? 0) + sale.totalProfit.toDouble();
    }

    _profitChartData =
        dailyProfit.entries.map((MapEntry<String, double> entry) {
      final DateTime date = DateTime.parse(entry.key);
      final double daysSinceStart =
          date.difference(_startDate).inDays.toDouble();
      return FlSpot(daysSinceStart, entry.value);
    }).toList()
          ..sort((FlSpot a, FlSpot b) => a.x.compareTo(b.x));
  }

  /// إعداد بيانات طرق الدفع
  void _preparePaymentMethodData() {
    final Map<String, int> paymentMethods = <String, int>{};

    for (final Sale sale in _sales) {
      paymentMethods[sale.paymentMethod] =
          (paymentMethods[sale.paymentMethod] ?? 0) + 1;
    }

    final List<Color> colors = <Color>[
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];

    _paymentMethodData =
        paymentMethods.entries.map((MapEntry<String, int> entry) {
      final int index = paymentMethods.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: entry.key,
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// إعداد بيانات المبيعات اليومية
  void _prepareDailySalesData() {
    final Map<String, double> dailySales = <String, double>{};

    for (final Sale sale in _sales) {
      final String dateKey = DateFormat('MM-dd').format(sale.saleDate);
      dailySales[dateKey] =
          (dailySales[dateKey] ?? 0) + sale.totalAmount.toDouble();
    }

    _dailySalesData = dailySales.entries.map((MapEntry<String, double> entry) {
      final int index = dailySales.keys.toList().indexOf(entry.key);
      return BarChartGroupData(
        x: index,
        barRods: <BarChartRodData>[
          BarChartRodData(
            toY: entry.value,
            color: Colors.purple,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// تحديث نطاق التاريخ
  Future<void> _updateDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  /// تصدير تقرير PDF
  Future<void> _exportSalesReport() async {
    if (_sales.isEmpty) {
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
            _buildPDFHeader(),
            pw.SizedBox(height: 20),
            _buildPDFSummary(),
            pw.SizedBox(height: 20),
            _buildPDFSalesTable(),
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
  pw.Widget _buildPDFHeader() => pw.Container(
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
                  'تقرير المبيعات',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.Text(
                  'فترة التقرير: ${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
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
  pw.Widget _buildPDFSummary() => pw.Container(
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
                _sales.fold<int>(
                    0, (int sum, Sale sale) => sum + sale.totalAmount)),
            _buildPDFSummaryItem(
                'إجمالي الأرباح',
                _sales.fold<int>(
                    0, (int sum, Sale sale) => sum + sale.totalProfit)),
            _buildPDFSummaryItem('عدد العمليات', _sales.length),
            _buildPDFSummaryItem(
                'متوسط البيع',
                _sales.isNotEmpty
                    ? _sales.fold<int>(0,
                            (int sum, Sale sale) => sum + sale.totalAmount) ~/
                        _sales.length
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
  pw.Widget _buildPDFSalesTable() => pw.Table(
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
          ..._sales.take(50).map((Sale sale) => pw.TableRow(
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('تقارير نقطة البيع المحسنة'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const <Widget>[
              Tab(text: 'المبيعات', icon: Icon(Icons.shopping_cart)),
              Tab(text: 'الجرد السريع', icon: Icon(Icons.inventory)),
              Tab(text: 'الإحصائيات', icon: Icon(Icons.analytics)),
              Tab(text: 'الرسوم البيانية', icon: Icon(Icons.bar_chart)),
            ],
          ),
          actions: <Widget>[
            // مؤشر حالة المزامنة
            _buildSyncStatusIndicator(),
            // زر التحديث
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildSalesTab(),
                  _buildQuickInventoryTab(),
                  _buildStatisticsTab(),
                  _buildChartsTab(),
                ],
              ),
      );

  /// بناء تبويب المبيعات
  Widget _buildSalesTab() => Column(
        children: <Widget>[
          _buildDateRangeBar(),
          _buildSalesStats(),
          Expanded(
            child: _sales.isEmpty ? _buildEmptySales() : _buildSalesList(),
          ),
        ],
      );

  /// بناء تبويب الجرد السريع
  Widget _buildQuickInventoryTab() => Column(
        children: <Widget>[
          _buildInventoryStats(),
          Expanded(
            child: _quickInventoryItems.isEmpty
                ? _buildEmptyInventory()
                : _buildQuickInventoryList(),
          ),
        ],
      );

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
  Widget _buildDateRangeBar() => Container(
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
              'الفترة: ${DateFormat('yyyy-MM-dd').format(_startDate)} - ${DateFormat('yyyy-MM-dd').format(_endDate)}',
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

  /// بناء إحصائيات المبيعات
  Widget _buildSalesStats() => Container(
        margin:
            const EdgeInsets.symmetric(horizontal: AppConstants.mediumPadding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                'إجمالي المبيعات',
                formatCurrency(_sales.fold<int>(
                    0, (int sum, Sale sale) => sum + sale.totalAmount)),
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildStatCard(
                'إجمالي الأرباح',
                formatCurrency(_sales.fold<int>(
                    0, (int sum, Sale sale) => sum + sale.totalProfit)),
                Icons.trending_up,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildStatCard(
                'عدد العمليات',
                _sales.length.toString(),
                Icons.receipt,
                Colors.orange,
              ),
            ),
          ],
        ),
      );

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
  Widget _buildSalesList() => ListView.builder(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        itemCount: _sales.length + (_hasMoreSales ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == _sales.length) {
            return _buildLoadMoreButton(_loadMoreSales);
          }

          final Sale sale = _sales[index];
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

  /// بناء قائمة الجرد السريع
  Widget _buildQuickInventoryList() => ListView.builder(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        itemCount: _quickInventoryItems.length + (_hasMoreQuick ? 1 : 0),
        itemBuilder: (BuildContext context, int index) {
          if (index == _quickInventoryItems.length) {
            return _buildLoadMoreButton(_loadMoreQuick);
          }

          final QuickInventoryItem item = _quickInventoryItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  item.scannedQuantity.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(item.name),
              subtitle: Text('الباركود: ${item.barcode}'),
              trailing: Text('${item.wholesalePrice} DZ'),
            ),
          );
        },
      );

  /// بناء إحصائيات عامة
  Widget _buildGeneralStats() => Card(
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
                        formatCurrency(_sales.fold<int>(0,
                            (int sum, Sale sale) => sum + sale.totalAmount))),
                  ),
                  Expanded(
                    child: _buildStatItem(
                        'إجمالي الأرباح',
                        formatCurrency(_sales.fold<int>(0,
                            (int sum, Sale sale) => sum + sale.totalProfit))),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildStatItem(
                        'عدد العمليات', _sales.length.toString()),
                  ),
                  Expanded(
                    child: _buildStatItem(
                        'متوسط البيع',
                        _sales.isNotEmpty
                            ? formatCurrency(_sales.fold<int>(
                                    0,
                                    (int sum, Sale sale) =>
                                        sum + sale.totalAmount) ~/
                                _sales.length)
                            : '0 DZ'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

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
  Widget _buildSalesStatistics() => Card(
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
              // إضافة المزيد من الإحصائيات هنا
              Text(
                  'أعلى مبلغ بيع: ${_sales.isNotEmpty ? formatCurrency(_sales.map((Sale sale) => sale.totalAmount).reduce((int a, int b) => a > b ? a : b)) : '0 DZ'}'),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                  'أقل مبلغ بيع: ${_sales.isNotEmpty ? formatCurrency(_sales.map((Sale sale) => sale.totalAmount).reduce((int a, int b) => a < b ? a : b)) : '0 DZ'}'),
            ],
          ),
        ),
      );

  /// بناء إحصائيات الجرد
  Widget _buildInventoryStatistics() => Card(
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
              Text('إجمالي العناصر: ${_quickInventoryItems.length}'),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                  'إجمالي الكمية: ${_quickInventoryItems.fold<int>(0, (int sum, QuickInventoryItem item) => sum + item.scannedQuantity)}'),
            ],
          ),
        ),
      );

  /// بناء رسم المبيعات
  Widget _buildSalesChart() => Card(
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
                child: _salesChartData.isEmpty
                    ? const Center(child: Text('لا توجد بيانات للعرض'))
                    : LineChart(
                        LineChartData(
                          borderData: FlBorderData(show: true),
                          lineBarsData: <LineChartBarData>[
                            LineChartBarData(
                              spots: _salesChartData,
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

  /// بناء رسم الأرباح
  Widget _buildProfitChart() => Card(
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
                child: _profitChartData.isEmpty
                    ? const Center(child: Text('لا توجد بيانات للعرض'))
                    : LineChart(
                        LineChartData(
                          borderData: FlBorderData(show: true),
                          lineBarsData: <LineChartBarData>[
                            LineChartBarData(
                              spots: _profitChartData,
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

  /// بناء رسم طرق الدفع
  Widget _buildPaymentMethodChart() => Card(
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
                child: _paymentMethodData.isEmpty
                    ? const Center(child: Text('لا توجد بيانات للعرض'))
                    : PieChart(
                        PieChartData(
                          sections: _paymentMethodData,
                          centerSpaceRadius: 40,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );

  /// بناء رسم المبيعات اليومية
  Widget _buildDailySalesChart() => Card(
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
                child: _dailySalesData.isEmpty
                    ? const Center(child: Text('لا توجد بيانات للعرض'))
                    : BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: _dailySalesData.isNotEmpty
                              ? _dailySalesData
                                      .map((BarChartGroupData data) =>
                                          data.barRods.first.toY)
                                      .reduce((double a, double b) =>
                                          a > b ? a : b) *
                                  1.1
                              : 100,
                          barGroups: _dailySalesData,
                          titlesData: const FlTitlesData(),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );

  /// بناء إحصائيات الجرد
  Widget _buildInventoryStats() => Container(
        margin: const EdgeInsets.all(AppConstants.mediumPadding),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _buildStatCard(
                'إجمالي العناصر',
                _quickInventoryItems.length.toString(),
                Icons.inventory,
                Colors.blue,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            Expanded(
              child: _buildStatCard(
                'إجمالي الكمية',
                _quickInventoryItems
                    .fold<int>(
                        0,
                        (int sum, QuickInventoryItem item) =>
                            sum + item.scannedQuantity)
                    .toString(),
                Icons.shopping_cart,
                Colors.orange,
              ),
            ),
          ],
        ),
      );

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

  /// بناء رسالة فارغة للجرد
  Widget _buildEmptyInventory() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.inventory_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: AppConstants.mediumPadding),
            Text(
              'لا توجد عناصر في الجرد السريع',
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

  /// تحميل المزيد من المبيعات
  Future<void> _loadMoreSales() async {
    if (_isLoadingMoreSales || !_hasMoreSales) return;

    setState(() {
      _isLoadingMoreSales = true;
    });

    try {
      final PageResult<Sale> page = await POSService.getCombinedSalesPage(
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        setState(() {
          _sales.addAll(page.items);
          _hasMoreSales = page.hasMore;
        });
        _prepareChartData();
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل المزيد من المبيعات في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadMoreSales',
        },
      );
      debugPrint('خطأ في تحميل المزيد من المبيعات: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreSales = false;
        });
      }
    }
  }

  /// تحميل المزيد من الجرد السريع
  Future<void> _loadMoreQuick() async {
    if (_isLoadingMoreQuick || !_hasMoreQuick) return;

    setState(() {
      _isLoadingMoreQuick = true;
    });

    try {
      final PageResult<QuickInventoryItem> page =
          await POSService.getQuickInventoryPage(
        startAfter: _lastQuickDoc,
      );

      if (mounted) {
        setState(() {
          _quickInventoryItems.addAll(page.items);
          _lastQuickDoc = page.lastDocument;
          _hasMoreQuick = page.hasMore;
        });
      }
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        userAction: 'تحميل المزيد من الجرد السريع في تقارير POS',
        context: <String, dynamic>{
          'operation': '_loadMoreQuick',
        },
      );
      debugPrint('خطأ في تحميل المزيد من الجرد السريع: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreQuick = false;
        });
      }
    }
  }

  /// بناء مؤشر حالة المزامنة
  Widget _buildSyncStatusIndicator() {
    final int unsyncedCount =
        _sales.where((Sale sale) => !sale.isSynced).length;

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
