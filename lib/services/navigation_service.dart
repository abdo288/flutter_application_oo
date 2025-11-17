import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_event_bus.dart';
import 'app_state_manager.dart';
import 'cross_tab_sync_service.dart';

/// خدمة التنقل مع تمرير البيانات
class NavigationService {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static void Function(int)? _onTabTapped;

  /// تهيئة NavigationService
  static void initialize({
    required GlobalKey<NavigatorState> navigatorKey,
    required void Function(int) onTabTapped,
  }) {
    _navigatorKey = navigatorKey;
    _onTabTapped = onTabTapped;
    debugPrint('🚀 تم تهيئة NavigationService');
  }

  /// الانتقال إلى تبويب مع بيانات
  static void navigateToTab(
    Ref ref,
    int tabIndex, {
    Map<String, dynamic>? data,
    String? sourceTab,
    bool clearPreviousData = false,
  }) {
    if (_onTabTapped == null) {
      debugPrint('❌ NavigationService غير مهيأ');
      return;
    }

    final BuildContext? context = _navigatorKey?.currentContext;
    if (context == null) {
      debugPrint('❌ لا يمكن الوصول إلى BuildContext');
      return;
    }

    try {
      // 1. حفظ البيانات في AppStateNotifier
      if (data != null) {
        final AppStateNotifier stateManager =
            ref.read(appStateNotifierProvider.notifier);

        if (clearPreviousData) {
          // مسح البيانات السابقة
          for (final String key in data.keys) {
            stateManager.removeSharedData('nav_$key');
          }
        }

        // حفظ البيانات الجديدة
        data.forEach((String key, value) {
          stateManager.setSharedData('nav_$key', value);
        });

        debugPrint('💾 حفظ بيانات التنقل: ${data.keys.join(', ')}');
      }

      // 2. إطلاق حدث تغيير التبويب
      AppEventBus.fire(TabChangedEvent(
        _getCurrentTabIndex(context),
        tabIndex,
        data: data,
      ));

      // 3. الانتقال
      _onTabTapped!(tabIndex);

      // 4. مسح البيانات بعد 10 ثواني (اختياري)
      if (data != null) {
        Future.delayed(const Duration(seconds: 10), () {
          _clearNavigationData(ref, data.keys.toList());
        });
      }

      debugPrint('🔄 الانتقال إلى التبويب: $tabIndex');
    } catch (e) {
      debugPrint('❌ خطأ في التنقل: $e');
    }
  }

  /// الانتقال مع فلتر
  static void navigateWithFilter(
    Ref ref,
    int tabIndex,
    String filterType,
    filterValue, {
    String? sourceTab,
  }) {
    navigateToTab(
      ref,
      tabIndex,
      data: <String, dynamic>{
        'filterType': filterType,
        'filterValue': filterValue,
        'sourceTab': sourceTab,
      },
      sourceTab: sourceTab,
    );
  }

  /// الانتقال مع بحث
  static void navigateWithSearch(
    Ref ref,
    int tabIndex,
    String searchQuery, {
    String? sourceTab,
  }) {
    navigateToTab(
      ref,
      tabIndex,
      data: <String, dynamic>{
        'searchQuery': searchQuery,
        'sourceTab': sourceTab,
      },
      sourceTab: sourceTab,
    );
  }

  /// الانتقال مع تمييز عنصر
  static void navigateWithHighlight(
    Ref ref,
    int tabIndex,
    String itemId, {
    String? sourceTab,
  }) {
    navigateToTab(
      ref,
      tabIndex,
      data: <String, dynamic>{
        'highlightItemId': itemId,
        'sourceTab': sourceTab,
      },
      sourceTab: sourceTab,
    );
  }

  /// الانتقال مع إجراء
  static void navigateWithAction(
    Ref ref,
    int tabIndex,
    String action, {
    Map<String, dynamic>? actionData,
    String? sourceTab,
  }) {
    final Map<String, dynamic> data = <String, dynamic>{
      'action': action,
      'sourceTab': sourceTab,
    };

    if (actionData != null) {
      data.addAll(actionData);
    }

    navigateToTab(
      ref,
      tabIndex,
      data: data,
      sourceTab: sourceTab,
    );
  }

