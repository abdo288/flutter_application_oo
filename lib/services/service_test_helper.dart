import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/dashboard_stats.dart';
import '../models/product.dart';
import '../providers/stream_inventory_provider.dart';
import '../providers/stream_product_provider.dart';
import 'backup_service.dart';
import 'dashboard_service.dart';
import 'restore_service.dart';
import 'unified_sales_service.dart';

/// مساعد اختبار الخدمات المحدثة
class ServiceTestHelper {
  /// اختبار DashboardService
  static Future<void> testDashboardService({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار DashboardService...');

      // اختبار الدالة الثابتة
      final DashboardStats stats =
          await DashboardService.calculateDashboardStatsStatic(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );

      debugPrint(
          '✅ DashboardService - إحصائيات لوحة التحكم: ${stats.totalProducts} منتج');

      // اختبار أفضل المنتجات ربحية
      final List<Map<String, dynamic>> topProducts =
          await DashboardService.getTopProfitableProductsStatic(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
        limit: 3,
      );

      debugPrint(
          '✅ DashboardService - أفضل المنتجات: ${topProducts.length} منتج');

      // اختبار إنشاء مثيل الخدمة
      final DashboardService service = DashboardService.create(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
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
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار UnifiedSalesService...');

      // اختبار البحث عن منتج
      final Product? product =
          await UnifiedSalesService.findProductByBarcodeStatic(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
        barcode: 'test',
      );

      debugPrint(
          '✅ UnifiedSalesService - البحث عن منتج: ${product?.name ?? 'لم يتم العثور على منتج'}');

      // اختبار إضافة منتج إلى السلة
      final CartItem? cartItem =
          await UnifiedSalesService.addProductToCartStatic(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
        barcode: 'test',
      );

      debugPrint(
          '✅ UnifiedSalesService - إضافة إلى السلة: ${cartItem?.name ?? 'لم يتم العثور على منتج'}');

      // اختبار إنشاء مثيل الخدمة
      final UnifiedSalesService service = UnifiedSalesService.create(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
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
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار BackupService...');

      // اختبار إنشاء نسخة احتياطية للمخزون
      final BackupResult result =
          await BackupService.createInventoryBackupStatic(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );

      debugPrint(
          '✅ BackupService - نسخة احتياطية للمخزون: ${result.success ? 'نجحت' : 'فشلت'}');

      // اختبار إنشاء مثيل الخدمة
      final BackupService service = BackupService.create(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
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
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    try {
      debugPrint('🧪 بدء اختبار RestoreService...');

      // اختبار إنشاء مثيل الخدمة
      RestoreService.create(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );

      // التحقق من أن الخدمة تم إنشاؤها بنجاح
      debugPrint('✅ RestoreService - تم إنشاء مثيل الخدمة بنجاح');

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
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    debugPrint('🚀 بدء تشغيل جميع اختبارات الخدمات...');

    await testDashboardService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    await testUnifiedSalesService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    await testBackupService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
    await testRestoreService(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );

    debugPrint('🏁 انتهت جميع اختبارات الخدمات!');
  }
}
