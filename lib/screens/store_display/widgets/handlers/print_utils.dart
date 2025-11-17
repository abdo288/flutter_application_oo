import 'package:barcode/barcode.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../models/inventory_item.dart';
import 'print_options_dialog.dart';

/// أدوات مساعدة للطباعة
class PrintUtils {
  /// التحقق من صحة الباركود لمعيار Code128
  static bool isValidCode128Barcode(String barcode) {
    if (barcode.isEmpty) return false;

    // Code128 يدعم ASCII من 32 إلى 126
    for (int i = 0; i < barcode.length; i++) {
      final int charCode = barcode.codeUnitAt(i);
      if (charCode < 32 || charCode > 126) {
        return false;
      }
    }

    return true;
  }

  /// تنظيف أسماء الملفات من الأحرف غير المسموحة
  static String sanitizeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  /// الحصول على تنسيق الصفحة حسب نوع الورق
  static PdfPageFormat getPageFormat(PaperSize size) {
    switch (size) {
      case PaperSize.roll57:
        return PdfPageFormat.roll57;
      case PaperSize.roll80:
        return PdfPageFormat.roll80;
      case PaperSize.a4:
        return PdfPageFormat.a4;
    }
  }

  /// بناء ملصق الباركود
  static pw.Widget buildLabel(
      InventoryItem item, PrintOptions options, int index) {
    final pw.Barcode barcode = Barcode.code128();

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: <pw.Widget>[
          if (options.includeName) ...<pw.Widget>[
            pw.Text(
              item.name,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
          ],
          pw.BarcodeWidget(
            barcode: barcode,
            data: item.barcode!,
            width: (options.size == PaperSize.a4) ? 200 : double.infinity,
            height: (options.size == PaperSize.a4) ? 60 : 40,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            item.barcode!,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (options.includeStockQty) ...<pw.Widget>[
            pw.SizedBox(height: 4),
            pw.Text(
              'الكمية: ${item.quantity}',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
          if (options.quantity > 1) ...<pw.Widget>[
            pw.SizedBox(height: 2),
            pw.Text(
              'نسخة ${index + 1} من ${options.quantity}',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
  }
}