  /// قراءة بيانات التنقل
  static T? getNavigationData<T>(Ref ref, String key) {
    try {
      final AppStateNotifier stateManager =
          ref.read(appStateNotifierProvider.notifier);
      return stateManager.getSharedData<T>('nav_$key');
    } catch (e) {
      debugPrint('❌ خطأ في قراءة بيانات التنقل: $e');
      return null;
    }
  }

  /// مسح بيانات التنقل
  static void clearNavigationData(Ref ref, List<String> keys) {
    _clearNavigationData(ref, keys);
  }

  /// مسح جميع بيانات التنقل
  static void clearAllNavigationData(Ref ref) {
    try {
      final AppStateNotifier stateManager =
          ref.read(appStateNotifierProvider.notifier);
      final Map<String, dynamic> sharedData =
          stateManager.getSharedData<Map<String, dynamic>>('_sharedData') ??
              <String, dynamic>{};
      final List<String> navKeys = sharedData.keys
          .where((String key) => key.startsWith('nav_'))
          .toList();

      for (final String key in navKeys) {
        stateManager.removeSharedData(key);
      }

      debugPrint('🧹 مسح جميع بيانات التنقل');
    } catch (e) {
      debugPrint('❌ خطأ في مسح بيانات التنقل: $e');
    }
  }

  /// الحصول على التبويب الحالي
  static int _getCurrentTabIndex(BuildContext context) {
    // يمكن تحسين هذا لاحقاً
    return 0;
  }

  /// مسح بيانات التنقل
  static void _clearNavigationData(Ref ref, List<String> keys) {
    try {
      final AppStateNotifier stateManager =
          ref.read(appStateNotifierProvider.notifier);
      for (final String key in keys) {
        stateManager.removeSharedData('nav_$key');
      }
      debugPrint('🧹 مسح بيانات التنقل: ${keys.join(', ')}');
    } catch (e) {
      debugPrint('❌ خطأ في مسح بيانات التنقل: $e');
    }
  }
}

/// مساعد للتنقل مع التبويبات
class TabNavigationHelper {
  /// الانتقال إلى ProductList مع فلتر
  static void goToProductListWithFilter(
    Ref ref,
    String filterType,
    filterValue,
  ) {
    NavigationService.navigateWithFilter(
      ref,
      3, // ProductList tab index
      filterType,
      filterValue,
      sourceTab: 'helper',
    );
  }

  /// الانتقال إلى Inventory مع فلتر
  static void goToInventoryWithFilter(
    Ref ref,
    String filterType,
    filterValue,
  ) {
    NavigationService.navigateWithFilter(
      ref,
      2, // ProductForm tab index (نموذج المنتج)
      filterType,
      filterValue,
      sourceTab: 'helper',
    );
  }

  /// الانتقال إلى POS مع منتج
  static void goToPOSWithProduct(
    Ref ref,
    String productId,
  ) {
    NavigationService.navigateWithAction(
      ref,
      4, // POS tab index
      'addProduct',
      actionData: <String, dynamic>{'productId': productId},
      sourceTab: 'helper',
    );
  }

  /// الانتقال إلى Dashboard مع إحصائيات
  static void goToDashboardWithStats(
    Ref ref,
    Map<String, dynamic> stats,
  ) {
    NavigationService.navigateToTab(
      ref,
      0, // Dashboard tab index
      data: <String, dynamic>{
        'stats': stats,
        'refreshStats': true,
      },
      sourceTab: 'helper',
    );
  }

  /// الانتقال إلى AddProduct مع بيانات
  static void goToAddProductWithData(
    Ref ref,
    Map<String, dynamic> productData,
  ) {
    NavigationService.navigateToTab(
      ref,
      1, // AddProduct tab index
      data: <String, dynamic>{
        'productData': productData,
        'prefillForm': true,
      },
      sourceTab: 'helper',
    );
  }
}

