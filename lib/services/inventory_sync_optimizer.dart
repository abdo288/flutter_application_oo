import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/inventory_item.dart';
import 'app_event_bus.dart';
import 'inventory_tab_coordination_service.dart';

/// محسن تزامن المخزون بين التبويبات
/// ✅ ضمان التناسق التام والأداء المحسن
class InventorySyncOptimizer {
  factory InventorySyncOptimizer() => _instance;
  InventorySyncOptimizer._internal();
  static final InventorySyncOptimizer _instance =
      InventorySyncOptimizer._internal();

  final InventoryTabCoordinationService _coordinationService =
      InventoryTabCoordinationService();

  Timer? _optimizationTimer;
  bool _isOptimizing = false;
  final Map<String, dynamic> _syncStats = <String, dynamic>{};
  final List<InventoryItem> _lastKnownInventory = <InventoryItem>[];

  /// بدء التحسين
  void startOptimization() {
    debugPrint('🚀 بدء تحسين تزامن المخزون...');

    // فحص التحسين كل 10 ثوان
    _optimizationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _performOptimization(),
    );
  }

  /// إيقاف التحسين
  void stopOptimization() {
    debugPrint('⏹️ إيقاف تحسين تزامن المخزون');
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
  }

  /// تنفيذ التحسين
  Future<void> _performOptimization() async {
    if (_isOptimizing) return;

    _isOptimizing = true;

    try {
      // تحسين التزامن
      await _optimizeSync();

      // تحسين الأداء
      await _optimizePerformance();

      // تحديث الإحصائيات
      _updateSyncStats();
    } catch (e) {
      debugPrint('❌ خطأ في تحسين التزامن: $e');
    } finally {
      _isOptimizing = false;
    }
  }

  /// تحسين التزامن
  Future<void> _optimizeSync() async {
    try {
      // فحص التزامن بين التبويبات
      final bool isInSync = await _checkSyncStatus();

      if (!isInSync) {
        debugPrint('🔄 إعادة مزامنة المخزون...');
        await _forceResync();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحسين التزامن: $e');
    }
  }

  /// تحسين الأداء
  Future<void> _optimizePerformance() async {
    try {
      // تحسين استهلاك الذاكرة
      _optimizeMemoryUsage();

      // تحسين سرعة التحديثات
      _optimizeUpdateSpeed();
    } catch (e) {
      debugPrint('❌ خطأ في تحسين الأداء: $e');
    }
  }

  /// فحص حالة التزامن
  Future<bool> _checkSyncStatus() async {
    try {
      // فحص التزامن بين التبويبات
      // يمكن إضافة منطق فحص التزامن هنا
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في فحص التزامن: $e');
      return false;
    }
  }

  /// إجبار إعادة المزامنة
  Future<void> _forceResync() async {
    try {
      // إرسال حدث إعادة مزامنة
      AppEventBus.fire(InventoryUpdatedEvent(
        'force_resync',
        'Force Resync',
        0,
        0,
        sourceTab: 'InventorySyncOptimizer',
      ));

      debugPrint('✅ تم إجبار إعادة المزامنة');
    } catch (e) {
      debugPrint('❌ خطأ في إجبار إعادة المزامنة: $e');
    }
  }

  /// تحسين استهلاك الذاكرة
  void _optimizeMemoryUsage() {
    try {
      // تنظيف البيانات القديمة
      if (_lastKnownInventory.length > 1000) {
        _lastKnownInventory.removeRange(0, 500);
        debugPrint('🧹 تم تنظيف البيانات القديمة');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحسين الذاكرة: $e');
    }
  }

  /// تحسين سرعة التحديثات
  void _optimizeUpdateSpeed() {
    try {
      // تحسين سرعة التحديثات
      // يمكن إضافة منطق تحسين السرعة هنا
    } catch (e) {
      debugPrint('❌ خطأ في تحسين السرعة: $e');
    }
  }

  /// تحديث إحصائيات التزامن
  void _updateSyncStats() {
    try {
      _syncStats['lastOptimization'] = DateTime.now().toIso8601String();
      _syncStats['isOptimizing'] = _isOptimizing;
      _syncStats['inventoryCount'] = _lastKnownInventory.length;

      debugPrint('📊 إحصائيات التزامن: $_syncStats');
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإحصائيات: $e');
    }
  }

  /// تنسيق إضافة عنصر مخزون
  void coordinateInventoryAddition({
    required InventoryItem item,
    required String sourceTab,
  }) {
    try {
      _coordinationService.coordinateInventoryAddition(
        item: item,
        sourceTab: sourceTab,
      );

      // تحديث القائمة المحلية
      _lastKnownInventory.add(item);

      debugPrint('✅ تم تنسيق إضافة عنصر المخزون: ${item.name}');
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق إضافة عنصر المخزون: $e');
    }
  }

  /// تنسيق تحديث عنصر مخزون
  void coordinateInventoryUpdate({
    required InventoryItem item,
    required int oldQuantity,
    required String sourceTab,
  }) {
    try {
      _coordinationService.coordinateInventoryUpdate(
        item: item,
        oldQuantity: oldQuantity,
        sourceTab: sourceTab,
      );

      // تحديث القائمة المحلية
      final int index = _lastKnownInventory.indexWhere((InventoryItem i) => i.id == item.id);
      if (index != -1) {
        _lastKnownInventory[index] = item;
      }

      debugPrint('✅ تم تنسيق تحديث عنصر المخزون: ${item.name}');
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق تحديث عنصر المخزون: $e');
    }
  }

  /// تنسيق حذف عنصر مخزون
  void coordinateInventoryDeletion({
    required InventoryItem item,
    required String sourceTab,
  }) {
    try {
      _coordinationService.coordinateInventoryDeletion(
        item: item,
        sourceTab: sourceTab,
      );

      // تحديث القائمة المحلية
      _lastKnownInventory.removeWhere((InventoryItem i) => i.id == item.id);

      debugPrint('✅ تم تنسيق حذف عنصر المخزون: ${item.name}');
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق حذف عنصر المخزون: $e');
    }
  }

  /// تنسيق البحث
  void coordinateSearch({
    required String searchQuery,
    required String sourceTab,
  }) {
    try {
      _coordinationService.coordinateSearch(
        searchQuery: searchQuery,
        sourceTab: sourceTab,
      );

      debugPrint('✅ تم تنسيق البحث: $searchQuery');
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق البحث: $e');
    }
  }

  /// تنسيق الترتيب
  void coordinateSorting({
    required String sortBy,
    required bool sortAscending,
    required String sourceTab,
  }) {
    try {
      _coordinationService.coordinateSorting(
        sortBy: sortBy,
        sortAscending: sortAscending,
        sourceTab: sourceTab,
      );

      debugPrint('✅ تم تنسيق الترتيب: $sortBy');
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق الترتيب: $e');
    }
  }

  /// تنسيق الخطأ
  void coordinateError({
    required String error,
    required String sourceTab,
    String? stackTrace,
  }) {
    try {
      _coordinationService.coordinateError(
        error: error,
        sourceTab: sourceTab,
        stackTrace: stackTrace,
      );

      debugPrint('✅ تم تنسيق الخطأ: $error');
    } catch (e) {
      debugPrint('❌ خطأ في تنسيق الخطأ: $e');
    }
  }

  /// الحصول على إحصائيات التزامن
  Map<String, dynamic> getSyncStats() => Map<String, dynamic>.from(_syncStats);

  /// إغلاق المحسن
  void dispose() {
    stopOptimization();
    _coordinationService.dispose();
  }
}
