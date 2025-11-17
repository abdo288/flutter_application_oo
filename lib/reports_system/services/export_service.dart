import 'dart:async';
import 'dart:io';

// import 'package:excel/excel.dart'; // تم تعطيله مؤقتاً
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/eod_report.dart';
import '../models/dashboard_summary.dart';
import '../models/export_options.dart';
import '../models/inventory_report.dart';
import '../models/payment_report.dart';
import '../models/sales_analytics.dart';
import '../validators/model_validators.dart';

/// خدمة التصدير
class ExportService {
  factory ExportService() => _instance;
  ExportService._internal();
  static final ExportService _instance = ExportService._internal();

  /// تصدير إلى PDF
  Future<String> exportToPDF(data, ExportOptions options) async {
    try {
      // التحقق من صحة خيارات التصدير
      final ValidationResult validation =
          ExportOptionsValidator.validate(options);
      if (!validation.isValid) {
        throw Exception('خيارات التصدير غير صحيحة: ${validation.errorMessage}');
      }

      final pw.Document document = pw.Document();

      // إضافة الصفحات حسب نوع البيانات
      if (data is DashboardSummary) {
        _addDashboardToPDF(document, data, options);
      } else if (data is SalesAnalytics) {
        _addSalesAnalyticsToPDF(document, data, options);
      } else if (data is PaymentReport) {
        _addPaymentReportToPDF(document, data, options);
      } else if (data is InventoryReport) {
        _addInventoryReportToPDF(document, data, options);
      } else if (data is EODReport) {
        _addEODReportToPDF(document, data, options);
      } else {
        throw Exception('نوع البيانات غير مدعوم للتصدير');
      }

      // حفظ الملف
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = '${options.fileName}.pdf';
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsBytes(await document.save());

      return filePath;
    } catch (e) {
      debugPrint('❌ خطأ في تصدير PDF: $e');
      rethrow;
    }
  }

  /// تصدير إلى Excel
  Future<String> exportToExcel(data, ExportOptions options) async {
    try {
      // تنفيذ مبسط - في التطبيق الحقيقي ستحتاج إلى مكتبة Excel
      throw UnimplementedError('تصدير Excel غير مدعوم حالياً');
    } catch (e) {
      debugPrint('❌ خطأ في تصدير Excel: $e');
      rethrow;
    }
  }

  /// تصدير إلى CSV
  Future<String> exportToCSV(data, ExportOptions options) async {
    try {
      List<List<dynamic>> csvData = <List<dynamic>>[];

      // إضافة البيانات حسب النوع
      if (data is DashboardSummary) {
        csvData = _convertDashboardToCSV(data);
      } else if (data is SalesAnalytics) {
        csvData = _convertSalesAnalyticsToCSV(data);
      } else if (data is PaymentReport) {
        csvData = _convertPaymentReportToCSV(data);
      } else if (data is InventoryReport) {
        csvData = _convertInventoryReportToCSV(data);
      } else if (data is EODReport) {
        csvData = _convertEODReportToCSV(data);
      } else {
        throw Exception('نوع البيانات غير مدعوم للتصدير');
      }

      // تحويل إلى CSV
      const ListToCsvConverter converter = ListToCsvConverter();
      final String csvString = converter.convert(csvData);

      // حفظ الملف
      final Directory directory = await getApplicationDocumentsDirectory();
      final String fileName = '${options.fileName}.csv';
      final String filePath = '${directory.path}/$fileName';
      final File file = File(filePath);
      await file.writeAsString(csvString);

      return filePath;
    } catch (e) {
      debugPrint('❌ خطأ في تصدير CSV: $e');
      rethrow;
    }
  }

