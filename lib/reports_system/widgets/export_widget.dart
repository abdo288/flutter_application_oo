import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_options.dart';
import '../providers/export_provider.dart';
import 'loading_widget.dart';

/// Widget للتصدير
class ExportWidget extends ConsumerWidget {
  const ExportWidget({
    super.key,
    required this.data,
    this.title = 'تصدير التقرير',
  });

  final dynamic data;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ExportStatus exportStatus = ref.watch(exportStatusProvider);
    final String? exportedFilePath = ref.watch(exportedFilePathProvider);
    final String? exportError = ref.watch(exportErrorProvider);
    final ExportOptions exportOptions = ref.watch(exportOptionsProvider);

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // خيارات التصدير
            if (exportStatus == ExportStatus.idle) ...<Widget>[
              _buildFormatSelector(ref, exportOptions),
              const SizedBox(height: 16),
              _buildPageSizeSelector(ref, exportOptions),
              const SizedBox(height: 16),
              _buildOrientationSelector(ref, exportOptions),
              const SizedBox(height: 16),
              _buildOptionsSelector(ref, exportOptions),
            ],

            // حالة التصدير
            if (exportStatus == ExportStatus.exporting) ...<Widget>[
              const ProgressLoadingWidget(
                progress: 0.0,
                message: 'جاري تصدير التقرير...',
                steps: <String>[
                  'تحضير البيانات',
                  'إنشاء الملف',
                  'حفظ الملف',
                  'الانتهاء',
                ],
              ),
            ],

            // حالة الطباعة
            if (exportStatus == ExportStatus.printing) ...<Widget>[
              const ProgressLoadingWidget(
                progress: 0.0,
                message: 'جاري إرسال التقرير للطباعة...',
                steps: <String>[
                  'تحضير البيانات',
                  'إرسال للطابعة',
                  'الانتهاء',
                ],
              ),
            ],

            // نجح التصدير
            if (exportStatus == ExportStatus.completed) ...<Widget>[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'تم تصدير التقرير بنجاح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (exportedFilePath != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'تم حفظ الملف في: $exportedFilePath',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            // فشل التصدير
            if (exportStatus == ExportStatus.failed) ...<Widget>[
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'فشل في تصدير التقرير',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              if (exportError != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  exportError,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
      actions: <Widget>[
        if (exportStatus == ExportStatus.idle) ...<Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final void Function(Object, ExportOptions) exportData =
                  ref.read(exportDataProvider);
              exportData(data as Object, exportOptions);
            },
            child: const Text('تصدير'),
          ),
          ElevatedButton(
            onPressed: () {
              final void Function(Object, ExportOptions) printReport =
                  ref.read(printReportProvider);
              printReport(data as Object, exportOptions);
            },
            child: const Text('طباعة'),
          ),
        ],
        if (exportStatus == ExportStatus.completed) ...<Widget>[
          TextButton(
            onPressed: () {
              ref.read(resetExportProvider)();
              Navigator.of(context).pop();
            },
            child: const Text('إغلاق'),
          ),
        ],
        if (exportStatus == ExportStatus.failed) ...<Widget>[
          TextButton(
            onPressed: () {
              ref.read(resetExportProvider)();
            },
            child: const Text('إعادة المحاولة'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ],
    );
  }

  Widget _buildFormatSelector(WidgetRef ref, ExportOptions options) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'تنسيق الملف',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ExportFormat>(
            initialValue: options.format,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: ExportFormat.values
                .map((ExportFormat format) => DropdownMenuItem(
                      value: format,
                      child: Text(_getFormatLabel(format)),
                    ))
                .toList(),
            onChanged: (ExportFormat? value) {
              if (value != null) {
                ref.read(exportOptionsProvider.notifier).state =
                    options.copyWith(format: value);
              }
            },
          ),
        ],
      );

  Widget _buildPageSizeSelector(WidgetRef ref, ExportOptions options) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'حجم الصفحة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PageSize>(
            initialValue: options.pageSize,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: PageSize.values
                .map((PageSize size) => DropdownMenuItem(
                      value: size,
                      child: Text(_getPageSizeLabel(size)),
                    ))
                .toList(),
            onChanged: (PageSize? value) {
              if (value != null) {
                ref.read(exportOptionsProvider.notifier).state =
                    options.copyWith(pageSize: value);
              }
            },
          ),
        ],
      );

  Widget _buildOrientationSelector(WidgetRef ref, ExportOptions options) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'اتجاه الصفحة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: RadioListTile<PageOrientation>(
                  title: const Text('عمودي'),
                  value: PageOrientation.portrait,
                  groupValue: options.orientation,
                  onChanged: (PageOrientation? value) {
                    if (value != null) {
                      ref.read(exportOptionsProvider.notifier).state =
                          options.copyWith(orientation: value);
                    }
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<PageOrientation>(
                  title: const Text('أفقي'),
                  value: PageOrientation.landscape,
                  groupValue: options.orientation,
                  onChanged: (PageOrientation? value) {
                    if (value != null) {
                      ref.read(exportOptionsProvider.notifier).state =
                          options.copyWith(orientation: value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildOptionsSelector(WidgetRef ref, ExportOptions options) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'خيارات إضافية',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('تضمين الرسوم البيانية'),
            value: options.includeCharts,
            onChanged: (bool? value) {
              ref.read(exportOptionsProvider.notifier).state =
                  options.copyWith(includeCharts: value ?? false);
            },
          ),
          CheckboxListTile(
            title: const Text('تضمين الملخص'),
            value: options.includeSummary,
            onChanged: (bool? value) {
              ref.read(exportOptionsProvider.notifier).state =
                  options.copyWith(includeSummary: value ?? false);
            },
          ),
        ],
      );

  String _getFormatLabel(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.xml:
        return 'XML';
      case ExportFormat.html:
        return 'HTML';
      case ExportFormat.unknown:
        return 'غير معروف';
    }
  }

  String _getPageSizeLabel(PageSize size) {
    switch (size) {
      case PageSize.a4:
        return 'A4';
      case PageSize.a3:
        return 'A3';
      case PageSize.letter:
        return 'Letter';
      case PageSize.legal:
        return 'Legal';
      case PageSize.tabloid:
        return 'Tabloid';
    }
  }
}
