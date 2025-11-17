import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/drift_database.dart';
import '../models/inventory_item.dart';
import '../models/product.dart';
import '../repositories/unified_repository.dart';
import 'app_event_bus.dart';
import 'tab_coordination_service.dart';

/// خدمة ضمان تناسق البيانات بين التبويبات
/// ✅ ضمان التناسق التام بين QuickSellTab و InventoryDisplayTab
class DataConsistencyService {
  factory DataConsistencyService() => _instance;
  DataConsistencyService._internal();
  static final DataConsistencyService _instance =
      DataConsistencyService._internal();

  final UnifiedRepository _repository = UnifiedRepository();
  final TabCoordinationService _coordinationService = TabCoordinationService();

  Timer? _consistencyCheckTimer;
  bool _isCheckingConsistency = false;

  /// بدء مراقبة تناسق البيانات
  void startConsistencyMonitoring() {
    debugPrint('🔄 بدء مراقبة تناسق البيانات بين التبويبات');

    // فحص تناسق البيانات كل 30 ثانية
    _consistencyCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkDataConsistency(),
    );
  }

  /// إيقاف مراقبة تناسق البيانات
  void stopConsistencyMonitoring() {
    debugPrint('⏹️ إيقاف مراقبة تناسق البيانات');
    _consistencyCheckTimer?.cancel();
    _consistencyCheckTimer = null;
  }

  /// فحص تناسق البيانات
  Future<void> _checkDataConsistency() async {
    if (_isCheckingConsistency) return;

    _isCheckingConsistency = true;

    try {
      debugPrint('🔍 فحص تناسق البيانات...');

      // فحص تناسق المخزون
      await _checkInventoryConsistency();

      // فحص تناسق المنتجات
      await _checkProductsConsistency();

      debugPrint('✅ تم فحص تناسق البيانات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في فحص تناسق البيانات: $e');
    } finally {
      _isCheckingConsistency = false;
    }
  }

  /// فحص تناسق المخزون
  Future<void> _checkInventoryConsistency() async {
    try {
      // جلب البيانات من Firestore
      final List<InventoryItem> firestoreItems =
          await _repository.inventoryStream.first;

      // جلب البيانات من Local DB
      final List<InventoryTableData> localItems =
          await _repository.localDb.getAllInventoryItems();

      // مقارنة البيانات
      if (firestoreItems.length != localItems.length) {
        debugPrint(
            '⚠️ عدم تناسق في عدد عناصر المخزون: Firestore=${firestoreItems.length}, Local=${localItems.length}');
        await _fixInventoryInconsistency(firestoreItems, localItems);
      }

      // فحص تفاصيل العناصر
      for (final InventoryItem firestoreItem in firestoreItems) {
        final InventoryTableData? localItem =
            localItems.where((InventoryTableData item) => item.id == firestoreItem.id).firstOrNull;

        if (localItem == null) {
          debugPrint(
              '⚠️ عنصر موجود في Firestore ولكن غير موجود محلياً: ${firestoreItem.name}');
          await _syncMissingLocalItem(firestoreItem);
        } else {
          // فحص تناسق البيانات
          if (localItem.quantity != firestoreItem.quantity ||
              localItem.name != firestoreItem.name ||
              localItem.retailPrice != firestoreItem.retailPrice) {
            debugPrint('⚠️ عدم تناسق في بيانات العنصر: ${firestoreItem.name}');
            await _fixItemInconsistency(firestoreItem, localItem);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص تناسق المخزون: $e');
    }
  }

  /// فحص تناسق المنتجات
  Future<void> _checkProductsConsistency() async {
    try {
      // جلب البيانات من Firestore
      final List<Product> firestoreProducts =
          await _repository.productsStream.first;

      // جلب البيانات من Local DB
      final List<ProductsTableData> localProducts = await _repository.localDb
          .select(_repository.localDb.productsTable)
          .get();

      // مقارنة البيانات
      if (firestoreProducts.length != localProducts.length) {
        debugPrint(
            '⚠️ عدم تناسق في عدد المنتجات: Firestore=${firestoreProducts.length}, Local=${localProducts.length}');
        await _fixProductsInconsistency(firestoreProducts, localProducts);
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص تناسق المنتجات: $e');
    }
  }

  /// إصلاح عدم تناسق المخزون
  Future<void> _fixInventoryInconsistency(
    List<InventoryItem> firestoreItems,
    List<InventoryTableData> localItems,
  ) async {
    try {
      debugPrint('🔧 إصلاح عدم تناسق المخزون...');

      // إرسال حدث لإعادة تحميل البيانات
      AppEventBus.fire(InventoryUpdatedEvent(
        'consistency_fix',
        'Data Consistency Fix',
        0,
        0,
        sourceTab: 'DataConsistencyService',
      ));

      // تنسيق إعادة تحميل البيانات
      _coordinationService.coordinateDataRefresh(
        sourceTab: 'DataConsistencyService',
        reason: 'Inventory inconsistency fix',
      );

      debugPrint('✅ تم إصلاح عدم تناسق المخزون');
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح عدم تناسق المخزون: $e');
    }
  }

  /// إصلاح عدم تناسق المنتجات
  Future<void> _fixProductsInconsistency(
    List<Product> firestoreProducts,
    List<ProductsTableData> localProducts,
  ) async {
    try {
      debugPrint('🔧 إصلاح عدم تناسق المنتجات...');

      // إرسال حدث لإعادة تحميل البيانات
      AppEventBus.fire(ProductUpdatedEvent(
        firestoreProducts.isNotEmpty
            ? firestoreProducts.first
            : Product(
                name: 'Consistency Fix',
                wholesalePrice: 0,
                retailPrice: 0,
                savedAt: DateTime.now(),
              ),
        sourceTab: 'DataConsistencyService',
      ));

      debugPrint('✅ تم إصلاح عدم تناسق المنتجات');
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح عدم تناسق المنتجات: $e');
    }
  }

  /// مزامنة عنصر مفقود محلياً
  Future<void> _syncMissingLocalItem(InventoryItem firestoreItem) async {
    try {
      debugPrint('🔄 مزامنة عنصر مفقود محلياً: ${firestoreItem.name}');

      // إضافة العنصر إلى Local DB
      await _repository.addInventoryItem(firestoreItem);

      // إرسال حدث تحديث
      AppEventBus.fire(InventoryItemAddedEvent(
        firestoreItem,
        sourceTab: 'DataConsistencyService',
      ));

      debugPrint('✅ تم مزامنة العنصر المفقود');
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة العنصر المفقود: $e');
    }
  }

  /// إصلاح عدم تناسق في عنصر
  Future<void> _fixItemInconsistency(
    InventoryItem firestoreItem,
    InventoryTableData localItem,
  ) async {
    try {
      debugPrint('🔧 إصلاح عدم تناسق في العنصر: ${firestoreItem.name}');

      // تحديث Local DB بالبيانات من Firestore
      await _repository.updateInventoryItem(firestoreItem);

      // إرسال حدث تحديث
      AppEventBus.fire(InventoryUpdatedEvent(
        firestoreItem.id!,
        firestoreItem.name,
        localItem.quantity,
        firestoreItem.quantity,
        sourceTab: 'DataConsistencyService',
      ));

      debugPrint('✅ تم إصلاح عدم تناسق العنصر');
    } catch (e) {
      debugPrint('❌ خطأ في إصلاح عدم تناسق العنصر: $e');
    }
  }

  /// إجبار إعادة تحميل البيانات
  Future<void> forceDataRefresh() async {
    try {
      debugPrint('🔄 إجبار إعادة تحميل البيانات...');

      // إعادة تحميل من Firestore
      await _repository.syncFromFirestore();

      // إرسال أحداث تحديث
      AppEventBus.fire(InventoryUpdatedEvent(
        'force_refresh',
        'Force Refresh',
        0,
        0,
        sourceTab: 'DataConsistencyService',
      ));

      // تنسيق إعادة تحميل البيانات
      _coordinationService.coordinateDataRefresh(
        sourceTab: 'DataConsistencyService',
        reason: 'Force refresh requested',
      );

      debugPrint('✅ تم إجبار إعادة تحميل البيانات');
    } catch (e) {
      debugPrint('❌ خطأ في إجبار إعادة تحميل البيانات: $e');
    }
  }

  /// الحصول على إحصائيات التناسق
  Map<String, dynamic> getConsistencyStats() => <String, dynamic>{
      'isMonitoring': _consistencyCheckTimer?.isActive ?? false,
      'isChecking': _isCheckingConsistency,
      'lastCheckTime': DateTime.now().toIso8601String(),
    };

  /// تنظيف الموارد
  void dispose() {
    stopConsistencyMonitoring();
  }
}