/// مساعد للتنقل مع الأحداث
class EventNavigationHelper {
  /// معالجة حدث إضافة منتج
  static void handleProductAdded(
    Ref ref,
    ProductAddedEvent event,
  ) {
    // الانتقال إلى ProductList مع تمييز المنتج الجديد
    NavigationService.navigateWithHighlight(
      ref,
      3, // ProductList tab index
      event.product.id ?? '',
      sourceTab: event.sourceTab,
    );
  }

  /// معالجة حدث تحديث مخزون
  static void handleInventoryUpdated(
    Ref ref,
    InventoryUpdatedEvent event,
  ) {
    // الانتقال إلى Inventory مع تمييز العنصر المحدث
    NavigationService.navigateWithHighlight(
      ref,
      2, // ProductForm tab index (نموذج المنتج)
      event.itemId,
      sourceTab: event.sourceTab,
    );
  }

  /// معالجة حدث إتمام بيع
  static void handleSaleCompleted(
    Ref ref,
    SaleCompletedEvent event,
  ) {
    // إطلاق حدث تحديث التقارير
    AppEventBus.fire(ReportsUpdateEvent(
      'sale',
      sourceTab: event.sourceTab,
      data: <String, dynamic>{
        'saleId': event.sale.id,
        'saleAmount': event.sale.totalAmount,
        'saleDate': event.sale.saleDate.toIso8601String(),
      },
    ));

    // إشعار CrossTabSyncService
    CrossTabSyncService.notifyReportsUpdate(
      'sale',
      sourceTab: event.sourceTab,
      data: <String, dynamic>{
        'saleId': event.sale.id,
        'saleAmount': event.sale.totalAmount,
      },
    );

    // الانتقال إلى Dashboard مع تحديث الإحصائيات
    NavigationService.navigateToTab(
      ref,
      0, // Dashboard tab index
      data: <String, dynamic>{
        'refreshStats': true,
        'showSaleSuccess': true,
        'saleAmount': event.sale.totalAmount,
        'triggerReportsUpdate': true,
      },
      sourceTab: event.sourceTab,
    );
  }

  /// معالجة حدث تنبيه مخزون منخفض
  static void handleLowStockAlert(
    Ref ref,
    LowStockAlertEvent event,
  ) {
    // الانتقال إلى Inventory مع فلتر المخزون المنخفض
    NavigationService.navigateWithFilter(
      ref,
      2, // ProductForm tab index (نموذج المنتج)
      'lowStock',
      true,
      sourceTab: 'alert',
    );
  }
}

/// مساعد للتنقل مع البيانات المعقدة
class ComplexNavigationHelper {
  /// الانتقال مع بيانات منتج كاملة
  static void navigateWithProductData(
    Ref ref,
    int tabIndex,
    Map<String, dynamic> productData, {
    String? sourceTab,
  }) {
    NavigationService.navigateToTab(
      ref,
      tabIndex,
      data: <String, dynamic>{
        'productData': productData,
        'navigationType': 'product',
        'sourceTab': sourceTab,
      },
      sourceTab: sourceTab,
    );
  }

  /// الانتقال مع بيانات مخزون كاملة
  static void navigateWithInventoryData(
    Ref ref,
    int tabIndex,
    Map<String, dynamic> inventoryData, {
    String? sourceTab,
  }) {
    NavigationService.navigateToTab(
      ref,
      tabIndex,
      data: <String, dynamic>{
        'inventoryData': inventoryData,
        'navigationType': 'inventory',
        'sourceTab': sourceTab,
      },
      sourceTab: sourceTab,
    );
  }

  /// الانتقال مع بيانات بيع كاملة
  static void navigateWithSaleData(
    Ref ref,
    int tabIndex,
    Map<String, dynamic> saleData, {
    String? sourceTab,
  }) {
    NavigationService.navigateToTab(
      ref,
      tabIndex,
      data: <String, dynamic>{
        'saleData': saleData,
        'navigationType': 'sale',
        'sourceTab': sourceTab,
      },
      sourceTab: sourceTab,
    );
  }
}
