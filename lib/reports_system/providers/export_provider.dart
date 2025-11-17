import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/export_options.dart';
import '../services/export_service.dart';

/// Provider لخدمة التصدير
final Provider<ExportService> exportServiceProvider = Provider<ExportService>(
    (ProviderRef<ExportService> ref) => ExportService());

/// Provider لخيارات التصدير
final StateProvider<ExportOptions> exportOptionsProvider =
    StateProvider<ExportOptions>(
        (StateProviderRef<ExportOptions> ref) => ExportOptions(
              fileName: 'report_${DateTime.now().millisecondsSinceEpoch}',
              format: ExportFormat.pdf,
            ));

/// Provider لحالة التصدير
final StateProvider<ExportStatus> exportStatusProvider =
    StateProvider<ExportStatus>(
        (StateProviderRef<ExportStatus> ref) => ExportStatus.idle);

/// Provider لتقدم التصدير
final StateProvider<double> exportProgressProvider =
    StateProvider<double>((StateProviderRef<double> ref) => 0.0);

/// Provider لمسار الملف المُصدَّر
final StateProvider<String?> exportedFilePathProvider =
    StateProvider<String?>((StateProviderRef<String?> ref) => null);

/// Provider لخطأ التصدير
final StateProvider<String?> exportErrorProvider =
    StateProvider<String?>((StateProviderRef<String?> ref) => null);

/// Provider لتصدير البيانات
final Provider<void Function(Object, ExportOptions options)>
    exportDataProvider = Provider<void Function(Object, ExportOptions options)>(
        (ProviderRef<void Function(Object, ExportOptions options)> ref) =>
            (Object data, ExportOptions options) async {
              try {
                ref.read(exportStatusProvider.notifier).state =
                    ExportStatus.exporting;
                ref.read(exportProgressProvider.notifier).state = 0.0;
                ref.read(exportErrorProvider.notifier).state = null;

                final ExportService service = ref.read(exportServiceProvider);

                // محاكاة التقدم
                for (int i = 0; i <= 100; i += 10) {
                  ref.read(exportProgressProvider.notifier).state = i / 100.0;
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                }

                final String filePath =
                    await service.exportToPDF(data, options);

                ref.read(exportedFilePathProvider.notifier).state = filePath;
                ref.read(exportStatusProvider.notifier).state =
                    ExportStatus.completed;
                ref.read(exportProgressProvider.notifier).state = 1.0;
              } catch (e) {
                ref.read(exportErrorProvider.notifier).state = e.toString();
                ref.read(exportStatusProvider.notifier).state =
                    ExportStatus.failed;
                ref.read(exportProgressProvider.notifier).state = 0.0;
              }
            });

/// Provider لطباعة التقرير
final Provider<void Function(Object, ExportOptions options)>
    printReportProvider =
    Provider<void Function(Object, ExportOptions options)>(
        (ProviderRef<void Function(Object, ExportOptions options)> ref) =>
            (Object data, ExportOptions options) async {
              try {
                ref.read(exportStatusProvider.notifier).state =
                    ExportStatus.printing;
                ref.read(exportErrorProvider.notifier).state = null;

                final ExportService service = ref.read(exportServiceProvider);
                await service.printReport(data, options);

                ref.read(exportStatusProvider.notifier).state =
                    ExportStatus.completed;
              } catch (e) {
                ref.read(exportErrorProvider.notifier).state = e.toString();
                ref.read(exportStatusProvider.notifier).state =
                    ExportStatus.failed;
              }
            });

/// Provider لإعادة تعيين حالة التصدير
final Provider<void Function()> resetExportProvider =
    Provider<void Function()>((ProviderRef<void Function()> ref) => () {
          ref.read(exportStatusProvider.notifier).state = ExportStatus.idle;
          ref.read(exportProgressProvider.notifier).state = 0.0;
          ref.read(exportedFilePathProvider.notifier).state = null;
          ref.read(exportErrorProvider.notifier).state = null;
        });

/// حالة التصدير
enum ExportStatus {
  idle,
  exporting,
  printing,
  completed,
  failed,
}
