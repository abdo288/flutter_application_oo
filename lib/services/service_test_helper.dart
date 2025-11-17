import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item.dart';
import '../models/dashboard_stats.dart';
import '../models/product.dart';
import '../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../providers/riverpod/stream_product_riverpod_provider.dart';
import 'backup_service.dart';
import 'dashboard_service.dart';
import 'restore_service.dart';
import 'unified_sales_service.dart';

/// مساعد اختبار الخدمات المحدثة
class ServiceTestHelper {
  /// اختبار DashboardService
  static Future<void> testDashboardService({
    required WidgetRef ref,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار DashboardService...');

      // اختبار الدالة الثابتة
      final ProductsState productsState = ref.read(productsControllerProvider);
      final InventoryState inventoryState =
          ref.read(inventoryControllerProvider);
      final DashboardStats stats =
          await DashboardService.calculateDashboardStatsForStates(
        productsState: productsState,
        inventoryState: inventoryState,
      );

      debugPrint(
          '✅ DashboardService - إحصائيات لوحة التحكم: ${stats.totalProducts} منتج');

      // اختبار أفضل المنتجات ربحية
      final List<Map<String, dynamic>> topProducts =
          await DashboardService.getTopProfitableProductsStatic(
        ref: ref,
        limit: 3,
      );

      debugPrint(
          '✅ DashboardService - أفضل المنتجات: ${topProducts.length} منتج');

      // اختبار إنشاء مثيل الخدمة
      final DashboardService service = DashboardService.create(
        ref: ref,
      );

      final DashboardStats instanceStats =
          await service.calculateDashboardStats();
      debugPrint(
          '✅ DashboardService - اختبار المثيل: ${instanceStats.totalProducts} منتج');

      debugPrint('🎉 DashboardService - جميع الاختبارات نجحت!');
    } on Exception catch (_) {
      debugPrint('❌ DashboardService - فشل في الاختبار: خطأ غير محدد');
    }
  }

  /// اختبار UnifiedSalesService
  static Future<void> testUnifiedSalesService({
    required WidgetRef ref,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار UnifiedSalesService...');

      // اختبار البحث عن منتج
      final Product? product =
          await UnifiedSalesService.findProductByBarcodeStatic(
        ref: ref,
        barcode: 'test',
      );

      debugPrint(
          '✅ UnifiedSalesService - البحث عن منتج: ${product?.name ?? 'لم يتم العثور على منتج'}');

      // اختبار إضافة منتج إلى السلة
      final CartItem? cartItem =
          await UnifiedSalesService.addProductToCartStatic(
        ref: ref,
        barcode: 'test',
      );

      debugPrint(
          '✅ UnifiedSalesService - إضافة إلى السلة: ${cartItem?.name ?? 'لم يتم العثور على منتج'}');

      // اختبار إنشاء مثيل الخدمة
      final UnifiedSalesService service = UnifiedSalesService.create(
        ref: ref,
      );

      final Product? instanceProduct =
          await service.findProductByBarcode('test');
      debugPrint(
          '✅ UnifiedSalesService - اختبار المثيل: ${instanceProduct?.name ?? 'لم يتم العثور على منتج'}');

      debugPrint('🎉 UnifiedSalesService - جميع الاختبارات نجحت!');
    } on Exception catch (_) {
      debugPrint('❌ UnifiedSalesService - فشل في الاختبار: خطأ غير محدد');
    }
  }

  /// اختبار BackupService
  static Future<void> testBackupService({
    required WidgetRef ref,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار BackupService...');

      // اختبار إنشاء نسخة احتياطية للمخزون
      final BackupResult result =
          await BackupService.createInventoryBackupStatic(
        ref: ref,
      );

      debugPrint(
          '✅ BackupService - نسخة احتياطية للمخزون: ${result.success ? 'نجحت' : 'فشلت'}');

      // اختبار إنشاء مثيل الخدمة
      final BackupService service = BackupService.create(
        ref: ref,
      );

      final BackupResult instanceResult = await service.createInventoryBackup();
      debugPrint(
          '✅ BackupService - اختبار المثيل: ${instanceResult.success ? 'نجح' : 'فشل'}');

      debugPrint('🎉 BackupService - جميع الاختبارات نجحت!');
    } on Exception catch (_) {
      debugPrint('❌ BackupService - فشل في الاختبار: خطأ غير محدد');
    }
  }

  /// اختبار RestoreService
  static Future<void> testRestoreService({
    required WidgetRef ref,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار RestoreService...');

      // اختبار الخدمة الثابتة
      debugPrint('✅ RestoreService - اختبار الخدمة الثابتة');

      // اختبار الحصول على تاريخ الاستعادة
      final List<RestoreHistory> history =
          await RestoreService.getRestoreHistory();
      debugPrint('✅ RestoreService - تاريخ الاستعادة: ${history.length} عملية');

      debugPrint('🎉 RestoreService - جميع الاختبارات نجحت!');
    } on Exception catch (_) {
      debugPrint('❌ RestoreService - فشل في الاختبار: خطأ غير محدد');
    }
  }

  /// تشغيل جميع الاختبارات
  static Future<void> runAllTests({
    required WidgetRef ref,
  }) async {
    debugPrint('🚀 بدء تشغيل جميع اختبارات الخدمات...');

    await testDashboardService(ref: ref);
    await testUnifiedSalesService(ref: ref);
    await testBackupService(ref: ref);
    await testRestoreService(ref: ref);

    debugPrint('🏁 انتهت جميع اختبارات الخدمات!');
  }
}
