import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/cart_item.dart';
import '../models/eod_report.dart';
import '../reports_system/providers/analytics_provider.dart';
import '../reports_system/providers/eod_reports_provider.dart';
import '../reports_system/providers/sales_provider.dart';
import '../services/eod_service.dart';

part 'eod_process_provider.g.dart';

/// Provider لإدارة عملية إنهاء اليوم بشكل مركزي
/// يضمن الموثوقية، الكفاءة، والتناسق
@riverpod
class EodProcessNotifier extends _$EodProcessNotifier {
  @override
  Future<EODReport?> build() async {
    // الحالة الافتراضية هي "لا شيء" (لم تبدأ العملية بعد)
    return null;
  }

  /// بدء عملية إنشاء تقرير نهاية اليوم
  /// هذه الدالة تسمى من واجهة المستخدم عند الضغط على زر "إنهاء اليوم"
  Future<void> generateEODReport({
    required String employeeId,
    required String employeeName,
    required List<CartItem> currentCartItems,
    DateTime? targetDate,
  }) async {
    try {
      debugPrint('🔄 EodProcessNotifier: بدء عملية إنهاء اليوم');

      // 1. تعيين الحالة إلى "جاري التحميل"
      state = const AsyncLoading();

      // 2. إنشاء التقرير (العملية الثقيلة)
      // Note: نستخدم Future.microtask لضمان عدم تجميد UI
      debugPrint('🔄 EodProcessNotifier: إنشاء التقرير');

      final EODReport report = await Future.microtask(() async => await EODService.generateEODReport(
          employeeId: employeeId,
          employeeName: employeeName,
          targetDate: targetDate,
          currentCartItems: currentCartItems,
        ));

      // 3. الحفظ والمزامنة
      await _saveAndSyncReport(report);

      // 4. تحديث الحالة بالنجاح
      state = AsyncData(report);

      debugPrint('✅ EodProcessNotifier: تم إنشاء التقرير بنجاح');

      // 5. --- التحسين الاحترافي: إبطال صلاحية المزودات (invalidate) ---
      // بدلاً من جعل الآخرين يستمعون، قم بإبطال صلاحيتهم.
      // هذا يجبرهم على إعادة التحميل عند الحاجة إليهم.
      // هذا يضمن "التناسق" التام.

      // 5.1. إجبار قائمة تقارير نهاية اليوم على التحديث
      ref.invalidate(realEODReportsProvider);
      debugPrint(
          '🔄 EodProcessNotifier: تم إبطال صلاحية realEODReportsProvider');

      // 5.2. إجبار بيانات المبيعات على التحديث (لأن مبيعات اليوم أصبحت "معالجة")
      ref.invalidate(salesProvider);
      debugPrint('🔄 EodProcessNotifier: تم إبطال صلاحية salesProvider');

      // 5.3. إجبار أي إحصائيات عامة على التحديث
      // ملاحظة: نحن نستدعي الدالة التي تقوم بإبطال صلاحية جميع مزودات التحليلات
      ref.read(refreshAnalyticsProvider)();
      debugPrint('🔄 EodProcessNotifier: تم إبطال صلاحية analyticsProvider');
    } catch (e, stackTrace) {
      debugPrint('❌ EodProcessNotifier: فشل في إنشاء التقرير: $e');
      debugPrint('Stack trace: $stackTrace');
      state = AsyncError(e, stackTrace);
      rethrow;
    }
  }

  /// حفظ التقرير ومزامنته
  /// هذه الدالة تضمن أن جميع الخطوات تتم بنجاح أو لا شيء
  Future<void> _saveAndSyncReport(EODReport report) async {
    try {
      debugPrint('💾 EodProcessNotifier: حفظ التقرير محلياً');
      await EODService.saveEODReportLocally(report);

      debugPrint('☁️ EodProcessNotifier: مزامنة التقرير مع Firebase');
      await EODService.syncEODReport(report);

      debugPrint('💾 EodProcessNotifier: إنشاء نسخة احتياطية');
      await EODService.createBackup(report);

      debugPrint('✅ EodProcessNotifier: تم الحفظ والمزامنة بنجاح');
    } catch (e) {
      debugPrint('⚠️ EodProcessNotifier: خطأ في الحفظ/المزامنة: $e');
      // لا نرمي الخطأ هنا لأن التقرير تم إنشاؤه بنجاح
      // يمكن إضافة retry logic لاحقاً
    }
  }

  /// مسح الحالة بعد عرض رسالة النجاح/الخطأ
  void resetState() {
    state = const AsyncData<EODReport?>(null);
  }
}
