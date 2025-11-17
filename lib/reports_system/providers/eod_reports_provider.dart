import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/eod_report.dart';
import '../../services/eod_service.dart';

/// Provider لتقارير نهاية اليوم المحلية
final FutureProvider<List<EODReport>> localEODReportsProvider =
    FutureProvider<List<EODReport>>(
        (FutureProviderRef<List<EODReport>> ref) async =>
            await EODService.getLocalEODReports());

/// Provider لجلب جميع التقارير الحقيقية (محلية + Firebase)
/// يستمع إلى تحديثات EodProcessNotifier لضمان التناسق
final FutureProvider<List<EODReport>> realEODReportsProvider =
    FutureProvider<List<EODReport>>(
        (FutureProviderRef<List<EODReport>> ref) async {
  debugPrint('🔄 realEODReportsProvider: جلب التقارير الحقيقية');

  // ✅ مهم للتناسق: الاستماع إلى حالة EodProcessNotifier
  // عندما يكتمل إنشاء تقرير جديد، يتم إعادة بناء هذا المزود تلقائياً
  // Note: يتم تحقيق التناسق عبر refreshEODReportsProvider من الـ UI

  return await EODService.getAllRealEODReports();
});

/// Provider لتقارير نهاية اليوم من Firebase
final FutureProviderFamily<List<EODReport>, Map<String, dynamic>>
    firebaseEODReportsProvider =
    FutureProvider.family<List<EODReport>, Map<String, dynamic>>(
        (FutureProviderRef<List<EODReport>> ref,
            Map<String, dynamic> params) async {
  final int limit = params['limit'] as int? ?? 50;
  final DateTime? startDate = params['startDate'] as DateTime?;
  final DateTime? endDate = params['endDate'] as DateTime?;

  return await EODService.getFirebaseEODReports(
    limit: limit,
    startDate: startDate,
    endDate: endDate,
  );
});

/// Provider للبحث في تقارير نهاية اليوم
final FutureProviderFamily<List<EODReport>, Map<String, dynamic>>
    searchEODReportsProvider =
    FutureProvider.family<List<EODReport>, Map<String, dynamic>>(
        (FutureProviderRef<List<EODReport>> ref,
            Map<String, dynamic> params) async {
  final String? query = params['query'] as String?;
  final DateTime? startDate = params['startDate'] as DateTime?;
  final DateTime? endDate = params['endDate'] as DateTime?;
  final String? employeeId = params['employeeId'] as String?;
  final double? minSales = params['minSales'] as double?;
  final double? maxSales = params['maxSales'] as double?;
  final int limit = params['limit'] as int? ?? 50;

  debugPrint('🔍 searchEODReportsProvider: بدء البحث مع المعايير:');
  debugPrint('   - query: $query');
  debugPrint('   - startDate: $startDate');
  debugPrint('   - endDate: $endDate');
  debugPrint('   - employeeId: $employeeId');
  debugPrint('   - limit: $limit');

  final List<EODReport> reports = await EODService.searchEODReports(
    query: query,
    startDate: startDate,
    endDate: endDate,
    employeeId: employeeId,
    minSales: minSales,
    maxSales: maxSales,
    limit: limit,
  );

  debugPrint('✅ searchEODReportsProvider: تم إرجاع ${reports.length} تقرير');
  return reports;
});

/// Provider لتقرير نهاية اليوم بواسطة ID
final FutureProviderFamily<EODReport?, String> eodReportByIdProvider =
    FutureProvider.family<EODReport?, String>(
        (FutureProviderRef<EODReport?> ref, String reportId) async =>
            await EODService.getEODReportById(reportId));

/// Provider لإحصائيات تقارير نهاية اليوم
final FutureProviderFamily<Map<String, dynamic>, Map<String, DateTime?>>
    eodReportsStatisticsProvider =
    FutureProvider.family<Map<String, dynamic>, Map<String, DateTime?>>(
        (FutureProviderRef<Map<String, dynamic>> ref,
            Map<String, DateTime?> params) async {
  final DateTime? startDate = params['startDate'];
  final DateTime? endDate = params['endDate'];

  return await EODService.getEODReportsStatistics(
    startDate: startDate,
    endDate: endDate,
  );
});

/// Provider لحالة التحديث
final StateProvider<bool> eodReportsRefreshProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Provider لإعادة تحميل تقارير نهاية اليوم
final Provider<void Function()> refreshEODReportsProvider =
    Provider<void Function()>((ProviderRef<void Function()> ref) => () {
          ref.invalidate(localEODReportsProvider);
          ref.invalidate(firebaseEODReportsProvider);
          ref.invalidate(searchEODReportsProvider);
          ref.invalidate(eodReportByIdProvider);
          ref.invalidate(eodReportsStatisticsProvider);
          ref.read(eodReportsRefreshProvider.notifier).state =
              !ref.read(eodReportsRefreshProvider);
        });

/// Provider لحالة معالجة تقرير نهاية اليوم
final StateProvider<bool> eodProcessingProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);

/// Provider لحالة مزامنة التقارير
final StateProvider<bool> eodSyncProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => false);