  /// طباعة مباشرة
  Future<void> printReport(data, ExportOptions options) async {
    try {
      final pw.Document document = pw.Document();

      // إضافة البيانات إلى PDF
      if (data is DashboardSummary) {
        await _addDashboardToPDF(document, data, options);
      } else if (data is EODReport) {
        await _addEODReportToPDF(document, data, options);
      } else {
        throw Exception('نوع البيانات غير مدعوم للطباعة');
      }

      // طباعة
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => document.save(),
        name: options.fileName,
      );
    } catch (e) {
      debugPrint('❌ خطأ في الطباعة: $e');
      rethrow;
    }
  }

  /// إضافة لوحة التحكم إلى PDF
  Future<void> _addDashboardToPDF(pw.Document document, DashboardSummary data,
      ExportOptions options) async {
    document.addPage(
      pw.Page(
        pageFormat: _getPageFormat(options.pageSize, options.orientation),
        margin: pw.EdgeInsets.all(options.margins.left),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            // العنوان
            pw.Header(
              level: 0,
              child: pw.Text(
                'تقرير لوحة التحكم',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),

            // الإحصائيات الرئيسية
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: <pw.Widget>[
                _buildStatCard('إجمالي المبيعات اليوم',
                    '${data.totalSalesToday.toStringAsFixed(2)} DZ'),
                _buildStatCard('عدد العملاء', '${data.totalCustomersToday}'),
                _buildStatCard('المعاملات', '${data.totalTransactionsToday}'),
                _buildStatCard('متوسط قيمة البيع',
                    '${data.averageSaleValue.toStringAsFixed(2)} DZ'),
              ],
            ),
            pw.SizedBox(height: 20),

            // أفضل المنتجات
            pw.Text(
              'أفضل المنتجات مبيعاً',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FixedColumnWidth(50),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(100),
              },
              children: <pw.TableRow>[
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('الترتيب',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('اسم المنتج',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('الكمية',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('القيمة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...data.topProducts
                    .map((TopProductSummary product) => pw.TableRow(
                          children: <pw.Widget>[
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${product.rank}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(product.productName),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${product.quantitySold}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  '${product.totalValue.toStringAsFixed(2)} DZ'),
                            ),
                          ],
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// إضافة تقرير EOD إلى PDF
  Future<void> _addEODReportToPDF(
      pw.Document document, EODReport data, ExportOptions options) async {
    document.addPage(
      pw.Page(
        pageFormat: _getPageFormat(options.pageSize, options.orientation),
        margin: pw.EdgeInsets.all(options.margins.left),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            // العنوان
            pw.Header(
              level: 0,
              child: pw.Text(
                'تقرير نهاية اليوم - ${data.reportNumber}',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'التاريخ: ${data.date.day}/${data.date.month}/${data.date.year}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),

            // الإحصائيات الرئيسية
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: <pw.Widget>[
                _buildStatCard('إجمالي المبيعات',
                    '${data.totalSales.toStringAsFixed(2)} DZ'),
                _buildStatCard('الربح الإجمالي',
                    '${data.totalProfit.toStringAsFixed(2)} DZ'),
                _buildStatCard('المنتجات المباعة', '${data.totalItemsSold}'),
                _buildStatCard('المنتجات المختلفة', '${data.uniqueProducts}'),
              ],
            ),
            pw.SizedBox(height: 20),

            // أفضل المنتجات
            pw.Text(
              'أفضل المنتجات مبيعاً',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FixedColumnWidth(50),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(100),
              },
              children: <pw.TableRow>[
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: <pw.Widget>[
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('الترتيب',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('اسم المنتج',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('الكمية',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('القيمة',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                ...data.topProducts
                    .take(10)
                    .map((TopProduct product) => pw.TableRow(
                          children: <pw.Widget>[
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  '${data.topProducts.indexOf(product) + 1}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(product.name),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text('${product.quantity}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                  '${product.totalValue.toStringAsFixed(2)} DZ'),
                            ),
                          ],
                        )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// بناء بطاقة إحصائية
  pw.Widget _buildStatCard(String title, String value) => pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          children: <pw.Widget>[
            pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      );

  /// الحصول على تنسيق الصفحة
  PdfPageFormat _getPageFormat(PageSize pageSize, PageOrientation orientation) {
    PdfPageFormat format;
    switch (pageSize) {
      case PageSize.a4:
        format = PdfPageFormat.a4;
        break;
      case PageSize.a3:
        format = PdfPageFormat.a3;
        break;
      case PageSize.letter:
        format = PdfPageFormat.letter;
        break;
      case PageSize.legal:
        format = PdfPageFormat.legal;
        break;
      case PageSize.tabloid:
        format = PdfPageFormat.a4; // استخدام A4 كبديل
        break;
    }

    if (orientation == PageOrientation.landscape) {
      format = format.landscape;
    }

    return format;
  }

  // دوال Excel معطلة مؤقتاً

  /// تحويل لوحة التحكم إلى CSV
  List<List<dynamic>> _convertDashboardToCSV(DashboardSummary data) =>
      <List<dynamic>>[
        <dynamic>['تقرير لوحة التحكم'],
        <dynamic>[''],
        <dynamic>[
          'إجمالي المبيعات اليوم',
          '${data.totalSalesToday.toStringAsFixed(2)} DZ'
        ],
        <dynamic>['عدد العملاء', '${data.totalCustomersToday}'],
        <dynamic>['المعاملات', '${data.totalTransactionsToday}'],
        <dynamic>[
          'متوسط قيمة البيع',
          '${data.averageSaleValue.toStringAsFixed(2)} DZ'
        ],
        <dynamic>[''],
        <dynamic>['أفضل المنتجات مبيعاً'],
        <dynamic>['الترتيب', 'اسم المنتج', 'الكمية', 'القيمة'],
        ...data.topProducts.map((TopProductSummary product) => <dynamic>[
              product.rank,
              product.productName,
              product.quantitySold,
              '${product.totalValue.toStringAsFixed(2)} DZ',
            ]),
      ];

  /// تحويل تقرير EOD إلى CSV
  List<List<dynamic>> _convertEODReportToCSV(EODReport data) => <List<dynamic>>[
        <dynamic>['تقرير نهاية اليوم - ${data.reportNumber}'],
        <dynamic>[
          'التاريخ',
          '${data.date.day}/${data.date.month}/${data.date.year}'
        ],
        <dynamic>[''],
        <dynamic>[
          'إجمالي المبيعات',
          '${data.totalSales.toStringAsFixed(2)} DZ'
        ],
        <dynamic>[
          'الربح الإجمالي',
          '${data.totalProfit.toStringAsFixed(2)} DZ'
        ],
        <dynamic>['المنتجات المباعة', '${data.totalItemsSold}'],
        <dynamic>['المنتجات المختلفة', '${data.uniqueProducts}'],
        <dynamic>[''],
        <dynamic>['أفضل المنتجات مبيعاً'],
        <dynamic>['الترتيب', 'اسم المنتج', 'الكمية', 'القيمة'],
        ...data.topProducts.take(10).map((TopProduct product) => <dynamic>[
              data.topProducts.indexOf(product) + 1,
              product.name,
              product.quantity,
              '${product.totalValue.toStringAsFixed(2)} DZ',
            ]),
      ];

  // دوال إضافية للأنواع الأخرى (مبسطة)
  void _addSalesAnalyticsToPDF(
      pw.Document document, SalesAnalytics data, ExportOptions options) {}
  void _addPaymentReportToPDF(
      pw.Document document, PaymentReport data, ExportOptions options) {}
  void _addInventoryReportToPDF(
      pw.Document document, InventoryReport data, ExportOptions options) {}
  List<List<dynamic>> _convertSalesAnalyticsToCSV(SalesAnalytics data) =>
      <List<dynamic>>[];
  List<List<dynamic>> _convertPaymentReportToCSV(PaymentReport data) =>
      <List<dynamic>>[];
  List<List<dynamic>> _convertInventoryReportToCSV(InventoryReport data) =>
      <List<dynamic>>[];
}
