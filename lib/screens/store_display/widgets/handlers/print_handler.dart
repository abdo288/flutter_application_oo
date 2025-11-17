import 'dart:async';
import 'dart:typed_data';

import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/inventory_item.dart';
import '../../../../utils/snackbar_utils.dart';
import 'print_options_dialog.dart';
import 'print_utils.dart';

/// معالج عمليات الطباعة
class PrintHandler {
  /// طباعة الباركود
  static Future<void> printBarcode(
    BuildContext context,
    InventoryItem item,
  ) async {
    try {
      if ((item.barcode ?? '').isEmpty) {
        SnackbarUtils.showError(
            context, AppLocalizations.of(context).noBarcodeForItem);
        return;
      }

      // نافذة خيارات الطباعة
      final PrintOptions? options = await PrintOptionsDialog.show(context);
      if (options == null) return;

      await _printBarcodeWithOptions(context, item, options);
    } catch (e) {
      debugPrint('❌ خطأ في طباعة الباركود: $e');
      if (context.mounted) {
        SnackbarUtils.showError(context, 'خطأ في طباعة الباركود: $e');
      }
    }
  }

  /// طباعة الباركود مع الخيارات
  static Future<void> _printBarcodeWithOptions(
    BuildContext context,
    InventoryItem item,
    PrintOptions options,
  ) async {
    try {
      // التحقق من صحة بيانات الباركود
      if (item.barcode == null || item.barcode!.isEmpty) {
        SnackbarUtils.showError(context, 'باركود المنتج غير صالح');
        return;
      }

      // التحقق من أن الباركود يحتوي على أحرف صالحة لـ Code128
      if (!PrintUtils.isValidCode128Barcode(item.barcode!)) {
        SnackbarUtils.showError(
            context, 'باركود المنتج غير متوافق مع معيار Code128');
        return;
      }

      // إنشاء اسم ملف فريد لتجنب التعارض
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName =
          PrintUtils.sanitizeFileName('barcode_${item.barcode}_$timestamp.pdf');

      // محاولة استخدام layoutPdf أولاً، وإذا فشل نستخدم sharePdf
      try {
        await Printing.layoutPdf(
          name: fileName,
          onLayout: (PdfPageFormat incomingFormat) async {
            try {
              final pw.Document doc = pw.Document();
              Barcode.code128();

              // تحديد مقاس الصفحة المطلوب
              final PdfPageFormat targetFormat =
                  PrintUtils.getPageFormat(options.size);

              // استخدام المقاس القادم من النظام إذا كان صالحاً، وإلا نستخدم المحدد
              final PdfPageFormat pageFormat =
                  (incomingFormat.width > 0 && incomingFormat.height > 0)
                      ? incomingFormat
                      : targetFormat;

              // إنشاء ملصق واحد
              pw.Widget buildLabel(int index) =>
                  PrintUtils.buildLabel(item, options, index);

              // إضافة الصفحات حسب نوع الورق
              if (options.size == PaperSize.a4) {
                // تخطيط A4 مع شبكة ملصقات
                const int columns = 2;
                const double padding = 12;
                int printed = 0;

                while (printed < options.quantity) {
                  final int remaining = options.quantity - printed;
                  final int itemsInPage =
                      (remaining > columns * 8) ? columns * 8 : remaining;

                  doc.addPage(
                    pw.Page(
                      pageFormat: pageFormat,
                      margin: const pw.EdgeInsets.all(20),
                      build: (pw.Context context) => pw.GridView(
                        crossAxisCount: columns,
                        childAspectRatio: 1.5,
                        mainAxisSpacing: padding,
                        crossAxisSpacing: padding,
                        children: List<pw.Widget>.generate(
                          itemsInPage,
                          (int i) => pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                  color: PdfColors.grey300, width: 0.5),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: buildLabel(printed + i),
                          ),
                        ),
                      ),
                    ),
                  );
                  printed += itemsInPage;
                }
              } else {
                // تخطيط الرول: صفحة لكل ملصق
                for (int i = 0; i < options.quantity; i++) {
                  doc.addPage(
                    pw.Page(
                      pageFormat: pageFormat,
                      margin: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      build: (pw.Context context) => buildLabel(i),
                    ),
                  );
                }
              }

              final Uint8List pdfBytes = await doc.save();

              // التحقق من أن الملف تم إنشاؤه بنجاح
              if (pdfBytes.isEmpty) {
                throw Exception('فشل في إنشاء ملف PDF');
              }

              return pdfBytes;
            } catch (e) {
              // في حالة حدوث خطأ، نعيد ملف PDF بسيط يحتوي على رسالة خطأ
              final pw.Document errorDoc = pw.Document();
              errorDoc.addPage(
                pw.Page(
                  pageFormat: PdfPageFormat.a4,
                  build: (pw.Context context) => pw.Center(
                    child: pw.Text(
                      'خطأ في إنشاء الباركود: ${e.toString()}',
                      style: const pw.TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
              return await errorDoc.save();
            }
          },
        );

        // إضافة تأخير قصير لضمان إغلاق الملف السابق
        await Future<void>.delayed(const Duration(milliseconds: 500));

        if (context.mounted) {
          SnackbarUtils.showSuccess(context, 'تمت الطباعة بنجاح');
        }
      } catch (e) {
        // إذا فشل layoutPdf، نستخدم sharePdf كبديل
        if (context.mounted) {
          SnackbarUtils.showInfo(
              context, 'جاري استخدام طريقة بديلة للطباعة...');
        }
        await _printWithSharePdf(context, item, options, fileName);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'خطأ في الطباعة: ${e.toString()}');
      }
    }
  }

  /// طريقة بديلة للطباعة باستخدام sharePdf
  static Future<void> _printWithSharePdf(
    BuildContext context,
    InventoryItem item,
    PrintOptions options,
    String fileName,
  ) async {
    try {
      final pw.Document doc = pw.Document();
      Barcode.code128();

      // تحديد مقاس الصفحة المطلوب
      final PdfPageFormat targetFormat = PrintUtils.getPageFormat(options.size);

      // إنشاء ملصق واحد
      pw.Widget buildLabel(int index) =>
          PrintUtils.buildLabel(item, options, index);

      // إضافة الصفحات حسب نوع الورق
      if (options.size == PaperSize.a4) {
        const int columns = 2;
        const double padding = 12;
        int printed = 0;

        while (printed < options.quantity) {
          final int remaining = options.quantity - printed;
          final int itemsInPage =
              (remaining > columns * 8) ? columns * 8 : remaining;

          doc.addPage(
            pw.Page(
              pageFormat: targetFormat,
              margin: const pw.EdgeInsets.all(20),
              build: (pw.Context context) => pw.GridView(
                crossAxisCount: columns,
                childAspectRatio: 1.5,
                mainAxisSpacing: padding,
                crossAxisSpacing: padding,
                children: List<pw.Widget>.generate(
                  itemsInPage,
                  (int i) => pw.Container(
                    decoration: pw.BoxDecoration(
                      border:
                          pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: buildLabel(printed + i),
                  ),
                ),
              ),
            ),
          );
          printed += itemsInPage;
        }
      } else {
        for (int i = 0; i < options.quantity; i++) {
          doc.addPage(
            pw.Page(
              pageFormat: targetFormat,
              margin: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              build: (pw.Context context) => buildLabel(i),
            ),
          );
        }
      }

      final Uint8List pdfBytes = await doc.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );

      if (context.mounted) {
        SnackbarUtils.showSuccess(context, 'تم حفظ الملف بنجاح');
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarUtils.showError(context, 'خطأ في الحفظ: ${e.toString()}');
      }
    }
  }
}
